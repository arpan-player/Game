extends Area2D

class_name DamageArea2D

# Generic damage area for melee/ult.
# Arms when a hit should be possible, then applies at most once per arm.

var _armed := false
var _damage := 0.0
var _owner: Node = null
var _hit_bodies := {}

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	monitoring = false

func arm(damage_amount: float, owner_node: Node) -> void:
	_damage = damage_amount
	_owner = owner_node
	_hit_bodies.clear()
	_armed = true
	monitoring = true

func disarm() -> void:
	_armed = false
	monitoring = false

func _on_body_entered(body: Node) -> void:
	if not _armed:
		return
	if body == _owner:
		return
	if _hit_bodies.has(body):
		return
	if body.has_method("apply_damage"):
		body.apply_damage(_damage, _owner)
		_hit_bodies[body] = true

