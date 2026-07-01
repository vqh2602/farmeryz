extends Control
class_name ActionOverlay

# Signal phát khi user bắt đầu KÉO thực sự (đã di chuyển đủ xa)
signal item_drag_started(action_type: String, item_id: String)

@onready var prev_button: Button = $PanelContainer/MarginContainer/MainHBox/PrevButton
@onready var next_button: Button = $PanelContainer/MarginContainer/MainHBox/NextButton
@onready var item_container: HBoxContainer = $PanelContainer/MarginContainer/MainHBox/ItemContainer

var current_target: PlaceableObject = null
var current_mode: String = "" # "plant" or "harvest"

# Trạng thái pending drag (user đã ấn nhưng chưa kéo đủ xa)
var _pending_action_type: String = ""
var _pending_item_id: String = ""
var _pending_start_pos: Vector2 = Vector2.ZERO
var _is_pending: bool = false
const DRAG_THRESHOLD: float = 8.0

# Các biến phục vụ phân trang
var current_page: int = 0
const PAGE_SIZE: int = 3
var all_seeds: Array = []

func _ready():
	hide()
	if prev_button:
		prev_button.pressed.connect(_on_prev_pressed)
	if next_button:
		next_button.pressed.connect(_on_next_pressed)

func show_for_plant(target: PlaceableObject):
	current_target = target
	current_mode = "plant"
	_cancel_pending()
	
	# Thu thập tất cả hạt giống từ shop để hiển thị (kể cả số lượng = 0 để không bị thiếu cây)
	all_seeds.clear()
	var main_ui = get_tree().get_first_node_in_group("main_ui")
	if main_ui:
		var seeds = main_ui.SHOP_ITEMS.get("farms", [])
		for seed_data in seeds:
			var crop_id = seed_data.get("crop_id", "")
			if crop_id != "":
				all_seeds.append(seed_data)
				
	current_page = 0
	_populate_seeds_page()
	_update_position(target)
	show()

func show_for_harvest(target: PlaceableObject):
	current_target = target
	current_mode = "harvest"
	_cancel_pending()
	
	if prev_button: prev_button.visible = false
	if next_button: next_button.visible = false
	
	_populate_harvest()
	_update_position(target)
	show()

func _update_position(target: PlaceableObject):
	# Sử dụng call_deferred để kích thước size được tính toán chính xác sau khi thêm/xóa node
	call_deferred("_deferred_update_position", target)

func _deferred_update_position(target: PlaceableObject):
	if is_instance_valid(target):
		position = target.global_position + Vector2(-size.x / 2, -100)

func _populate_seeds_page():
	for child in item_container.get_children():
		child.queue_free()
		
	var start_idx = current_page * PAGE_SIZE
	var end_idx = min(start_idx + PAGE_SIZE, all_seeds.size())
	
	for i in range(start_idx, end_idx):
		var seed_data = all_seeds[i]
		var crop_id = seed_data["crop_id"]
		var count = GameData.get_seed_count(crop_id)
		
		# Tạo button với số lượng hạt hiện có
		var btn = _create_item_button(seed_data["icon"], str(count))
		btn.gui_input.connect(_on_item_gui_input.bind(btn, "plant", crop_id))
		item_container.add_child(btn)
		
	# Cập nhật trạng thái ẩn/hiện nút next/prev
	if prev_button:
		prev_button.visible = current_page > 0
	if next_button:
		next_button.visible = end_idx < all_seeds.size()

func _populate_harvest():
	for child in item_container.get_children():
		child.queue_free()
		
	var icon_path = "res://Arts/UI/item thu hoach/liem.png"
	if current_target and current_target.has_method("get_harvest_icon"):
		icon_path = current_target.call("get_harvest_icon")
		
	var btn = _create_item_button(icon_path, "")
	btn.gui_input.connect(_on_item_gui_input.bind(btn, "harvest", ""))
	item_container.add_child(btn)

func _on_prev_pressed():
	if current_page > 0:
		current_page -= 1
		_populate_seeds_page()
		_update_position(current_target)

func _on_next_pressed():
	if (current_page + 1) * PAGE_SIZE < all_seeds.size():
		current_page += 1
		_populate_seeds_page()
		_update_position(current_target)

func _create_item_button(icon_path: String, label_text: String) -> TextureRect:
	var rect = TextureRect.new()
	var tex = load(icon_path)
	if tex:
		rect.texture = tex
	rect.custom_minimum_size = Vector2(80, 80)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	if label_text != "":
		var label = Label.new()
		label.text = label_text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 4)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.add_child(label)
	return rect

func _on_item_gui_input(event: InputEvent, btn: TextureRect, action_type: String, item_id: String):
	# Khi ấn xuống: ghi nhớ item, CHƯA emit signal, CHƯA hide
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			print("[Overlay] gui_input: MouseButton PRESS on '", item_id, "' at ", event.global_position)
			_pending_action_type = action_type
			_pending_item_id = item_id
			_pending_start_pos = event.global_position
			_is_pending = true
			get_viewport().set_input_as_handled()
		else:
			print("[Overlay] gui_input: MouseButton RELEASE")
			if _is_pending:
				print("[Overlay]   -> still pending, cancel (tap without drag)")
				_cancel_pending()
	elif event is InputEventScreenTouch:
		if event.pressed:
			print("[Overlay] gui_input: ScreenTouch PRESS on '", item_id, "' at ", event.position)
			_pending_action_type = action_type
			_pending_item_id = item_id
			_pending_start_pos = event.position
			_is_pending = true
			get_viewport().set_input_as_handled()
		else:
			print("[Overlay] gui_input: ScreenTouch RELEASE")
			if _is_pending:
				print("[Overlay]   -> still pending, cancel (tap without drag)")
				_cancel_pending()
	else:
		# Không in log mouse motion để tránh rác console
		if not event is InputEventMouseMotion:
			print("[Overlay] gui_input: other event: ", event.get_class())

func _input(event):
	if not _is_pending:
		return
	
	# Khi đang pending, "nuốt" mọi event liên quan để PlacementManager không nhận được
	if event is InputEventMouseMotion:
		var dist = event.global_position.distance_to(_pending_start_pos)
		print("[Overlay] _input: MouseMotion dist=", snapped(dist, 0.1), " threshold=", DRAG_THRESHOLD)
		if dist >= DRAG_THRESHOLD:
			print("[Overlay]   -> DRAG THRESHOLD MET! Starting real drag")
			_start_real_drag()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var dist = event.position.distance_to(_pending_start_pos)
		print("[Overlay] _input: ScreenDrag dist=", snapped(dist, 0.1), " threshold=", DRAG_THRESHOLD)
		if dist >= DRAG_THRESHOLD:
			print("[Overlay]   -> DRAG THRESHOLD MET! Starting real drag")
			_start_real_drag()
		get_viewport().set_input_as_handled()
	
	# Nếu nhả tay mà chưa đủ xa → hủy
	elif event is InputEventMouseButton:
		print("[Overlay] _input: MouseButton pressed=", event.pressed)
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			print("[Overlay]   -> RELEASE while pending, cancel")
			_cancel_pending()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		print("[Overlay] _input: ScreenTouch pressed=", event.pressed)
		if not event.pressed:
			print("[Overlay]   -> RELEASE while pending, cancel")
			_cancel_pending()
		get_viewport().set_input_as_handled()

func _start_real_drag():
	print("[Overlay] _start_real_drag: type=", _pending_action_type, " id=", _pending_item_id)
	var action_type = _pending_action_type
	var item_id = _pending_item_id
	_cancel_pending()
	hide()
	item_drag_started.emit(action_type, item_id)

func _cancel_pending():
	_is_pending = false
	_pending_action_type = ""
	_pending_item_id = ""
	_pending_start_pos = Vector2.ZERO
