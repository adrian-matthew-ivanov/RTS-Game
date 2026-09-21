extends Node2D

@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner
@onready var level_spawner: MultiplayerSpawner = $LevelSpawner

var PLAYER_SCENE: PackedScene = load("res://objects/player.tscn")

var LEVEL_1: PackedScene = load("res://scenes/levels/level_1.tscn")

var _players: Dictionary[int, Node] = {}

func _ready() -> void:
	Lobby.server_started.connect(server_start)
	Lobby.peer_connected.connect(peer_connected)
	Lobby.peer_disconnected.connect(peer_disconnected)

func _process(delta: float) -> void:
	pass

func server_start() -> void:
	_clear_players()
	_clear_level()
	
	_switch_level(LEVEL_1)
	_spawn_player(multiplayer.get_unique_id())

func peer_connected(peer_id : int) -> void:
	_spawn_player(peer_id)
	
func peer_disconnected(peer_id : int) -> void:
	_despawn_player(peer_id)
	
func _spawn_player(peer_id : int) -> void:
	var player = PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	
	_players[peer_id] = player
	$Players.add_child(player)
	
func _despawn_player(peer_id : int) -> void:
	$Players.remove_child(_players[peer_id])
	_players.erase(peer_id)
	
func _switch_level(level : PackedScene) -> void:
	$Level.add_child(level.instantiate())	
	
func _clear_players() -> void:
	var players = $Players
	for c in players.get_children():
		players.remove_child(c)
		c.queue_free()
		
func _clear_level() -> void:
	var level = $Level
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()
