extends Label

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var player := scene.get_node_or_null("Player")
	if player == null:
		return
	# player has: hp, max_hp
	text = "HP: %d/%d" % [player.hp, player.max_hp]