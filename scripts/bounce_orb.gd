extends StaticBody2D
class_name BounceOrb

const SPRITESHEET_ANIM := preload("res://scripts/spritesheet_anim.gd")
const SHEET_ORB: Texture2D = preload("res://assets/spritesheets/pogo_orb_strip_512x128.png")

const FRAME_W := 128
const FRAME_H := 128
const FRAMES := 4

@onready var sprite: AnimatedSprite2D = $Sprite2D

func _ready() -> void:
	if sprite == null:
		return
	var frames := SpriteFrames.new()
	SPRITESHEET_ANIM.add_strip(frames, "idle", SHEET_ORB, FRAME_W, FRAME_H, FRAMES, 10.0, true)
	sprite.sprite_frames = frames
	sprite.play("idle")

func pulse() -> void:
	if sprite == null:
		return
	sprite.scale = Vector2(1.10, 0.90)
	var t := create_tween()
	t.tween_property(sprite, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
