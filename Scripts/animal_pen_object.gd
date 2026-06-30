extends PlaceableObject
class_name AnimalPenObject

@export var pen_type: String = ""
@export var animal_capacity: int = 4
@export var fallback_roam_rect: Rect2 = Rect2(Vector2(-120, -92), Vector2(240, 132))
@export var area_node_path: NodePath = NodePath("Area/CollisionShape2D")

var _animals: Array[Node] = []


func accepts_animal_type(animal_type: String) -> bool:
	return animal_type == pen_type and _animals.size() < animal_capacity


func add_animal(animal: Node) -> void:
	if animal == null or _animals.has(animal):
		return

	_animals.append(animal)
	if animal.get_parent() != self:
		var old_global_position := (animal as Node2D).global_position if animal is Node2D else Vector2.ZERO
		var old_parent := animal.get_parent()
		if old_parent != null:
			old_parent.remove_child(animal)
		add_child(animal)
		if animal is Node2D:
			(animal as Node2D).global_position = old_global_position
			(animal as Node2D).z_index = 10

	if animal.has_method("set_home_pen"):
		animal.call("set_home_pen", self)


func get_random_animal_position() -> Vector2:
	var rect := get_roam_rect_local()
	var point := rect.position + Vector2(randf() * rect.size.x, randf() * rect.size.y)
	return to_global(point)


func clamp_animal_world_position(world_position: Vector2) -> Vector2:
	var rect := get_roam_rect_local()
	var local := to_local(world_position)
	local.x = clampf(local.x, rect.position.x, rect.position.x + rect.size.x)
	local.y = clampf(local.y, rect.position.y, rect.position.y + rect.size.y)
	return to_global(local)


func contains_animal_world_position(world_position: Vector2) -> bool:
	return get_roam_rect_local().has_point(to_local(world_position))


func get_roam_rect_local() -> Rect2:
	var shape_node := get_node_or_null(area_node_path) as CollisionShape2D
	if shape_node != null and shape_node.shape is RectangleShape2D:
		var rect_shape := shape_node.shape as RectangleShape2D
		return Rect2(shape_node.position - rect_shape.size * 0.5, rect_shape.size)

	return fallback_roam_rect
