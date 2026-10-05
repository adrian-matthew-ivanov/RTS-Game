extends Node

enum ScreenName { NONE, CONNECT, START_MATCH, HUD, SERVER}

var screens = {};

func register_screen(screen : RTSScreen, screen_name : ScreenName) -> void:
	screens[screen_name] = screen

func open(screen_name : ScreenName) -> void:
	_hide_all_screens()
	var found_screen = false
	if screens.has(screen_name):
		screens[screen_name].show()
		found_screen = true
		
	if (!found_screen):
		print("failed to find screen" + str(screen_name))
	
func _hide_all_screens() -> void:
	for screen in screens.values():
		screen.hide()
