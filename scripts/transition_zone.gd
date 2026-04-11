extends Area2D
class_name TransitionZone

@export_file("*.tscn") var target_scene: String
@export var required_packets := 0

@onready var sprite: Sprite2D = $Sprite2D

var _busy := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _gm() -> RunState:
	return get_tree().root.get_node_or_null("GameManager") as RunState

func _process(_delta: float) -> void:
	var gm := _gm()
	var packets := 0 if gm == null else gm.packets
	if required_packets > 0 and packets < required_packets:
		sprite.modulate = Color(1, 0.5, 0.5, 1)
	else:
		sprite.modulate = Color(1, 1, 1, 1)

func _on_body_entered(body: Node) -> void:
	if _busy:
		return
	var player := body as PlayerPlatformer
	if player == null:
		return
	if target_scene == "":
		return
	var gm := _gm()
	var packets := 0 if gm == null else gm.packets
	if required_packets > 0 and packets < required_packets:
		print("LOCKED: need %d packets" % required_packets)
		return
	_busy = true
	get_tree().change_scene_to_file(target_scene)
