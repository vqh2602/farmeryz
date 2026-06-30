extends Node2D
class_name PlaceableObject

@export var object_id: String = "object"
@export var display_name: String = "Object"

# Kích thước mô tả object, dùng cho UI/debug.
@export var size_in_cells: Vector2i = Vector2i(1, 1)

# Có cho kéo không.
@export var draggable: bool = true

# Có chiếm/chặn ô không.
@export var blocks_cells: bool = true

# Nếu object có TileMapLayer con tên Area, dùng các cell đã vẽ ở đó làm footprint.
@export var use_area_footprint: bool = true
@export var area_layer_name: StringName = &"Area"
@export var hide_area_footprint_layer: bool = true

# Object isometric thường đặt pivot ở giữa chân/móng nhà.
# Footprint mặc định vì vậy được canh quanh pivot này, không lấy pivot làm góc.
@export var use_bottom_center_footprint_anchor: bool = true

# Bật nếu muốn tự khai báo chính xác các ô object chiếm.
@export var use_custom_footprint: bool = false

# Danh sách offset các ô object chiếm, tính từ current_cell.
# Nếu khai báo custom thì dùng đúng danh sách này, không tự canh bottom-center.
@export var custom_footprint: Array[Vector2i] = []

var current_cell: Vector2i = Vector2i.ZERO


func _ready():
	var area_layer := get_area_footprint_layer()
	if area_layer != null and hide_area_footprint_layer:
		area_layer.visible = false


func set_cell(cell: Vector2i):
	current_cell = cell


func can_drag() -> bool:
	return draggable


func has_factory_animation() -> bool:
	return get_factory_animation_player() != null


func play_factory_animation(mode_name: String) -> void:
	var player := get_factory_animation_player()
	if player != null and player.has_method("play"):
		player.call("play", mode_name)


func get_factory_animation_mode() -> String:
	var player := get_factory_animation_player()
	if player != null and player.has_method("get_current_mode"):
		return str(player.call("get_current_mode"))
	return ""


func get_factory_animation_player() -> Node:
	var visual := get_node_or_null("Visual")
	if visual != null and visual.has_method("play") and visual.has_method("has_animation_mode"):
		return visual

	return null


func get_footprint_offsets() -> Array[Vector2i]:
	if use_custom_footprint and custom_footprint.size() > 0:
		return custom_footprint

	var area_offsets := get_area_footprint_offsets()
	if area_offsets.size() > 0:
		return area_offsets

	var offsets: Array[Vector2i] = []
	var start_x: int = 0
	var start_y: int = 0

	if use_bottom_center_footprint_anchor:
		start_x = -floori(float(size_in_cells.x) / 2.0)
		start_y = -(size_in_cells.y - 1)

	for y in range(size_in_cells.y):
		for x in range(size_in_cells.x):
			offsets.append(Vector2i(start_x + x, start_y + y))

	return offsets


func get_area_footprint_layer() -> TileMapLayer:
	if not use_area_footprint:
		return null

	return get_node_or_null(NodePath(area_layer_name)) as TileMapLayer


func get_area_footprint_offsets() -> Array[Vector2i]:
	var area_layer := get_area_footprint_layer()
	if area_layer == null:
		return []

	var offsets: Array[Vector2i] = []
	for cell in area_layer.get_used_cells():
		offsets.append(cell)

	offsets.sort()
	return offsets


func get_total_occupied_cells() -> int:
	return get_footprint_offsets().size()
