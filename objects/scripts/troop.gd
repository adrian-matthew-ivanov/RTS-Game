extends RTSUnit


@export var speed: float = 40.0
 
var hp: int = 10
var target: Node2D = null

func _ready() -> void:
	super()
	if not multiplayer.is_server():
		set_physics_process(false)
		return
 
	var timer := Timer.new()
	timer.wait_time = 3.0
	timer.timeout.connect(find_target)
	add_child(timer)
	timer.start()
	find_target()
	
	print(name, " owner=", owner_id, " units=", get_tree().get_nodes_in_group("units").size(), " target=", target)
	
func find_target() -> void:
	target = null
	var closest := INF
	for unit in get_tree().get_nodes_in_group("units"):
		if unit == self or unit.get("owner_id") == owner_id:
			continue
		var dist := global_position.distance_squared_to(unit.global_position)
		if dist < closest:
			closest = dist
			target = unit
			
	print("FOUND")

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	global_position = global_position.move_toward(target.global_position, speed * delta)
