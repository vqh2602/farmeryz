extends Node2D
class_name AnimalLayerAnim

@export var idle_bob_amount: float = 2.0
@export var idle_bob_speed: float = 3.0
@export var walk_bob_amount: float = 3.0
@export var walk_leg_angle: float = 0.22
@export var wing_angle: float = 0.10
@export var tail_angle: float = 0.08

var is_walking: bool = false
var _time: float = 0.0
var _base_scale: Vector2
var _base_positions: Dictionary = {}
var _base_rotations: Dictionary = {}
var _pivots: Dictionary = {}


func _ready() -> void:
	_base_scale = scale
	_cache_pivots(self)


func _process(delta: float) -> void:
	_time += delta
	if is_walking:
		_apply_walk()
	else:
		_apply_idle()


func set_walking(value: bool) -> void:
	is_walking = value


func set_facing(dir: int) -> void:
	scale = Vector2(abs(_base_scale.x) * dir, _base_scale.y)


func _cache_pivots(node: Node) -> void:
	if node is Node2D:
		var node_2d := node as Node2D
		var key := String(node_2d.name)
		_pivots[key] = node_2d
		_base_positions[node_2d] = node_2d.position
		_base_rotations[node_2d] = node_2d.rotation

	for child in node.get_children():
		_cache_pivots(child)


func _apply_idle() -> void:
	var bob := sin(_time * idle_bob_speed) * idle_bob_amount
	_bob("BodyPivot", bob)
	_bob("HeadPivot", bob * 0.55)
	_bob("WingPivot", bob * 0.30)
	_bob("WingLeftPivot", bob * 0.30)
	_bob("WingRightPivot", bob * 0.30)

	_rotate("TailPivot", sin(_time * 2.1) * tail_angle)
	_rotate("WingPivot", sin(_time * 6.0) * wing_angle)
	_rotate("WingLeftPivot", sin(_time * 7.0) * wing_angle)
	_rotate("WingRightPivot", -sin(_time * 7.0) * wing_angle)
	_reset_legs()


func _apply_walk() -> void:
	var step: float = sin(_time * 9.5)
	var bob: float = absf(step) * walk_bob_amount

	_bob("BodyPivot", -bob)
	_bob("HeadPivot", -bob * 0.75)
	_bob("WingPivot", -bob * 0.25)

	_rotate("LegBackPivot", step * walk_leg_angle)
	_rotate("LegFrontPivot", -step * walk_leg_angle)
	_rotate("LegBack2Pivot", -step * walk_leg_angle)
	_rotate("LegFront2Pivot", step * walk_leg_angle)
	_rotate("TailPivot", sin(_time * 5.5) * tail_angle)
	_rotate("WingPivot", sin(_time * 8.0) * wing_angle)
	_rotate("WingLeftPivot", sin(_time * 9.0) * wing_angle)
	_rotate("WingRightPivot", -sin(_time * 9.0) * wing_angle)


func _bob(pivot_name: String, amount: float) -> void:
	var pivot := _pivots.get(pivot_name) as Node2D
	if pivot == null:
		return

	pivot.position = (_base_positions[pivot] as Vector2) + Vector2(0, amount)


func _rotate(pivot_name: String, amount: float) -> void:
	var pivot := _pivots.get(pivot_name) as Node2D
	if pivot == null:
		return

	pivot.rotation = float(_base_rotations[pivot]) + amount


func _reset_legs() -> void:
	for pivot_name in ["LegBackPivot", "LegFrontPivot", "LegBack2Pivot", "LegFront2Pivot"]:
		_rotate(pivot_name, 0.0)
