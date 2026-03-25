extends CanvasLayer

@onready var _hp_bar: ProgressBar = $HPBar
@onready var _heat_bar: ProgressBar = $HeatBar
@onready var _ult_label: Label = $UltLabel
@onready var _hp_label: Label = $HPLabel
@onready var _heat_label: Label = $HeatLabel
@onready var _help_label: Label = $HelpLabel

func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	_hp_bar.max_value = player.max_hp
	_hp_bar.value = player.get_hp()
	_hp_label.text = "HP %d/%d" % [int(player.get_hp()), int(player.max_hp)]

	_heat_bar.max_value = player.heat_max
	_heat_bar.value = player.get_heat()
	_heat_label.text = "Heat %d/%d" % [int(player.get_heat()), int(player.heat_max)]

	_help_label.text = "Goal: build heat to unlock Ult. LMB=melee, RMB=ranged, E=ult, N=new quest, Esc=settings."

	if player.is_ult_ready():
		_ult_label.text = "ULT READY (E)"
	else:
		_ult_label.text = "Ult locked"

