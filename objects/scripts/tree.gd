extends Node2D

class_name RTSTree

@export var is_chopped: bool = false

@onready var sprite = $Tree

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func chop():
	is_chopped = true
