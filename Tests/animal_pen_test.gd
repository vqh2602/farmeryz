extends SceneTree

const PAIRS := [
	{"pen": "res://Sence/Objects/Henhouse/Henhouse.tscn", "animal": "res://Sence/Objects/Chicken/Chicken.tscn", "type": "chicken", "id": "chicken", "name": "Gà"},
	{"pen": "res://Sence/Objects/Cowshed/Cowshed.tscn", "animal": "res://Sence/Objects/Cow/Cow.tscn", "type": "cow", "id": "cow", "name": "Bò"},
	{"pen": "res://Sence/Objects/Pigpen/Pigpen.tscn", "animal": "res://Sence/Objects/Pig/Pig.tscn", "type": "pig", "id": "pig", "name": "Heo"},
	{"pen": "res://Sence/Objects/Sheepfold/Sheepfold.tscn", "animal": "res://Sence/Objects/Sheep/Sheep.tscn", "type": "sheep", "id": "sheep", "name": "Cừu"},
	{"pen": "res://Sence/Objects/Beehive/Beehive.tscn", "animal": "res://Sence/Objects/Bee/Bee.tscn", "type": "bee", "id": "bee", "name": "Ong"},
	{"pen": "res://Sence/Objects/OstrichHouse/OstrichHouse.tscn", "animal": "res://Sence/Objects/Ostrich/Ostrich.tscn", "type": "ostrich", "id": "ostrich", "name": "Đà Điểu"},
	{"pen": "res://Sence/Objects/PeacockHouse/PeacockHouse.tscn", "animal": "res://Sence/Objects/Peacock/Peacock.tscn", "type": "peacock", "id": "peacock", "name": "Công"},
]

var failures: Array[String] = []


func _init() -> void:
	await process_frame
	await _run_tests()
	if failures.is_empty():
		print("animal_pen_test: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _run_tests() -> void:
	await _assert_direct_pen_confinement()
	await _assert_store_places_animal_into_pen()
	await _save_reference_sheet()


func _assert_direct_pen_confinement() -> void:
	var stage := Node2D.new()
	root.add_child(stage)

	for index in range(PAIRS.size()):
		var pair: Dictionary = PAIRS[index]
		var pen := _instantiate(pair.pen) as AnimalPenObject
		var animal := _instantiate(pair.animal) as AnimalObject
		_assert(pen != null, "Không load được chuồng: %s" % pair.pen)
		_assert(animal != null, "Không load được animal: %s" % pair.animal)
		if pen == null or animal == null:
			continue

		pen.position = Vector2(index * 420, 0)
		stage.add_child(pen)
		stage.add_child(animal)
		pen.add_animal(animal)

		_assert(pen.accepts_animal_type(pair.type), "Chuồng không nhận đúng type trước khi đầy: %s" % pair.type)
		_assert(animal.home_pen == pen, "Animal chưa được gán home_pen: %s" % pair.type)
		_assert(not animal.draggable and not animal.blocks_cells, "Animal không được chiếm/kéo như object map: %s" % pair.type)

		for step in range(90):
			await process_frame
			_assert(pen.contains_animal_world_position(animal.global_position), "Animal đi ra ngoài Area chuồng %s ở frame %s" % [pair.type, step])

	stage.queue_free()


func _assert_store_places_animal_into_pen() -> void:
	var scene: Node = load("res://Sence/base.tscn").instantiate()
	root.add_child(scene)
	await process_frame

	var manager: PlacementManager = scene.get_node("PlacementManager")
	var objects := scene.get_node("Objects") as Node2D
	var pen := _instantiate("res://Sence/Objects/Henhouse/Henhouse.tscn") as AnimalPenObject
	objects.add_child(pen)
	pen.global_position = Vector2(120, 140)

	var animal := manager.start_build_from_shop_item({
		"id": "test_chicken",
		"name": "Gà",
		"scene": "res://Sence/Objects/Chicken/Chicken.tscn",
		"animal_pen_type": "chicken",
	})

	_assert(animal != null, "Store animal phải tạo được khi có chuồng đúng type")
	_assert(manager.dragging_object == null, "Animal từ store không được chuyển sang drag tự do ngoài map")
	if animal != null:
		_assert(animal is AnimalObject, "Animal từ store phải là AnimalObject")
		_assert((animal as AnimalObject).home_pen == pen, "Animal từ store phải nằm trong chuồng đúng type")
		_assert(pen.contains_animal_world_position(animal.global_position), "Animal từ store spawn ngoài Area chuồng")

	scene.queue_free()


func _save_reference_sheet() -> void:
	if DisplayServer.get_name() == "headless":
		return

	root.size = Vector2i(1400, 1120)
	var stage := Node2D.new()
	root.add_child(stage)

	for index in range(PAIRS.size()):
		var pair: Dictionary = PAIRS[index]
		var pen := _instantiate(pair.pen) as AnimalPenObject
		var animal := _instantiate(pair.animal) as AnimalObject
		if pen == null or animal == null:
			continue

		pen.position = Vector2(170 + (index % 3) * 430, 250 + int(index / 3) * 300)
		stage.add_child(pen)
		stage.add_child(animal)
		pen.add_animal(animal)
		animal.global_position = pen.to_global(pen.get_roam_rect_local().get_center())

	await create_timer(0.6).timeout
	root.get_texture().get_image().save_png("/tmp/farmery_animal_pen_scenes.png")
	stage.queue_free()


func _instantiate(path: String) -> Node:
	var packed_scene := load(path) as PackedScene
	_assert(packed_scene != null, "Không load được scene: %s" % path)
	if packed_scene == null:
		return null
	return packed_scene.instantiate()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
