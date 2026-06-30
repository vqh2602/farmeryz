extends Node2D
class_name UnityFactoryAnimPlayer

@export_file("*.json") var animation_data_path: String = ""
@export var default_mode: String = "active"
@export var autoplay: bool = true

var _animations: Dictionary = {}
var _mode: String = ""
var _time: float = 0.0
var _length: float = 0.0
var _base_positions: Dictionary = {}
var _base_scales: Dictionary = {}
var _base_visibility: Dictionary = {}
var _node_cache: Dictionary = {}
var _missing_paths: Dictionary = {}


func _ready() -> void:
	_capture_base_state(self)
	_load_animation_data()
	if autoplay:
		play(default_mode)


func _process(delta: float) -> void:
	if _mode.is_empty() or not _animations.has(_mode):
		return

	var anim: Dictionary = _animations[_mode]
	_length = maxf(float(anim.get("length", 0.0)), 0.0)
	if _length <= 0.0:
		return

	_time = fmod(_time + delta, _length)
	_apply_mode_at_time(_time)


func play(mode_name: String) -> void:
	if not _animations.has(mode_name):
		push_warning("Factory animation mode không tồn tại: %s (%s)" % [mode_name, animation_data_path])
		return

	_mode = mode_name
	_time = 0.0
	var anim: Dictionary = _animations[_mode]
	_length = maxf(float(anim.get("length", 0.0)), 0.0)
	_apply_mode_at_time(0.0)


func play_idle() -> void:
	play("idle")


func play_active() -> void:
	play("active")


func get_current_mode() -> String:
	return _mode


func has_animation_mode(mode_name: String) -> bool:
	return _animations.has(mode_name)


func _load_animation_data() -> void:
	if animation_data_path.is_empty():
		return

	if not FileAccess.file_exists(animation_data_path):
		push_warning("Không tìm thấy factory animation data: %s" % animation_data_path)
		return

	var file := FileAccess.open(animation_data_path, FileAccess.READ)
	if file == null:
		push_warning("Không mở được factory animation data: %s" % animation_data_path)
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Factory animation data không hợp lệ: %s" % animation_data_path)
		return

	_animations = (parsed as Dictionary).get("animations", {})


func _capture_base_state(node: Node) -> void:
	if node is Node2D:
		var node_2d := node as Node2D
		var path := String(get_path_to(node_2d))
		_base_positions[path] = node_2d.position
		_base_scales[path] = node_2d.scale

	if node is CanvasItem:
		var canvas_item := node as CanvasItem
		var path := String(get_path_to(canvas_item))
		_base_visibility[path] = canvas_item.visible

	for child in node.get_children():
		_capture_base_state(child)


func _restore_base_state() -> void:
	for path in _base_positions:
		var node := _get_node_by_path(path) as Node2D
		if node != null:
			node.position = _base_positions[path]

	for path in _base_scales:
		var node := _get_node_by_path(path) as Node2D
		if node != null:
			node.scale = _base_scales[path]

	for path in _base_visibility:
		var node := _get_node_by_path(path) as CanvasItem
		if node != null:
			node.visible = _base_visibility[path]


func _apply_mode_at_time(time: float) -> void:
	_restore_base_state()
	if not _animations.has(_mode):
		return

	var anim: Dictionary = _animations[_mode]
	_apply_position_curves(anim.get("position", {}), time)
	_apply_scale_curves(anim.get("scale", {}), time)
	_apply_visibility_curves(anim.get("visible", {}), time)


func _apply_position_curves(curves: Dictionary, time: float) -> void:
	for path in curves:
		var node := _get_node_by_path(path) as Node2D
		if node == null:
			continue

		node.position = _sample_vector2(curves[path], time, node.position)


func _apply_scale_curves(curves: Dictionary, time: float) -> void:
	for path in curves:
		var node := _get_node_by_path(path) as Node2D
		if node == null:
			continue

		node.scale = _sample_vector2(curves[path], time, node.scale)


func _apply_visibility_curves(curves: Dictionary, time: float) -> void:
	for path in curves:
		var node := _get_node_by_path(path) as CanvasItem
		if node == null:
			continue

		node.visible = _sample_bool(curves[path], time, node.visible)


func _sample_vector2(keys: Array, time: float, fallback: Vector2) -> Vector2:
	if keys.is_empty():
		return fallback

	var first: Array = keys[0]
	if time <= float(first[0]):
		return Vector2(float(first[1]), float(first[2]))

	for index in range(keys.size() - 1):
		var left: Array = keys[index]
		var right: Array = keys[index + 1]
		var left_time := float(left[0])
		var right_time := float(right[0])
		if time <= right_time:
			var span := maxf(right_time - left_time, 0.0001)
			var weight := clampf((time - left_time) / span, 0.0, 1.0)
			return Vector2(
				lerpf(float(left[1]), float(right[1]), weight),
				lerpf(float(left[2]), float(right[2]), weight)
			)

	var last: Array = keys[keys.size() - 1]
	return Vector2(float(last[1]), float(last[2]))


func _sample_bool(keys: Array, time: float, fallback: bool) -> bool:
	if keys.is_empty():
		return fallback

	var value := fallback
	for key in keys:
		var row: Array = key
		if time + 0.0001 < float(row[0]):
			break
		value = float(row[1]) >= 0.5

	return value


func _get_node_by_path(path: String) -> Node:
	if _node_cache.has(path):
		var cached = _node_cache[path]
		if is_instance_valid(cached):
			return cached

	var node := get_node_or_null(NodePath(path))
	if node == null and not _missing_paths.has(path):
		_missing_paths[path] = true
		push_warning("Thiếu node factory animation: %s trong %s" % [path, animation_data_path])

	_node_cache[path] = node
	return node
