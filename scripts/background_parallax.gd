extends Node2D

@export var far_factor: float = 0.85
@export var mid_factor: float = 0.95
@export var cover_margin: float = 1.35

@onready var far: Sprite2D = $Far
@onready var mid: Sprite2D = $Mid

var _cam: Camera2D
var _cam_start: Vector2 = Vector2.ZERO
var _has_start := false

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

	# Keep layers centered on the camera, then apply parallax offset based on camera delta.
	# This avoids drifting to edges as world coords grow.
	far.global_position = cam_pos + delta * (far_factor - 1.0)
	mid.global_position = cam_pos + delta * (mid_factor - 1.0)

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
	var tex_size: Vector2 = far.texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return

	var s: float = max(world_view.x / tex_size.x, world_view.y / tex_size.y) * cover_margin
	far.scale = Vector2(s, s)
	mid.scale = Vector2(s, s)
