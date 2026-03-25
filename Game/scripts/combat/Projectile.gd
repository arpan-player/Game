extends Area2D

@export var lifetime_sec: float = 1.2

var _dir: Vector2 = Vector2.RIGHT
var _speed: float = 500.0
var _damage: float = 10.0
var _owner: Node = null
var _time: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func setup(direction: Vector2, speed: float, damage: float, owner_node: Node) -> void:
	_dir = direction.normalized()
	_speed = speed
	_damage = damage
	_owner = owner_node

func _process(delta: float) -> void:
	_time += delta
	if _time >= lifetime_sec:
		queue_free()
		return
	global_position += _dir * _speed * delta

func _on_body_entered(body: Node) -> void:
	if body == _owner:
		return
	if body.has_method("apply_damage"):
		body.apply_damage(_damage, _owner)
	queue_free()

