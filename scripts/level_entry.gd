extends Node2D

@export var reset_run_on_enter := true

func _ready() -> void:
	if reset_run_on_enter:
		GameManager.reset_run()
