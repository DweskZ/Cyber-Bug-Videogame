extends Control
class_name StartMenu

@export var start_scene: String = "res://scenes/Level01.tscn"

@onready var title_label: Label = %TitleLabel
@onready var start_button: Button = %StartButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	if title_label != null:
		title_label.text = "CYBER BUG"
	if start_button != null:
		start_button.pressed.connect(_on_start_pressed)
	if quit_button != null:
		quit_button.pressed.connect(_on_quit_pressed)

	# Default focus for keyboard/controller.
	if start_button != null:
		start_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_start_pressed()

func _on_start_pressed() -> void:
	var gm := get_node_or_null("/root/GameManager") as RunState
	if gm != null:
		gm.reset_run()
	get_tree().change_scene_to_file(start_scene)

func _on_quit_pressed() -> void:
	get_tree().quit()
