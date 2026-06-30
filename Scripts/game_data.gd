extends Node

var seed_inventory: Dictionary = {
	"wheat": 6,
	"corn": 6,
	"carrot": 6
}

func get_seed_count(crop_id: String) -> int:
	return seed_inventory.get(crop_id, 0)

func consume_seed(crop_id: String) -> bool:
	if get_seed_count(crop_id) > 0:
		seed_inventory[crop_id] -= 1
		return true
	return false

func add_seeds(crop_id: String, amount: int):
	if seed_inventory.has(crop_id):
		seed_inventory[crop_id] += amount
	else:
		seed_inventory[crop_id] = amount
