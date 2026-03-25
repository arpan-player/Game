extends CanvasLayer

@onready var _cross: Node2D = $Cross
var _settings: Node = null
var _virtual_pos: Vector2
var _last_mouse_pos: Vector2
var _enabled: bool = true

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	add_to_group("crosshair")
	_settings = get_tree().get_first_node_in_group("settings")
	_virtual_pos = get_viewport().get_mouse_position()
	_last_mouse_pos = _virtual_pos

func _process(_delta: float) -> void:
	if not _enabled:
		return
	var mouse_pos := get_viewport().get_mouse_position()
	var delta := mouse_pos - _last_mouse_pos
	_last_mouse_pos = mouse_pos

	var sens := 1.0
	if _settings != null and ("pointer_sensitivity" in _settings):
		sens = float(_settings.pointer_sensitivity)

	_virtual_pos += delta * sens
	var r := get_viewport().get_visible_rect()
	_virtual_pos.x = clampf(_virtual_pos.x, r.position.x, r.end.x)
	_virtual_pos.y = clampf(_virtual_pos.y, r.position.y, r.end.y)

	_cross.position = _virtual_pos

func get_screen_pos() -> Vector2:
	return _cross.position

func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	visible = enabled

