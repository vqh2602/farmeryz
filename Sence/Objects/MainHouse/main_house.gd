extends Node2D

# Scene object nhà chính.
# Chỉ chứa hình ảnh + thông tin vùng chiếm ô.
# Logic đặt/xóa/check ô để trong base.gd hoặc world.gd.

@export var object_id: String = "main_house"
@export var display_name: String = "Main House"
@export var size_in_cells: Vector2i = Vector2i(4, 4)

var origin_cell: Vector2i = Vector2i.ZERO

func set_origin_cell(cell: Vector2i) -> void:
	origin_cell = cell

func get_occupied_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(size_in_cells.x):
		for y in range(size_in_cells.y):
			cells.append(origin_cell + Vector2i(x, y))
	return cells
