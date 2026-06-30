extends PlaceableObject
class_name AnimalObject

@export var animal_type: String = ""
@export var walk_speed: float = 34.0
@export var min_idle_time: float = 1.0
@export var max_idle_time: float = 2.8
@export var free_wander_radius: Vector2 = Vector2(80, 38)
@export var visual_node_path: NodePath = NodePath("Visual")

var home_pen: AnimalPenObject
var target_position: Vector2
var is_walking: bool = false
var idle_timer: float = 0.0
var _free_origin: Vector2
var _facing_dir: int = 1


func _ready() -> void:
	draggable = false
	blocks_cells = false
	_free_origin = global_position
	target_position = global_position
	_start_idle_timer()


func _process(delta: float) -> void:
	if is_walking:
		_walk_to_target(delta)
	else:
		idle_timer -= delta
		if idle_timer <= 0.0:
			_pick_new_target()

	_update_visual_walk_state()


func set_home_pen(pen: AnimalPenObject) -> void:
	home_pen = pen
	_free_origin = pen.get_random_animal_position()
	global_position = _free_origin
	target_position = _free_origin
	is_walking = false
	_start_idle_timer()


func _walk_to_target(delta: float) -> void:
	var to_target := target_position - global_position
	if to_target.length() <= 3.0:
		global_position = _clamp_to_home(target_position)
		is_walking = false
		_start_idle_timer()
		return

	var move_dir := to_target.normalized()
	global_position = _clamp_to_home(global_position + move_dir * walk_speed * delta)
	if abs(move_dir.x) > 0.02:
		_set_facing(-1 if move_dir.x < 0.0 else 1)


func _pick_new_target() -> void:
	if home_pen != null and is_instance_valid(home_pen):
		target_position = home_pen.get_random_animal_position()
	else:
		target_position = _free_origin + Vector2(
			randf_range(-free_wander_radius.x, free_wander_radius.x),
			randf_range(-free_wander_radius.y, free_wander_radius.y)
		)

	is_walking = true


func _clamp_to_home(world_position: Vector2) -> Vector2:
	if home_pen != null and is_instance_valid(home_pen):
		return home_pen.clamp_animal_world_position(world_position)

	var min_pos := _free_origin - free_wander_radius
	var max_pos := _free_origin + free_wander_radius
	return Vector2(
		clampf(world_position.x, min_pos.x, max_pos.x),
		clampf(world_position.y, min_pos.y, max_pos.y)
	)


func _set_facing(dir: int) -> void:
	if dir == _facing_dir:
		return

	_facing_dir = dir
	var visual := get_node_or_null(visual_node_path) as Node2D
	if visual != null and visual.has_method("set_facing"):
		visual.call("set_facing", dir)


func _update_visual_walk_state() -> void:
	var visual := get_node_or_null(visual_node_path)
	if visual != null and visual.has_method("set_walking"):
		visual.call("set_walking", is_walking)


func _start_idle_timer() -> void:
	idle_timer = randf_range(min_idle_time, max_idle_time)
