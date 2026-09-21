class_name RTSScreen
extends Control

@export var ScreenName : ScreenManager.ScreenName = ScreenManager.ScreenName.NONE

func _ready() -> void:
	register_screen()

# Your custom function to call on ready
func register_screen() -> void:
	ScreenManager.register_screen(self, ScreenName)
