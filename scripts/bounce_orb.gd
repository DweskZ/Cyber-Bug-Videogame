extends Area2D
class_name BounceOrb

@export var bounce_velocity := -520.0
@export var bounce_only_when_falling := true
@export var require_down_attack := true
@export var cooldown := 0.05

@onready var sprite: Node2D = $Sprite2D

var _cooldown_t := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if _cooldown_t > 0.0:
		_cooldown_t = maxf(_cooldown_t - delta, 0.0)

func _on_body_entered(body: Node) -> void:
	if _cooldown_t > 0.0:
		return

	var player := body as PlayerPlatformer
	if player == null:
		return

	if require_down_attack and not player.is_down_attack_active():
		return

	if bounce_only_when_falling and player.velocity.y < 0.0:
		return

	player.velocity.y = bounce_velocity
	player.reset_pogo()

	# Tiny squash feedback
	sprite.scale = Vector2(1.08, 0.92)
	var t := create_tween()
	t.tween_property(sprite, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_cooldown_t = cooldown
