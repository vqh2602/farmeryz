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

# Object isometric thường đặt pivot ở giữa chân/móng nhà.
# Footprint mặc định vì vậy được canh quanh pivot này, không lấy pivot làm góc.
@export var use_bottom_center_footprint_anchor: bool = true

# Bật nếu muốn tự khai báo chính xác các ô object chiếm.
@export var use_custom_footprint: bool = false

# Danh sách offset các ô object chiếm, tính từ current_cell.
# Nếu khai báo custom thì dùng đúng danh sách này, không tự canh bottom-center.
@export var custom_footprint: Array[Vector2i] = []

var current_cell: Vector2i = Vector2i.ZERO


func set_cell(cell: Vector2i):
	current_cell = cell


func can_drag() -> bool:
	return draggable


func get_footprint_offsets() -> Array[Vector2i]:
	if use_custom_footprint and custom_footprint.size() > 0:
		return custom_footprint

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


func get_total_occupied_cells() -> int:
	return get_footprint_offsets().size()
