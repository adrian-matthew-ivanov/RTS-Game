extends Node

var root: Node2D
var level: Node2D
var players: Node2D

func register_root(root: Node2D) -> void:
	pass

func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	pass

func do_action(action: Enums.Action) -> void:
	sync_action.rpc_id(1, action)

@rpc("any_peer", "reliable")
func sync_action(action: int):
	var current_action: Enums.Action = action as Enums.Action
	if multiplayer.is_server():
		print("Server received action: ", current_action)
		
func enter_game() -> void:
	# TODO implement match start sync
	# ScreenManager.open(ScreenManager.ScreenName.START_MATCH)
	# all players must confirm before start
	
	if (is_multiplayer_authority()):
		# server has custom UI
		ScreenManager.open(ScreenManager.ScreenName.SERVER)
	else:
		ScreenManager.open(ScreenManager.ScreenName.HUD)
