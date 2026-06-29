extends SceneTree

var failures: Array[String] = []


func _initialize():
	test_default_bottom_center_offsets()
	test_custom_footprint_is_preserved()
	test_base_scene_main_house_preview()

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
	], "2x2 footprint is centered on the building foundation")

	assert_offsets(Vector2i(3, 2), [
		Vector2i(-1, -1),
		Vector2i(0, -1),
		Vector2i(1, -1),
		Vector2i(-1, 0),
		Vector2i(0, 0),
		Vector2i(1, 0),
	], "3x2 footprint keeps a rectangular isometric block")


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
	var preview_layer: TileMapLayer = scene.get_node("PreviewLayer")
	var origin := obj.current_cell

	assert_equal(manager.valid_preview_source_id, 12, "valid preview uses the blue tile")
	assert_equal(manager.invalid_preview_source_id, 13, "invalid preview uses the red tile")

	assert_vector2i_arrays_equal(manager.get_object_footprint_cells(obj, origin), [
		origin + Vector2i(-1, -1),
		origin + Vector2i(0, -1),
		origin + Vector2i(-1, 0),
		origin + Vector2i(0, 0),
	], "main house 2x2 footprint sits around the foundation pivot")

	manager.draw_preview_for_obj(obj, origin, manager.valid_preview_source_id)
	for cell in manager.get_object_footprint_cells(obj, origin):
		assert_equal(preview_layer.get_cell_source_id(cell), manager.valid_preview_source_id, "preview paints every footprint cell blue")

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


func assert_equal(actual, expected, label: String):
	if actual != expected:
		fail("%s: expected %s, got %s" % [label, expected, actual])


func fail(message: String):
	failures.append(message)
