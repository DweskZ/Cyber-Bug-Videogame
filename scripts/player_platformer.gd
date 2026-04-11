extends CharacterBody2D

@export var speed := 210.0
@export var accel := 1800.0
@export var jump_velocity := -360.0
@export var gravity := 980.0

@export var damage := 1
@export var attack_duration := 0.10
@export var attack_cooldown := 0.18

@onready var slash_pivot: Node2D = $SlashPivot
@onready var slash_hitbox: Area2D = $SlashPivot/SlashHitbox
@onready var slash_shape: CollisionShape2D = $SlashPivot/SlashHitbox/CollisionShape2D
@onready var slash_sprite: Sprite2D = $SlashPivot/SlashSprite

var _facing := 1
var _can_attack := true

func _ready() -> void:
	# Player: layer 1. Collide with world (layer 3 = 4) and enemies (layer 2 = 2).
	collision_layer = 1
	collision_mask = 4 | 2

	# Slash hitbox hits enemies only.
	slash_hitbox.collision_layer = 0
	slash_hitbox.collision_mask = 2
	slash_shape.disabled = true
	slash_sprite.visible = false
	slash_hitbox.body_entered.connect(_on_slash_body_entered)

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Horizontal movement
	var dir := Input.get_axis("ui_left", "ui_right")
	if dir != 0:
		_facing = sign(dir)
	velocity.x = move_toward(velocity.x, dir * speed, accel * delta)

	# Jump
	if is_on_floor() and Input.is_action_just_pressed("ui_up"):
		velocity.y = jump_velocity

	# Attack
	if Input.is_action_just_pressed("ui_accept"):
		_attack()

	move_and_slide()

func _attack() -> void:
	if not _can_attack:
		return
	_can_attack = false

	# Flip slash to face direction
	slash_pivot.scale.x = _facing
	slash_shape.disabled = false
	slash_sprite.visible = true
	await get_tree().create_timer(attack_duration).timeout
	slash_shape.disabled = true
	slash_sprite.visible = false

	await get_tree().create_timer(attack_cooldown).timeout
	_can_attack = true

func _on_slash_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, Vector2(_facing * 220.0, -80.0))