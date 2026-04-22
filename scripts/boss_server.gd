extends StaticBody2D
class_name BossServer

const SPRITESHEET_ANIM := preload("res://scripts/spritesheet_anim.gd")
const SHEET_IDLE: Texture2D = preload("res://assets/spritesheets/server_node_strip_512x128.png")
const SHEET_DESTROY: Texture2D = preload("res://assets/spritesheets/server_destroy_strip_512x128.png")

const FRAME_W := 128
const FRAME_H := 128
const IDLE_FRAMES := 4
const DESTROY_FRAMES := 4

signal destroyed(server: BossServer)

@export var max_hp := 3
@export var require_down_attack := false
@export var auto_add_to_group := true

@export var hit_flash_seconds := 0.08

@onready var sprite: AnimatedSprite2D = $Sprite2D

var hp := 0
var active := true

func _ready() -> void:
	_setup_spriteframes()
	if auto_add_to_group:
		add_to_group("boss_servers")
	reset_server()

func _setup_spriteframes() -> void:
	if sprite == null:
		return
	var frames := SpriteFrames.new()
	SPRITESHEET_ANIM.add_strip(frames, "idle", SHEET_IDLE, FRAME_W, FRAME_H, IDLE_FRAMES, 6.0, true)
	SPRITESHEET_ANIM.add_strip(frames, "destroy", SHEET_DESTROY, FRAME_W, FRAME_H, DESTROY_FRAMES, 12.0, false)
	sprite.sprite_frames = frames

func reset_server() -> void:
	hp = max_hp
	active = true
	visible = true
	# Make it hittable by the player's slash (player SlashHitbox mask=2).
	collision_layer = 2
	# Don't physically collide with anything.
	collision_mask = 0
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.disabled = false
	if sprite != null:
		sprite.modulate = Color(1, 1, 1, 1)
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")

func deactivate() -> void:
	active = false
	visible = false
	# Remove from gameplay collisions, but keep the node around for respawn.
	collision_layer = 0
	collision_mask = 0
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.disabled = true
	if sprite != null:
		sprite.stop()

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if not active:
		return
	if require_down_attack:
		# Down-attack in PlayerPlatformer sends kb = Vector2(0, 260).
		if not (absf(knockback.x) < 0.01 and knockback.y > 0.0):
			_flash(Color(1, 0.6, 0.6, 1))
			return

	hp -= amount
	_flash(Color(2.0, 2.0, 2.0, 1.0))
	if hp <= 0:
		_start_destroy_sequence()
		emit_signal("destroyed", self)

func _start_destroy_sequence() -> void:
	# Mark as inactive immediately so the boss can transition to Hurt as soon as the last server breaks.
	active = false
	collision_layer = 0
	collision_mask = 0
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.disabled = true
	if sprite == null or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation("destroy"):
		deactivate()
		return
	# Keep it visible while the destroy animation plays.
	visible = true
	sprite.modulate = Color(1, 1, 1, 1)
	sprite.play("destroy")
	# Hide after the animation finishes.
	if not sprite.animation_finished.is_connected(_on_destroy_finished):
		sprite.animation_finished.connect(_on_destroy_finished, CONNECT_ONE_SHOT)

func _on_destroy_finished() -> void:
	deactivate()

func _flash(tint: Color) -> void:
	if sprite == null:
		return
	var t := create_tween()
	t.tween_property(sprite, "modulate", tint, 0.02)
	t.tween_property(sprite, "modulate", Color(1, 1, 1, 1), hit_flash_seconds)
