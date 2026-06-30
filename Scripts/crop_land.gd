extends PlaceableObject
class_name CropLand

var current_crop_id: String = ""
var growth_time_total: float = 60.0 # Default 60 seconds
var current_growth_time: float = 0.0

@onready var crop_sprite: Sprite2D = $CropSprite

# Mapping crop_id to their texture paths
# Texture paths for stages 1, 2, 3
const CROP_TEXTURES = {
	"wheat": ["res://Arts/caytrong-v2/Wheat1.png", "res://Arts/caytrong-v2/Wheat2.png", "res://Arts/caytrong-v2/Wheat3.png"],
	"corn": ["res://Arts/caytrong-v2/corn1.png", "res://Arts/caytrong-v2/corn2.png", "res://Arts/caytrong-v2/corn3.png"],
	"carrot": ["res://Arts/caytrong-v2/carrot1.png", "res://Arts/caytrong-v2/carrot2.png", "res://Arts/caytrong-v2/carrot3.png"],
	"cabbage": ["res://Arts/caytrong-v2/Cabbage1.png", "res://Arts/caytrong-v2/Cabbage2.png", "res://Arts/caytrong-v2/Cabbage3.png"],
	"potato": ["res://Arts/caytrong-v2/Potato1.png", "res://Arts/caytrong-v2/Potato2.png", "res://Arts/caytrong-v2/Potato3.png"],
	"tomato": ["res://Arts/caytrong-v2/Tomato1.png", "res://Arts/caytrong-v2/Tomato2.png", "res://Arts/caytrong-v2/Tomato3.png"],
	"pumpkin": ["res://Arts/caytrong-v2/Pumpkin1.png", "res://Arts/caytrong-v2/Pumpkin2.png", "res://Arts/caytrong-v2/Pumpkin3.png"],
	"rice": ["res://Arts/caytrong-v2/Rice1.png", "res://Arts/caytrong-v2/Rice2.png", "res://Arts/caytrong-v2/Rice3.png"],
	"sugarcane": ["res://Arts/caytrong-v2/Sugarcane1.png", "res://Arts/caytrong-v2/Sugarcane2.png", "res://Arts/caytrong-v2/Sugarcane3.png"],
	"beans": ["res://Arts/caytrong-v2/beans1.png", "res://Arts/caytrong-v2/beans2.png", "res://Arts/caytrong-v2/beans3.png"],
	"cotton": ["res://Arts/caytrong-v2/cotton1.png", "res://Arts/caytrong-v2/cotton2.png", "res://Arts/caytrong-v2/cotton3.png"],
	"pepper": ["res://Arts/caytrong-v2/pepper1.png", "res://Arts/caytrong-v2/pepper2.png", "res://Arts/caytrong-v2/pepper3.png"],
	"sugar_beet": ["res://Arts/caytrong-v2/Sugar_Beet1.png", "res://Arts/caytrong-v2/Sugar_Beet2.png", "res://Arts/caytrong-v2/Sugar_Beet3.png"],
	"strawbarry": ["res://Arts/UI/shop/icon_caytrong_shop/Strawberry Bush tree.png", "res://Arts/UI/shop/icon_caytrong_shop/Strawberry Bush tree.png", "res://Arts/UI/shop/icon_caytrong_shop/Strawberry Bush tree.png"] # Placeholder for strawberry
}

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

func _process(delta):
	if current_crop_id != "":
		if current_growth_time < growth_time_total:
			current_growth_time += delta
			update_crop_visual()

func plant_seed(crop_id: String):
	current_crop_id = crop_id
	current_growth_time = 0.0
	
	if crop_sprite:
		crop_sprite.visible = true
		update_crop_visual()

func has_crop() -> bool:
	return current_crop_id != ""

func update_crop_visual():
	if current_crop_id == "" or not CROP_TEXTURES.has(current_crop_id):
		return
		
	var progress = current_growth_time / growth_time_total
	var stage_index = 0
	
	if progress >= 1.0:
		stage_index = 2 # 100% frame 3
	elif progress >= 0.3:
		stage_index = 1 # 30-99% frame 2
	else:
		stage_index = 0 # 0-30% frame 1
		
	var texture_path = CROP_TEXTURES[current_crop_id][stage_index]
	var tex = load(texture_path)
	if tex:
		crop_sprite.texture = tex
