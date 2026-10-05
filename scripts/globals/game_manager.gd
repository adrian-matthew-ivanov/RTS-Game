extends Node

var root: Node
var level_root: Node
var player_root: Node

var _players: Dictionary[int, Node] = {}

var LEVEL_1: PackedScene = load("res://scenes/levels/level_1.tscn")
var PLAYER_SCENE: PackedScene = load("res://objects/player.tscn")

func register_root(root: Node2D) -> void:
	self.root = root
	self.level_root = root.find_child("Level")
	self.player_root = root.find_child("Players")

func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	pass
	
func spawn_player(peer_id : int) -> void:
	var player = PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	
	_players[peer_id] = player
	player_root.add_child(player)
	
func despawn_player(peer_id : int) -> void:
	player_root.remove_child(_players[peer_id])
	_players.erase(peer_id)
	
func _switch_level(level : PackedScene) -> void:
	level_root.add_child(level.instantiate())	
	
func _clear_players() -> void:
	for c in player_root.get_children():
		player_root.remove_child(c)
		c.queue_free()
		
func _clear_level() -> void:
	for c in level_root.get_children():
		level_root.remove_child(c)
		c.queue_free()
		
#########################################

func start_game() -> void:
	if (is_multiplayer_authority()):
		_clear_players()
		_clear_level()
		
		_switch_level(LEVEL_1)
		spawn_player(multiplayer.get_unique_id())
		

func enter_game() -> void:
	# TODO implement match start sync
	# ScreenManager.open(ScreenManager.ScreenName.START_MATCH)
	# all players must confirm before start
	
	if (is_multiplayer_authority()):
		# server has custom UI
		ScreenManager.open(ScreenManager.ScreenName.SERVER)
	else:
		ScreenManager.open(ScreenManager.ScreenName.HUD)

func build_action(structure: StructureData, position: Vector2) -> void:
	on_build_action.rpc(1, Globals.get_structure_id(structure), position)

@rpc("any_peer", "reliable")
func on_build_action(peer_id:int, structure_id: int, position: Vector2):
	if multiplayer.is_server():
		var child: Node2D = Globals.id_to_structure[structure_id].structure.instantiate()
		child.global_position = position
		level_root.add_child(child, true)
