extends Node
class_name RTSResourceContainer

@export var gold: float = 0;
@export var wood: float = 0;

static func can_buy(have: RTSResourceContainer, cost: RTSResourceContainer) -> bool:
	for resource in have.get_property_list():
		if resource["type"] == TYPE_FLOAT:
			if have.get(resource["name"]) < cost.get(resource["name"]):
				return false
	return true
