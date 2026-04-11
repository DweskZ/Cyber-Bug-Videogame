extends Label

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var player := scene.get_node_or_null("Player") as PlayerPlatformer
	if player == null:
		return
	var gm := get_tree().root.get_node_or_null("GameManager") as RunState
	var packets := 0 if gm == null else gm.packets
	text = "HP: %d/%d  BUG: %d" % [player.hp, player.max_hp, packets]