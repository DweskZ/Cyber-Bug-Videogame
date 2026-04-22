extends CharacterBody2D
class_name OpenClawBoss

const SPRITESHEET_ANIM := preload("res://scripts/spritesheet_anim.gd")

# OpenClaw boss sprites (processed, already transparent).
# 4-frame horizontal strips: 2048x512 (512x512 per frame).
const SHEET_IDLE: Texture2D = preload("res://assets/spritesheets/openclawboss_processed/openclawboss_walk_strip.png")
const SHEET_SWIPE: Texture2D = preload("res://assets/spritesheets/openclawboss_processed/openclawboss_attack_strip.png")
const SHEET_SLAM: Texture2D = preload("res://assets/spritesheets/openclawboss_processed/openclawboss_slam_strip.png")
const SHEET_HURT: Texture2D = preload("res://assets/spritesheets/openclawboss_processed/openclawboss_hurt_strip.png")
const SHEET_DEATH: Texture2D = preload("res://assets/spritesheets/openclawboss_processed/openclawboss_death_strip.png")
const SHEET_LASER: Texture2D = preload("res://assets/spritesheets/openclawboss_processed/openclawboss_laser_strip.png")

const IDLE_FRAMES := 4
const SWIPE_FRAMES := 4
const SLAM_FRAMES := 4
const HURT_FRAMES := 4
const DEATH_FRAMES := 4
const LASER_FRAMES := 4

@export var gravity := 980.0
@export var max_hp := 25
@export var move_speed := 70.0

# Scale for 512px frames. Target: ~3x the player (player is 128px @ 0.25 scale).
@export var visual_scale := 0.19

# Visual node placement (tweak to align sprite with collision hitbox)
@export var sprite_visual_pos := Vector2(0, -10)

# If true, compute stable offsets from alpha to keep the sprite anchored.
# Implementation uses an intersection-rect anchor to avoid "weapon-driven" sliding.
@export var use_auto_frame_offsets := false

# Per-animation offsets (in source-sheet pixels, then scaled by visual_scale).
@export var offset_idle := Vector2.ZERO
@export var offset_swipe := Vector2.ZERO
@export var offset_slam := Vector2.ZERO
@export var offset_laser := Vector2.ZERO
@export var offset_hurt := Vector2.ZERO
@export var offset_death := Vector2.ZERO

@export var touch_damage := 2

# Death pacing (let the death anim read before KernelEnding)
@export var death_hold_seconds := 1.8

# Server loop: boss is only damageable during the Hurt window.
@export var enable_server_loop := true
@export var server_group_name := "boss_servers"
@export_range(1.0, 8.0, 0.25) var hurt_stun_seconds := 3.5

# Attack tuning
@export var enable_swipe := true
@export var enable_laser := true
@export var enable_slam := true

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

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var swipe_area: Area2D = $SwipeArea
@onready var swipe_shape: CollisionShape2D = $SwipeArea/CollisionShape2D
@onready var swipe_fx: Sprite2D = $SwipeArea/SwipeFX
@onready var laser_area: Area2D = $LaserArea
@onready var laser_shape: CollisionShape2D = $LaserArea/CollisionShape2D
@onready var laser_fx: Sprite2D = $LaserArea/LaserFX
@onready var slam_area: Area2D = $SlamArea
@onready var slam_shape: CollisionShape2D = $SlamArea/CollisionShape2D
@onready var slam_fx: Sprite2D = $SlamArea/SlamFX

var hp := 0
var _facing := -1
var _dying := false

var _state := "idle"
var _t := 0.0

var _damageable := true
var _servers: Array[BossServer] = []

var _player_collision_exception_set := false

# Per-frame visual offsets (computed from alpha), optional.
var _frame_offsets := {} # StringName -> PackedVector2Array

func _ready() -> void:
	hp = max_hp
	collision_layer = 2
	collision_mask = 1
	_setup_spriteframes()
	sprite.scale = Vector2.ONE * visual_scale
	sprite.position = sprite_visual_pos

	# Optional per-frame offset hook.
	if use_auto_frame_offsets:
		sprite.frame_changed.connect(_on_sprite_frame_changed)
		sprite.animation_changed.connect(_on_sprite_animation_changed)
	_apply_visual_offset()

	_disable_hitboxes()

	swipe_area.body_entered.connect(_on_hitbox_body_entered)
	laser_area.body_entered.connect(_on_hitbox_body_entered)
	slam_area.body_entered.connect(_on_hitbox_body_entered)

	if enable_server_loop:
		_start_server_cycle()

func _physics_process(delta: float) -> void:
	if _dying:
		_disable_hitboxes()
		return

	# Keep transforms stable (same trick as the main character).
	sprite.position = sprite_visual_pos
	sprite.scale = Vector2.ONE * visual_scale
	sprite.rotation = 0.0

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	var player := get_tree().current_scene.get_node_or_null("Player") as PlayerPlatformer
	# Prevent the player body from physically blocking/standing on the boss.
	# We still damage the player via the boss Areas (Swipe/Laser/Slam + touch).
	if player != null and not _player_collision_exception_set:
		add_collision_exception_with(player)
		_player_collision_exception_set = true

	# Hurt/stun window: boss is fixed and vulnerable.
	if _state == "hurt":
		_disable_hitboxes()
		velocity = Vector2.ZERO
		_t -= delta
		if sprite != null and sprite.animation != "hurt":
			sprite.play("hurt")
		_apply_visual_offset()
		if _t <= 0.0 and enable_server_loop:
			_end_hurt_stun()
		move_and_slide()
		return
	# Lock facing during attacks to avoid visual "sliding" when the player crosses sides mid-action.
	# In idle we can update every frame so the boss doesn't get stuck walking one direction.
	if player != null and _state == "idle":
		_facing = int(sign(player.global_position.x - global_position.x))
		if _facing == 0:
			_facing = -1
	sprite.flip_h = _facing > 0

	# Boss animation based on state
	var desired_anim := "idle"
	if _state.begins_with("swipe"):
		desired_anim = "swipe"
	elif _state == "hurt":
		desired_anim = "hurt"
	elif _state.begins_with("laser"):
		desired_anim = "laser"
	elif _state.begins_with("slam"):
		desired_anim = "slam"
	if sprite.animation != desired_anim:
		sprite.play(desired_anim)

	# Apply per-frame offset (optional) + per-animation tweak.
	_apply_visual_offset()

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
					if enable_swipe:
						_start_attack("swipe", swipe_windup)
					elif enable_slam:
						_start_attack("slam", slam_windup)
					elif enable_laser:
						_start_attack("laser", laser_windup)
				else:
					# Mid/long range: mix slam and laser.
					var choices: Array[String] = []
					if enable_slam:
						choices.append("slam")
					if enable_laser:
						choices.append("laser")
					# If everything is disabled, just keep pacing.
					if choices.size() > 0:
						var pick := choices[randi() % choices.size()]
						if pick == "slam":
							_start_attack("slam", slam_windup)
						else:
							_start_attack("laser", laser_windup)
	else:
		_t -= delta
		if _state == "swipe_windup":
			velocity.x = 0.0
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

func _setup_spriteframes() -> void:
	var frames := SpriteFrames.new()

	var idle_sz := _frame_size_from_sheet(SHEET_IDLE, IDLE_FRAMES)
	var idle_w := idle_sz.x
	var idle_h := idle_sz.y
	_add_strip_baked(frames, "idle", SHEET_IDLE, idle_w, idle_h, IDLE_FRAMES, 8.0, true)
	if use_auto_frame_offsets:
		_frame_offsets[&"idle"] = _compute_frame_offsets(SHEET_IDLE, idle_w, idle_h, IDLE_FRAMES)

	var swipe_sz := _frame_size_from_sheet(SHEET_SWIPE, SWIPE_FRAMES)
	var swipe_w := swipe_sz.x
	var swipe_h := swipe_sz.y
	_add_strip_baked(frames, "swipe", SHEET_SWIPE, swipe_w, swipe_h, SWIPE_FRAMES, 12.0, true)
	if use_auto_frame_offsets:
		_frame_offsets[&"swipe"] = _compute_frame_offsets(SHEET_SWIPE, swipe_w, swipe_h, SWIPE_FRAMES)

	var laser_sz := _frame_size_from_sheet(SHEET_LASER, LASER_FRAMES)
	var laser_w := laser_sz.x
	var laser_h := laser_sz.y
	_add_strip_baked(frames, "laser", SHEET_LASER, laser_w, laser_h, LASER_FRAMES, 10.0, true)
	if use_auto_frame_offsets:
		_frame_offsets[&"laser"] = _compute_frame_offsets(SHEET_LASER, laser_w, laser_h, LASER_FRAMES)

	var slam_sz := _frame_size_from_sheet(SHEET_SLAM, SLAM_FRAMES)
	var slam_w := slam_sz.x
	var slam_h := slam_sz.y
	_add_strip_baked(frames, "slam", SHEET_SLAM, slam_w, slam_h, SLAM_FRAMES, 10.0, true)
	if use_auto_frame_offsets:
		_frame_offsets[&"slam"] = _compute_frame_offsets(SHEET_SLAM, slam_w, slam_h, SLAM_FRAMES)

	var hurt_sz := _frame_size_from_sheet(SHEET_HURT, HURT_FRAMES)
	var hurt_w := hurt_sz.x
	var hurt_h := hurt_sz.y
	_add_strip_baked(frames, "hurt", SHEET_HURT, hurt_w, hurt_h, HURT_FRAMES, 10.0, false)
	if use_auto_frame_offsets:
		_frame_offsets[&"hurt"] = _compute_frame_offsets(SHEET_HURT, hurt_w, hurt_h, HURT_FRAMES)

	var death_sz := _frame_size_from_sheet(SHEET_DEATH, DEATH_FRAMES)
	var death_w := death_sz.x
	var death_h := death_sz.y
	_add_strip_baked(frames, "death", SHEET_DEATH, death_w, death_h, DEATH_FRAMES, 8.0, false)
	if use_auto_frame_offsets:
		_frame_offsets[&"death"] = _compute_frame_offsets(SHEET_DEATH, death_w, death_h, DEATH_FRAMES)

	sprite.sprite_frames = frames
	sprite.play("idle")

func _frame_size_from_sheet(sheet: Texture2D, frames: int) -> Vector2i:
	if sheet == null or frames <= 0:
		return Vector2i.ZERO
	var img := sheet.get_image()
	if img != null:
		return Vector2i(int(img.get_width() / frames), int(img.get_height()))
	return Vector2i(int(sheet.get_width() / frames), int(sheet.get_height()))

func _add_strip_baked(
	frames: SpriteFrames,
	anim_name: String,
	sheet: Texture2D,
	frame_w: int,
	frame_h: int,
	frame_count: int,
	fps: float,
	loop: bool
) -> void:
	if frames == null or sheet == null:
		return
	if not frames.has_animation(anim_name):
		frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, fps)
	frames.set_animation_loop(anim_name, loop)

	var img := sheet.get_image()
	if img == null:
		return
	img.convert(Image.FORMAT_RGBA8)

	# Some generated strips include blank padding frames.
	# Replace blanks with the previous good frame so the animation never flickers.
	var texs: Array[Texture2D] = []
	texs.resize(frame_count)
	var first_good: Texture2D = null

	for i in range(frame_count):
		var r := Rect2i(i * frame_w, 0, frame_w, frame_h)
		var sub := img.get_region(r)
		var used := sub.get_used_rect()
		var used_area := used.size.x * used.size.y
		if used_area < 256:
			texs[i] = null
			continue
		var tex := ImageTexture.create_from_image(sub)
		texs[i] = tex
		if first_good == null:
			first_good = tex

	if first_good == null:
		return

	var last_good: Texture2D = first_good
	for i in range(frame_count):
		if texs[i] == null:
			texs[i] = last_good
		else:
			last_good = texs[i]

	for i in range(frame_count):
		frames.add_frame(anim_name, texs[i])

func _compute_frame_offsets(sheet: Texture2D, frame_w: int, frame_h: int, frame_count: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(frame_count)
	if sheet == null:
		return out
	var img := sheet.get_image()
	if img == null:
		return out
	img.convert(Image.FORMAT_RGBA8)

	# 1) First pass: compute used rect per frame.
	var used_rects: Array[Rect2i] = []
	used_rects.resize(frame_count)
	var have_any := false
	var inter := Rect2i()

	for i in range(frame_count):
		var r := Rect2i(i * frame_w, 0, frame_w, frame_h)
		var sub := img.get_region(r)
		var used := sub.get_used_rect()
		var used_area := used.size.x * used.size.y
		if used.size.x <= 0 or used.size.y <= 0 or used_area < 256:
			used_rects[i] = Rect2i()
			continue
		used_rects[i] = used
		if not have_any:
			have_any = true
			inter = used
		else:
			inter = inter.intersection(used)

	# 2) If intersection is valid, anchor to it (stable across frames).
	if have_any and inter.size.x > 0 and inter.size.y > 0:
		var ax := float(inter.position.x) + float(inter.size.x) * 0.5
		var ay := float(inter.position.y) + float(inter.size.y)
		var o := Vector2(float(frame_w) * 0.5 - ax, float(frame_h) * 0.5 - ay)
		for i in range(frame_count):
			out[i] = (out[i - 1] if i > 0 else o)
		return out

	# 3) Fallback: per-frame bottom-center anchor.
	for i in range(frame_count):
		var used := used_rects[i]
		if used.size.x <= 0 or used.size.y <= 0:
			out[i] = (out[i - 1] if i > 0 else Vector2.ZERO)
			continue
		var ax := float(used.position.x) + float(used.size.x) * 0.5
		var ay := float(used.position.y) + float(used.size.y)
		out[i] = Vector2(float(frame_w) * 0.5 - ax, float(frame_h) * 0.5 - ay)
	return out

func _on_sprite_frame_changed() -> void:
	_apply_visual_offset()

func _on_sprite_animation_changed() -> void:
	_apply_visual_offset()

func _tweak_for_anim(anim: StringName) -> Vector2:
	if anim == &"idle":
		return offset_idle
	if anim == &"swipe":
		return offset_swipe
	if anim == &"slam":
		return offset_slam
	if anim == &"laser":
		return offset_laser
	if anim == &"hurt":
		return offset_hurt
	if anim == &"death":
		return offset_death
	return Vector2.ZERO

func _apply_visual_offset() -> void:
	if sprite == null:
		return
	var anim: StringName = sprite.animation
	var tweak := _tweak_for_anim(anim)

	if use_auto_frame_offsets:
		var arr: PackedVector2Array = _frame_offsets.get(anim, PackedVector2Array())
		var o := Vector2.ZERO
		if arr.size() > 0:
			var idx := clampi(sprite.frame, 0, arr.size() - 1)
			o = arr[idx]
		# When flipped, mirror X offset.
		if sprite.flip_h:
			o.x = -o.x
			tweak.x = -tweak.x
		sprite.offset = o + tweak
	else:
		# Only the manual tweak, to avoid per-frame "sliding".
		if sprite.flip_h:
			tweak.x = -tweak.x
		sprite.offset = tweak

func _start_server_cycle() -> void:
	_damageable = false
	_refresh_servers()
	if _servers.size() == 0:
		# No placed servers in the scene, fallback to normal damage.
		_damageable = true
		return
	_reset_servers()

func _refresh_servers() -> void:
	_servers.clear()
	if not is_inside_tree():
		return
	var nodes := get_tree().get_nodes_in_group(server_group_name)
	for n in nodes:
		var s := n as BossServer
		if s == null:
			continue
		# Ensure we only connect once.
		if not s.destroyed.is_connected(_on_server_destroyed):
			s.destroyed.connect(_on_server_destroyed)
		_servers.append(s)

func _reset_servers() -> void:
	for s in _servers:
		if is_instance_valid(s):
			s.reset_server()

func _all_servers_down() -> bool:
	for s in _servers:
		if is_instance_valid(s) and s.active:
			return false
	return true

func _on_server_destroyed(server: BossServer) -> void:
	# When all placed servers are down, boss becomes vulnerable for a short hurt/stun window.
	if _all_servers_down():
		_enter_hurt_stun()

func _enter_hurt_stun() -> void:
	_state = "hurt"
	_t = hurt_stun_seconds
	_damageable = true
	_disable_hitboxes()
	velocity = Vector2.ZERO
	if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")
	_apply_visual_offset()

func _end_hurt_stun() -> void:
	_damageable = false
	_state = "idle"
	_t = 0.35
	_reset_servers()

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
	# These can be called from inside physics callbacks (e.g. body_entered / hit detection).
	# Use deferred writes to avoid "flushing queries" errors.
	if swipe_shape != null:
		swipe_shape.set_deferred("disabled", true)
	if laser_shape != null:
		laser_shape.set_deferred("disabled", true)
	if slam_shape != null:
		slam_shape.set_deferred("disabled", true)
	if swipe_area != null:
		swipe_area.set_deferred("monitoring", false)
	if laser_area != null:
		laser_area.set_deferred("monitoring", false)
	if slam_area != null:
		slam_area.set_deferred("monitoring", false)

	if swipe_fx != null:
		swipe_fx.visible = false
	if laser_fx != null:
		laser_fx.visible = false
	if slam_fx != null:
		slam_fx.visible = false

func _enable_swipe() -> void:
	swipe_area.position = Vector2(55.0 * float(_facing), 0)
	swipe_shape.set_deferred("disabled", false)
	swipe_area.set_deferred("monitoring", true)

	swipe_fx.visible = true
	swipe_fx.flip_h = _facing < 0
	swipe_fx.modulate.a = 0.0
	swipe_fx.scale = Vector2(0.95, 0.95)
	var t := create_tween()
	t.tween_property(swipe_fx, "modulate:a", 0.85, 0.04)
	t.parallel().tween_property(swipe_fx, "scale", Vector2(1.05, 1.05), swipe_active)

func _enable_laser() -> void:
	laser_area.position = Vector2(95.0 * float(_facing), -10)
	laser_shape.set_deferred("disabled", false)
	laser_area.set_deferred("monitoring", true)

	laser_fx.visible = true
	laser_fx.flip_h = _facing < 0
	laser_fx.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(laser_fx, "modulate:a", 0.85, 0.06)

func _enable_slam() -> void:
	slam_area.position = Vector2(0, 30)
	slam_shape.set_deferred("disabled", false)
	slam_area.set_deferred("monitoring", true)

	slam_fx.visible = true
	slam_fx.modulate.a = 0.0
	slam_fx.scale = Vector2(0.7, 0.7)
	var t := create_tween()
	t.tween_property(slam_fx, "modulate:a", 0.8, 0.05)
	t.parallel().tween_property(slam_fx, "scale", Vector2(1.25, 1.25), slam_active)

func _on_hitbox_body_entered(body: Node) -> void:
	var player := body as PlayerPlatformer
	if player == null:
		return
	var dir_to_player := int(sign(player.global_position.x - global_position.x))
	if dir_to_player == 0:
		dir_to_player = _facing
	player.take_hit(touch_damage, Vector2(float(dir_to_player) * 320.0, -160.0))

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if _dying:
		return
	if enable_server_loop and not _damageable:
		# Shielded: only damageable during Hurt window.
		_flash(Color(0.6, 0.85, 1.6, 1.0))
		return
	hp -= amount
	if knockback != Vector2.ZERO:
		# Boss is heavy: damp knockback so pogo/down-attack can't yeet it out of the arena.
		var kb := knockback
		kb.x = clampf(kb.x, -160.0, 160.0)
		# Never push the boss downward (positive Y), prevents floor tunneling / getting shoved off-screen.
		kb.y = minf(kb.y, 0.0)
		kb.y = clampf(kb.y, -180.0, 0.0)
		velocity += kb * 0.35
	_flash(Color(2.0, 2.0, 2.0, 1.0))
	if hp <= 0:
		_dying = true
		Engine.time_scale = 1.0
		_disable_hitboxes()
		call_deferred("_die_sequence")

func _die_sequence() -> void:
	# Play death anim, then give it a moment to read before the KernelEnding trigger.
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
	await get_tree().create_timer(death_hold_seconds).timeout
	_end_game()

func _end_game() -> void:
	get_tree().change_scene_to_file("res://scenes/KernelEnding.tscn")

func _flash(tint: Color) -> void:
	var t := create_tween()
	t.tween_property(sprite, "modulate", tint, 0.05)
	t.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.12)
