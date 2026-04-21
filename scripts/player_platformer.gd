extends CharacterBody2D
class_name PlayerPlatformer

const SPRITESHEET_ANIM := preload("res://scripts/spritesheet_anim.gd")

const HIT_SPARK: Texture2D = preload("res://assets/hit_spark.svg")
const SHEET_IDLE: Texture2D = preload("res://assets/gemini_generated/characters/player/player_idle.png")
const SHEET_RUN: Texture2D = preload("res://assets/gemini_generated/characters/player/player_run.png")
const SHEET_JUMP: Texture2D = preload("res://assets/gemini_generated/characters/player/player_jump.png")
const SHEET_ATTACK: Texture2D = preload("res://assets/gemini_generated/characters/player/player_attack.png")
const SHEET_DOWN_ATTACK: Texture2D = preload("res://assets/gemini_generated/characters/player/player_down_attack.png")

const PLAYER_FRAME_W := 128
const PLAYER_FRAME_H := 128

# Visual tuning (the generated sheets are 128x128 frames, so we scale them down).
@export var visual_scale := 0.25

@export var speed := 210.0
@export var accel := 1800.0
@export var jump_velocity := -360.0
@export var gravity := 980.0

@export var coyote_time := 0.10
@export var jump_buffer_time := 0.12
@export var jump_cut_multiplier := 0.45

# Down-attack pogo tuning. NOTE: jump_velocity is negative, so values > 1.0 bounce higher.
@export_range(0.2, 2.0, 0.05) var pogo_bounce_multiplier := 1.20

@export var max_hp := 5
@export var invincibility_time := 0.60

@export var damage := 1
@export var attack_duration := 0.14
@export var attack_cooldown := 0.20

@export var hitstop_on_hit := 0.035
@export var hitstop_on_hurt := 0.06

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var cam: Camera2D = $Camera2D
@onready var slash_pivot: Node2D = $SlashPivot
@onready var slash_hitbox: Area2D = $SlashPivot/SlashHitbox
@onready var slash_shape: CollisionShape2D = $SlashPivot/SlashHitbox/CollisionShape2D
@onready var slash_sprite: Sprite2D = $SlashPivot/SlashSprite

var hp: int

var _facing := 1
var _can_attack := true
var _inv_timer := 0.0
var _coyote := 0.0
var _jump_buf := 0.0
var _hitstop_lock := false
var _dying := false

var _sprite_base_pos := Vector2.ZERO
var _slash_base_pos := Vector2.ZERO
var _anim_t := 0.0

var _attack_mode := 0 # 0=side, 1=down
var _pogo_used := false
var _is_attacking := false

func _ready() -> void:
	hp = max_hp
	_setup_spriteframes()

	# Player: layer 1. Collide with world only (combat uses hitboxes).
	collision_layer = 1
	collision_mask = 1

	# Slash hitbox hits enemies only.
	slash_hitbox.collision_layer = 0
	slash_hitbox.collision_mask = 2
	slash_shape.disabled = true
	slash_sprite.visible = false
	slash_hitbox.body_entered.connect(_on_slash_body_entered)

	_sprite_base_pos = sprite.position
	_slash_base_pos = slash_pivot.position
	sprite.position = _sprite_base_pos
	sprite.rotation = 0.0
	sprite.scale = Vector2.ONE * visual_scale

func _physics_process(delta: float) -> void:
	# Timers
	if _inv_timer > 0.0:
		_inv_timer = maxf(_inv_timer - delta, 0.0)

	if is_on_floor():
		_coyote = coyote_time
	else:
		_coyote = maxf(_coyote - delta, 0.0)

	if Input.is_action_just_pressed("ui_up"):
		_jump_buf = jump_buffer_time
	else:
		_jump_buf = maxf(_jump_buf - delta, 0.0)

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Horizontal movement
	var dir := Input.get_axis("ui_left", "ui_right")
	if dir != 0:
		_facing = sign(dir)
	velocity.x = move_toward(velocity.x, dir * speed, accel * delta)

	# Buffered jump + coyote time
	if _jump_buf > 0.0 and _coyote > 0.0:
		velocity.y = jump_velocity
		_jump_buf = 0.0
		_coyote = 0.0

	# Variable jump height (jump cut)
	if Input.is_action_just_released("ui_up") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

	# Attack
	if Input.is_action_just_pressed("ui_accept"):
		_attack()

	move_and_slide()
	_update_visuals(delta)

func _update_visuals(delta: float) -> void:
	_anim_t += delta
	sprite.flip_h = _facing < 0
	# Keep transforms stable now that we use real frames.
	sprite.position = _sprite_base_pos
	sprite.scale = Vector2.ONE * visual_scale
	sprite.rotation = 0.0

	# Animation selection
	if _is_attacking:
		return
	var desired := "idle"
	if not is_on_floor():
		desired = "jump"
	elif absf(velocity.x) > 10.0:
		desired = "run"
	if sprite.animation != desired:
		sprite.play(desired)

func _setup_spriteframes() -> void:
	# Build SpriteFrames from baked horizontal strips.
	var frames := SpriteFrames.new()
	SPRITESHEET_ANIM.add_strip(frames, "idle", SHEET_IDLE, PLAYER_FRAME_W, PLAYER_FRAME_H, 4, 8.0, true)
	SPRITESHEET_ANIM.add_strip(frames, "run", SHEET_RUN, PLAYER_FRAME_W, PLAYER_FRAME_H, 6, 12.0, true)
	SPRITESHEET_ANIM.add_strip(frames, "jump", SHEET_JUMP, PLAYER_FRAME_W, PLAYER_FRAME_H, 4, 10.0, true)
	SPRITESHEET_ANIM.add_strip(frames, "attack", SHEET_ATTACK, PLAYER_FRAME_W, PLAYER_FRAME_H, 6, 14.0, false)
	SPRITESHEET_ANIM.add_strip(frames, "down_attack", SHEET_DOWN_ATTACK, PLAYER_FRAME_W, PLAYER_FRAME_H, 4, 14.0, false)
	sprite.sprite_frames = frames
	sprite.play("idle")

func _attack() -> void:
	if not _can_attack:
		return
	_can_attack = false
	_pogo_used = false
	_is_attacking = true

	var down_attack := (not is_on_floor()) and Input.is_action_pressed("ui_down")
	_attack_mode = 1 if down_attack else 0
	if down_attack:
		if sprite.animation != "down_attack":
			sprite.play("down_attack")
	else:
		if sprite.animation != "attack":
			sprite.play("attack")

	# Position + orientation
	slash_pivot.scale = Vector2.ONE
	if down_attack:
		slash_pivot.position = Vector2(0, 18)
		slash_sprite.flip_h = false
	else:
		slash_pivot.position = Vector2(14.0 * float(_facing), _slash_base_pos.y)
		slash_sprite.flip_h = _facing < 0

	# No slash VFX: now that we have proper attack frames, keep it hitbox-only.
	slash_shape.disabled = false
	await get_tree().create_timer(attack_duration).timeout
	slash_shape.disabled = true

	# Restore pivot
	slash_pivot.position = _slash_base_pos
	_attack_mode = 0

	# Keep the animation locked until it finishes (prevents the “x3 speed / snap back to idle” feel).
	await sprite.animation_finished
	_is_attacking = false

	await get_tree().create_timer(attack_cooldown).timeout
	_can_attack = true

func reset_pogo() -> void:
	_pogo_used = false

func _on_slash_body_entered(body: Node) -> void:
	var kb := Vector2(_facing * 220.0, -80.0)
	if _attack_mode == 1:
		kb = Vector2(0, 260.0)

	if body is EnemyWalker:
		var enemy := body as EnemyWalker
		enemy.take_damage(damage, kb)
		_spawn_hit_spark(enemy.global_position + Vector2(_facing * 8.0, -10.0))
	elif body is OpenClawBoss:
		var boss := body as OpenClawBoss
		boss.take_damage(damage, kb)
		_spawn_hit_spark(boss.global_position + Vector2(_facing * 8.0, -10.0))
	else:
		return

	# Down-slash pogo bounce (HK-style)
	if _attack_mode == 1 and not _pogo_used:
		velocity.y = jump_velocity * pogo_bounce_multiplier
		_pogo_used = true

	_camera_bump(1.2)
	_hit_stop(hitstop_on_hit)

func _spawn_hit_spark(world_pos: Vector2) -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	var scene := tree.current_scene
	if scene == null:
		return
	var s := Sprite2D.new()
	s.texture = HIT_SPARK
	s.global_position = world_pos
	s.scale = Vector2(0.7, 0.7)
	s.modulate = Color(1, 1, 1, 0.95)
	s.z_index = 50
	scene.add_child(s)

	var t := create_tween()
	t.tween_property(s, "scale", Vector2(1.25, 1.25), 0.08)
	t.parallel().tween_property(s, "modulate:a", 0.0, 0.08)
	t.tween_callback(Callable(s, "queue_free"))

func take_hit(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if _dying:
		return
	if _inv_timer > 0.0:
		return

	hp = max(hp - amount, 0)
	if hp <= 0:
		_die()
		return

	_inv_timer = invincibility_time

	if knockback != Vector2.ZERO:
		velocity += knockback

	_flash(Color(1, 0.45, 0.45, 1))
	_camera_bump(2.0)
	_hit_stop(hitstop_on_hurt)

func _die() -> void:
	if _dying:
		return
	_dying = true
	# Ensure we don't carry slow-motion across reload.
	Engine.time_scale = 1.0
	_hitstop_lock = false
	call_deferred("_reload_scene")

func _reload_scene() -> void:
	get_tree().reload_current_scene()

func _exit_tree() -> void:
	# Safety: never leave the engine slowed down.
	Engine.time_scale = 1.0

func _flash(tint: Color) -> void:
	if not is_instance_valid(sprite):
		return
	var t := create_tween()
	t.tween_property(sprite, "modulate", tint, 0.05)
	t.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.12)

func _camera_bump(strength: float) -> void:
	if not is_instance_valid(cam):
		return
	var dx := randf_range(-strength, strength)
	var dy := randf_range(-strength, strength)
	cam.offset = Vector2(dx, dy)
	var t := create_tween()
	t.tween_property(cam, "offset", Vector2.ZERO, 0.10)

func _hit_stop(duration: float) -> void:
	if _hitstop_lock:
		return
	_hitstop_lock = true
	var prev := Engine.time_scale
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = prev
	_hitstop_lock = false
