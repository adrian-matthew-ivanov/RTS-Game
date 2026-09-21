extends CharacterBody2D

@onready var peer_id_label = $PeerIdLabel
@onready var sprite = $AnimatedSprite2D

const SPEED = 100.0

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction:
		velocity = direction * SPEED
		sprite.flip_h = direction.x < 0
		
		if sprite.animation != "walk":
			sprite.play("walk")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)
		
		if sprite.animation != "idle":
			sprite.play("idle")

	move_and_slide()
	
func _enter_tree() -> void:
	var authority_id = name.to_int()
	set_multiplayer_authority(authority_id)

func _ready():
	peer_id_label.text = name
	
	if is_multiplayer_authority():
		$Camera2D.make_current()
