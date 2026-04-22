extends StaticBody2D
class_name BossServer

signal destroyed(server: BossServer)

@export var max_hp := 3
@export var require_down_attack := false

@export var hit_flash_seconds := 0.08

@onready var sprite: Sprite2D = $Sprite2D

var hp := 0

func _ready() -> void:
	hp = max_hp
	# Make it hittable by the player's slash (player SlashHitbox mask=2).
	collision_layer = 2
	# Don't physically collide with anything.
	collision_mask = 0

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if require_down_attack:
		# Down-attack in PlayerPlatformer sends kb = Vector2(0, 260).
		if not (absf(knockback.x) < 0.01 and knockback.y > 0.0):
			_flash(Color(1, 0.6, 0.6, 1))
			return

	hp -= amount
	_flash(Color(2.0, 2.0, 2.0, 1.0))
	if hp <= 0:
		emit_signal("destroyed", self)
		queue_free()

func _flash(tint: Color) -> void:
	if sprite == null:
		return
	var t := create_tween()
	t.tween_property(sprite, "modulate", tint, 0.02)
	t.tween_property(sprite, "modulate", Color(1, 1, 1, 1), hit_flash_seconds)
