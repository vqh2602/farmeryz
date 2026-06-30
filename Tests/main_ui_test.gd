extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	await process_frame
	await _run_tests()
	if failures.is_empty():
		print("main_ui_test: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _run_tests() -> void:
	_assert_base_scene_has_main_ui()
	var ui := await _create_ui()
	_assert_hud_nodes(ui)
	_assert_store_unlocked_for_test(ui)
	_assert_shop_items_have_valid_object_scenes(ui)
	_assert_shop_opens_and_closes(ui)
	_assert_shop_categories_render(ui)
	await _assert_shop_item_starts_build_drag()
	await _save_reference_shots(ui)


func _assert_base_scene_has_main_ui() -> void:
	var scene := load("res://Sence/base.tscn") as PackedScene
	_assert(scene != null, "Không load được Sence/base.tscn")
	var world := scene.instantiate()
	_assert(world.get_node_or_null("MainUI") != null, "base.tscn chưa gắn node MainUI")
	world.queue_free()


func _create_ui() -> CanvasLayer:
	var ui_script := load("res://Scripts/main_ui.gd")
	var ui := CanvasLayer.new()
	ui.name = "MainUIUnderTest"
	ui.set_script(ui_script)
	root.add_child(ui)
	await process_frame
	return ui


func _assert_hud_nodes(ui: CanvasLayer) -> void:
	_assert(ui.get_node_or_null("Hud") != null, "HUD không được tạo")
	_assert(ui.get_node_or_null("Hud/ShopButton") != null, "Thiếu nút Shop trên HUD")
	_assert(ui.get_node_or_null("Hud/LeftNav/HomeButton") != null, "Thiếu nút Home trên HUD")
	_assert(ui.get_node_or_null("Hud/LeftNav/SettingsButton") != null, "Thiếu nút Settings trên HUD")
	_assert(ui.get_node_or_null("Hud/Currency") != null, "Thiếu cụm tiền/kim cương trên HUD")
	_assert(ui.get_node_or_null("Hud/AnimationControls") != null, "Thiếu cụm nút Idle/Active trên HUD")


func _assert_store_unlocked_for_test(ui: CanvasLayer) -> void:
	for category_id in ui.SHOP_ITEMS.keys():
		for item in ui.SHOP_ITEMS[category_id]:
			_assert(not ui._is_item_locked(item), "Store test phải mở khóa item: %s" % item.get("name", "unknown"))


func _assert_shop_items_have_valid_object_scenes(ui: CanvasLayer) -> void:
	for category_id in ui.SHOP_ITEMS.keys():
		for item in ui.SHOP_ITEMS[category_id]:
			if not item.has("scene"):
				continue

			var scene_path: String = item.get("scene", "")
			_assert(not scene_path.is_empty(), "Item %s phải trỏ tới scene riêng" % item.get("name", "unknown"))
			_assert(ResourceLoader.exists(scene_path), "Scene object không tồn tại: %s" % scene_path)

			var packed_scene := load(scene_path) as PackedScene
			_assert(packed_scene != null, "Không load được scene object: %s" % scene_path)
			if packed_scene == null:
				continue

			var instance := packed_scene.instantiate()
			_assert(instance is PlaceableObject, "Root scene phải là PlaceableObject: %s" % scene_path)
			if _is_factory_object_scene(scene_path):
				var visual := instance.get_node_or_null("Visual")
				_assert(visual != null, "Factory scene phải có Visual composite: %s" % scene_path)
			instance.queue_free()


func _is_factory_object_scene(scene_path: String) -> bool:
	for folder_name in ["Bakery", "FoodProcessor", "Dairy", "SugarProcessor", "CornOven", "PieBakery", "Roaster", "SushiShop", "Accessories"]:
		if scene_path.contains("/%s/" % folder_name):
			return true
	return false


func _assert_shop_opens_and_closes(ui: CanvasLayer) -> void:
	_assert(not ui.is_shop_open(), "Shop không được mở sẵn khi vào game")
	ui.show_shop()
	_assert(ui.is_shop_open(), "show_shop() không mở màn cửa hàng")
	_assert(not ui.get_node("Hud").visible, "HUD phải ẩn khi shop mở")
	var grid := ui.get_node_or_null("ShopScreen/ItemArea/ItemScroll/ItemGrid") as GridContainer
	_assert(grid != null, "Thiếu grid item trong shop")
	_assert(grid.get_child_count() >= 4, "Shop không render đủ item ban đầu")
	ui.hide_shop()
	_assert(not ui.is_shop_open(), "hide_shop() không đóng shop")
	_assert(ui.get_node("Hud").visible, "HUD phải hiện lại khi đóng shop")


func _assert_shop_categories_render(ui: CanvasLayer) -> void:
	var grid := ui.get_node("ShopScreen/ItemArea/ItemScroll/ItemGrid") as GridContainer
	for category_id in ["factory", "plants", "animals", "farms", "decor"]:
		ui._select_category(category_id)
		await process_frame
		_assert(grid.get_child_count() > 0, "Danh mục %s không render item" % category_id)
		_assert(grid.columns >= 2 and grid.columns <= 4, "Grid columns của %s ngoài khoảng responsive" % category_id)


func _assert_shop_item_starts_build_drag() -> void:
	var scene: Node = load("res://Sence/base.tscn").instantiate()
	root.add_child(scene)
	await process_frame

	var ui: CanvasLayer = scene.get_node("MainUI") as CanvasLayer
	var manager: PlacementManager = scene.get_node("PlacementManager")
	var item := {
		"id": "ui_test_bakery",
		"name": "UI Test Bakery",
		"icon": "res://Arts/UI/shop/icon_nhamay-assets/Bakery.png",
		"scene": "res://Sence/Objects/Bakery/Bakery.tscn",
	}

	ui.show_shop()
	ui._start_build_from_item(item)
	await process_frame

	_assert(not ui.is_shop_open(), "Chọn item build phải đóng shop")
	_assert(manager.dragging_object != null, "Chọn item build phải bắt đầu kéo object mới")
	_assert(manager.shop_spawn_object == manager.dragging_object, "Object đang kéo phải là spawn từ shop")
	_assert(ui.get_node("Hud/AnimationControls").visible, "Kéo factory từ shop phải hiện nút Idle/Active")

	manager.cancel_shop_spawn()
	await process_frame
	scene.queue_free()


func _save_reference_shots(ui: CanvasLayer) -> void:
	if DisplayServer.get_name() == "headless":
		return

	root.size = Vector2i(1200, 650)
	ui.hide_shop()
	await process_frame
	root.get_texture().get_image().save_png("/tmp/farmery_ui_hud.png")

	ui._select_category("factory")
	ui.show_shop()
	await process_frame
	root.get_texture().get_image().save_png("/tmp/farmery_ui_shop.png")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
