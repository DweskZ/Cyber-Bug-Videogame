extends CharacterBody2D

@export var speed := 70.0
@export var gravity := 980.0
@export var max_hp := 3
@export var patrol_distance := 80.0

var hp := 0
var _dir := -1
var _start_x := 0.0

func _ready() -> void:
	hp = max_hp
	_start_x = global_position.x
	# Enemy: layer 2. Collide with world (4) and player (1).
	collision_layer = 2
	collision_mask = 4 | 1

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	# Patrol left/right in a small range
	velocity.x = _dir * speed
	if abs(global_position.x - _start_x) > patrol_distance:
		_dir *= -1

	move_and_slide()

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	hp -= amount
	if knockback != Vector2.ZERO:
		velocity += knockback
	if hp <= 0:
		queue_free()