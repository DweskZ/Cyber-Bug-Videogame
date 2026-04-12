extends CanvasLayer

@onready var far: Sprite2D = $Far
@onready var mid: Sprite2D = $Mid

func _ready() -> void:
	_fit_to_viewport()
	get_viewport().size_changed.connect(_fit_to_viewport)

func _fit_to_viewport() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	if vp.x <= 0 or vp.y <= 0:
		return
	if far.texture == null:
		return
	var tex_size: Vector2 = far.texture.get_size()
	if tex_size.x <= 0 or tex_size.y <= 0:
		return
	var s: float = max(vp.x / tex_size.x, vp.y / tex_size.y)
	far.position = vp * 0.5
	mid.position = vp * 0.5
	far.scale = Vector2(s, s)
	mid.scale = Vector2(s, s)
