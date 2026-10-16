# This script is an autoload, that can be accessed from any other script!

extends Node

@onready var jump_sfx = $JumpSfx
@onready var coin_pickup_sfx = $CoinPickup
@onready var death_sfx = $DeathSfx
@onready var respawn_sfx = $RespawnSfx
@onready var level_complete_sfx = $LevelCompleteSfx

var music: AudioStreamPlayer
var track = -1
var streams: Dictionary = {}
var music_fade: Tween

func _ready() -> void:
	music = AudioStreamPlayer.new()
	music.bus = &"music"
	add_child(music)
	jump_sfx.stream = _stream("jump")
	jump_sfx.volume_db = -13
	coin_pickup_sfx.stream = _stream("pickup")
	coin_pickup_sfx.volume_db = -14
	death_sfx.stream = _stream("hurt")
	death_sfx.volume_db = -11
	respawn_sfx.stream = _stream("checkpoint")
	respawn_sfx.volume_db = -13
	level_complete_sfx.stream = _stream("portal")
	level_complete_sfx.volume_db = -12

func _stream(effect: String) -> AudioStream:
	if not streams.has(effect):
		streams[effect] = load("res://Assets/Sound/Swamp/" + effect + ".wav")
	return streams[effect]

func play_effect(effect: String, volume: float = -10, pitch: float = 1) -> void:
	var sound = AudioStreamPlayer.new()
	sound.stream = _stream(effect)
	sound.volume_db = volume
	sound.pitch_scale = pitch
	sound.bus = &"sfx"
	add_child(sound)
	sound.finished.connect(sound.queue_free)
	sound.play()

func start_music(number: int, volume: float = -21) -> void:
	if track == number and music.playing:
		return
	track = number
	if music_fade != null and music_fade.is_valid():
		music_fade.kill()
	var song = _stream("forest_%d" % clampi(number, 1, 4)) as AudioStreamWAV
	song.loop_mode = AudioStreamWAV.LOOP_FORWARD
	song.loop_begin = 0
	song.loop_end = int(song.get_length() * song.mix_rate)
	music.stream = song
	music.volume_db = -40
	music.play()
	music_fade = create_tween()
	music_fade.tween_property(music, "volume_db", volume, 1.2)

func stop_music() -> void:
	if music_fade != null and music_fade.is_valid():
		music_fade.kill()
	music.stop()
	track = -1
