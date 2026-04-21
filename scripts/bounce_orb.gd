extends StaticBody2D
class_name BounceOrb

@onready var sprite: Node2D = $Sprite2D

func pulse() -> void:
	if sprite == null:
		return
	sprite.scale = Vector2(1.10, 0.90)
	var t := create_tween()
	t.tween_property(sprite, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
