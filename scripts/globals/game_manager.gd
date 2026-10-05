extends Node


func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	pass


func enter_game() -> void:
	# TODO implement match start sync
	# ScreenManager.open(ScreenManager.ScreenName.START_MATCH)
	# all players must confirm before start
	
	if (is_multiplayer_authority()):
		# server has custom UI
		ScreenManager.open(ScreenManager.ScreenName.SERVER)
	else:
		ScreenManager.open(ScreenManager.ScreenName.HUD)
