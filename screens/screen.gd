class_name RTSScreen
extends Control

@export var ScreenName : ScreenManager.ScreenName = ScreenManager.ScreenName.NONE

func _ready() -> void:
	register()

# Your custom function to call on ready
func register() -> void:
	ScreenManager.register(self, ScreenName)
