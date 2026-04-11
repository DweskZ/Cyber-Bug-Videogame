extends Node2D

@export var reset_run_on_enter := true

func _ready() -> void:
	if reset_run_on_enter:
		var gm := get_tree().root.get_node_or_null("GameManager") as RunState
		if gm != null:
			gm.reset_run()
