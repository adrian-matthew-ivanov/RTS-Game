extends Node

enum ScreenName { CONNECT, }

func Open(screen_name : ScreenName) -> void:
	_hide_all_screens()
	$HomeScreen.show()
	
func _hide_all_screens() -> void:
	for child in $UIRoot.get_children():
		var control = child as Control
		if (control):
			control.hide()
