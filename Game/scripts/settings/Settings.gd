extends Node

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "input"
const KEY_POINTER_SENS := "pointer_sensitivity"

@export var pointer_sensitivity: float = 1.0

func _ready() -> void:
	add_to_group("settings")
	load_settings()

func load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)
	if err == OK:
		pointer_sensitivity = float(cfg.get_value(SECTION, KEY_POINTER_SENS, pointer_sensitivity))

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, KEY_POINTER_SENS, pointer_sensitivity)
	cfg.save(SETTINGS_PATH)

