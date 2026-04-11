extends CharacterBody2D
class_name OpenClawBoss

@export var gravity := 980.0
@export var max_hp := 25
@export var move_speed := 70.0

@export var touch_damage := 2

# Attack tuning
@export var swipe_range := 70.0
@export var swipe_windup := 0.35
@export var swipe_active := 0.14
@export var swipe_cooldown := 0.65

@export var laser_windup := 0.55
@export var laser_active := 0.30
@export var laser_cooldown := 0.90

@export var slam_windup := 0.35
@export var slam_jump_v := -420.0
@export var slam_active := 0.18
@export var slam_cooldown := 0.90

@onready var sprite: Sprite2D = $Sprite2D
@onready var swipe_area: Area2D = $SwipeArea
@onready var swipe_shape: CollisionShape2D = $SwipeArea/CollisionShape2D
@onready var laser_area: Area2D = $LaserArea
@onready var laser_shape: CollisionShape2D = $LaserArea/CollisionShape2D
@onready var slam_area: Area2D = $SlamArea
@onready var slam_shape: CollisionShape2D = $SlamArea/CollisionShape2D

var hp := 0
var _facing := -1

var _state := "idle"
var _t := 0.0

func _ready() -> void:
	hp = max_hp
	collision_layer = 2
	collision_mask = 4

	_disable_hitboxes()

	swipe_area.body_entered.connect(_on_hitbox_body_entered)
	laser_area.body_entered.connect(_on_hitbox_body_entered)
	slam_area.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	var player := get_tree().current_scene.get_node_or_null("Player") as PlayerPlatformer
	if player != null:
		_facing = int(sign(player.global_position.x - global_position.x))
		if _facing == 0:
			_facing = -1
		sprite.flip_h = _facing > 0

	# State machine
	if _state == "idle":
		_disable_hitboxes()
		velocity.x = 0.0
		# small pacing toward player
		if player != null:
			var dist := absf(player.global_position.x - global_position.x)
			if dist > 90.0:
				velocity.x = float(_facing) * move_speed
			# choose an attack
			_t -= delta
			if _t <= 0.0:
				if dist < swipe_range:
					_start_attack("swipe", swipe_windup)
				else:
					# alternate laser/slam
					if randi() % 2 == 0:
						_start_attack("laser", laser_windup)
					else:
						_start_attack("slam", slam_windup)
	else:
		_t -= delta
		if _state == "swipe_windup":
			velocity.x = 0.0
			scale = Vector2(1.08, 0.92)
			if _t <= 0.0:
				_state = "swipe_active"
				_t = swipe_active
				_enable_swipe()
		elif _state == "swipe_active":
			velocity.x = 0.0
			if _t <= 0.0:
				_end_attack(swipe_cooldown)

		elif _state == "laser_windup":
			velocity.x = 0.0
			scale = Vector2(1.04, 0.96)
			if _t <= 0.0:
				_state = "laser_active"
				_t = laser_active
				_enable_laser()
		elif _state == "laser_active":
			velocity.x = 0.0
			if _t <= 0.0:
				_end_attack(laser_cooldown)

		elif _state == "slam_windup":
			velocity.x = 0.0
			scale = Vector2(1.12, 0.88)
			if _t <= 0.0:
				_state = "slam_jump"
				velocity.y = slam_jump_v
		elif _state == "slam_jump":
			# wait to land
			if is_on_floor() and velocity.y >= 0.0:
				_state = "slam_active"
				_t = slam_active
				_enable_slam()
		elif _state == "slam_active":
			velocity.x = 0.0
			if _t <= 0.0:
				_end_attack(slam_cooldown)

	move_and_slide()

func _start_attack(kind: String, windup: float) -> void:
	scale = Vector2.ONE
	_disable_hitboxes()
	if kind == "swipe":
		_state = "swipe_windup"
		_t = windup
	elif kind == "laser":
		_state = "laser_windup"
		_t = windup
	elif kind == "slam":
		_state = "slam_windup"
		_t = windup

func _end_attack(cooldown: float) -> void:
	scale = Vector2.ONE
	_disable_hitboxes()
	_state = "idle"
	_t = cooldown

func _disable_hitboxes() -> void:
	swipe_shape.disabled = true
	laser_shape.disabled = true
	slam_shape.disabled = true
	swipe_area.monitoring = false
	laser_area.monitoring = false
	slam_area.monitoring = false

func _enable_swipe() -> void:
	swipe_area.position = Vector2(40.0 * float(_facing), 0)
	swipe_shape.disabled = false
	swipe_area.monitoring = true

func _enable_laser() -> void:
	laser_area.position = Vector2(70.0 * float(_facing), -8)
	laser_shape.disabled = false
	laser_area.monitoring = true

func _enable_slam() -> void:
	slam_area.position = Vector2(0, 20)
	slam_shape.disabled = false
	slam_area.monitoring = true

func _on_hitbox_body_entered(body: Node) -> void:
	var player := body as PlayerPlatformer
	if player == null:
		return
	var dir_to_player := int(sign(player.global_position.x - global_position.x))
	if dir_to_player == 0:
		dir_to_player = _facing
	player.take_hit(touch_damage, Vector2(float(dir_to_player) * 320.0, -160.0))

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	hp -= amount
	_flash(Color(2.0, 2.0, 2.0, 1.0))
	if hp <= 0:
		get_tree().change_scene_to_file("res://scenes/KernelEnding.tscn")

func _flash(tint: Color) -> void:
	var t := create_tween()
	t.tween_property(sprite, "modulate", tint, 0.05)
	t.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.12)
