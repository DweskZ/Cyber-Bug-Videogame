extends Node
class_name RunState

signal packets_changed(packets: int)

var packets: int = 0

func reset_run() -> void:
	packets = 0
	packets_changed.emit(packets)

func add_packets(amount: int = 1) -> void:
	packets += amount
	packets_changed.emit(packets)
