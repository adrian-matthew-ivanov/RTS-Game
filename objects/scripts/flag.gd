@tool
extends Sprite2D

@export var gray_tint_color: Color = Color.RED:
	set(value):
		gray_tint_color = value
		_update_shader()

@export_range(0.0, 1.0) var tint_strength: float = 1.0:
	set(value):
		tint_strength = value
		_update_shader()

@export_range(0.0, 0.5) var gray_tolerance: float = 0.05:
	set(value):
		gray_tolerance = value
		_update_shader()

func _ready() -> void:
	if material is ShaderMaterial:
		material = material.duplicate() 
		
	_update_shader()

func _process(delta: float) -> void:
	if material is ShaderMaterial:
		#material = material.duplicate() 
		pass
	_update_shader()

func _update_shader() -> void:
	if material is ShaderMaterial:
		material.set_shader_parameter("tint_color", gray_tint_color)
		material.set_shader_parameter("tint_strength", tint_strength)
		material.set_shader_parameter("tolerance", gray_tolerance)
