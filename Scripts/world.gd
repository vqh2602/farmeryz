extends Node2D

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var placement_manager: PlacementManager = $PlacementManager
@onready var cell_debug_label: Label = $CanvasLayer/CellDebugLabel


func _process(_delta):
	var mouse_cell: Vector2i = get_mouse_cell()
	var mouse_global: Vector2 = get_global_mouse_position()

	if cell_debug_label:
		var drag_info: String = "None"

		if placement_manager != null:
			drag_info = placement_manager.get_dragging_info_text()

		cell_debug_label.text = "Mouse Cell: %s | Pos: %s\n%s" % [
			mouse_cell,
			mouse_global.round(),
			drag_info
		]

		var viewport_size: Vector2 = get_viewport_rect().size
		cell_debug_label.position = Vector2(20, viewport_size.y - 70)


func get_mouse_cell() -> Vector2i:
	var mouse_global: Vector2 = get_global_mouse_position()
	var local_pos: Vector2 = ground_layer.to_local(mouse_global)
	return ground_layer.local_to_map(local_pos)
