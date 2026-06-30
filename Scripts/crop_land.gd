extends PlaceableObject
class_name CropLand

var current_crop_id: String = ""
var growth_time_total: float = 60.0 # Loaded dynamically from CropData
var current_growth_time: float = 0.0
var crop_data: CropData = null

@onready var crop_sprite: Sprite2D = $CropSprite

func _ready():
	super._ready()
	if crop_sprite:
		crop_sprite.visible = false
		
		# Thêm hiệu ứng gió thổi (Sway shader)
		var mat = ShaderMaterial.new()
		var shader = Shader.new()
		shader.code = """
shader_type canvas_item;
uniform float speed = 2.0;
uniform float strength = 0.05;
void vertex() {
	// UV.y = 0 là đỉnh, 1 là đáy. Ta muốn đỉnh lắc nhiều, đáy đứng yên.
	float weight = 1.0 - UV.y;
	float sway = sin(TIME * speed + VERTEX.x + VERTEX.y) * strength;
	VERTEX.x += sway * weight * 100.0;
}
"""
		mat.shader = shader
		crop_sprite.material = mat

	if current_crop_id != "":
		_load_crop_data(current_crop_id)
		if crop_data and crop_sprite:
			crop_sprite.visible = true
			update_crop_visual()

func _process(delta):
	if current_crop_id != "":
		if current_growth_time < growth_time_total:
			current_growth_time += delta
			update_crop_visual()

func plant_seed(crop_id: String):
	current_crop_id = crop_id
	current_growth_time = 0.0
	_load_crop_data(crop_id)
	
	if crop_sprite:
		crop_sprite.visible = true
		update_crop_visual()

func has_crop() -> bool:
	return current_crop_id != ""

func is_fully_grown() -> bool:
	return has_crop() and current_growth_time >= growth_time_total

func harvest() -> String:
	if not is_fully_grown():
		return ""
		
	var harvested_crop_id = current_crop_id
	current_crop_id = ""
	current_growth_time = 0.0
	crop_data = null
	
	if crop_sprite:
		crop_sprite.visible = false
		crop_sprite.texture = null
		
	return harvested_crop_id

func update_crop_visual():
	if current_crop_id == "" or crop_data == null or crop_data.stage_textures.size() == 0:
		return
		
	var progress = current_growth_time / growth_time_total
	var stage_index = 0
	
	if progress >= 1.0:
		stage_index = min(2, crop_data.stage_textures.size() - 1) # 100% frame 3
	elif progress >= 0.3:
		stage_index = min(1, crop_data.stage_textures.size() - 1) # 30-99% frame 2
	else:
		stage_index = 0 # 0-30% frame 1
		
	var tex = crop_data.stage_textures[stage_index]
	if tex and crop_sprite:
		crop_sprite.texture = tex

func _load_crop_data(crop_id: String):
	var path = "res://Sence/Farm/Crops/%s.tres" % crop_id
	if ResourceLoader.exists(path):
		crop_data = load(path) as CropData
		if crop_data:
			growth_time_total = crop_data.growth_time
	else:
		push_warning("CropData resource not found at: %s" % path)
		crop_data = null
		growth_time_total = 60.0
