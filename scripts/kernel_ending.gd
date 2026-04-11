extends Control

@onready var label: Label = $Label

func _ready():
	label.text = ""
	await _line("KERNEL PANIC", 0.35)
	await _line("fatal: OPENCLAW_GUARDIAN segfault (0xC0DE)", 0.45)
	await _line("bug_injected: SUCCESS", 0.35)
	await _line("system: shutting down...", 0.55)
	await get_tree().create_timer(0.6, true, false, true).timeout
	label.text += "\n\nKERNEL ERROR"

func _line(t: String, delay_s: float):
	label.text += t + "\n"
	await get_tree().create_timer(delay_s, true, false, true).timeout
