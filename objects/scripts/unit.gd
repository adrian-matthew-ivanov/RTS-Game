extends Node2D
class_name RTSUnit

@export var owner_id: int

func set_owner_id(owner_id: int) -> void:
	self.owner_id = owner_id

func _ready():
	add_to_group("units")
