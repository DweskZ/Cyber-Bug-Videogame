extends CharacterBody2D

@export var speed := 70.0
@export var gravity := 980.0
@export var max_hp := 3
@export var patrol_distance := 80.0

@export var touch_damage := 1
@export var touch_knockback_x := 260.0
@export var touch_knockback_y := -140.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var damage_area: Area2D = $DamageArea

var hp := 0
var _dir := -1
var _start_x := 0.0

func _ready() -> void:
	hp = max_hp
	_start_x = global_position.x
	# Enemy: layer 2. Collide with world (4) and player (1).
	collision_layer = 2
	collision_mask = 4 | 1

	damage_area.collision_layer = 0
	damage_area.collision_mask = 1
	damage_area.body_entered.connect(_on_damage_area_body_entered)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	# Patrol left/right in a small range
	velocity.x = _dir * speed
	if abs(global_position.x - _start_x) > patrol_distance:
		_dir *= -1

	move_and_slide()

func _on_damage_area_body_entered(body: Node) -> void:
	if body.has_method("take_hit"):
		var dir_to_player := sign(body.global_position.x - global_position.x)
		if dir_to_player == 0:
			dir_to_player = -_dir
		body.take_hit(touch_damage, Vector2(dir_to_player * touch_knockback_x, touch_knockback_y))

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	hp -= amount
	if knockback != Vector2.ZERO:
		velocity += knockback
	_flash(Color(1, 1, 1, 1))
	if hp <= 0:
		queue_free()

func _flash(tint: Color) -> void:
	if not is_instance_valid(sprite):
		return
	var t := create_tween()
	t.tween_property(sprite, "modulate", tint, 0.05)
	t.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.10)