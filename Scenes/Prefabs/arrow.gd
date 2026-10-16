extends CharacterBody2D

@export var damage: int = 25
@export var gravity: float = 240.0
var flying = true

func shoot(direction: Vector2, speed: float, lifetime: float) -> void:
	velocity = direction.normalized() * speed
	rotation = velocity.angle()
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	if not flying:
		return
	velocity.y += gravity * delta
	rotation = velocity.angle()
	var collision = move_and_collide(velocity * delta)
	if collision == null:
		return
	flying = false
	var target = collision.get_collider()
	if target is Enemy:
		target.take_damage(damage, global_position.x)
		queue_free()
	else:
		# Remain embedded briefly instead of bouncing like the old fireball.
		set_collision_layer_value(5, false)
		collision_mask = 0
		get_tree().create_timer(0.7).timeout.connect(queue_free)
	AudioManager.play_effect("arrow_hit", -13)
