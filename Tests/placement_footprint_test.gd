extends SceneTree

var failures: Array[String] = []


func _initialize():
	test_default_bottom_center_offsets()
	test_custom_footprint_is_preserved()
	test_base_scene_main_house_preview()
	test_drag_requires_hold_and_motion()
	test_drag_lock_rejects_stale_or_mismatched_pending()
	test_shop_spawn_clears_pending_drag_lock()
	test_shop_spawn_placeable_object()
	test_shop_spawn_invalid_cell_removes_new_object()

	if failures.is_empty():
		print("placement_footprint_test: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func test_default_bottom_center_offsets():
	assert_offsets(Vector2i(1, 1), [
		Vector2i(0, 0),
	], "1x1 footprint stays on the pivot cell")

	assert_offsets(Vector2i(2, 2), [
		Vector2i(-1, -1),
		Vector2i(0, -1),
		Vector2i(-1, 0),
		Vector2i(0, 0),
	], "2x2 footprint is a filled square block")

	assert_offsets(Vector2i(3, 2), [
		Vector2i(-1, -1),
		Vector2i(0, -1),
		Vector2i(1, -1),
		Vector2i(-1, 0),
		Vector2i(0, 0),
		Vector2i(1, 0),
	], "3x2 footprint is a filled rectangular block")


func test_custom_footprint_is_preserved():
	var obj := PlaceableObject.new()
	obj.use_custom_footprint = true
	obj.custom_footprint = [
		Vector2i(0, 0),
		Vector2i(2, 0),
	]

	assert_vector2i_arrays_equal(obj.get_footprint_offsets(), obj.custom_footprint, "custom footprints are not re-anchored")
	obj.free()


func test_base_scene_main_house_preview():
	var scene: Node = load("res://Sence/base.tscn").instantiate()
	root.add_child(scene)
	await process_frame

	var manager: PlacementManager = scene.get_node("PlacementManager")
	var obj: PlaceableObject = scene.get_node("Objects/MainHouse")
	var objects: Node2D = scene.get_node("Objects")
	var area_layer: TileMapLayer = obj.get_node("Area")
	var preview_layer: TileMapLayer = scene.get_node("PreviewLayer")
	var origin := obj.current_cell

	assert_bool(not area_layer.visible, "object Area layer is config-only and hidden at runtime")
	assert_equal(preview_layer.tile_set, manager.ground_layer.tile_set, "preview layer uses the same TileSet as the isometric ground")
	assert_bool(preview_layer.z_index > objects.z_index, "preview layer renders above objects so footprint stays visible")
	assert_equal(manager.valid_preview_source_id, 12, "valid preview uses the blue tile")
	assert_equal(manager.invalid_preview_source_id, 13, "invalid preview uses the red tile")
	assert_equal(manager.occupied_source_id, 14, "occupied preview uses the yellow tile")

	var expected_offsets := area_layer.get_used_cells()
	expected_offsets.sort()
	assert_vector2i_arrays_equal(obj.get_footprint_offsets(), expected_offsets, "main house footprint comes from its Area layer")
	assert_equal(obj.get_total_occupied_cells(), 25, "main house Area footprint has 25 cells")

	manager.draw_preview_for_obj(obj, origin, manager.valid_preview_source_id)
	for cell in manager.get_object_footprint_cells(obj, origin):
		assert_equal(preview_layer.get_cell_source_id(cell), manager.valid_preview_source_id, "preview paints every footprint cell blue")

	var odd_y_cells := manager.get_object_footprint_cells(obj, Vector2i(1, 11))
	var even_y_cells := manager.get_object_footprint_cells(obj, Vector2i(1, 12))
	assert_equal(odd_y_cells.size(), expected_offsets.size(), "Area footprint keeps all cells on odd y origins")
	assert_equal(even_y_cells.size(), expected_offsets.size(), "Area footprint keeps all cells on even y origins")
	assert_equal(get_row_widths(odd_y_cells), get_row_widths(even_y_cells), "Area footprint row structure is stable between odd/even y")

	var other := PlaceableObject.new()
	other.size_in_cells = Vector2i(1, 1)
	other.current_cell = origin + Vector2i(5, 5)
	objects.add_child(other)

	manager.draw_drag_preview_for_obj(obj, origin, manager.valid_preview_source_id)
	assert_equal(preview_layer.get_cell_source_id(other.current_cell), manager.occupied_source_id, "drag preview still shows other occupied cells")
	for cell in manager.get_object_footprint_cells(obj, origin):
		assert_equal(preview_layer.get_cell_source_id(cell), manager.valid_preview_source_id, "drag preview paints moving object over occupied context")

	scene.queue_free()


func test_drag_requires_hold_and_motion():
	var scene: Node = load("res://Sence/base.tscn").instantiate()
	root.add_child(scene)
	await process_frame

	var manager: PlacementManager = scene.get_node("PlacementManager")
	var obj: PlaceableObject = scene.get_node("Objects/MainHouse")
	obj.draggable = true
	var now := Time.get_ticks_msec()

	manager.pending_drag_object = obj
	manager.pending_drag_screen_pos = Vector2.ZERO
	manager.pending_drag_start_msec = now
	manager.pending_drag_instance_id = obj.get_instance_id()
	manager.try_promote_pending_drag(Vector2(manager.drag_start_distance + 20.0, 0.0), false)
	assert_equal(manager.dragging_object, null, "mouse down plus immediate motion does not start drag")

	manager.pending_drag_object = obj
	manager.pending_drag_screen_pos = Vector2.ZERO
	manager.pending_drag_start_msec = now - int((manager.drag_hold_seconds + 0.1) * 1000.0)
	manager.pending_drag_instance_id = obj.get_instance_id()
	manager.try_promote_pending_drag(Vector2(manager.drag_start_distance - 1.0, 0.0), false)
	assert_equal(manager.dragging_object, null, "hold without enough motion does not start drag")

	manager.pending_drag_object = obj
	manager.pending_drag_screen_pos = Vector2.ZERO
	manager.pending_drag_start_msec = now - int((manager.drag_hold_seconds + 0.1) * 1000.0)
	manager.pending_drag_instance_id = obj.get_instance_id()
	manager.try_promote_pending_drag(Vector2(manager.drag_start_distance + 20.0, 0.0), false)
	assert_equal(manager.dragging_object, obj, "hold plus drag starts moving the selected object")

	manager.dragging_object = null
	manager.cancel_pending_drag()
	manager.clear_preview()
	scene.queue_free()


func test_drag_lock_rejects_stale_or_mismatched_pending():
	var scene: Node = load("res://Sence/base.tscn").instantiate()
	root.add_child(scene)
	await process_frame

	var manager: PlacementManager = scene.get_node("PlacementManager")
	var obj: PlaceableObject = scene.get_node("Objects/MainHouse")
	obj.draggable = true
	var now := Time.get_ticks_msec() - int((manager.drag_hold_seconds + 0.1) * 1000.0)

	manager.pending_drag_object = obj
	manager.pending_drag_screen_pos = Vector2.ZERO
	manager.pending_drag_start_msec = now
	manager.pending_drag_instance_id = obj.get_instance_id() + 1
	manager.try_promote_pending_drag(Vector2(manager.drag_start_distance + 20.0, 0.0), false)
	assert_equal(manager.dragging_object, null, "mismatched drag lock never starts dragging another object")
	assert_equal(manager.pending_drag_object, null, "mismatched drag lock clears stale pending object")

	manager.pending_drag_object = obj
	manager.pending_drag_screen_pos = Vector2.ZERO
	manager.pending_drag_start_msec = now
	manager.pending_drag_instance_id = obj.get_instance_id()
	manager.try_promote_pending_drag(Vector2(manager.drag_start_distance + 20.0, 0.0))
	assert_equal(manager.dragging_object, null, "pending drag does not promote after the mouse button is no longer held")
	assert_equal(manager.pending_drag_object, null, "released mouse clears pending drag")

	scene.queue_free()


func test_shop_spawn_clears_pending_drag_lock():
	var scene: Node = load("res://Sence/base.tscn").instantiate()
	root.add_child(scene)
	await process_frame

	var manager: PlacementManager = scene.get_node("PlacementManager")
	var obj: PlaceableObject = scene.get_node("Objects/MainHouse")
	var item := {
		"id": "test_bakery",
		"name": "Test Bakery",
		"icon": "res://Arts/UI/shop/icon_nhamay-assets/Bakery.png",
		"scene": "res://Sence/Objects/Bakery/Bakery.tscn",
	}

	manager.pending_drag_object = obj
	manager.pending_drag_screen_pos = Vector2.ZERO
	manager.pending_drag_start_msec = Time.get_ticks_msec()
	manager.pending_drag_instance_id = obj.get_instance_id()

	var spawned := manager.start_build_from_shop_item(item)
	assert_bool(spawned != null, "shop spawn still creates an object while an old pending drag exists")
	assert_equal(manager.pending_drag_object, null, "shop spawn clears any old pending map drag")
	assert_equal(manager.dragging_object, spawned, "shop spawn locks drag to the new shop object")

	scene.queue_free()


func test_shop_spawn_placeable_object():
	var scene: Node = load("res://Sence/base.tscn").instantiate()
	root.add_child(scene)
	await process_frame

	var manager: PlacementManager = scene.get_node("PlacementManager")
	var objects: Node2D = scene.get_node("Objects")
	var item := {
		"id": "test_bakery",
		"name": "Test Bakery",
		"icon": "res://Arts/UI/shop/icon_nhamay-assets/Bakery.png",
		"scene": "res://Sence/Objects/Bakery/Bakery.tscn",
	}

	var before_count := objects.get_child_count()
	var obj := manager.start_build_from_shop_item(item)
	assert_bool(obj != null, "shop item creates a PlaceableObject")
	assert_equal(objects.get_child_count(), before_count + 1, "spawned shop object is added to Objects")
	assert_equal(manager.dragging_object, obj, "spawned shop object starts in drag mode")
	assert_equal(obj.size_in_cells, Vector2i(3, 2), "spawned shop object keeps configured footprint size")
	assert_bool(obj.get_node_or_null("Sprite2D") != null, "spawned shop object has a Sprite2D")
	assert_equal(obj.display_name, "Test Bakery", "spawned shop object can override display name from shop")

	var target_cell := Vector2i(12, 12)
	manager.current_cell = target_cell
	manager.move_object_to_cell(obj, target_cell)
	manager.stop_drag()
	await process_frame

	assert_equal(manager.dragging_object, null, "valid shop placement exits drag mode")
	assert_bool(objects.get_children().has(obj), "valid shop placement keeps the new object")
	assert_equal(obj.current_cell, target_cell, "valid shop placement stores the final cell")
	for cell in manager.get_object_footprint_cells(obj, target_cell):
		assert_equal(manager.obj_layer_block.get_cell_source_id(cell), manager.occupied_source_id, "valid shop placement marks occupied cells")

	scene.queue_free()


func test_shop_spawn_invalid_cell_removes_new_object():
	var scene: Node = load("res://Sence/base.tscn").instantiate()
	root.add_child(scene)
	await process_frame

	var manager: PlacementManager = scene.get_node("PlacementManager")
	var objects: Node2D = scene.get_node("Objects")
	var main_house: PlaceableObject = scene.get_node("Objects/MainHouse")
	var item := {
		"id": "test_land",
		"name": "Test Land",
		"icon": "res://Arts/UI/shop/icon_chuong-assets/land.png",
		"scene": "res://Sence/Objects/CropLand/CropLand.tscn",
	}

	var before_count := objects.get_child_count()
	var obj := manager.start_build_from_shop_item(item)
	assert_bool(obj != null, "invalid placement test creates a shop object")
	manager.current_cell = main_house.current_cell
	manager.move_object_to_cell(obj, main_house.current_cell)
	manager.stop_drag()
	await process_frame

	assert_equal(manager.dragging_object, null, "invalid shop placement exits drag mode")
	assert_equal(manager.shop_spawn_object, null, "invalid shop placement clears spawn state")
	assert_equal(objects.get_child_count(), before_count, "invalid shop placement removes the new object")

	scene.queue_free()


func assert_offsets(size: Vector2i, expected: Array[Vector2i], label: String):
	var obj := PlaceableObject.new()
	obj.size_in_cells = size
	assert_vector2i_arrays_equal(obj.get_footprint_offsets(), expected, label)
	obj.free()


func assert_vector2i_arrays_equal(actual: Array[Vector2i], expected: Array[Vector2i], label: String):
	if actual.size() != expected.size():
		fail("%s: expected %s cells, got %s (%s)" % [label, expected.size(), actual.size(), actual])
		return

	for index in range(expected.size()):
		if actual[index] != expected[index]:
			fail("%s: expected %s, got %s" % [label, expected, actual])
			return


func assert_rectangular_rows(actual: Array[Vector2i], size: Vector2i, label: String):
	var rows := {}
	for offset in actual:
		if not rows.has(offset.y):
			rows[offset.y] = []
		rows[offset.y].append(offset.x)

	if rows.size() != size.y:
		fail("%s: expected %s rows, got %s" % [label, size.y, rows.size()])
		return

	for row_key in rows.keys():
		var row: Array = rows[row_key]
		row.sort()
		if row.size() != size.x:
			fail("%s: row %s expected %s cells, got %s" % [label, row_key, size.x, row.size()])
			return
		for index in range(row.size()):
			if row[index] != row[0] + index:
				fail("%s: row %s has a gap: %s" % [label, row_key, row])
				return


func get_row_widths(cells: Array[Vector2i]) -> Array[int]:
	var rows := {}
	for cell in cells:
		if not rows.has(cell.y):
			rows[cell.y] = 0
		rows[cell.y] += 1

	var widths: Array[int] = []
	for row_key in rows.keys():
		widths.append(rows[row_key])

	widths.sort()
	return widths


func assert_equal(actual, expected, label: String):
	if actual != expected:
		fail("%s: expected %s, got %s" % [label, expected, actual])


func assert_bool(value: bool, label: String):
	if not value:
		fail(label)


func fail(message: String):
	failures.append(message)
