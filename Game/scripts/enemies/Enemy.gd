extends CharacterBody2D

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _melee_area: DamageArea2D = $MeleeArea
@onready var _hp_bar: ProgressBar = $HPBar

@export var max_hp: float = 100.0
var _hp: float

@export var move_speed: float = 150.0
@export var attack_range: float = 38.0
@export var melee_damage: float = 14.0
@export var attack_cooldown: float = 0.9
@export var attack_windup: float = 0.05
@export var attack_active: float = 0.12

var _attack_cooldown_remaining: float = 0.0
var _attack_elapsed: float = 0.0
var _is_attacking: bool = false
var _melee_area_armed_this_attack: bool = false

var _player: Node2D = null

func _ready() -> void:
	add_to_group("damageable")
	_hp = max_hp
	_sprite.texture = _make_pixel_texture(Color(1.0, 0.4, 0.4, 1.0))
	_melee_area.disarm()

	_player = get_tree().get_first_node_in_group("player")
	_hp_bar.max_value = max_hp
	_hp_bar.value = _hp

func _physics_process(_delta: float) -> void:
	if _player == null or not _player.is_inside_tree():
		_player = get_tree().get_first_node_in_group("player") as Node2D
		return
	if not _player.visible:
		return

	var to_player: Vector2 = _player.global_position - global_position
	var dist: float = to_player.length()

	# AI attack trigger.
	if dist <= attack_range and _attack_cooldown_remaining <= 0.0 and not _is_attacking:
		_start_attack()

	if not _is_attacking and dist > attack_range * 0.85:
		var dir: Vector2 = to_player.normalized()
		velocity = dir * move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		move_and_slide()

func _process(delta: float) -> void:
	_hp_bar.value = _hp
	_attack_cooldown_remaining = maxf(0.0, _attack_cooldown_remaining - delta)

	if _is_attacking:
		_attack_elapsed += delta

		if _attack_elapsed >= attack_windup and _attack_elapsed < (attack_windup + attack_active):
			if not _melee_area_armed_this_attack:
				_melee_area.arm(melee_damage, self)
				_melee_area_armed_this_attack = true
		elif _attack_elapsed >= (attack_windup + attack_active) and _melee_area.monitoring:
			_melee_area.disarm()

		if _attack_elapsed >= (attack_windup + attack_active):
			_is_attacking = false
			_attack_elapsed = 0.0
			_attack_cooldown_remaining = attack_cooldown

func _start_attack() -> void:
	_is_attacking = true
	_attack_elapsed = 0.0
	_melee_area_armed_this_attack = false

func apply_damage(amount: float, _source: Node) -> void:
	_hp -= amount
	_hp = maxf(0.0, _hp)
	if _hp <= 0.0:
		_on_death()

func _on_death() -> void:
	visible = false
	set_physics_process(false)
	_melee_area.disarm()

func _make_pixel_texture(color: Color) -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)
