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
@onready var main_ui: CanvasLayer = $"../MainUI"

var dragging_object: PlaceableObject = null
var selected_object: PlaceableObject = null
var pending_drag_object: PlaceableObject = null
var pending_drag_screen_pos: Vector2 = Vector2.ZERO
var pending_drag_start_msec: int = 0
var pending_drag_instance_id: int = 0

var action_overlay: Control = null
var current_action_type: String = "" # "plant" or "harvest"
var current_action_payload: String = ""
var is_action_dragging: bool = false
var action_drag_icon: Sprite2D = null
var shop_spawn_object: PlaceableObject = null
var shop_spawn_start_screen_pos: Vector2 = Vector2.ZERO
var shop_spawn_has_moved: bool = false
var shop_spawn_counter: int = 0
var drag_original_z_indexes: Dictionary = {}
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


	if action_overlay != null and not action_overlay.is_connected("item_drag_started", Callable(self, "_on_action_drag_started")):
		action_overlay.item_drag_started.connect(_on_action_drag_started)
		
	# Tạo sprite hiển thị khi kéo action
	action_drag_icon = Sprite2D.new()
	action_drag_icon.z_index = 200
	action_drag_icon.visible = false
	add_child(action_drag_icon)

func _process(delta):
	if pending_drag_object != null and dragging_object == null:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			cancel_pending_drag()
		else:
			try_promote_pending_drag()

	if dragging_object != null or is_action_dragging:
		update_edge_scroll(delta)


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_action_dragging:
				if not event.pressed:
					stop_action_drag()
				return
				
			if dragging_object != null:
				if not event.pressed:
					if dragging_object == shop_spawn_object and not shop_spawn_has_moved:
						return

					stop_drag()
				return

			if event.pressed:
				begin_drag_press(event.position)
			else:
				cancel_pending_drag()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if is_action_dragging:
				stop_action_drag()
			elif dragging_object == shop_spawn_object:
				cancel_shop_spawn()

	if event is InputEventMouseMotion:
		if is_action_dragging:
			update_action_drag(event.position)
			return
			
		if dragging_object == shop_spawn_object:
			shop_spawn_has_moved = shop_spawn_has_moved or shop_spawn_start_screen_pos.distance_to(event.position) >= drag_start_distance

		if pending_drag_object != null and dragging_object == null:
			try_promote_pending_drag(event.position)

		if dragging_object != null:
			update_drag()

	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE and dragging_object == shop_spawn_object:
			cancel_shop_spawn()


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
	if dragging_object != null or shop_spawn_object != null:
		return

	var obj: PlaceableObject = get_object_under_mouse()

	if obj == null:
		selected_object = null
		hide_animation_controls()
		cancel_pending_drag()
		if action_overlay:
			action_overlay.hide()
		return

	if not obj.can_drag():
		# Nếu là CropLand và không cho kéo (CropLand luôn không cho kéo do draggable = false)
		if obj.has_method("plant_seed"):
			if action_overlay:
				if obj.call("has_crop"):
					if obj.call("is_fully_grown"):
						action_overlay.call("show_for_harvest", obj)
				else:
					action_overlay.call("show_for_plant", obj)
		else:
			print("Object không cho kéo: ", obj.object_id)
		return

	selected_object = obj
	pending_drag_object = obj
	pending_drag_screen_pos = screen_pos
	pending_drag_start_msec = Time.get_ticks_msec()
	pending_drag_instance_id = obj.get_instance_id()
	current_cell = obj.current_cell
	if action_overlay:
		action_overlay.hide()


func cancel_pending_drag():
	pending_drag_object = null
	pending_drag_screen_pos = Vector2.ZERO
	pending_drag_start_msec = 0
	pending_drag_instance_id = 0


func try_promote_pending_drag(screen_pos: Vector2 = Vector2.INF, require_pressed: bool = true):
	if pending_drag_object == null:
		return

	if require_pressed and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		cancel_pending_drag()
		return

	if not is_instance_valid(pending_drag_object) or pending_drag_object.get_instance_id() != pending_drag_instance_id:
		cancel_pending_drag()
		return

	if not pending_drag_object.can_drag():
		cancel_pending_drag()
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
	if dragging_object != null:
		return

	dragging_object = obj
	current_cell = obj.current_cell

	print("=== START DRAG ===")
	print("Object: ", obj.object_id)
	print("Size in cells: ", obj.size_in_cells)
	print("Total cells: ", obj.get_total_occupied_cells())

	set_object_drag_visual(obj, true)
	show_animation_controls_for(obj)

	# Khi kéo object, bỏ vùng chiếm cũ của chính nó khỏi logic
	# để nó có thể kéo lại trên vị trí cũ mà không bị báo va chạm.
	rebuild_occupied_cells_except(obj)

	update_drag()


func stop_drag():
	if dragging_object == null:
		return

	var obj: PlaceableObject = dragging_object
	var is_shop_spawn := obj == shop_spawn_object

	if can_place_object_for_obj(obj, current_cell):
		if obj.has_method("set_crop_id"): # Duck-typing for SeedObject
			var target_crop_land = get_crop_land_at_cell(current_cell)
			if target_crop_land != null:
				target_crop_land.call("plant_seed", obj.get("crop_id"))
			
			obj.queue_free()
			dragging_object = null
			if is_shop_spawn:
				clear_shop_spawn_state()
			
			clear_preview()
			rebuild_occupied_cells()
			print("Gieo hạt thành công: ", obj.object_id, " tại ô: ", current_cell)
		else:
			move_object_to_cell(obj, current_cell)
			obj.set_cell(current_cell)

			set_object_drag_visual(obj, false)
			dragging_object = null
			if is_shop_spawn:
				clear_shop_spawn_state()

			clear_preview()
			rebuild_occupied_cells()
			show_animation_controls_for(obj)

			print("Đặt object thành công: ", obj.object_id, " tại ô: ", current_cell)
	else:
		if is_shop_spawn:
			remove_shop_spawn_object()
			dragging_object = null

			clear_preview()
			rebuild_occupied_cells()
			hide_animation_controls()

			print("Huỷ đặt object mới do ô không hợp lệ: ", obj.object_id)
			return

		move_object_to_cell(obj, obj.current_cell)

		set_object_drag_visual(obj, false)
		dragging_object = null

		clear_preview()
		rebuild_occupied_cells()
		show_animation_controls_for(obj)

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


func start_build_from_shop_item(item: Dictionary) -> PlaceableObject:
	if dragging_object != null:
		return null

	cancel_pending_drag()

	var scene_path: String = item.get("scene", "")
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_warning("Không có scene xây dựng hợp lệ cho item: %s" % item.get("name", "unknown"))
		return null

	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		push_warning("Không load được scene xây dựng: %s" % scene_path)
		return null

	if item.has("animal_pen_type"):
		return place_animal_from_shop_item(item, packed_scene)

	shop_spawn_counter += 1

	var instance := packed_scene.instantiate()
	if not instance is PlaceableObject:
		push_warning("Scene xây dựng phải có root PlaceableObject: %s" % scene_path)
		instance.queue_free()
		return null

	var obj := instance as PlaceableObject
	var base_id: String = item.get("id", obj.object_id)
	obj.name = _make_unique_object_name(base_id)
	obj.object_id = "%s_%03d" % [base_id, shop_spawn_counter]
	obj.display_name = item.get("name", obj.display_name)

	if obj.has_method("set_crop_id") and item.has("crop_id"):
		obj.call("set_crop_id", item.get("crop_id"))

	objects.add_child(obj)

	var spawn_cell := get_mouse_cell()
	obj.set_cell(spawn_cell)
	move_object_to_cell(obj, spawn_cell)

	shop_spawn_object = obj
	shop_spawn_start_screen_pos = world.get_viewport().get_mouse_position()
	shop_spawn_has_moved = false

	start_drag(obj)
	return obj


func place_animal_from_shop_item(item: Dictionary, packed_scene: PackedScene) -> PlaceableObject:
	var pen_type: String = item.get("animal_pen_type", "")
	var pen := find_available_animal_pen(pen_type)
	if pen == null:
		push_warning("Chưa có chuồng phù hợp cho animal: %s / %s" % [item.get("name", "unknown"), pen_type])
		return null

	shop_spawn_counter += 1
	var instance := packed_scene.instantiate()
	if not instance is PlaceableObject:
		push_warning("Scene animal phải có root PlaceableObject: %s" % item.get("scene", "unknown"))
		instance.queue_free()
		return null

	var obj := instance as PlaceableObject
	var base_id: String = item.get("id", obj.object_id)
	obj.name = _make_unique_object_name(base_id)
	obj.object_id = "%s_%03d" % [base_id, shop_spawn_counter]
	obj.display_name = item.get("name", obj.display_name)

	objects.add_child(obj)
	pen.add_animal(obj)
	hide_animation_controls()
	return obj


func find_available_animal_pen(pen_type: String) -> AnimalPenObject:
	for child in objects.get_children():
		if child is AnimalPenObject:
			var pen := child as AnimalPenObject
			if pen.accepts_animal_type(pen_type):
				return pen

	return null


func cancel_shop_spawn():
	if dragging_object != shop_spawn_object:
		return

	remove_shop_spawn_object()
	dragging_object = null
	clear_preview()
	rebuild_occupied_cells()
	hide_animation_controls()


func remove_shop_spawn_object():
	var obj := shop_spawn_object
	clear_shop_spawn_state()

	if obj != null and is_instance_valid(obj):
		obj.queue_free()


func clear_shop_spawn_state():
	shop_spawn_object = null
	shop_spawn_start_screen_pos = Vector2.ZERO
	shop_spawn_has_moved = false


func _make_unique_object_name(base_name: String) -> String:
	var clean_name := _sanitize_object_name(base_name)
	if clean_name.is_empty():
		clean_name = "shop_object"

	var candidate := clean_name
	var suffix := 1
	while objects.has_node(candidate):
		suffix += 1
		candidate = "%s_%d" % [clean_name, suffix]

	return candidate


func _sanitize_object_name(value: String) -> String:
	var clean := value.strip_edges().to_lower()
	clean = clean.replace(" ", "_")
	clean = clean.replace("-", "_")
	clean = clean.replace(".", "_")
	clean = clean.replace("/", "_")
	return clean


func set_object_drag_visual(obj: PlaceableObject, is_dragging: bool):
	if is_dragging:
		if not drag_original_z_indexes.has(obj):
			drag_original_z_indexes[obj] = obj.z_index
		obj.z_index = preview_layer.z_index + 10
		obj.modulate = Color(1, 1, 1, 0.86)
	else:
		obj.modulate = Color(1, 1, 1, 1.0)
		if drag_original_z_indexes.has(obj):
			obj.z_index = drag_original_z_indexes[obj]
			drag_original_z_indexes.erase(obj)


func show_animation_controls_for(obj: PlaceableObject) -> void:
	if main_ui != null and main_ui.has_method("show_animation_controls"):
		main_ui.call("show_animation_controls", obj)


func hide_animation_controls() -> void:
	if main_ui != null and main_ui.has_method("hide_animation_controls"):
		main_ui.call("hide_animation_controls")


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
			if object_contains_world_point(obj, mouse_global):
				return obj

	return null


func object_contains_world_point(node: Node, world_point: Vector2) -> bool:
	if node is Sprite2D:
		var sprite := node as Sprite2D
		if sprite.visible:
			var mouse_local: Vector2 = sprite.to_local(world_point)
			if sprite.get_rect().has_point(mouse_local):
				return true

	for child in node.get_children():
		if object_contains_world_point(child, world_point):
			return true

	return false


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


func get_crop_land_at_cell(cell: Vector2i) -> PlaceableObject:
	for child in objects.get_children():
		if child is PlaceableObject and child.has_method("plant_seed"):
			var crop_land = child as PlaceableObject
			var cells = get_object_footprint_cells(crop_land, crop_land.current_cell)
			if cell in cells:
				return crop_land
	return null


func can_place_object_for_obj(obj: PlaceableObject, origin_cell: Vector2i) -> bool:
	if obj.has_method("set_crop_id"):
		var target = get_crop_land_at_cell(origin_cell)
		if target != null and not target.call("has_crop"):
			return true
		return false

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
			
func _on_action_drag_started(action_type: String, item_id: String):
	is_action_dragging = true
	current_action_type = action_type
	current_action_payload = item_id
	action_drag_icon.visible = true
	if action_type == "harvest":
		action_drag_icon.texture = load("res://Arts/UI/item thu hoach/liem.png")
	else:
		var main_ui = get_tree().get_first_node_in_group("main_ui")
		if main_ui:
			var seeds = main_ui.SHOP_ITEMS.get("farms", [])
			for seed_data in seeds:
				if seed_data.get("crop_id") == item_id:
					action_drag_icon.texture = load(seed_data["icon"])
					break
	
	update_action_drag(get_viewport().get_mouse_position())

func update_action_drag(screen_pos: Vector2):
	if not is_action_dragging: return
	
	var world_pos = camera.get_global_transform_with_canvas().affine_inverse() * screen_pos
	action_drag_icon.global_position = world_pos
	
	var cell = get_cell_from_world_position(world_pos)
	var target = get_crop_land_at_cell(cell)
	
	if target != null and target.has_method("plant_seed"):
		if current_action_type == "plant":
			if not target.call("has_crop") and GameData.get_seed_count(current_action_payload) > 0:
				GameData.consume_seed(current_action_payload)
				target.call("plant_seed", current_action_payload)
		elif current_action_type == "harvest":
			if target.call("is_fully_grown"):
				var harvested_id = target.call("harvest")
				if harvested_id != "":
					GameData.add_seeds(harvested_id, 3)

func stop_action_drag():
	is_action_dragging = false
	current_action_type = ""
	current_action_payload = ""
	if action_drag_icon:
		action_drag_icon.visible = false
