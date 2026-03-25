extends Node2D

@onready var _quest: Node = $QuestSystem
@onready var _player := $Player
@onready var _camera: Camera2D = $Camera2D

func _ready() -> void:
	if _quest.has_signal("quest_started"):
		_quest.quest_started.connect(_player.on_quest_started)
	# Safety: also hide the OS cursor here (crosshair shows instead).
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _process(_delta: float) -> void:
	if _player.visible:
		_camera.global_position = _player.global_position

