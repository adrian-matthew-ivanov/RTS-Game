extends Node2D

@onready var velocity: Vector2 = Vector2(0, 0)

const SPEED = 100.0

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction:
		velocity = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)

	position += velocity * delta;
	
func _enter_tree() -> void:
	var authority_id = name.to_int()
	set_multiplayer_authority(authority_id)

func _ready():
	if is_multiplayer_authority():
		$Camera2D.make_current()
