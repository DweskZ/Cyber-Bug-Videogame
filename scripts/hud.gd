extends Label

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var player := scene.get_node_or_null("Player") as PlayerPlatformer
	if player == null:
		return
	text = "HP: %d/%d  BUG: %d" % [player.hp, player.max_hp, GameManager.packets]