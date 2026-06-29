extends Node2D

@export var idle_bob_amount: float = 2.5
@export var idle_bob_speed: float = 3.0

@export var walk_speed: float = 45.0
@export var walk_leg_angle: float = 0.18
@export var walk_bob_amount: float = 2.0

@export var can_wander: bool = true
@export var wander_radius: float = 120.0
@export var min_idle_time: float = 1.5
@export var max_idle_time: float = 3.5

@export var allow_flip: bool = true

@onready var chicken_root: Node2D = get_parent()

@onready var leg_back_pivot: Node2D = get_node_or_null("LegBackPivot")
@onready var leg_front_pivot: Node2D = get_node_or_null("LegFrontPivot")
@onready var body_pivot: Node2D = get_node_or_null("BodyPivot")
@onready var wing_pivot: Node2D = get_node_or_null("WingPivot")
@onready var head_pivot: Node2D = get_node_or_null("HeadPivot")

var time: float = 0.0

var base_scale: Vector2
var base_position: Vector2

var body_base_pos: Vector2
var head_base_pos: Vector2
var wing_base_rot: float
var leg_back_base_rot: float
var leg_front_base_rot: float

var target_position: Vector2
var is_walking: bool = false
var is_pecking: bool = false
var idle_timer: float = 0.0

var facing_dir: int = 1


func _ready():
	randomize()

	if not _validate_nodes():
		set_process(false)
		return

	base_scale = scale
	base_position = chicken_root.position

	body_base_pos = body_pivot.position
	head_base_pos = head_pivot.position

	wing_base_rot = wing_pivot.rotation
	leg_back_base_rot = leg_back_pivot.rotation
	leg_front_base_rot = leg_front_pivot.rotation

	target_position = chicken_root.position

	_start_idle_timer()


func _process(delta):
	time += delta

	if can_wander:
		_process_wander(delta)

	if is_walking:
		_update_walk_anim(delta)
	else:
		_update_idle_anim(delta)


func _validate_nodes() -> bool:
	if chicken_root == null:
		push_error("ChickenAnim lỗi: script phải gắn vào node Visual, Visual phải nằm dưới Chicken.")
		return false

	if leg_back_pivot == null:
		push_error("Thiếu node: Visual/LegBackPivot")
		return false

	if leg_front_pivot == null:
		push_error("Thiếu node: Visual/LegFrontPivot")
		return false

	if body_pivot == null:
		push_error("Thiếu node: Visual/BodyPivot")
		return false

	if wing_pivot == null:
		push_error("Thiếu node: Visual/WingPivot")
		return false

	if head_pivot == null:
		push_error("Thiếu node: Visual/HeadPivot")
		return false

	return true


func _process_wander(delta):
	if is_pecking:
		return

	if is_walking:
		var dir: Vector2 = target_position - chicken_root.position

		if dir.length() < 4.0:
			is_walking = false
			chicken_root.position = target_position
			_start_idle_timer()
			return

		var move_dir: Vector2 = dir.normalized()
		chicken_root.position += move_dir * walk_speed * delta

		if allow_flip and abs(move_dir.x) > 0.05:
			set_facing(-1 if move_dir.x < 0 else 1)

	else:
		idle_timer -= delta

		if idle_timer <= 0.0:
			if randf() < 0.45:
				_play_peck()
			else:
				_pick_new_target()


func set_facing(dir: int):
	if dir == facing_dir:
		return

	facing_dir = dir

	# Không set scale.x = 1 / -1 trực tiếp vì sẽ làm méo nếu Visual đang scale 0.4.
	# Giữ nguyên độ lớn scale ban đầu, chỉ đổi dấu x.
	scale = Vector2(abs(base_scale.x) * facing_dir, base_scale.y)


func _update_idle_anim(_delta):
	var bob: float = sin(time * idle_bob_speed) * idle_bob_amount

	body_pivot.position = body_base_pos + Vector2(0, bob)
	head_pivot.position = head_base_pos + Vector2(0, bob * 0.6)

	wing_pivot.rotation = wing_base_rot + sin(time * 2.0) * 0.04

	leg_back_pivot.rotation = leg_back_base_rot
	leg_front_pivot.rotation = leg_front_base_rot


func _update_walk_anim(_delta):
	var step: float = sin(time * 9.0)
	var bob: float = abs(step) * walk_bob_amount

	body_pivot.position = body_base_pos + Vector2(0, -bob)
	head_pivot.position = head_base_pos + Vector2(0, -bob * 0.8)

	leg_back_pivot.rotation = leg_back_base_rot + step * walk_leg_angle
	leg_front_pivot.rotation = leg_front_base_rot - step * walk_leg_angle

	wing_pivot.rotation = wing_base_rot + sin(time * 8.0) * 0.05


func _start_idle_timer():
	idle_timer = randf_range(min_idle_time, max_idle_time)


func _pick_new_target():
	var offset := Vector2(
		randf_range(-wander_radius, wander_radius),
		randf_range(-wander_radius * 0.45, wander_radius * 0.45)
	)

	target_position = base_position + offset
	is_walking = true


func _play_peck():
	if is_pecking:
		return

	is_pecking = true

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(head_pivot, "rotation", deg_to_rad(22), 0.16)
	tween.parallel().tween_property(head_pivot, "position", head_base_pos + Vector2(8, 12), 0.16)

	tween.tween_interval(0.12)

	tween.tween_property(head_pivot, "rotation", 0.0, 0.18)
	tween.parallel().tween_property(head_pivot, "position", head_base_pos, 0.18)

	await tween.finished

	is_pecking = false
	_start_idle_timer()
