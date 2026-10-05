extends Node

const CONFIG_PATH = "config/config.txt"
const STRUCTURES_PATH = "res://resources/structures/"

var structures: Array[StructureData] = []

var id_to_structure: Dictionary[int, StructureData] = {}

func _ready() -> void:
	if not ResourceLoader.has_cached(Globals.STRUCTURES_PATH) and not DirAccess.dir_exists_absolute(Globals.STRUCTURES_PATH):
		print("Failed to find structure resource path: " + Globals.STRUCTURES_PATH)
		return
		
	var files = ResourceLoader.list_directory(Globals.STRUCTURES_PATH)
	
	for file in files:
		if not file.ends_with(".tres"):
			continue
		
		var full_path = Globals.STRUCTURES_PATH.path_join(file)
		var res = ResourceLoader.load(full_path)
		
		if not res is StructureData:
			continue
		
		structures.append(res)
		var id = ResourceLoader.get_resource_uid(full_path)
		id_to_structure[id] = res
				
func get_structure_id(structure: StructureData) -> int:
	return ResourceLoader.get_resource_uid(structure.resource_path)
