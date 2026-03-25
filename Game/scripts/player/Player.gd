extends CharacterBody2D

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _aim_line: Line2D = $AimLine
@onready var _melee_flash: Line2D = $MeleeFlash
@onready var _melee_area: DamageArea2D = $MeleeArea
@onready var _ult_area: DamageArea2D = $UltArea

const DAMAGE_AREA_GROUP := "damageable"

# Movement
@export var move_speed: float = 220.0
@export var aim_line_extra: float = 2.0 # a tiny overshoot for readability

# HP
@export var max_hp: float = 200.0
var _hp: float

# Heat (overcharge)
@export var heat_max: float = 100.0
@export var heat_gain_per_melee: float = 22.0
@export var heat_cooldown_per_sec: float = 6.0
var _heat: float = 0.0
var _ult_ready: bool = false
var _ult_used_this_quest: bool = false

# Melee ability (Phase 1)
@export var melee_damage: float = 18.0
@export var melee_cooldown: float = 0.28
@export var melee_windup: float = 0.05
@export var melee_active: float = 0.10
@export var melee_offset: float = 18.0 # where the hitbox spawns from the player
@export var melee_radius: float = 14.0 # should match the CircleShape2D in the scene
@export var melee_flash_length: float = 26.0

var _melee_cooldown_remaining: float = 0.0
var _melee_elapsed: float = 0.0
var _is_melee_attacking: bool = false
var _melee_area_armed_this_attack: bool = false
var _aim_dir: Vector2 = Vector2.RIGHT

# Ranged (Phase 1b)
@export var ranged_damage: float = 10.0
@export var ranged_speed: float = 560.0
@export var ranged_cooldown: float = 0.20
@export var heat_gain_per_ranged: float = 14.0

var _ranged_cooldown_remaining: float = 0.0

# Ult (unlocks when overheat)
@export var ult_damage: float = 55.0
@export var ult_self_damage_percent_min: float = 0.50
@export var ult_self_damage_percent_max: float = 0.75
@export var ult_self_damage_on_cast: bool = true
@export var ult_range_radius: float = 90.0 # should match the CircleShape2D in the scene
@export var ult_active_time: float = 0.10

var _ult_time_remaining: float = 0.0

func _ready() -> void:
	add_to_group(DAMAGE_AREA_GROUP)
	add_to_group("player")
	_hp = max_hp
	# Create a simple placeholder pixel texture at runtime (no downloads needed).
	_sprite.texture = _make_pixel_texture(Color(0.4, 0.9, 1.0, 1.0))

	# Ensure areas are disabled by default.
	_melee_area.disarm()
	_ult_area.disarm()

func _process(delta: float) -> void:
	_update_heat(delta)
	_update_melee_flash()

	# Melee state machine.
	if _is_melee_attacking:
		_melee_elapsed += delta

		if _melee_elapsed >= melee_windup and _melee_elapsed < (melee_windup + melee_active):
			if not _melee_area_armed_this_attack:
				_melee_area.position = _aim_dir * melee_offset
				_melee_area.arm(melee_damage, self)
				_melee_area_armed_this_attack = true
		elif _melee_elapsed >= (melee_windup + melee_active) and _melee_area.monitoring:
			_melee_area.disarm()

		if _melee_elapsed >= (melee_windup + melee_active):
			_is_melee_attacking = false
			_melee_cooldown_remaining = melee_cooldown

	# Ult timing (hit happens via area overlap during the brief active window).
	if _ult_time_remaining > 0.0:
		_ult_time_remaining -= delta
		if _ult_time_remaining <= 0.0 and _ult_area.monitoring:
			_ult_area.disarm()

	_melee_cooldown_remaining = maxf(0.0, _melee_cooldown_remaining - delta)
	_ranged_cooldown_remaining = maxf(0.0, _ranged_cooldown_remaining - delta)

func _physics_process(delta: float) -> void:
	_update_aim()
	_handle_movement(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		try_cast_melee()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		try_cast_ranged()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			try_cast_ult()

func _update_aim() -> void:
	var crosshair := get_tree().get_first_node_in_group("crosshair")
	var screen_pos: Vector2 = get_viewport().get_mouse_position()
	if crosshair != null and crosshair.has_method("get_screen_pos"):
		screen_pos = crosshair.get_screen_pos()

	# Convert screen position to world position using the canvas transform (includes camera).
	var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	var v := (world_pos - global_position)
	if v.length_squared() > 0.0001:
		_aim_dir = v.normalized()

func _update_aim_line() -> void:
	if _aim_line == null:
		return
	var melee_reach := melee_offset + melee_radius + aim_line_extra
	_aim_line.clear_points()
	_aim_line.add_point(Vector2.ZERO)
	_aim_line.add_point(_aim_dir * melee_reach)

func _update_melee_flash() -> void:
	if _melee_flash == null:
		return
	if not _is_melee_attacking:
		_melee_flash.visible = false
		return

	var t := _melee_elapsed
	var is_active_window := (t >= melee_windup and t < (melee_windup + melee_active))
	_melee_flash.visible = is_active_window
	if not is_active_window:
		return

	_melee_flash.clear_points()
	_melee_flash.add_point(Vector2.ZERO)
	_melee_flash.add_point(_aim_dir * melee_flash_length)

func _handle_movement(_delta: float) -> void:
	var ix := 0.0
	var iy := 0.0
	# WASD + arrow support (keeps prototype setup minimal).
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		ix -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		ix += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		iy -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		iy += 1.0

	var dir := Vector2(ix, iy)
	if dir.length_squared() > 0.0001:
		dir = dir.normalized()

	velocity = dir * move_speed
	move_and_slide()

func _update_heat(delta: float) -> void:
	# Passive cooldown always applies (tunable later).
	_heat = maxf(0.0, _heat - heat_cooldown_per_sec * delta)

	if _heat >= heat_max:
		_ult_ready = true
	else:
		# If you want "once ready always ready" you can change this.
		_ult_ready = _ult_ready and _ult_used_this_quest == false

	if _ult_used_this_quest:
		_ult_ready = false

func try_cast_melee() -> void:
	if _is_melee_attacking:
		return
	if _melee_cooldown_remaining > 0.0:
		return
	_is_melee_attacking = true
	_melee_elapsed = 0.0
	_melee_area_armed_this_attack = false

	# Heat builds up on ability use.
	_heat = clampf(_heat + heat_gain_per_melee, 0.0, heat_max)

	# Update ult-ready immediately if we reached max.
	if _heat >= heat_max:
		_ult_ready = true

func try_cast_ult() -> void:
	if not _ult_ready:
		return
	if _ult_used_this_quest:
		return

	_ult_used_this_quest = true
	_ult_ready = false

	# Ult pulse active window.
	_ult_time_remaining = ult_active_time

	# Apply self-damage on cast (simple prototype).
	if ult_self_damage_on_cast:
		var p := randf_range(ult_self_damage_percent_min, ult_self_damage_percent_max)
		apply_damage(max_hp * p, self)

	# Arm area for enemy damage.
	_ult_area.position = Vector2.ZERO
	_ult_area.arm(ult_damage, self)

func try_cast_ranged() -> void:
	if _ranged_cooldown_remaining > 0.0:
		return

	var projectile_scene := preload("res://scenes/Projectile.tscn")
	var proj := projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position + _aim_dir * 10.0
	proj.setup(_aim_dir, ranged_speed, ranged_damage, self)

	_ranged_cooldown_remaining = ranged_cooldown
	_heat = clampf(_heat + heat_gain_per_ranged, 0.0, heat_max)
	if _heat >= heat_max:
		_ult_ready = true

func apply_damage(amount: float, _source: Node) -> void:
	_hp -= amount
	_hp = maxf(0.0, _hp)

	if _hp <= 0.0:
		_on_death()

func _on_death() -> void:
	# Prototype: just hide.
	visible = false
	set_physics_process(false)
	_melee_area.disarm()
	_ult_area.disarm()

func on_quest_started(_quest_id: int) -> void:
	# Reset overcharge per quest.
	_hp = max_hp
	_heat = 0.0
	_ult_ready = false
	_ult_used_this_quest = false
	_melee_cooldown_remaining = 0.0
	_is_melee_attacking = false
	_melee_elapsed = 0.0
	_melee_area_armed_this_attack = false
	_ult_time_remaining = 0.0
	visible = true
	set_physics_process(true)

func get_hp() -> float:
	return _hp

func get_heat() -> float:
	return _heat

func is_ult_ready() -> bool:
	return _ult_ready

func _make_pixel_texture(color: Color) -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)

