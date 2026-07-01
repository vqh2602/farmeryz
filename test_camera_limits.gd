extends SceneTree

func _init():
	var world_scene = load("res://Sence/base.tscn")
	var world = world_scene.instantiate()
	var ground_layer = world.get_node_or_null("GroundLayer")
	if not ground_layer:
		ground_layer = world.find_child("GroundLayer", true, false)
		
	if ground_layer:
		var used_rect = ground_layer.get_used_rect()
		print("Used rect: ", used_rect)
		
		var top_cell = used_rect.position
		var bottom_cell = used_rect.position + used_rect.size
		var right_cell = Vector2i(used_rect.position.x + used_rect.size.x, used_rect.position.y)
		var left_cell = Vector2i(used_rect.position.x, used_rect.position.y + used_rect.size.y)
		
		var top_pos = ground_layer.map_to_local(top_cell)
		var bottom_pos = ground_layer.map_to_local(bottom_cell)
		var right_pos = ground_layer.map_to_local(right_cell)
		var left_pos = ground_layer.map_to_local(left_cell)
		
		var min_x = min(top_pos.x, bottom_pos.x, right_pos.x, left_pos.x)
		var max_x = max(top_pos.x, bottom_pos.x, right_pos.x, left_pos.x)
		var min_y = min(top_pos.y, bottom_pos.y, right_pos.y, left_pos.y)
		var max_y = max(top_pos.y, bottom_pos.y, right_pos.y, left_pos.y)
		
		print("Calculated bounds: min_x=", min_x, " max_x=", max_x, " min_y=", min_y, " max_y=", max_y)
	else:
		print("GroundLayer not found!")
	quit()
