extends Control
class_name HUDIcons

const BUG_SHEET: Texture2D = preload("res://assets/spritesheets/bug_pickup_strip_256x64.png")
const FRAME_W := 64
const FRAME_H := 64

@export var icon_size := 28
@export_range(0.05, 1.0, 0.05) var empty_alpha := 0.25
@export var hp_full_tint: Color = Color(1.0, 0.35, 0.35, 1.0)
@export var hp_empty_tint: Color = Color(0.35, 0.35, 0.35, 1.0)
@export var packet_icon_size := 18
@export var show_packets := true

@onready var hp_row: HBoxContainer = %HPRow
@onready var packet_row: HBoxContainer = %PacketRow
@onready var packet_icon: TextureRect = %PacketIcon
@onready var packet_label: Label = %PacketLabel

var _icon_tex: Texture2D

func _ready() -> void:
	_icon_tex = _make_bug_frame_texture(0)
	if packet_icon != null:
		packet_icon.texture = _icon_tex
		packet_icon.custom_minimum_size = Vector2(packet_icon_size, packet_icon_size)
		packet_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		packet_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if packet_row != null:
		packet_row.visible = show_packets

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var player := scene.get_node_or_null("Player") as PlayerPlatformer
	if player == null:
		return

	_ensure_hp_icons(player.max_hp)
	_update_hp(player.hp, player.max_hp)

	if show_packets:
		var gm := get_tree().root.get_node_or_null("GameManager") as RunState
		var packets := 0 if gm == null else gm.packets
		if packet_label != null:
			packet_label.text = str(packets)

func _ensure_hp_icons(max_hp: int) -> void:
	if hp_row == null:
		return
	while hp_row.get_child_count() < max_hp:
		var tr := TextureRect.new()
		tr.texture = _icon_tex
		tr.custom_minimum_size = Vector2(icon_size, icon_size)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hp_row.add_child(tr)
	# Apply sizing/tile settings even when icon_size changes at runtime/Inspector.
	for i in range(hp_row.get_child_count()):
		var tr := hp_row.get_child(i) as TextureRect
		if tr == null:
			continue
		tr.custom_minimum_size = Vector2(icon_size, icon_size)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	while hp_row.get_child_count() > max_hp:
		var c := hp_row.get_child(hp_row.get_child_count() - 1)
		hp_row.remove_child(c)
		c.queue_free()

func _update_hp(hp: int, max_hp: int) -> void:
	if hp_row == null:
		return
	for i in range(max_hp):
		var tr := hp_row.get_child(i) as TextureRect
		if tr == null:
			continue
		if i < hp:
			tr.modulate = hp_full_tint
		else:
			tr.modulate = Color(hp_empty_tint.r, hp_empty_tint.g, hp_empty_tint.b, empty_alpha)

func _make_bug_frame_texture(frame: int) -> Texture2D:
	var at := AtlasTexture.new()
	at.atlas = BUG_SHEET
	at.region = Rect2(float(frame * FRAME_W), 0.0, float(FRAME_W), float(FRAME_H))
	return at
