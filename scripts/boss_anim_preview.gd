extends Node2D

# Quick visual harness to verify boss sprite anchoring without gameplay/physics noise.

const SHEET_IDLE: Texture2D = preload("res://assets/spritesheets/openclawboss_processed/openclawboss_walk_strip.png")
const SHEET_SWIPE: Texture2D = preload("res://assets/spritesheets/openclawboss_processed/openclawboss_attack_strip.png")
const SHEET_SLAM: Texture2D = preload("res://assets/spritesheets/openclawboss_processed/openclawboss_slam_strip.png")
const SHEET_HURT: Texture2D = preload("res://assets/spritesheets/openclawboss_processed/openclawboss_hurt_strip.png")
const SHEET_DEATH: Texture2D = preload("res://assets/spritesheets/openclawboss_processed/openclawboss_death_strip.png")
const SHEET_LASER: Texture2D = preload("res://assets/spritesheets/openclawboss_processed/openclawboss_laser_strip.png")

const IDLE_FRAMES := 4
const SWIPE_FRAMES := 4
const SLAM_FRAMES := 4
const HURT_FRAMES := 4
const DEATH_FRAMES := 4
const LASER_FRAMES := 4

@export var preview_scale := 0.10
@export var fps_idle := 8.0
@export var fps_swipe := 12.0
@export var fps_slam := 10.0
@export var fps_laser := 10.0
@export var fps_hurt := 10.0
@export var fps_death := 8.0

@onready var sprite: AnimatedSprite2D = $Sprite

func _ready() -> void:
	var frames := SpriteFrames.new()
	_add_strip(frames, "idle", SHEET_IDLE, IDLE_FRAMES, fps_idle, true)
	_add_strip(frames, "swipe", SHEET_SWIPE, SWIPE_FRAMES, fps_swipe, true)
	_add_strip(frames, "slam", SHEET_SLAM, SLAM_FRAMES, fps_slam, true)
	_add_strip(frames, "laser", SHEET_LASER, LASER_FRAMES, fps_laser, true)
	_add_strip(frames, "hurt", SHEET_HURT, HURT_FRAMES, fps_hurt, true)
	_add_strip(frames, "death", SHEET_DEATH, DEATH_FRAMES, fps_death, true)
	sprite.sprite_frames = frames
	sprite.scale = Vector2.ONE * preview_scale
	_cycle()

func _cycle() -> void:
	while true:
		await _play_for("idle", 0.8)
		await _play_for("swipe", 0.8)
		await _play_for("slam", 0.8)
		await _play_for("laser", 0.8)
		await _play_for("hurt", 0.8)
		await _play_for("death", 0.8)

func _play_for(anim: String, seconds: float) -> void:
	sprite.play(anim)
	await get_tree().create_timer(seconds).timeout

func _add_strip(frames: SpriteFrames, anim: String, sheet: Texture2D, frame_count: int, fps: float, loop: bool) -> void:
	if not frames.has_animation(anim):
		frames.add_animation(anim)
	frames.set_animation_speed(anim, fps)
	frames.set_animation_loop(anim, loop)
	var img := sheet.get_image()
	if img == null:
		return
	var fw := int(img.get_width() / frame_count)
	var fh := int(img.get_height())
	img.convert(Image.FORMAT_RGBA8)
	for i in range(frame_count):
		var r := Rect2i(i * fw, 0, fw, fh)
		var sub := img.get_region(r)
		frames.add_frame(anim, ImageTexture.create_from_image(sub))
