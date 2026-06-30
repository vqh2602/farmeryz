extends Node2D

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var placement_manager: PlacementManager = $PlacementManager
@onready var cell_debug_label: Label = $CanvasLayer/CellDebugLabel

var action_overlay: ActionOverlay
var farm_action_manager: FarmActionManager

func _ready():
	# Enable Y-sorting on the Objects container
	var objects_node = get_node_or_null("Objects")
	if objects_node:
		objects_node.y_sort_enabled = true
		print("[World] Enabled Y-sorting on Objects node")
		
	# Instantiate FarmActionManager
	farm_action_manager = FarmActionManager.new()
	farm_action_manager.name = "FarmActionManager"
	add_child(farm_action_manager)
		
	# Instance the ActionOverlay
	var overlay_scene = load("res://Sence/UI/ActionOverlay.tscn")
	if overlay_scene:
		action_overlay = overlay_scene.instantiate()
		add_child(action_overlay)
		if farm_action_manager:
			farm_action_manager.action_overlay = action_overlay
			action_overlay.item_drag_started.connect(farm_action_manager._on_action_drag_started)
			
	if "--run-tests" in OS.get_cmdline_args():
		_run_integration_tests()

func _run_integration_tests():
	print("=== INTEGRATION TEST START ===")
	await get_tree().create_timer(0.5).timeout
	
	# Setup: add seeds
	GameData.add_seeds("wheat", 3)
	print("Seeds: ", GameData.get_seed_count("wheat"))
	
	# Spawn CropLand
	var objects_node = get_node("Objects")
	var cropland_scene = load("res://Sence/Objects/CropLand/CropLand.tscn")
	var cropland = cropland_scene.instantiate()
	objects_node.add_child(cropland)
	cropland.global_position = Vector2(200, 200)
	placement_manager.register_existing_objects()
	await get_tree().process_frame
	
	print("TEST 1: CropLand initial state")
	print("  has_crop = ", cropland.has_crop(), " (expected: false)")
	assert(not cropland.has_crop(), "Should not have crop initially")
	
	# Open overlay for plant
	action_overlay.show_for_plant(cropland)
	await get_tree().process_frame
	print("TEST 2: Overlay visible after show_for_plant")
	print("  visible = ", action_overlay.visible, " (expected: true)")
	assert(action_overlay.visible, "Overlay should be visible")
	
	# Find first seed button
	var seed_btn: TextureRect = null
	for child in action_overlay.item_container.get_children():
		if child is TextureRect:
			seed_btn = child
			break
	assert(seed_btn != null, "Should have a seed button")
	print("  Found seed button")
	
	# Simulate PRESS on seed icon (gui_input)
	var press_pos = seed_btn.global_position + Vector2(40, 40)
	var mouse_down = InputEventMouseButton.new()
	mouse_down.button_index = MOUSE_BUTTON_LEFT
	mouse_down.pressed = true
	mouse_down.global_position = press_pos
	mouse_down.position = press_pos
	seed_btn.gui_input.emit(mouse_down)
	
	print("TEST 3: After pressing seed icon, overlay should STILL be visible")
	print("  overlay.visible = ", action_overlay.visible, " (expected: true)")
	print("  overlay._is_pending = ", action_overlay._is_pending, " (expected: true)")
	print("  farm_action.is_action_dragging = ", farm_action_manager.is_action_dragging, " (expected: false)")
	assert(action_overlay.visible, "Overlay should NOT hide on press")
	assert(action_overlay._is_pending, "Should be in pending state")
	assert(not farm_action_manager.is_action_dragging, "Action drag should NOT start yet")
	
	# Simulate DRAG far enough (> 8px threshold)
	var drag_pos = press_pos + Vector2(50, 50)
	var motion = InputEventMouseMotion.new()
	motion.global_position = drag_pos
	motion.position = drag_pos
	action_overlay._input(motion)
	
	print("TEST 4: After dragging past threshold")
	print("  overlay.visible = ", action_overlay.visible, " (expected: false)")
	print("  overlay._is_pending = ", action_overlay._is_pending, " (expected: false)")
	print("  placement.is_action_dragging = ", farm_action_manager.is_action_dragging, " (expected: true)")
	assert(not action_overlay.visible, "Overlay should be hidden after drag")
	assert(not action_overlay._is_pending, "Should no longer be pending")
	assert(farm_action_manager.is_action_dragging, "Action drag should be active")
	
	# Simulate dragging to CropLand position
	var camera = placement_manager.camera
	var cropland_screen_pos = camera.get_global_transform_with_canvas() * cropland.global_position
	var crop_motion = InputEventMouseMotion.new()
	crop_motion.position = cropland_screen_pos
	crop_motion.global_position = cropland_screen_pos
	farm_action_manager._unhandled_input(crop_motion)
	
	print("TEST 5: After dragging to CropLand")
	print("  has_crop = ", cropland.has_crop(), " (expected: true)")
	assert(cropland.has_crop(), "Should have planted crop")
	
	# Simulate release
	var mouse_up = InputEventMouseButton.new()
	mouse_up.button_index = MOUSE_BUTTON_LEFT
	mouse_up.pressed = false
	farm_action_manager._unhandled_input(mouse_up)
	
	print("TEST 6: After release")
	print("  is_action_dragging = ", farm_action_manager.is_action_dragging, " (expected: false)")
	assert(not farm_action_manager.is_action_dragging, "Should stop action drag")
	
	print("=== ALL INTEGRATION TESTS PASSED ===")
	get_tree().quit(0)

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
