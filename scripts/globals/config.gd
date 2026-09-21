extends Node


func get_ip() -> String:
	return _get_config_value(Globals.CONFIG_PATH, "IP")
	
func get_port() -> String:
	return _get_config_value(Globals.CONFIG_PATH, "PORT")


func _get_config_value(filename : String, key : String) -> String:
	var file : FileAccess = FileAccess.open(filename, FileAccess.READ)
	if not file:
		print("Failed to open file: ", filename)
		return ""
		
	var content : String = file.get_as_text()
	file.close()
	
	var regex : RegEx = RegEx.new()
	regex.compile("(?m)%s=(.*)(?m)$" % key)
	
	var results : Array[RegExMatch] = regex.search_all(content)
	if results.is_empty():
		print("No matches found.")
		return ""
	
	return  results[0].get_string(1) # first match group
	
	
