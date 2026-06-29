extends Node
class_name PlacementManager

@export var edge_scroll_margin: float = 80.0
@export var edge_scroll_speed: float = 650.0
@export var drag_hold_seconds: float = 0.18
@export var drag_start_distance: float = 10.0

# ID tile preview trong TileSet của base.tscn:
# 12 = xanh dương, 13 = đỏ, 14 = vàng, 15 = xanh lá.
@export var valid_preview_source_id: int = 12
@export var invalid_preview_source_id: int = 13
@export var occupied_source_id: int = 14
@export var preview_atlas_coords: Vector2i = Vector2i(0, 0)

@onready var world: Node2D = get_parent()
@onready var ground_layer: TileMapLayer = $"../GroundLayer"
@onready var block_layer: TileMapLayer = $"../BlockLayer"
@onready var obj_layer_block: TileMapLayer = $"../ObjLayerBlock"
@onready var preview_layer: TileMapLayer = $"../PreviewLayer"
@onready var objects: Node2D = $"../Objects"
@onready var camera: Camera2D = $"../Camera2D"

var dragging_object: PlaceableObject = null
var selected_object: PlaceableObject = null
var pending_drag_object: PlaceableObject = null
var pending_drag_screen_pos: Vector2 = Vector2.ZERO
var pending_drag_start_msec: int = 0
var current_cell: Vector2i = Vector2i.ZERO
var is_current_cell_valid: bool = false


func _ready():
	print("=== PlacementManager ready ===")

	# ObjLayerBlock chỉ dùng logic, nên có thể ẩn.
	obj_layer_block.visible = false

	# PreviewLayer dùng để hiện footprint/occupied trong edit mode.
	preview_layer.visible = true
	preview_layer.modulate = Color(1, 1, 1, 0.65)
	preview_layer.z_index = 160

	objects.z_index = 100

	register_existing_objects()


func _process(delta):
	if pending_drag_object != null and dragging_object == null:
		try_promote_pending_drag()

	if dragging_object != null:
		update_edge_scroll(delta)


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				begin_drag_press(event.position)
			else:
				if dragging_object != null:
					stop_drag()
				else:
					cancel_pending_drag()

	if event is InputEventMouseMotion:
		if pending_drag_object != null and dragging_object == null:
			try_promote_pending_drag(event.position)

		if dragging_object != null:
			update_drag()


func register_existing_objects():
	obj_layer_block.clear()
	preview_layer.clear()

	print("=== REGISTER EXISTING OBJECTS ===")

	for child in objects.get_children():
		if child is PlaceableObject:
			var obj: PlaceableObject = child as PlaceableObject
			var cell: Vector2i = get_cell_from_world_position(obj.global_position)

			obj.set_cell(cell)
			move_object_to_cell(obj, cell)

			print("Register object: ", obj.object_id)
			print(" - cell: ", cell)
			print(" - size_in_cells: ", obj.size_in_cells)
			print(" - total cells: ", obj.get_total_occupied_cells())
			print(" - draggable: ", obj.draggable)
			print(" - blocks_cells: ", obj.blocks_cells)

			if obj.blocks_cells:
				mark_occupied_cells_for_obj(obj, cell)
		else:
			print("Node này KHÔNG phải PlaceableObject: ", child.name)


func begin_drag_press(screen_pos: Vector2):
	var obj: PlaceableObject = get_object_under_mouse()

	if obj == null:
		selected_object = null
		cancel_pending_drag()
		return

	if not obj.can_drag():
		print("Object không cho kéo: ", obj.object_id)
		return

	selected_object = obj
	pending_drag_object = obj
	pending_drag_screen_pos = screen_pos
	pending_drag_start_msec = Time.get_ticks_msec()
	current_cell = obj.current_cell


func cancel_pending_drag():
	pending_drag_object = null
	pending_drag_screen_pos = Vector2.ZERO
	pending_drag_start_msec = 0


func try_promote_pending_drag(screen_pos: Vector2 = Vector2.INF):
	if pending_drag_object == null:
		return

	if screen_pos == Vector2.INF:
		screen_pos = world.get_viewport().get_mouse_position()

	var elapsed_seconds: float = float(Time.get_ticks_msec() - pending_drag_start_msec) / 1000.0
	var moved_distance: float = pending_drag_screen_pos.distance_to(screen_pos)

	if elapsed_seconds < drag_hold_seconds:
		return

	if moved_distance < drag_start_distance:
		return

	start_drag(pending_drag_object)
	cancel_pending_drag()


func start_drag(obj: PlaceableObject):
	dragging_object = obj
	current_cell = obj.current_cell

	print("=== START DRAG ===")
	print("Object: ", obj.object_id)
	print("Size in cells: ", obj.size_in_cells)
	print("Total cells: ", obj.get_total_occupied_cells())

	set_object_drag_visual(obj, true)

	# Khi kéo object, bỏ vùng chiếm cũ của chính nó khỏi logic
	# để nó có thể kéo lại trên vị trí cũ mà không bị báo va chạm.
	rebuild_occupied_cells_except(obj)

	update_drag()


func stop_drag():
	if dragging_object == null:
		return

	var obj: PlaceableObject = dragging_object

	if can_place_object_for_obj(obj, current_cell):
		move_object_to_cell(obj, current_cell)
		obj.set_cell(current_cell)

		set_object_drag_visual(obj, false)
		dragging_object = null

		clear_preview()
		rebuild_occupied_cells()

		print("Đặt object thành công: ", obj.object_id, " tại ô: ", current_cell)
	else:
		move_object_to_cell(obj, obj.current_cell)

		set_object_drag_visual(obj, false)
		dragging_object = null

		clear_preview()
		rebuild_occupied_cells()

		print("Không thể đặt object tại ô: ", current_cell, " trả về: ", obj.current_cell)


func update_drag():
	if dragging_object == null:
		return

	var cell: Vector2i = get_mouse_cell()
	current_cell = cell

	move_object_to_cell(dragging_object, cell)

	is_current_cell_valid = can_place_object_for_obj(dragging_object, cell)

	var source_id: int = valid_preview_source_id
	if not is_current_cell_valid:
		source_id = invalid_preview_source_id

	draw_drag_preview_for_obj(dragging_object, cell, source_id)

	print(
		"Dragging: ", dragging_object.object_id,
		" | cell: ", cell,
		" | size: ", dragging_object.size_in_cells,
		" | total: ", dragging_object.get_total_occupied_cells(),
		" | valid: ", is_current_cell_valid,
		" | source_id: ", source_id
	)


func set_object_drag_visual(obj: PlaceableObject, is_dragging: bool):
	if is_dragging:
		obj.modulate = Color(1, 1, 1, 0.55)
	else:
		obj.modulate = Color(1, 1, 1, 1.0)


func get_dragging_info_text() -> String:
	if dragging_object == null:
		return "None"

	var total_cells: int = dragging_object.get_total_occupied_cells()
	var status: String = "Khả dụng" if is_current_cell_valid else "Không khả dụng"

	return "%s | Cell: %s | Size: %sx%s | Chiếm: %s ô | %s" % [
		dragging_object.object_id,
		current_cell,
		dragging_object.size_in_cells.x,
		dragging_object.size_in_cells.y,
		total_cells,
		status
	]


func get_object_under_mouse() -> PlaceableObject:
	var mouse_global: Vector2 = world.get_global_mouse_position()

	var children: Array = objects.get_children()
	children.reverse()

	for child in children:
		if child is PlaceableObject:
			var obj: PlaceableObject = child as PlaceableObject
			var sprite: Sprite2D = obj.get_node_or_null("Sprite2D") as Sprite2D

			if sprite == null:
				continue

			var mouse_local: Vector2 = sprite.to_local(mouse_global)
			var rect: Rect2 = sprite.get_rect()

			if rect.has_point(mouse_local):
				return obj

	return null


func get_mouse_cell() -> Vector2i:
	var mouse_global: Vector2 = world.get_global_mouse_position()
	return get_cell_from_world_position(mouse_global)


func get_cell_from_world_position(world_position: Vector2) -> Vector2i:
	var local_pos: Vector2 = ground_layer.to_local(world_position)
	return ground_layer.local_to_map(local_pos)


func move_object_to_cell(obj: PlaceableObject, cell: Vector2i):
	var local_pos: Vector2 = ground_layer.map_to_local(cell)
	obj.global_position = ground_layer.to_global(local_pos)


func get_object_footprint_cells(obj: PlaceableObject, origin_cell: Vector2i) -> Array[Vector2i]:
	var area_layer := obj.get_area_footprint_layer()
	if area_layer != null and area_layer.get_used_cells().size() > 0:
		return get_area_footprint_cells(obj, area_layer, origin_cell)

	var cells: Array[Vector2i] = []

	for offset in obj.get_footprint_offsets():
		cells.append(origin_cell + offset)

	return cells


func get_area_footprint_cells(obj: PlaceableObject, area_layer: TileMapLayer, origin_cell: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var seen := {}
	var origin_local: Vector2 = ground_layer.map_to_local(origin_cell)

	for area_cell in area_layer.get_used_cells():
		var area_global: Vector2 = area_layer.to_global(area_layer.map_to_local(area_cell))
		var area_local_to_obj: Vector2 = obj.to_local(area_global)
		var target_cell: Vector2i = ground_layer.local_to_map(origin_local + area_local_to_obj)

		if not seen.has(target_cell):
			seen[target_cell] = true
			cells.append(target_cell)

	cells.sort()
	return cells


func can_place_object_for_obj(obj: PlaceableObject, origin_cell: Vector2i) -> bool:
	var cells: Array[Vector2i] = get_object_footprint_cells(obj, origin_cell)

	for cell in cells:
		if block_layer.get_cell_source_id(cell) != -1:
			return false

		if obj_layer_block.get_cell_source_id(cell) != -1:
			return false

	return true


func mark_occupied_cells_for_obj(obj: PlaceableObject, origin_cell: Vector2i):
	var cells: Array[Vector2i] = get_object_footprint_cells(obj, origin_cell)

	for cell in cells:
		obj_layer_block.set_cell(
			cell,
			occupied_source_id,
			preview_atlas_coords
		)


func clear_preview():
	preview_layer.clear()


func draw_preview_for_obj(obj: PlaceableObject, origin_cell: Vector2i, source_id: int):
	clear_preview()
	draw_footprint_cells_for_obj(obj, origin_cell, source_id)


func draw_drag_preview_for_obj(obj: PlaceableObject, origin_cell: Vector2i, source_id: int):
	clear_preview()
	draw_occupied_preview_except(obj)
	draw_footprint_cells_for_obj(obj, origin_cell, source_id)


func draw_occupied_preview_except(except_obj: PlaceableObject):
	for child in objects.get_children():
		if child is PlaceableObject:
			var obj: PlaceableObject = child as PlaceableObject

			if obj == except_obj:
				continue

			if obj.blocks_cells:
				draw_footprint_cells_for_obj(obj, obj.current_cell, occupied_source_id)


func draw_footprint_cells_for_obj(obj: PlaceableObject, origin_cell: Vector2i, source_id: int):

	var cells: Array[Vector2i] = get_object_footprint_cells(obj, origin_cell)

	for cell in cells:
		preview_layer.set_cell(
			cell,
			source_id,
			preview_atlas_coords
		)


func rebuild_occupied_cells():
	obj_layer_block.clear()

	for child in objects.get_children():
		if child is PlaceableObject:
			var obj: PlaceableObject = child as PlaceableObject

			if obj.blocks_cells:
				mark_occupied_cells_for_obj(obj, obj.current_cell)


func rebuild_occupied_cells_except(except_obj: PlaceableObject):
	obj_layer_block.clear()

	for child in objects.get_children():
		if child is PlaceableObject:
			var obj: PlaceableObject = child as PlaceableObject

			if obj == except_obj:
				continue

			if obj.blocks_cells:
				mark_occupied_cells_for_obj(obj, obj.current_cell)


func update_edge_scroll(delta: float):
	if camera == null:
		return

	var mouse_pos: Vector2 = world.get_viewport().get_mouse_position()
	var viewport_size: Vector2 = world.get_viewport_rect().size

	var move_dir: Vector2 = Vector2.ZERO

	if mouse_pos.x <= edge_scroll_margin:
		move_dir.x -= 1.0

	if mouse_pos.x >= viewport_size.x - edge_scroll_margin:
		move_dir.x += 1.0

	if mouse_pos.y <= edge_scroll_margin:
		move_dir.y -= 1.0

	if mouse_pos.y >= viewport_size.y - edge_scroll_margin:
		move_dir.y += 1.0

	if move_dir != Vector2.ZERO:
		move_dir = move_dir.normalized()
		camera.position += move_dir * edge_scroll_speed * camera.zoom.x * delta

		if dragging_object != null:
			update_drag()
