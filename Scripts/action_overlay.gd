extends Control
class_name ActionOverlay

signal item_drag_started(action_type: String, item_id: String)

@onready var item_container: HBoxContainer = $PanelContainer/MarginContainer/HBoxContainer

var current_target: PlaceableObject = null
var current_mode: String = "" # "plant" or "harvest"

func _ready():
	hide()

func show_for_plant(target: PlaceableObject):
	current_target = target
	current_mode = "plant"
	_populate_seeds()
	_update_position(target)
	show()

func show_for_harvest(target: PlaceableObject):
	current_target = target
	current_mode = "harvest"
	_populate_harvest()
	_update_position(target)
	show()

func _update_position(target: PlaceableObject):
	# Position above the target in world space
	position = target.global_position + Vector2(-size.x / 2, -100)

func _populate_seeds():
	for child in item_container.get_children():
		child.queue_free()
		
	# Lấy danh sách hạt giống từ shop data (farms category)
	var main_ui = get_tree().get_first_node_in_group("main_ui")
	if not main_ui: return
	
	var seeds = main_ui.SHOP_ITEMS.get("farms", [])
	for seed_data in seeds:
		var crop_id = seed_data.get("crop_id", "")
		if crop_id == "": continue
		
		var count = GameData.get_seed_count(crop_id)
		if count <= 0: continue # Optional: Only show seeds we have
		
		var btn = _create_item_button(seed_data["icon"], str(count))
		btn.gui_input.connect(_on_item_gui_input.bind(btn, "plant", crop_id))
		item_container.add_child(btn)

func _populate_harvest():
	for child in item_container.get_children():
		child.queue_free()
		
	var btn = _create_item_button("res://Arts/UI/item thu hoach/liem.png", "")
	btn.gui_input.connect(_on_item_gui_input.bind(btn, "harvest", ""))
	item_container.add_child(btn)

func _create_item_button(icon_path: String, label_text: String) -> TextureRect:
	var rect = TextureRect.new()
	var tex = load(icon_path)
	if tex:
		rect.texture = tex
	rect.custom_minimum_size = Vector2(80, 80)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_PASS
	
	if label_text != "":
		var label = Label.new()
		label.text = label_text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 4)
		rect.add_child(label)
		
	return rect

func _on_item_gui_input(event: InputEvent, btn: TextureRect, action_type: String, item_id: String):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		item_drag_started.emit(action_type, item_id)
		# Tắt menu khi bắt đầu kéo
		hide()
