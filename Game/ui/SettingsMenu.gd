extends CanvasLayer

@onready var _panel: Panel = $Panel
@onready var _slider: HSlider = $Panel/VBox/PointerSensSlider
@onready var _value_label: Label = $Panel/VBox/PointerSensRow/PointerSensValue

var _settings: Node = null
var _crosshair: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings = get_tree().get_first_node_in_group("settings")
	_crosshair = get_tree().get_first_node_in_group("crosshair")

	_slider.min_value = 0.2
	_slider.max_value = 3.0
	_slider.step = 0.05

	if _settings != null:
		_slider.value = _settings.pointer_sensitivity
	_update_label()

	_slider.value_changed.connect(_on_slider_changed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_toggle()

func _toggle() -> void:
	_panel.visible = not _panel.visible
	if _panel.visible:
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if _crosshair != null and _crosshair.has_method("set_enabled"):
			_crosshair.set_enabled(false)
	else:
		get_tree().paused = false
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		if _crosshair != null and _crosshair.has_method("set_enabled"):
			_crosshair.set_enabled(true)
		_save()

func _on_slider_changed(v: float) -> void:
	if _settings != null:
		_settings.pointer_sensitivity = float(v)
	_update_label()

func _update_label() -> void:
	_value_label.text = "x%.2f" % [_slider.value]

func _save() -> void:
	if _settings != null and _settings.has_method("save_settings"):
		_settings.save_settings()
