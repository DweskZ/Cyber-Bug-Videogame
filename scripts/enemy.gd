extends CharacterBody2D

@export var max_hp := 3
@export var friction := 900.0

var hp := 0

func _ready() -> void:
	hp = max_hp
	# Enemy on layer 2, collides with layer 1 (player)
	collision_layer = 2
	collision_mask = 1

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	hp -= amount
	if knockback != Vector2.ZERO:
		velocity += knockback
	if hp <= 0:
		queue_free()

func _physics_process(delta: float) -> void:
	# Simple slide-down of knockback
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()