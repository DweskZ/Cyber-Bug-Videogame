extends StaticBody2D
class_name BossServer

signal destroyed(server: BossServer)

@export var max_hp := 3
@export var require_down_attack := false
@export var auto_add_to_group := true

@export var hit_flash_seconds := 0.08

@onready var sprite: Sprite2D = $Sprite2D

var hp := 0
var active := true

func _ready() -> void:
	if auto_add_to_group:
		add_to_group("boss_servers")
	reset_server()

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

func deactivate() -> void:
	active = false
	visible = false
	# Remove from gameplay collisions, but keep the node around for respawn.
	collision_layer = 0
	collision_mask = 0
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.disabled = true

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
		deactivate()
		emit_signal("destroyed", self)

func _flash(tint: Color) -> void:
	if sprite == null:
		return
	var t := create_tween()
	t.tween_property(sprite, "modulate", tint, 0.02)
	t.tween_property(sprite, "modulate", Color(1, 1, 1, 1), hit_flash_seconds)
