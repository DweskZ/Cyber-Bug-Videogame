extends Area2D
class_name PacketPickup

@export var amount := 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	var player := body as PlayerPlatformer
	if player == null:
		return
	var gm := get_tree().root.get_node_or_null("GameManager") as RunState
	if gm != null:
		gm.add_packets(amount)
	queue_free()
