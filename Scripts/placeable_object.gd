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

# Bật nếu muốn tự khai báo chính xác các ô object chiếm.
@export var use_custom_footprint: bool = false

# Danh sách offset các ô object chiếm, tính từ current_cell.
# Ví dụ 2x2:
# [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)]
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

	for y in range(size_in_cells.y):
		for x in range(size_in_cells.x):
			offsets.append(Vector2i(x, y))

	return offsets


func get_total_occupied_cells() -> int:
	return get_footprint_offsets().size() 
