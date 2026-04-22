extends Control

@export var final_wait_seconds := 1.0
@export var final_fade_seconds := 0.35

@onready var log: RichTextLabel = $Log
@onready var final: Control = $Final

func _ready() -> void:
	if log != null:
		log.text = ""
	await _line("[b][color=#ff4d6d]KERNEL PANIC[/color][/b]", 0.35)
	await _line("[color=#a6ffcb]fatal[/color]: OPENCLAW_GUARDIAN segfault (0xC0DE)", 0.45)
	await _line("bug_injected: [color=#a6ffcb]SUCCESS[/color]", 0.35)
	await _line("system: shutting down...", 0.55)
	await get_tree().create_timer(final_wait_seconds, true, false, true).timeout
	_show_final()

func _line(bb: String, delay_s: float) -> void:
	if log != null:
		log.append_text(bb + "\n")
	await get_tree().create_timer(delay_s, true, false, true).timeout

func _show_final() -> void:
	if final == null:
		return
	final.visible = true
	final.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(final, "modulate:a", 1.0, final_fade_seconds)
