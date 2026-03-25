extends Node

signal quest_started(quest_id: int)

var _quest_id: int = 0

func _ready() -> void:
	begin_new_quest()

func begin_new_quest() -> void:
	_quest_id += 1
	quest_started.emit(_quest_id)

func _unhandled_input(event: InputEvent) -> void:
	# Prototype helper: press N to start a new quest.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_N:
			begin_new_quest()

