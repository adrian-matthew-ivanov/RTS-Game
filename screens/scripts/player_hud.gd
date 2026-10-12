extends RTSScreen

class_name PlayerHud

@onready var build_menu = $BuildMenu

enum Action {NULL, BUILD, DESTROY, INTERACT, GUIDE_TROOPS}

var current_action = Action.NULL
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
				current_action = Action.BUILD
		)
		
		new_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		build_menu.add_child(new_button)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func action_changed():
	if (current_action == Action.BUILD):
		build_menu.visible = true
	else:
		build_menu.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if (current_action == Action.BUILD && current_build != null):
				#GameManager.do_action(current_action)
				var position = get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
				GameManager.build_action(current_build, position)
				current_build = null
				current_action = Action.NULL
				action_changed()
				
func _action_cancel():
	current_action = Action.NULL
	action_changed()

func _action_build():
	current_action = Action.BUILD
	action_changed()

func _action_destroy():
	current_action = Action.DESTROY
	action_changed()

func _action_interact():
	current_action = Action.INTERACT
	action_changed()

func _action_guide_troops():
	current_action = Action.GUIDE_TROOPS
	action_changed()
