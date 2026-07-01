extends SceneTree

func _init():
	var world_scene = load("res://Sence/base.tscn")
	var world = world_scene.instantiate()
	var ground_layer = world.get_node("GroundLayer")
	
	print("Tile shape: ", ground_layer.tile_set.tile_shape)
	print("Tile layout: ", ground_layer.tile_set.tile_layout)
	
	quit()
