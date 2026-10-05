extends RTSScreen

class_name PlayerHud

@onready var selection_buttons = $SelectionButtons

var current_action = Enums.Action.NULL
var current_build: StructureData = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
		
	for structure in Globals.structures:
		var new_button = Button.new()
		new_button.text = structure.display_name
		
		new_button.pressed.connect(
			func():
				current_build = structure
				current_action = Enums.Action.BUILD
		)
		
		selection_buttons.add_child(new_button)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if (current_action == Enums.Action.BUILD && current_build != null):
				#GameManager.do_action(current_action)
				GameManager.build_action(current_build, get_global_mouse_position())
				current_build = null
				current_action = Enums.Action.NULL

func _on_cancel_build_pressed() -> void:
	current_action = Enums.Action.NULL
