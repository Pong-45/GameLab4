class_name Player
extends CharacterBody2D

signal hit_enemy
signal hit_trap 


# --------- VARIABLES ---------- #

@export_category("Player Properties") # You can tweak these changes according to your likings
@export var move_speed : float = 300
@export var jump_force : float = 650
@export var gravity : float = 30
@export var max_jump_count : int = 2
@export var bullet_scene : PackedScene
@export var shoot_cooldown_time : float = 0.36
@export var bullet_lifetime = 2.5

var jump_count : int = 2
var flip_x = false

@export_category("Toggle Functions") # Double jump feature is disable by default (Can be toggled from inspector)
@export var double_jump : = false

var is_grounded : bool = false
var movement_enabled : bool = true
var spawn_point = Vector2(0,0)
var is_attacking = false
var shoot_cooldown_timer = 0.0
var can_damage = true
var is_hurt = false
var is_dying = false
var jump_effect: Tween
var speed_time: float = 0.0
var jump_time: float = 0.0
var portal_cooldown: float = 0.0

@onready var player_sprite : AnimationPlayer = $Avatar/AnimationPlayer
@onready var player_node = $Avatar
@onready var bullet_marker = $BulletMarker
@onready var particle_trails = $ParticleTrails
@onready var death_particles = $DeathParticles



# --------- BUILT-IN FUNCTIONS ---------- #
func _ready() -> void:
	spawn_point = global_position
	if GameManager.save_player_position.x != 0:
		global_position =  GameManager.save_player_position
		GameManager.save_player_position = Vector2.ZERO
	player_sprite.animation_finished.connect(_on_animation_finished)
	if not GameManager.saved_buffs.is_empty():
		speed_time = GameManager.saved_buffs.get("speed", 0.0)
		jump_time = GameManager.saved_buffs.get("jump", 0.0)
		GameManager.saved_buffs.clear()
	
func _physics_process(_delta):
	if is_dying:
		return
	is_grounded = is_on_floor()
	movement()
	_handle_enemy_contact()

func _process(_delta):
	speed_time = maxf(0, speed_time - _delta)
	jump_time = maxf(0, jump_time - _delta)
	portal_cooldown = maxf(0, portal_cooldown - _delta)
	player_animations()
	flip_player()
	handle_shooting()
	if shoot_cooldown_timer > 0:
		shoot_cooldown_timer -= _delta
	
# --------- CUSTOM FUNCTIONS ---------- #

# <-- Player Movement Code -->
func movement():
	# Gravity
	if !is_on_floor():
		velocity.y += gravity
	elif is_on_floor():
		jump_count = max_jump_count
		if abs(velocity.x)>0.5:
			velocity.x *= 0.6
		else:
			velocity.x =0 
	
	handle_jumping()
	
	# Move Player
	if movement_enabled:
		if Input.is_action_pressed("Left"):
			velocity.x = -move_speed * (1.5 if speed_time > 0 else 1.0)
			flip_x = true
		if Input.is_action_pressed("Right"):
			velocity.x = move_speed * (1.5 if speed_time > 0 else 1.0)
			flip_x = false
	if velocity.y > 5000:
		hit_trap.emit()
	move_and_slide()

# Handles jumping functionality (double jump or single jump, can be toggled from inspector)
func handle_jumping():
	if Input.is_action_just_pressed("Jump") and movement_enabled:
		if is_on_floor() and !double_jump:
			jump()
		elif double_jump and jump_count > 0:
			jump()
			jump_count -= 1

# Player jump
func jump():
	jump_tween()
	AudioManager.jump_sfx.play()
	velocity.y = -jump_force * (1.3 if jump_time > 0 else 1.0)
	if not is_attacking and not is_hurt:
		player_sprite.play("Jump")
		player_sprite.seek(0, true)

# Handle Player Animations
func player_animations():
	particle_trails.emitting = false
	if is_dying or is_hurt or is_attacking:
		return
	
	if is_on_floor():
		if abs(velocity.x) > 1:
			particle_trails.emitting = true
			_play_animation("Run" if abs(velocity.x) >= move_speed * 0.8 else "Walk")
		else:
			_play_animation("Idle")
	else:
		_play_animation("Jump")

func _play_animation(animation: String) -> void:
	# Do not restart a one-shot jump while the player is still airborne.
	if player_sprite.assigned_animation != animation:
		player_sprite.play(animation)


# Flip player sprite based on X velocity
func flip_player():
	if flip_x: 
		player_node.scale.x = -1
	else:
		player_node.scale.x = 1
	bullet_marker.position.x = -29 if flip_x else 29

# Tween Animations
func death_tween():
	if is_dying:
		return
	is_dying = true
	is_attacking = false
	is_hurt = false
	can_damage = false
	movement_enabled = false
	velocity = Vector2.ZERO
	if jump_effect != null and jump_effect.is_valid():
		jump_effect.kill()
	scale = Vector2.ONE
	AudioManager.death_sfx.play()
	player_node.modulate = Color.WHITE
	player_sprite.play("Die")
	await player_sprite.animation_finished
	death_particles.emitting = true
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	tween.parallel().tween_property(self, "position", Vector2(position.x,position.y-100), 0.15)
	await tween.finished
	global_position = spawn_point
	await get_tree().create_timer(0.3).timeout
	is_dying = false
	movement_enabled = true
	can_damage = true
	velocity = Vector2.ZERO
	player_sprite.play("Idle")
	AudioManager.respawn_sfx.play()
	respawn_tween()

func respawn_tween():
	var tween = create_tween()
	tween.stop(); tween.play()
	tween.tween_property(self, "scale", Vector2.ONE, 0.15) 
	tween.parallel().tween_property(self, "position", spawn_point, 0.15)

func jump_tween():
	if jump_effect != null and jump_effect.is_valid():
		jump_effect.kill()
	jump_effect = create_tween()
	jump_effect.tween_property(self, "scale", Vector2(0.9, 1.1), 0.1)
	jump_effect.tween_property(self, "scale", Vector2.ONE, 0.1)

func damage_tween():
	is_hurt = true
	is_attacking = false
	player_sprite.play("Hurt")
	var tween = create_tween() 
	tween.stop(); tween.play()
	can_damage = false
	for i in range(1,10):
		tween.tween_property(player_node , "modulate", Color.RED, 0.1)
		tween.tween_property(player_node , "modulate", Color.WHITE, 0.1)
	await tween.finished
	can_damage = not is_dying

func _handle_enemy_contact() -> void:
	if !can_damage:
		return
	var bodies = $Collision.get_overlapping_bodies()
	for body in bodies:
		if body != null:
			_on_collision_body_entered(body)
			
func _apply_enemy_damage(body) -> void:
	var dx = body.position.x - position.x
	velocity.y = -400
	if dx > 0:
		velocity.x = -300
	else:
		velocity.x = 300
	damage_tween()
	hit_enemy.emit()

func receive_hit(amount: int, source: Vector2) -> void:
	if not can_damage or is_dying:
		return
	velocity = Vector2(-260 if source.x > global_position.x else 260, -330)
	damage_tween()
	AudioManager.play_effect("hurt", -11)
	GameManager.damage(amount)
# --------- SIGNALS ---------- #

# Reset the player's position to the current level spawn point if collided with any trap
func _on_collision_body_entered(body):
	if is_dying:
		return
	if body.is_in_group("Traps"):
		hit_trap.emit()
	if body.is_in_group("Enemy") and can_damage:
		_apply_enemy_damage(body)

func handle_shooting():
	if Input.is_action_just_pressed("Shoot") and movement_enabled and not is_hurt and not is_attacking and shoot_cooldown_timer <= 0:
		shoot()

func shoot():
	if bullet_scene == null:
		return
	is_attacking = true
	flip_player()
	player_sprite.play("Attack")
	shoot_cooldown_timer = shoot_cooldown_time
	# Release at frame six, when the bowstring snaps forward.
	await get_tree().create_timer(0.18).timeout
	if is_dying or is_hurt:
		return
	var bullet = bullet_scene.instantiate()
	var sign_x = 1.0 if player_node.scale.x > 0 else -1.0
	var dir = Vector2(sign_x, -0.04)
	get_parent().add_child(bullet)
	bullet.global_position = bullet_marker.global_position
	bullet.shoot(dir, 780, bullet_lifetime)
	AudioManager.play_effect("bow", -11)

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "Attack":
		is_attacking = false
	elif anim_name == "Hurt":
		is_hurt = false
	
