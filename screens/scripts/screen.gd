class_name RTSScreen
extends Control

@export var ScreenName : ScreenManager.ScreenName = ScreenManager.ScreenName.NONE

func _ready() -> void:
	register_screen()

func register_screen() -> void:
	ScreenManager.register_screen(self, ScreenName)
