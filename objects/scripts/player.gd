extends Node2D

class_name RTSPlayer

var velocity: Vector2 = Vector2(0, 0)

@export var zoom_speed: float = 0.5
@export var min_zoom: float = 1.5
@export var max_zoom: float = 7.0

var target_zoom: float
var is_dragging: bool = false

@onready var camera = $Camera2D

const SPEED = 600.0

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		print("Exiting early! Not the authority.") 
		return

	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction:
		velocity = direction * SPEED / camera.zoom
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)
		
	if Input.is_action_just_pressed("zoom_in"):
		target_zoom += zoom_speed
	elif Input.is_action_just_pressed("zoom_out"):
		target_zoom -= zoom_speed
	
	target_zoom = clamp(target_zoom, min_zoom, max_zoom)
	
	position += velocity * delta
	camera.zoom = camera.zoom.lerp(Vector2(target_zoom, target_zoom), zoom_speed * 10 * delta)
	
func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
	elif event is InputEventMouseMotion and is_dragging:
		position -= event.relative / camera.zoom
		camera.global_position = global_position
		camera.reset_smoothing()

func _enter_tree() -> void:
	var authority_id = name.to_int()
	set_multiplayer_authority(authority_id)

func _ready():
	target_zoom = camera.zoom.x
	
	if is_multiplayer_authority():
		$Camera2D.make_current()
