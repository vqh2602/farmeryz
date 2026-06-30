extends SceneTree

const FACTORY_SCENES := [
	"res://Sence/Objects/Bakery/Bakery.tscn",
	"res://Sence/Objects/FoodProcessor/FoodProcessor.tscn",
	"res://Sence/Objects/Dairy/Dairy.tscn",
	"res://Sence/Objects/SugarProcessor/SugarProcessor.tscn",
	"res://Sence/Objects/CornOven/CornOven.tscn",
	"res://Sence/Objects/PieBakery/PieBakery.tscn",
	"res://Sence/Objects/Roaster/Roaster.tscn",
	"res://Sence/Objects/SushiShop/SushiShop.tscn",
	"res://Sence/Objects/Accessories/Accessories.tscn",
	"res://Sence/Objects/CakeBakery/CakeBakery.tscn",
	"res://Sence/Objects/CoffeeMachine/CoffeeMachine.tscn",
	"res://Sence/Objects/FlowerFactory/FlowerFactory.tscn",
	"res://Sence/Objects/Goldsmith/Goldsmith.tscn",
	"res://Sence/Objects/Hats/Hats.tscn",
	"res://Sence/Objects/KnittingTable/KnittingTable.tscn",
	"res://Sence/Objects/PaintFactory/PaintFactory.tscn",
	"res://Sence/Objects/PaperFactory/PaperFactory.tscn",
	"res://Sence/Objects/SewingTable/SewingTable.tscn",
	"res://Sence/Objects/Smelter/Smelter.tscn",
	"res://Sence/Objects/Blender/Blender.tscn",
	"res://Sence/Objects/CandyFactory/CandyFactory.tscn",
	"res://Sence/Objects/CreamFreezer/CreamFreezer.tscn",
	"res://Sence/Objects/JamFactory/JamFactory.tscn",
	"res://Sence/Objects/Juicer/Juicer.tscn",
	"res://Sence/Objects/MexicanFood/MexicanFood.tscn",
	"res://Sence/Objects/PizzaOven/PizzaOven.tscn",
	"res://Sence/Objects/Wok/Wok.tscn",
]

var failures: Array[String] = []


func _init() -> void:
	await process_frame
	await _run_tests()
	if failures.is_empty():
		print("factory_scene_test: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _run_tests() -> void:
	for scene_path in FACTORY_SCENES:
		_assert_factory_scene(scene_path)
	await _assert_factory_animation_runs_while_dragging_and_after_place()
	await _save_reference_sheet()
	await _save_drag_animation_frames()


func _assert_factory_scene(scene_path: String) -> void:
	var packed_scene := load(scene_path) as PackedScene
	_assert(packed_scene != null, "Không load được factory scene: %s" % scene_path)
	if packed_scene == null:
		return

	var instance := packed_scene.instantiate()
	_assert(instance is PlaceableObject, "Root factory scene phải là PlaceableObject: %s" % scene_path)

	var visual := instance.get_node_or_null("Visual")
	_assert(visual != null, "Factory scene thiếu Visual: %s" % scene_path)
	if visual != null:
		_assert(visual.has_method("play"), "Visual factory phải dùng UnityFactoryAnimPlayer: %s" % scene_path)
		_assert(visual.get("default_mode") == "active", "Factory phải chạy active mặc định để thấy animation khi kéo: %s" % scene_path)
		_assert(_count_sprite_nodes(visual) >= 2, "Factory scene cần tách ít nhất 2 Sprite2D layer: %s" % scene_path)
		_assert_factory_anim_data(scene_path, visual)

	instance.queue_free()


func _assert_factory_anim_data(scene_path: String, visual: Node) -> void:
	var data_path := str(visual.get("animation_data_path"))
	_assert(not data_path.is_empty(), "Factory thiếu animation_data_path: %s" % scene_path)
	_assert(FileAccess.file_exists(data_path), "Factory animation JSON không tồn tại: %s" % data_path)
	if not FileAccess.file_exists(data_path):
		return

	var file := FileAccess.open(data_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	_assert(typeof(data) == TYPE_DICTIONARY, "Factory animation JSON lỗi parse: %s" % data_path)
	if typeof(data) != TYPE_DICTIONARY:
		return

	_assert(data.get("missing_source_paths", []).is_empty(), "Factory còn thiếu path clone từ .anim: %s" % data_path)
	var missing_anim_files: Array = data.get("missing_anim_files", [])
	if scene_path.contains("Dairy"):
		_assert(missing_anim_files.size() == 1 and missing_anim_files[0] == "idle.anim", "Dairy chỉ được thiếu idle.anim do source không có file: %s" % data_path)
	else:
		_assert(missing_anim_files.is_empty(), "Factory thiếu file .anim nguồn: %s" % data_path)

	var active_counts: Dictionary = data.get("source_counts", {}).get("active", {})
	var active_total := int(active_counts.get("position", 0)) + int(active_counts.get("scale", 0)) + int(active_counts.get("visible", 0))
	_assert(active_total > 0, "Factory active.anim không được clone curve nào: %s" % data_path)
	_assert(_count_descendants(visual) >= int(data.get("node_count", 0)), "Scene thiếu node so với JSON clone: %s" % scene_path)

	if scene_path.contains("SugarProcessor"):
		_assert(visual.get_node_or_null("may/frame_1_1") != null, "SugarProcessor thiếu frame may/1.1")
		_assert(visual.get_node_or_null("chau/frame_1") != null, "SugarProcessor thiếu frame chau/1")


func _assert_factory_animation_runs_while_dragging_and_after_place() -> void:
	var scene: Node = load("res://Sence/base.tscn").instantiate()
	root.add_child(scene)
	await process_frame

	var manager: PlacementManager = scene.get_node("PlacementManager")
	manager.edge_scroll_margin = -1.0
	var item := {
		"id": "anim_test_bakery",
		"name": "Anim Test Bakery",
		"scene": "res://Sence/Objects/Bakery/Bakery.tscn",
	}

	var obj := manager.start_build_from_shop_item(item)
	_assert(obj != null, "Không spawn được factory để test animation khi kéo")
	if obj == null:
		scene.queue_free()
		return

	_assert(obj.z_index > manager.preview_layer.z_index, "Factory đang kéo phải render trên PreviewLayer để không bị footprint che animation")
	_assert(obj.get_factory_animation_mode() == "active", "Factory kéo từ shop phải chạy active mặc định")

	var ui := scene.get_node("MainUI") as CanvasLayer
	var controls := ui.get_node_or_null("Hud/AnimationControls") as Control
	_assert(controls != null and controls.visible, "Kéo factory phải hiện nút Idle/Active")
	if controls != null:
		var idle_button := controls.get_node_or_null("ModeButtons/IdleButton") as Button
		var active_button := controls.get_node_or_null("ModeButtons/ActiveButton") as Button
		_assert(idle_button != null, "Thiếu nút Idle")
		_assert(active_button != null, "Thiếu nút Active")
		if idle_button != null and active_button != null:
			idle_button.pressed.emit()
			await process_frame
			_assert(obj.get_factory_animation_mode() == "idle", "Bấm Idle không chuyển animation mode")
			active_button.pressed.emit()
			await process_frame
			_assert(obj.get_factory_animation_mode() == "active", "Bấm Active không chuyển animation mode")

	var animated_node := obj.get_node_or_null("Visual/bao_nguyenlieu_2") as Node2D
	_assert(animated_node != null, "Factory spawn thiếu node animation khi kéo")
	if animated_node == null:
		scene.queue_free()
		return

	var drag_start_pos := animated_node.position
	await create_timer(0.35).timeout
	var drag_end_pos := animated_node.position
	_assert(drag_start_pos.distance_to(drag_end_pos) > 0.5, "Factory animation không chạy khi đang kéo trên map")

	manager.current_cell = Vector2i(16, 12)
	manager.move_object_to_cell(obj, manager.current_cell)
	manager.stop_drag()
	await process_frame
	_assert(obj.z_index <= manager.preview_layer.z_index, "Factory sau khi đặt phải restore z_index bình thường")
	_assert(controls != null and controls.visible, "Đặt factory xong vẫn phải hiện nút Idle/Active cho object đang chọn")

	var placed_start_pos := animated_node.position
	await create_timer(0.35).timeout
	var placed_end_pos := animated_node.position
	_assert(placed_start_pos.distance_to(placed_end_pos) > 0.5, "Factory animation dừng sau khi đặt xuống map")

	scene.queue_free()


func _save_reference_sheet() -> void:
	if DisplayServer.get_name() == "headless":
		return

	root.size = Vector2i(1800, 1560)
	var stage := Node2D.new()
	root.add_child(stage)

	for index in range(FACTORY_SCENES.size()):
		var packed_scene := load(FACTORY_SCENES[index]) as PackedScene
		var instance := packed_scene.instantiate() as Node2D
		instance.position = Vector2(170 + (index % 5) * 340, 220 + int(index / 5) * 245)
		stage.add_child(instance)

	await create_timer(0.4).timeout
	root.get_texture().get_image().save_png("/tmp/farmery_factory_scenes.png")
	stage.queue_free()


func _save_drag_animation_frames() -> void:
	if DisplayServer.get_name() == "headless":
		return

	root.size = Vector2i(1200, 760)
	var scene: Node = load("res://Sence/base.tscn").instantiate()
	root.add_child(scene)
	await process_frame

	var manager: PlacementManager = scene.get_node("PlacementManager")
	manager.edge_scroll_margin = -1.0
	var obj := manager.start_build_from_shop_item({
		"id": "render_anim_bakery",
		"name": "Render Anim Bakery",
		"scene": "res://Sence/Objects/Bakery/Bakery.tscn",
	})
	if obj != null:
		var main_house := scene.get_node("Objects/MainHouse") as Node2D
		manager.current_cell = Vector2i(8, 16)
		obj.global_position = main_house.global_position + Vector2(-320, 120)
		manager.draw_drag_preview_for_obj(obj, manager.current_cell, manager.valid_preview_source_id)
		manager.dragging_object = null

	await create_timer(0.1).timeout
	root.get_texture().get_image().save_png("/tmp/farmery_factory_drag_anim_a.png")
	await create_timer(0.45).timeout
	root.get_texture().get_image().save_png("/tmp/farmery_factory_drag_anim_b.png")
	scene.queue_free()


func _count_sprite_nodes(parent: Node) -> int:
	var count := 0
	for child in parent.get_children():
		if child is Sprite2D:
			count += 1
		count += _count_sprite_nodes(child)
	return count


func _count_descendants(parent: Node) -> int:
	var count := 0
	for child in parent.get_children():
		count += 1
		count += _count_descendants(child)
	return count


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
