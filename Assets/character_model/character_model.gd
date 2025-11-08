extends Node3D
class_name CharacterModel

@export var animation_tree: AnimationTree

func _ready() -> void:
	pass

func on_state_machine_animation_state_changed(state: String) -> void:
	animation_tree["parameters/unarmed_movement/transition_request"] = state