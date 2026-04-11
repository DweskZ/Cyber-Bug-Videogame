extends Area2D
class_name TransitionZone

@export_file("*.tscn") var target_scene: String
@export var required_packets := 0

@onready var sprite: Sprite2D = $Sprite2D

var _busy := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(_delta: float) -> void:
	if required_packets > 0 and GameManager.packets < required_packets:
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
	if required_packets > 0 and GameManager.packets < required_packets:
		print("LOCKED: need %d packets" % required_packets)
		return
	_busy = true
	get_tree().change_scene_to_file(target_scene)
