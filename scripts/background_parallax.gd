extends Node2D

# Parallax factors: 1.0 = almost no perceived movement (more stable), lower = more parallax.
@export var far_factor: float = 0.99
@export var mid_factor: float = 0.995
@export var cover_margin: float = 1.35
@export var ground_y: float = 150.0

@onready var far: Sprite2D = $Far
@onready var mid: Sprite2D = $Mid

var _cam: Camera2D
var _cam_start: Vector2 = Vector2.ZERO
var _has_start := false

var _mid_half_h: float = 0.0

func _ready() -> void:
	_cam = get_viewport().get_camera_2d()
	if _cam != null:
		_cam_start = _cam.global_position
		_has_start = true
	_fit_to_view()
	get_viewport().size_changed.connect(_fit_to_view)

func _process(_delta: float) -> void:
	if _cam == null:
		_cam = get_viewport().get_camera_2d()
	if _cam == null:
		return
	if not _has_start:
		_cam_start = _cam.global_position
		_has_start = true

	var cam_pos: Vector2 = _cam.global_position
	var delta: Vector2 = cam_pos - _cam_start

	# Fixed background: lock to camera so it doesn't parallax or bob.
	far.global_position = cam_pos
	# Mid layer is optional; keep it locked too (and it can stay invisible).
	mid.global_position = cam_pos

func _fit_to_view() -> void:
	if far.texture == null:
		return
	var vp: Vector2 = get_viewport_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	var zoom: Vector2 = Vector2.ONE
	if _cam != null:
		zoom = _cam.zoom
	if zoom.x <= 0.0 or zoom.y <= 0.0:
		zoom = Vector2.ONE

	var world_view: Vector2 = Vector2(vp.x / zoom.x, vp.y / zoom.y)
	var far_size: Vector2 = far.texture.get_size()
	if far_size.x <= 0.0 or far_size.y <= 0.0:
		return
	var mid_size: Vector2 = far_size
	if mid.texture != null:
		mid_size = mid.texture.get_size()
	var far_s: float = max(world_view.x / far_size.x, world_view.y / far_size.y) * cover_margin
	var mid_s: float = max(world_view.x / mid_size.x, world_view.y / mid_size.y) * cover_margin
	far.scale = Vector2(far_s, far_s)
	mid.scale = Vector2(mid_s, mid_s)
	_mid_half_h = (mid_size.y * mid_s) * 0.5
