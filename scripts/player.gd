extends CharacterBody2D

@export var speed := 140.0
@export var damage := 1
@export var attack_duration := 0.12
@export var attack_cooldown := 0.22
@export var knockback := 220.0

@onready var sword_hitbox: Area2D = $SwordHitbox
@onready var sword_shape: CollisionShape2D = $SwordHitbox/CollisionShape2D

var _facing: Vector2 = Vector2.RIGHT
var _can_attack := true

func _ready() -> void:
	# Player on layer 1, collides with layer 2 (enemy)
	collision_layer = 1
	collision_mask = 2 | 4  # enemies + walls

	# Sword hitbox hits enemies (layer 2) only
	sword_hitbox.collision_layer = 0
	sword_hitbox.collision_mask = 2
	sword_hitbox.monitoring = true

	sword_shape.disabled = true
	sword_hitbox.body_entered.connect(_on_sword_body_entered)

func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_dir.length() > 0.0:
		_facing = input_dir.normalized()

	velocity = input_dir * speed
	move_and_slide()

	if Input.is_action_just_pressed("ui_accept"):
		_attack()

func _attack() -> void:
	if not _can_attack:
		return
	_can_attack = false

	# Put the hitbox in front of the player
	sword_hitbox.position = _facing * 14.0
	sword_shape.disabled = false
	await get_tree().create_timer(attack_duration).timeout
	sword_shape.disabled = true

	await get_tree().create_timer(attack_cooldown).timeout
	_can_attack = true

func _on_sword_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, _facing * knockback)