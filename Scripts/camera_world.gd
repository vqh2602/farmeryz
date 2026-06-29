extends Camera2D

@export var drag_speed: float = 1.0

@export var zoom_speed: float = 0.08
@export var pinch_zoom_speed: float = 0.35
@export var min_zoom: float = 0.35
@export var max_zoom: float = 2.5

var dragging_camera: bool = false


func _ready():
	enabled = true
	make_current()
	set_process_input(true)
	print("Camera ready, current = ", is_current())


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			dragging_camera = event.pressed

		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(-zoom_speed)

		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(zoom_speed)

	if event is InputEventMouseMotion and dragging_camera:
		var mouse_delta: Vector2 = event.relative
		position -= mouse_delta * zoom.x * drag_speed

	if event is InputEventPanGesture:
		if is_placing_or_dragging_object():
			return

		var pan_delta: Vector2 = event.delta
		position += pan_delta * zoom.x * 8.0

	if event is InputEventMagnifyGesture:
		var factor: float = event.factor
		var amount: float = (1.0 - factor) * pinch_zoom_speed
		zoom_camera(amount)


func zoom_camera(amount: float):
	var new_zoom: float = zoom.x + amount
	new_zoom = clamp(new_zoom, min_zoom, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)


func is_placing_or_dragging_object() -> bool:
	var world = get_parent()
	var placement_manager = world.get_node_or_null("PlacementManager")

	if placement_manager != null and "dragging_object" in placement_manager:
		return placement_manager.dragging_object != null

	return false
