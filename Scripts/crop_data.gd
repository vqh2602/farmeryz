extends Resource
class_name CropData

@export var crop_id: String = ""
@export var display_name: String = ""
@export var growth_time: float = 60.0 # in seconds
@export var stage_textures: Array[Texture2D] = []
@export var seed_icon: Texture2D = null
@export var visual_scale: Vector2 = Vector2(0.8, 0.8)
