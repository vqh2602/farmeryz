extends PlaceableObject
class_name SeedObject

var crop_id: String = ""

func _ready():
	super._ready()
	# Seeds don't have an area footprint or visual until planted
	use_area_footprint = false
	size_in_cells = Vector2i(1, 1)

func set_crop_id(id: String):
	crop_id = id
