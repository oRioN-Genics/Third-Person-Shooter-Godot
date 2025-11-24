extends CharacterBody3D

@export var is_local_player: bool = true

@onready var state_machine: StateMachine = $StateMachine
@onready var camera_node: Node3D = $Camera

func _ready() -> void:
	if state_machine:
		state_machine._set_active(is_local_player)
	
	if camera_node.has_method("set_is_local"):
		camera_node.set_is_local(is_local_player)


func set_velocity_from_motion(vel: Vector3) -> void:
	velocity = vel


func _physics_process(_delta: float) -> void:
	move_and_slide()
