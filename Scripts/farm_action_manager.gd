extends Node
class_name FarmActionManager

@onready var world: Node2D = get_parent()
@onready var ground_layer: TileMapLayer = $"../GroundLayer"
@onready var objects: Node2D = $"../Objects"
@onready var camera: Camera2D = $"../Camera2D"

var action_overlay: ActionOverlay = null

var is_action_dragging: bool = false
var current_action_type: String = "" # "plant" or "harvest"
var current_action_payload: String = ""
var action_drag_icon: Sprite2D = null
var action_drag_start_screen_pos: Vector2 = Vector2.ZERO

func _ready():
	print("=== FarmActionManager ready ===")
	
	# Create sprite for dragging action tools
	action_drag_icon = Sprite2D.new()
	action_drag_icon.z_index = 200
	action_drag_icon.visible = false
	action_drag_icon.scale = Vector2(0.5, 0.5)
	world.add_child(action_drag_icon)

func _unhandled_input(event):
	# 1. Handle clicks on CropLand or PerennialTree to open ActionOverlay
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var world_pos = get_viewport().get_canvas_transform().affine_inverse() * event.position
		var cell = get_cell_from_world_position(world_pos)
		
		# Check CropLand first
		var cropland = get_crop_land_at_cell(cell)
		if cropland:
			print("[FAM] Clicked CropLand at cell: ", cell)
			if action_overlay:
				if cropland.call("has_crop"):
					if cropland.call("is_fully_grown"):
						action_overlay.show_for_harvest(cropland)
				else:
					action_overlay.show_for_plant(cropland)
			get_viewport().set_input_as_handled()
			return
			
		# Check PerennialTree next
		var tree = get_perennial_tree_at_cell(cell)
		if tree:
			print("[FAM] Clicked PerennialTree at cell: ", cell)
			if not tree.get("is_dead"):
				if tree.call("is_fully_grown"):
					if action_overlay:
						action_overlay.show_for_harvest(tree)
			get_viewport().set_input_as_handled()
			return

	# 2. Handle Action dragging stop
	if event is InputEventScreenTouch:
		if not event.pressed and is_action_dragging:
			print("[FAM] _unhandled_input: stop_action_drag (touch release)")
			stop_action_drag()
			get_viewport().set_input_as_handled()
			return
			
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_action_dragging and not event.pressed:
				print("[FAM] _unhandled_input: stop_action_drag (mouse release)")
				stop_action_drag()
				get_viewport().set_input_as_handled()
				return

	# 3. Handle Action dragging motion
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		if is_action_dragging:
			var dist = event.position.distance_to(action_drag_start_screen_pos)
			if dist > 10.0:
				update_action_drag(event.position)
			else:
				var world_pos = get_viewport().get_canvas_transform().affine_inverse() * event.position
				action_drag_icon.global_position = world_pos
			get_viewport().set_input_as_handled()
			return

func get_cell_from_world_position(world_position: Vector2) -> Vector2i:
	var local_pos: Vector2 = ground_layer.to_local(world_position)
	return ground_layer.local_to_map(local_pos)

func get_crop_land_at_cell(cell: Vector2i) -> PlaceableObject:
	for child in objects.get_children():
		if child is PlaceableObject and child.has_method("plant_seed"):
			if child.current_cell == cell:
				return child
	return null

func get_perennial_tree_at_cell(cell: Vector2i) -> PlaceableObject:
	for child in objects.get_children():
		if child is PlaceableObject and child.has_method("is_perennial_tree"):
			if child.current_cell == cell:
				return child
	return null

func _on_action_drag_started(action_type: String, item_id: String):
	print("[FAM] _on_action_drag_started: type=", action_type, " id=", item_id)
	is_action_dragging = true
	current_action_type = action_type
	current_action_payload = item_id
	action_drag_icon.visible = true
	
	if action_type == "harvest":
		var icon_path = "res://Arts/UI/item thu hoach/liem.png"
		if action_overlay and is_instance_valid(action_overlay.current_target):
			if action_overlay.current_target.has_method("get_harvest_icon"):
				icon_path = action_overlay.current_target.call("get_harvest_icon")
		action_drag_icon.texture = load(icon_path)
	else:
		var main_ui = get_tree().get_first_node_in_group("main_ui")
		if main_ui:
			var seeds = main_ui.SHOP_ITEMS.get("farms", [])
			for seed_data in seeds:
				if seed_data.get("crop_id") == item_id:
					action_drag_icon.texture = load(seed_data["icon"])
					break
	
	action_drag_start_screen_pos = get_viewport().get_mouse_position()
	var world_pos = get_viewport().get_canvas_transform().affine_inverse() * action_drag_start_screen_pos
	action_drag_icon.global_position = world_pos

func update_action_drag(screen_pos: Vector2):
	if not is_action_dragging: return
	
	var world_pos = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	action_drag_icon.global_position = world_pos
	
	var cell = get_cell_from_world_position(world_pos)
	
	# Check cropland and tree targets
	var target = get_crop_land_at_cell(cell)
	var is_tree = false
	if target == null:
		target = get_perennial_tree_at_cell(cell)
		is_tree = target != null
		
	print("[FAM] update_action_drag: screen=", screen_pos, " cell=", cell, " target=", target, " is_tree=", is_tree)
	
	if target != null:
		if current_action_type == "plant" and target.has_method("plant_seed"):
			if not target.call("has_crop") and GameData.get_seed_count(current_action_payload) > 0:
				GameData.consume_seed(current_action_payload)
				target.call("plant_seed", current_action_payload)
		elif current_action_type == "harvest":
			if target.call("is_fully_grown"):
				if is_tree:
					var harvested_id = target.call("harvest")
					if harvested_id != "":
						GameData.add_seeds(harvested_id, 3)
						_spawn_harvest_effect_for_tree(target.global_position, harvested_id)
				else:
					var crop_data = target.get("crop_data")
					var harvested_id = target.call("harvest")
					if harvested_id != "":
						GameData.add_seeds(harvested_id, 3)
						_spawn_harvest_effect(target.global_position, crop_data)

func _spawn_harvest_effect(pos: Vector2, crop_data: CropData):
	if crop_data == null: return
	
	var tex = crop_data.seed_icon
	if tex == null and crop_data.stage_textures.size() > 0:
		tex = crop_data.stage_textures[-1]
		
	if tex == null: return
	
	var effect_script = load("res://Scripts/harvest_effect.gd")
	var effect = Node2D.new()
	effect.set_script(effect_script)
	
	var target_screen_pos = Vector2(80, 80)
	world.add_child(effect)
	effect.global_position = pos
	effect.call("setup", tex, target_screen_pos)

func _spawn_harvest_effect_for_tree(pos: Vector2, tree_type: String):
	# Tải hình ảnh quả tương ứng từ thư mục hạt cây trồng lâu năm
	var path = "res://Arts/caylaunam/hatcaytrong/%s.png" % tree_type
	if not ResourceLoader.exists(path):
		# Fallback nếu không có
		path = "res://Arts/caytrong-assets/hat_giong/%s.png" % tree_type
		
	if not ResourceLoader.exists(path): return
	var tex = load(path)
	
	var effect_script = load("res://Scripts/harvest_effect.gd")
	var effect = Node2D.new()
	effect.set_script(effect_script)
	
	var target_screen_pos = Vector2(80, 80)
	world.add_child(effect)
	effect.global_position = pos
	effect.call("setup", tex, target_screen_pos)

func stop_action_drag():
	print("[FAM] stop_action_drag: was type=", current_action_type, " id=", current_action_payload)
	is_action_dragging = false
	current_action_type = ""
	current_action_payload = ""
	if action_drag_icon:
		action_drag_icon.visible = false
