extends Node2D

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var block_layer: TileMapLayer = $BlockLayer
@onready var objects: Node2D = $Objects

var occupied_cells := {}
var main_house_scene := preload("res://Scenes/Objects/MainHouse.tscn")

func _ready() -> void:
	place_main_house(Vector2i(10, 10))

func can_place_object(origin_cell: Vector2i, size: Vector2i) -> bool:
	for x in range(size.x):
		for y in range(size.y):
			var cell := origin_cell + Vector2i(x, y)

			if ground_layer.get_cell_source_id(cell) == -1:
				return false

			if block_layer.get_cell_source_id(cell) != -1:
				return false

			if occupied_cells.has(cell):
				return false

	return true

func occupy_cells(origin_cell: Vector2i, size: Vector2i) -> void:
	for x in range(size.x):
		for y in range(size.y):
			var cell := origin_cell + Vector2i(x, y)
			occupied_cells[cell] = true

func place_main_house(cell: Vector2i) -> void:
	var house = main_house_scene.instantiate()
	var size: Vector2i = house.size_in_cells

	if not can_place_object(cell, size):
		print("Không thể đặt nhà tại ô: ", cell)
		house.queue_free()
		return

	objects.add_child(house)

	var local_pos := ground_layer.map_to_local(cell)
	house.global_position = ground_layer.to_global(local_pos)
	house.set_origin_cell(cell)

	occupy_cells(cell, size)
