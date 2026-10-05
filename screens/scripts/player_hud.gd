extends RTSScreen

class_name PlayerHud

@onready var selection_buttons = $SelectionButtons

var current_action = Enums.Action.NULL

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
					
	for structure in Globals.structures:
		var new_button = Button.new()
		new_button.text = structure.display_name
		
		selection_buttons.add_child(new_button)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if (current_action == Enums.Action.BUILD):
				GameManager.do_action(current_action)
				current_action = Enums.Action.NULL

func _on_cancel_build_pressed() -> void:
	current_action = Enums.Action.NULL
