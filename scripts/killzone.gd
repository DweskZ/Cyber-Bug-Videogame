extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	var player := body as PlayerPlatformer
	if player == null:
		return
	Engine.time_scale = 1.0
	call_deferred("_reload")

func _reload() -> void:
	get_tree().reload_current_scene()
