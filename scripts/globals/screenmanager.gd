class_name ScreenManager
extends Node
 

enum ScreenName { NONE, CONNECT, START_MATCH}

var screens = {};

func register_screen(screen : RTSScreen, screen_name : ScreenName) -> void:
	screens[screen_name] = screen

func open(screen_name : ScreenName) -> void:
	_hide_all_screens()
	screens[screen_name].show()
	
func _hide_all_screens() -> void:
	for screen in screens.values():
		screen.hide()
