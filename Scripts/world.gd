extends Node2D

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var placement_manager: PlacementManager = $PlacementManager
@onready var cell_debug_label: Label = $CanvasLayer/CellDebugLabel

var action_overlay: ActionOverlay
var farm_action_manager: FarmActionManager

func _ready():
	# Enable Y-sorting on the Objects container
	var objects_node = get_node_or_null("Objects")
	if objects_node:
		objects_node.y_sort_enabled = true
		print("[World] Enabled Y-sorting on Objects node")
		
	# Instantiate FarmActionManager
	farm_action_manager = FarmActionManager.new()
	farm_action_manager.name = "FarmActionManager"
	add_child(farm_action_manager)
		
	# Instance the ActionOverlay
	var overlay_scene = load("res://Sence/Farm/ActionOverlay.tscn")
	if overlay_scene:
		action_overlay = overlay_scene.instantiate()
		action_overlay.z_index = 300
		add_child(action_overlay)
		if farm_action_manager:
			farm_action_manager.action_overlay = action_overlay
			action_overlay.item_drag_started.connect(farm_action_manager._on_action_drag_started)

func _process(_delta):
	var mouse_cell: Vector2i = get_mouse_cell()
	var mouse_global: Vector2 = get_global_mouse_position()

	if cell_debug_label:
		var drag_info: String = "None"

		if placement_manager != null:
			drag_info = placement_manager.get_dragging_info_text()

		cell_debug_label.text = "Mouse Cell: %s | Pos: %s\n%s" % [
			mouse_cell,
			mouse_global.round(),
			drag_info
		]

		var viewport_size: Vector2 = get_viewport_rect().size
		cell_debug_label.position = Vector2(20, viewport_size.y - 70)


func get_mouse_cell() -> Vector2i:
	var mouse_global: Vector2 = get_global_mouse_position()
	var local_pos: Vector2 = ground_layer.to_local(mouse_global)
	return ground_layer.local_to_map(local_pos)
