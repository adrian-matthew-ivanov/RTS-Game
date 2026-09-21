extends Node

const DEFAULT_PORT = 8910
const DEFAULT_IP = "127.0.0.1"

signal server_started
signal peer_connected(id : int)
signal peer_disconnected(id : int)
signal connected_to_server
signal connection_failed
signal server_disconnected

func _ready() -> void:
	# Listen to multiplayer signals
	# The following emit on both clients and servers
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	# The rest only emit for clients
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

## --- Network Lifecycle Management ---
func start_enet_server(port: int = DEFAULT_PORT) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(port)
	if (error):
		print(error)
	multiplayer.multiplayer_peer = peer
	_start_server_common()

func start_enet_client(address: String, port: int = DEFAULT_PORT) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(address, port)
	if (error):
		print(error)
	multiplayer.multiplayer_peer = peer

func start_websocket_server(port: int = DEFAULT_PORT) -> void:
	var peer: WebSocketMultiplayerPeer = WebSocketMultiplayerPeer.new()
	var error: Error = peer.create_server(port)
	if (error):
		print(error)
	multiplayer.multiplayer_peer = peer
	_start_server_common()

func start_websocket_client(url: String) -> void:
	var peer: WebSocketMultiplayerPeer = WebSocketMultiplayerPeer.new()
	var error: Error = peer.create_client(url)
	if (error):
		print(error)
	multiplayer.multiplayer_peer = peer

func _start_server_common() -> void:
	if multiplayer.is_server():
		server_started.emit()
	

## --- Network Signal Callbacks ---

func _on_peer_connected(id: int):
	print("Peer connected: ", id)
	if multiplayer.is_server():
		peer_connected.emit(id)

func _on_peer_disconnected(id: int):
	print("Peer disconnected: ", id)
	if multiplayer.is_server():
		peer_disconnected.emit(id)

func _on_connected_to_server():
	print("Connected to server successfully!")
	connected_to_server.emit()

func _on_connection_failed():
	print("Connection failed.")
	multiplayer.multiplayer_peer = null
	connection_failed.emit()
	
func _on_server_disconnected():
	print("Server disconnected.")
	server_disconnected.emit()

## --- Internal Registry Management ---

@rpc("call_local", "reliable")
func start_game(scene_path: String):
	# Safely transition everyone out of the lobby into the game arena
	get_tree().change_scene_to_file(scene_path)
