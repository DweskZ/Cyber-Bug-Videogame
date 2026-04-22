extends Area2D
class_name PacketPickup

const SPRITESHEET_ANIM := preload("res://scripts/spritesheet_anim.gd")
const SHEET_BUG: Texture2D = preload("res://assets/spritesheets/bug_pickup_strip_256x64.png")

const FRAME_W := 64
const FRAME_H := 64
const FRAMES := 4

@export var amount := 1

@onready var sprite: AnimatedSprite2D = $Sprite2D

func _ready() -> void:
	if sprite != null:
		var frames := SpriteFrames.new()
		SPRITESHEET_ANIM.add_strip(frames, "idle", SHEET_BUG, FRAME_W, FRAME_H, FRAMES, 8.0, true)
		sprite.sprite_frames = frames
		sprite.play("idle")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	var player := body as PlayerPlatformer
	if player == null:
		return
	var gm := get_tree().root.get_node_or_null("GameManager") as RunState
	if gm != null:
		gm.add_packets(amount)
	queue_free()
