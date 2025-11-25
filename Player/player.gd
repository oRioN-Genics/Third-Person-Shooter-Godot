extends CharacterBody3D
class_name Player

@export var player_id: int = -1
var is_local_player: bool = false

@onready var state_machine: StateMachine = $StateMachine
@onready var camera_node: Node3D = $Camera

func _ready() -> void:
	pass


func setup(id: int, is_local: bool) -> void:
	player_id = id
	is_local_player = is_local
	name = "Player_%d" % id

	if state_machine:
		state_machine.set_active(is_local_player)

	if camera_node.has_method("set_is_local"):
		camera_node.set_is_local(is_local_player)


func set_velocity_from_motion(vel: Vector3) -> void:
	velocity = vel


func _physics_process(_delta: float) -> void:
	move_and_slide()


func apply_remote_input(input_data: Dictionary) -> void:
	pass
