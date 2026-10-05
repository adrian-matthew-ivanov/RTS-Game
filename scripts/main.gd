extends Node2D

@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner
@onready var level_spawner: MultiplayerSpawner = $LevelSpawner

func _ready() -> void:
	Lobby.server_started.connect(server_start)
	Lobby.peer_connected.connect(peer_connected)
	Lobby.peer_disconnected.connect(peer_disconnected)
	Lobby.connected_to_server.connect(connected_to_server)
	
	GameManager.register_root(self)
	
	ScreenManager.open(ScreenManager.ScreenName.CONNECT)

func server_start() -> void:
	GameManager.start_game()
	GameManager.enter_game()

func peer_connected(peer_id : int) -> void:
	GameManager.spawn_player(peer_id)
	
func peer_disconnected(peer_id : int) -> void:
	GameManager.despawn_player(peer_id)


func connected_to_server() -> void:
	GameManager.enter_game()
