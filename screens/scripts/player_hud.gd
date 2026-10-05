extends RTSScreen

class_name PlayerHud

var current_action = Enums.Action.NULL

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if (current_action == Enums.Action.PLACE_HOUSE):
				GameManager.do_action(current_action)

func _on_build_house_pressed() -> void:
	current_action = Enums.Action.PLACE_HOUSE

func _on_cancel_build_pressed() -> void:
	current_action = Enums.Action.NULL
