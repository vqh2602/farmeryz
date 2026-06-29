extends SceneTree

var failures: Array[String] = []


func _initialize():
	test_default_bottom_center_offsets()
	test_custom_footprint_is_preserved()
	test_base_scene_main_house_preview()
	test_drag_requires_hold_and_motion()

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
	var now := Time.get_ticks_msec()

	manager.pending_drag_object = obj
	manager.pending_drag_screen_pos = Vector2.ZERO
	manager.pending_drag_start_msec = now
	manager.try_promote_pending_drag(Vector2(manager.drag_start_distance + 20.0, 0.0))
	assert_equal(manager.dragging_object, null, "mouse down plus immediate motion does not start drag")

	manager.pending_drag_object = obj
	manager.pending_drag_screen_pos = Vector2.ZERO
	manager.pending_drag_start_msec = now - int((manager.drag_hold_seconds + 0.1) * 1000.0)
	manager.try_promote_pending_drag(Vector2(manager.drag_start_distance - 1.0, 0.0))
	assert_equal(manager.dragging_object, null, "hold without enough motion does not start drag")

	manager.pending_drag_object = obj
	manager.pending_drag_screen_pos = Vector2.ZERO
	manager.pending_drag_start_msec = now - int((manager.drag_hold_seconds + 0.1) * 1000.0)
	manager.try_promote_pending_drag(Vector2(manager.drag_start_distance + 20.0, 0.0))
	assert_equal(manager.dragging_object, obj, "hold plus drag starts moving the selected object")

	manager.dragging_object = null
	manager.cancel_pending_drag()
	manager.clear_preview()
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
