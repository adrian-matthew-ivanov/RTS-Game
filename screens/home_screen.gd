extends Control

@onready var host_port_text: TextEdit = $HostPort

@onready var join_ip_text: TextEdit = $JoinIP
@onready var join_port_text: TextEdit = $JoinPort

func _ready() -> void:
	join_ip_text.text = Configloader.get_ip()
	join_port_text.text = Configloader.get_port()
	host_port_text.text = Configloader.get_port()
	

func _process(delta: float) -> void:
	pass

func _on_host_pressed() -> void:
	Lobby.start_enet_server(host_port_text.text.to_int())

func _on_join_pressed() -> void:
	Lobby.start_enet_client(join_ip_text.text, join_port_text.text.to_int())
