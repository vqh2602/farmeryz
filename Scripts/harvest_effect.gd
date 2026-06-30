extends Node2D
class_name HarvestEffect

var bg_sprite: Sprite2D
var product_sprite: Sprite2D
var loop_tween: Tween

func setup(product_texture: Texture2D, target_screen_pos: Vector2):
	# 1. Background Basket (giothuhoach)
	bg_sprite = Sprite2D.new()
	bg_sprite.texture = load("res://Arts/UI/item thu hoach/giothuhoach.png")
	bg_sprite.name = "bg_thuhoach"
	add_child(bg_sprite)
	
	# 2. Product Icon (wheat, corn, etc.)
	product_sprite = Sprite2D.new()
	product_sprite.texture = product_texture
	product_sprite.name = "icon_Product"
	product_sprite.position = Vector2(0, -10)
	product_sprite.scale = Vector2(0.8, 0.8)
	add_child(product_sprite)
	
	z_index = 250 # Render above all cropland elements
	
	# Pop up animation
	scale = Vector2.ZERO
	var pop_tween = create_tween().set_parallel(true)
	pop_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await pop_tween.finished
	
	# Start floating loop (cloning thuhoach.anim)
	start_floating_animation()
	
	# Wait 0.6s and then fly to the target UI position
	await get_tree().create_timer(0.6).timeout
	fly_to_target(target_screen_pos)

func start_floating_animation():
	loop_tween = create_tween().set_loops().set_parallel(true)
	
	# bg_thuhoach position.y: bobs up and down (2.0s duration total)
	loop_tween.tween_property(bg_sprite, "position:y", -12.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	loop_tween.tween_property(bg_sprite, "position:y", 0.0, 1.0).set_delay(1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# bg_thuhoach scale: squash & stretch
	bg_sprite.scale = Vector2(1.03, 0.96)
	loop_tween.tween_property(bg_sprite, "scale", Vector2(1.03, 1.03), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	loop_tween.tween_property(bg_sprite, "scale", Vector2(1.03, 0.96), 1.0).set_delay(1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# icon_Product scale: breathing pulsing
	product_sprite.scale = Vector2(0.8, 0.8)
	loop_tween.tween_property(product_sprite, "scale", Vector2(0.76, 0.76), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	loop_tween.tween_property(product_sprite, "scale", Vector2(0.8, 0.8), 1.0).set_delay(1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func fly_to_target(target_pos: Vector2):
	if loop_tween:
		loop_tween.kill()
		
	# Convert screen coordinate (target UI position) back to world position for Node2D movement
	var world_target = get_viewport().get_canvas_transform().affine_inverse() * target_pos
	
	var fly_tween = create_tween().set_parallel(true)
	fly_tween.tween_property(self, "global_position", world_target, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	fly_tween.tween_property(self, "scale", Vector2(0.2, 0.2), 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fly_tween.tween_property(self, "modulate:a", 0.0, 0.8)
	
	fly_tween.finished.connect(queue_free)
