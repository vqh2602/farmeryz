extends PlaceableObject
class_name PerennialTree

@export var tree_type: String = "apple" # "apple", "cacao", "cherry"
@export var visual_scale: Vector2 = Vector2(0.9, 0.9)
@export var foliage_y_offset: float = 60.0

@export var wind_speed: float = 2.0
@export var wind_strength: float = 0.08

# Thời gian phát triển cho từng giai đoạn (giây)
@export var stage_time_0_to_1: float = 5.0
@export var stage_time_1_to_2: float = 5.0
@export var stage_time_2_to_3: float = 5.0
@export var stage_time_3_to_4: float = 5.0
@export var cooldown_regrow: float = 10.0 # Thời gian chín lại sau khi thu hoạch

var current_stage: int = 1 # 1 -> 3
var harvest_count: int = 0 # Tối đa 3 lần
var is_dead: bool = false
var growth_timer: float = 0.0

var trunk_sprite: Sprite2D  # Thân cây: cố định, không đung đưa
var foliage_sprite: Sprite2D # Tán lá: đung đưa theo gió

var time_passed: float = 0.0

func _ready():
	super._ready()
	
	# 1. Khởi tạo Thân cây (trunk_sprite)
	trunk_sprite = Sprite2D.new()
	trunk_sprite.name = "TrunkSprite"
	trunk_sprite.centered = true
	trunk_sprite.scale = visual_scale
	add_child(trunk_sprite)
	
	# 2. Khởi tạo Tán lá (foliage_sprite)
	foliage_sprite = Sprite2D.new()
	foliage_sprite.name = "FoliageSprite"
	foliage_sprite.centered = true
	foliage_sprite.scale = visual_scale
	add_child(foliage_sprite)
	
	_update_visuals()

func _process(delta: float):
	# 1. Logic đung đưa theo gió (Wind sway) CHỈ áp dụng cho tán lá (foliage_sprite)
	if not Engine.is_editor_hint():
		time_passed += delta
		if not is_dead and foliage_sprite.visible:
			foliage_sprite.skew = sin(time_passed * wind_speed) * wind_strength
		else:
			foliage_sprite.skew = 0.0
	
	# 2. Logic phát triển thời gian
	if is_dead or current_stage >= 3:
		return
		
	growth_timer += delta
	var target_time = _get_time_for_current_stage()
	
	if growth_timer >= target_time:
		growth_timer = 0.0
		current_stage += 1
		_update_visuals()
		print("[Tree] ", object_id, " phát triển lên giai đoạn: ", current_stage)

func is_perennial_tree() -> bool:
	return true

func is_fully_grown() -> bool:
	return current_stage == 3 and not is_dead

func get_harvest_icon() -> String:
	# Cây lâu năm thu hoạch bằng GIỎ
	return "res://Arts/UI/item thu hoach/giothuhoach.png"

func harvest() -> String:
	if not is_fully_grown():
		return ""
		
	harvest_count += 1
	print("[Tree] ", object_id, " thu hoạch lần thứ: ", harvest_count)
	
	if harvest_count >= 3:
		is_dead = true
		_update_visuals()
	else:
		# Trở về giai đoạn 2 (resting - không quả) để bắt đầu chín lại
		current_stage = 2
		growth_timer = 0.0
		_update_visuals()
		
	return tree_type

func _get_time_for_current_stage() -> float:
	match current_stage:
		1: return stage_time_1_to_2
		2: return cooldown_regrow if harvest_count > 0 else stage_time_2_to_3
	return 9999.0

func _update_visuals():
	if is_dead:
		# Khi chết: thân là stage 5, tán là stage 4
		var dead_trunk_path = "res://Arts/caylaunam/cay trong/%s5.png" % tree_type
		var dead_foliage_path = "res://Arts/caylaunam/cay trong/%s4.png" % tree_type
		
		if ResourceLoader.exists(dead_trunk_path):
			trunk_sprite.texture = load(dead_trunk_path)
		if ResourceLoader.exists(dead_foliage_path):
			foliage_sprite.texture = load(dead_foliage_path)
			
		foliage_sprite.visible = true
		
		trunk_sprite.modulate = Color.WHITE
		foliage_sprite.modulate = Color.WHITE
		
		_adjust_sprite_positions()
		return
		
	# Cây còn sống: trả về màu sắc tươi sáng
	trunk_sprite.modulate = Color.WHITE
	foliage_sprite.modulate = Color.WHITE
	
	# Load thân cây base (e.g. apple.png, cacao.png, cherry.png)
	var trunk_path = "res://Arts/caylaunam/cay trong/%s.png" % tree_type
	if ResourceLoader.exists(trunk_path):
		trunk_sprite.texture = load(trunk_path)
		
	# Giai đoạn 1->3: hiển thị tán lá tương ứng (e.g. apple1.png -> apple3.png)
	foliage_sprite.visible = true
	var foliage_path = "res://Arts/caylaunam/cay trong/%s%d.png" % [tree_type, current_stage]
	if ResourceLoader.exists(foliage_path):
		foliage_sprite.texture = load(foliage_path)
	else:
		push_warning("[Tree] Không tìm thấy ảnh tán lá: " + foliage_path)
			
	_adjust_sprite_positions()

func _adjust_sprite_positions():
	# Căn chỉnh để đáy của thân cây nằm chính xác tại Y = 0 (mặt đất)
	if trunk_sprite and trunk_sprite.texture:
		trunk_sprite.position.y = - (trunk_sprite.texture.get_size().y * visual_scale.y) / 2
	# Tán lá được nâng lên cao hơn thân cây (foliage_y_offset) để không che lấp gốc
	if foliage_sprite and foliage_sprite.visible and foliage_sprite.texture:
		foliage_sprite.position.y = - (foliage_sprite.texture.get_size().y * visual_scale.y) / 2 - (foliage_y_offset * visual_scale.y)
