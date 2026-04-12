extends CharacterBody2D
class_name EnemyWalker

const SPRITESHEET_ANIM := preload("res://scripts/spritesheet_anim.gd")

const SHEET_IDLE: Texture2D = preload("res://assets/spritesheets/enemy_idle.png")
const SHEET_RUN: Texture2D = preload("res://assets/spritesheets/enemy_run.png")
const SHEET_ATTACK: Texture2D = preload("res://assets/spritesheets/enemy_attack.png")

const ENEMY_FRAME_W := 128
const ENEMY_FRAME_H := 128

@export var gravity := 980.0
@export var max_hp := 3

@export var patrol_speed := 60.0
@export var patrol_distance := 80.0

@export var aggro_range := 160.0
@export var chase_speed := 90.0

@export var attack_range := 44.0
@export var windup_time := 0.22
@export var active_time := 0.12
@export var cooldown_time := 0.60
@export var lunge_speed := 260.0

@export var touch_damage := 1
@export var touch_knockback_x := 260.0
@export var touch_knockback_y := -140.0

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var damage_area: Area2D = $DamageArea

var hp := 0
var _dir := -1
var _start_x := 0.0

var _sprite_base_pos := Vector2.ZERO
var _anim_t := 0.0

var _cooldown := 0.0
var _attack_phase := 0 # 0=none, 1=windup, 2=active
var _attack_t := 0.0
var _attack_dir := 1

func _ready() -> void:
	hp = max_hp
	_start_x = global_position.x
	_setup_spriteframes()

	# Enemy: layer 2. Collide with world only. Damage is via DamageArea.
	collision_layer = 2
	collision_mask = 4

	damage_area.collision_layer = 0
	damage_area.collision_mask = 1
	damage_area.monitoring = false
	damage_area.body_entered.connect(_on_damage_area_body_entered)

	_sprite_base_pos = sprite.position

func _physics_process(delta: float) -> void:
	# Cooldowns
	if _cooldown > 0.0:
		_cooldown = maxf(_cooldown - delta, 0.0)

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	var player := (get_tree().current_scene.get_node_or_null("Player") as PlayerPlatformer)
	var has_player := player != null
	var dx := 99999.0
	var dist := 99999.0
	if has_player:
		dx = player.global_position.x - global_position.x
		dist = absf(dx)
		_dir = int(sign(dx))
		if _dir == 0:
			_dir = 1

	# Attack state machine
	if _attack_phase == 1:
		# Windup
		velocity.x = 0.0
		scale = Vector2(1.08, 0.92)
		_attack_t -= delta
		if _attack_t <= 0.0:
			_attack_phase = 2
			_attack_t = active_time
			_attack_dir = _dir
			damage_area.monitoring = true
			velocity.x = float(_attack_dir) * lunge_speed
	elif _attack_phase == 2:
		# Active lunge
		_attack_t -= delta
		velocity.x = float(_attack_dir) * lunge_speed
		if _attack_t <= 0.0:
			damage_area.monitoring = false
			scale = Vector2.ONE
			_attack_phase = 0
			_cooldown = cooldown_time
	else:
		# No attack, choose behavior
		scale = Vector2.ONE
		if has_player and dist < aggro_range:
			# If close enough and off cooldown, start windup
			if dist < attack_range and _cooldown <= 0.0 and is_on_floor():
				_attack_phase = 1
				_attack_t = windup_time
				velocity.x = 0.0
			else:
				velocity.x = float(_dir) * chase_speed
		else:
			# Patrol
			velocity.x = float(_dir) * patrol_speed
			if absf(global_position.x - _start_x) > patrol_distance:
				_dir *= -1

	move_and_slide()
	_update_visuals(delta)

func _update_visuals(delta: float) -> void:
	_anim_t += delta
	sprite.flip_h = _dir > 0
	sprite.position = _sprite_base_pos

	var desired := "idle"
	if _attack_phase != 0:
		desired = "attack"
	elif absf(velocity.x) > 1.0:
		desired = "run"
	if sprite.animation != desired:
		sprite.play(desired)

func _setup_spriteframes() -> void:
	var frames := SpriteFrames.new()
	SPRITESHEET_ANIM.add_strip(frames, "idle", SHEET_IDLE, ENEMY_FRAME_W, ENEMY_FRAME_H, 4, 8.0, true)
	SPRITESHEET_ANIM.add_strip(frames, "run", SHEET_RUN, ENEMY_FRAME_W, ENEMY_FRAME_H, 6, 12.0, true)
	SPRITESHEET_ANIM.add_strip(frames, "attack", SHEET_ATTACK, ENEMY_FRAME_W, ENEMY_FRAME_H, 6, 18.0, true)
	sprite.sprite_frames = frames
	sprite.play("idle")

func _on_damage_area_body_entered(body: Node) -> void:
	# Only active during attack (monitoring=true)
	var player := body as PlayerPlatformer
	if player == null:
		return
	var dir_to_player := int(sign(player.global_position.x - global_position.x))
	if dir_to_player == 0:
		dir_to_player = -_dir
	player.take_hit(touch_damage, Vector2(float(dir_to_player) * touch_knockback_x, touch_knockback_y))

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	hp -= amount
	if knockback != Vector2.ZERO:
		velocity += knockback
	_squash()
	_flash(Color(2.0, 2.0, 2.0, 1.0))
	if hp <= 0:
		queue_free()

func _squash() -> void:
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.12, 0.9), 0.05)
	t.tween_property(self, "scale", Vector2.ONE, 0.10)

func _flash(tint: Color) -> void:
	if not is_instance_valid(sprite):
		return
	var t := create_tween()
	t.tween_property(sprite, "modulate", tint, 0.05)
	t.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.10)
