extends SceneTree

func _init():
	var world_scene = load("res://Sence/base.tscn")
	var world = world_scene.instantiate()
	var ground_layer = world.get_node("GroundLayer")
	
	var test_cell = Vector2i(10, -5)
	var godot_local = ground_layer.map_to_local(test_cell)
	
	var tile_size = ground_layer.tile_set.tile_size
	var half_w = float(tile_size.x) / 2.0
	var half_h = float(tile_size.y) / 2.0
	
	var tx = float(test_cell.x)
	var ty = float(test_cell.y)
	
	var math_px = (tx - ty) * half_w
	var math_py = (tx + ty) * half_h
	
	print("Godot local: ", godot_local)
	print("Math local: ", Vector2(math_px, math_py))
	
	quit()
