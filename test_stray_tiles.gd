extends SceneTree

func _init():
	var world_scene = load("res://Sence/base.tscn")
	var world = world_scene.instantiate()
	var ground_layer = world.get_node("GroundLayer")
	
	var used_cells = ground_layer.get_used_cells()
	print("Total cells: ", used_cells.size())
	
	var min_x = 999999
	var max_x = -999999
	var min_y = 999999
	var max_y = -999999
	
	for cell in used_cells:
		min_x = min(min_x, cell.x)
		max_x = max(max_x, cell.x)
		min_y = min(min_y, cell.y)
		max_y = max(max_y, cell.y)
		
	print("Actual bounds of used cells: X(", min_x, " to ", max_x, ") Y(", min_y, " to ", max_y, ")")
	quit()
