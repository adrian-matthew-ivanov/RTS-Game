extends Node
class_name RTSResourceContainer

enum RTSResource {
	GOLD, 
	WOOD,
}

var inventory: Dictionary[RTSResource, float] = {
	RTSResource.GOLD: 0,
	RTSResource.WOOD: 0
}

static func can_buy(have: RTSResourceContainer, cost: RTSResourceContainer) -> bool:
	for resource in RTSResource.keys():
		if have[resource] < cost[resource]:
			return false
	return true
