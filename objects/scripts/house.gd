extends RTSUnit

@export var spawn_unit: PackedScene

func _ready() -> void:
	super()
	if multiplayer.is_server():
		var timer := Timer.new()
		add_child(timer)
		
		timer.wait_time = 5.0
		timer.one_shot = false
		timer.timeout.connect(spawn_troop)
		
		timer.start()


func _process(delta: float) -> void:
	pass
	

func spawn_troop() -> void:
	var unit: Node2D = spawn_unit.instantiate()
	unit.global_position  = self.global_position
	GameManager.spawn(self, unit)
