extends CharacterBody2D
class_name PlayerPlatformer

const HIT_SPARK: Texture2D = preload("res://assets/hit_spark.svg")

@export var speed := 210.0
@export var accel := 1800.0
@export var jump_velocity := -360.0
@export var gravity := 980.0

@export var coyote_time := 0.10
@export var jump_buffer_time := 0.12
@export var jump_cut_multiplier := 0.45

@export var max_hp := 5
@export var invincibility_time := 0.60

@export var damage := 1
@export var attack_duration := 0.10
@export var attack_cooldown := 0.18

@export var hitstop_on_hit := 0.035
@export var hitstop_on_hurt := 0.06

@onready var sprite: Sprite2D = $Sprite2D
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

var _sprite_base_pos := Vector2.ZERO
var _anim_t := 0.0

func _ready() -> void:
	hp = max_hp

	# Player: layer 1. Collide with world (layer 3 = 4) and enemies (layer 2 = 2).
	collision_layer = 1
	collision_mask = 4 | 2

	# Slash hitbox hits enemies only.
	slash_hitbox.collision_layer = 0
	slash_hitbox.collision_mask = 2
	slash_shape.disabled = true
	slash_sprite.visible = false
	slash_hitbox.body_entered.connect(_on_slash_body_entered)

	_sprite_base_pos = sprite.position

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
	# Cheap but nice-looking "animation" via transforms (no spritesheet yet)	
	_anim_t += delta
	sprite.flip_h = _facing < 0

	if is_on_floor():
		var run_amount := clampf(absf(velocity.x) / maxf(speed, 0.001), 0.0, 1.0)
		if run_amount > 0.05:
			var bob := sin(_anim_t * 18.0) * 0.6
			sprite.position = _sprite_base_pos + Vector2(0, bob)
			var s := 1.0 + sin(_anim_t * 18.0) * 0.04
			sprite.scale = Vector2(s, 2.0 - s)
		else:
			var idle := sin(_anim_t * 2.5) * 0.25
			sprite.position = _sprite_base_pos + Vector2(0, idle)
			sprite.scale = Vector2.ONE
		sprite.rotation = lerpf(sprite.rotation, 0.0, 0.2)
	else:
		# In air
		sprite.position = _sprite_base_pos
		sprite.scale = Vector2.ONE
		var tilt := clampf(velocity.y / 900.0, -0.18, 0.18)
		sprite.rotation = lerpf(sprite.rotation, tilt, 0.12)

func _attack() -> void:
	if not _can_attack:
		return
	_can_attack = false

	# Put slash on the correct side (don't just mirror in place)
	slash_pivot.position.x = 14.0 * float(_facing)
	slash_pivot.scale.x = 1.0
	slash_sprite.flip_h = _facing < 0

	# Swing it (cheap "frames" via tween)
	var start_rot := -0.95 * float(_facing)
	var end_rot := 0.15 * float(_facing)
	slash_sprite.rotation = start_rot
	slash_sprite.scale = Vector2(0.9, 0.9)
	slash_sprite.modulate.a = 0.0

	slash_shape.disabled = false
	slash_sprite.visible = true
	var tw := create_tween()
	tw.tween_property(slash_sprite, "modulate:a", 0.95, 0.03)
	tw.parallel().tween_property(slash_sprite, "scale", Vector2(1.08, 1.08), attack_duration)
	tw.parallel().tween_property(slash_sprite, "rotation", end_rot, attack_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(attack_duration).timeout
	slash_shape.disabled = true
	slash_sprite.visible = false

	await get_tree().create_timer(attack_cooldown).timeout
	_can_attack = true

func _on_slash_body_entered(body: Node) -> void:
	var enemy := body as EnemyWalker
	if enemy == null:
		return
	enemy.take_damage(damage, Vector2(_facing * 220.0, -80.0))
	_spawn_hit_spark(enemy.global_position + Vector2(_facing * 8.0, -10.0))
	_camera_bump(1.2)
	_hit_stop(hitstop_on_hit)

func _spawn_hit_spark(world_pos: Vector2) -> void:
	var scene := get_tree().current_scene
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
	if _inv_timer > 0.0:
		return

	hp = max(hp - amount, 0)
	_inv_timer = invincibility_time

	if knockback != Vector2.ZERO:
		velocity += knockback

	_flash(Color(1, 0.45, 0.45, 1))
	_camera_bump(2.0)
	_hit_stop(hitstop_on_hurt)

	if hp <= 0:
		get_tree().reload_current_scene()

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