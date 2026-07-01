extends Camera2D

@export var drag_speed: float = 1.0
@export var zoom_speed: float = 0.08
@export var pinch_zoom_speed: float = 0.35
@export var min_zoom: float = 0.35
@export var max_zoom: float = 2.5

var dragging_camera: bool = false


var _farm_center: Vector2 = Vector2.ZERO
var _farm_half_size: Vector2 = Vector2.ZERO
var _has_farm_bounds: bool = false

func _ready():
	enabled = true
	make_current()
	set_process_input(true)
	_setup_camera_limits()

func _setup_camera_limits():
	var world = get_parent()
	if not world: return
	
	var ground_layer = world.get_node_or_null("GroundLayer")
	if ground_layer and ground_layer is TileMapLayer:
		var used_rect = ground_layer.get_used_rect()
		
		# Get the 4 extreme corners of the used_rect in map coordinates
		var top_cell = used_rect.position
		var bottom_cell = used_rect.position + used_rect.size
		var right_cell = Vector2i(used_rect.position.x + used_rect.size.x, used_rect.position.y)
		var left_cell = Vector2i(used_rect.position.x, used_rect.position.y + used_rect.size.y)
		
		# Convert to local pixel coordinates
		var top_pos = ground_layer.map_to_local(top_cell)
		var bottom_pos = ground_layer.map_to_local(bottom_cell)
		var right_pos = ground_layer.map_to_local(right_cell)
		var left_pos = ground_layer.map_to_local(left_cell)
		
		# Calculate exact bounding box in pixel space
		var min_x = min(top_pos.x, bottom_pos.x, right_pos.x, left_pos.x)
		var max_x = max(top_pos.x, bottom_pos.x, right_pos.x, left_pos.x)
		var min_y = min(top_pos.y, bottom_pos.y, right_pos.y, left_pos.y)
		var max_y = max(top_pos.y, bottom_pos.y, right_pos.y, left_pos.y)
		
		# We use an ellipse inscribed inside this bounding box to restrict camera position
		# This perfectly matches the shape of an isometric map and cuts off the 4 empty gray corners
		_farm_center = Vector2((min_x + max_x) / 2.0, (min_y + max_y) / 2.0)
		_farm_half_size = Vector2((max_x - min_x) / 2.0, (max_y - min_y) / 2.0)
		
		# Add a small padding to half size so user can see edges comfortably
		_farm_half_size.x -= 200 # Thu hẹp xíu để không ra tới rìa quá xa
		_farm_half_size.y -= 150
		
		if _farm_half_size.x > 0 and _farm_half_size.y > 0:
			_has_farm_bounds = true

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_LEFT:
			# Dùng chuột trái để kéo thả map giống game mobile nếu không click vào object
			dragging_camera = event.pressed and not is_placing_or_dragging_object()

		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(-zoom_speed)

		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(zoom_speed)

	if event is InputEventMouseMotion and dragging_camera:
		if is_placing_or_dragging_object():
			dragging_camera = false
			return

		var new_pos = position - event.relative * zoom.x * drag_speed
		
		# Clamping camera position to the farm's ellipse bounds
		if _has_farm_bounds:
			var rel_pos = new_pos - _farm_center
			var ellipse_val = pow(rel_pos.x / _farm_half_size.x, 2) + pow(rel_pos.y / _farm_half_size.y, 2)
			if ellipse_val > 1.0:
				var scale_factor = 1.0 / sqrt(ellipse_val)
				new_pos = _farm_center + rel_pos * scale_factor
				
		position = new_pos

	if event is InputEventPanGesture:
		if is_placing_or_dragging_object():
			return

		var new_pos = position + event.delta * zoom.x * 8.0
		if _has_farm_bounds:
			var rel_pos = new_pos - _farm_center
			var ellipse_val = pow(rel_pos.x / _farm_half_size.x, 2) + pow(rel_pos.y / _farm_half_size.y, 2)
			if ellipse_val > 1.0:
				var scale_factor = 1.0 / sqrt(ellipse_val)
				new_pos = _farm_center + rel_pos * scale_factor
		position = new_pos

	if event is InputEventMagnifyGesture:
		var amount: float = (1.0 - event.factor) * pinch_zoom_speed
		zoom_camera(amount)


func zoom_camera(amount: float):
	var new_zoom: float = clampf(zoom.x + amount, min_zoom, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)


func is_placing_or_dragging_object() -> bool:
	var world := get_parent()
	if world == null:
		return false

	var placement_manager := world.get_node_or_null("PlacementManager")
	if placement_manager != null and "dragging_object" in placement_manager:
		return placement_manager.dragging_object != null

	return false
