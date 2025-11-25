extends CharacterBody3D
class_name Player

@export var player_id: int = -1
var is_local_player: bool = false

const PLAYER_MOVEMENT_STATS := preload("res://Player/player_movement_stats.tres")

@onready var run_speed: float = PLAYER_MOVEMENT_STATS.get_velocity(
	PLAYER_MOVEMENT_STATS.jump_distance,
	PLAYER_MOVEMENT_STATS.time_to_jump_apex + PLAYER_MOVEMENT_STATS.time_to_land
)
@onready var state_machine: StateMachine = $StateMachine
@onready var camera_node: Node3D = $Camera


func _ready() -> void:
	pass


func setup(id: int, is_local: bool) -> void:
	player_id = id
	is_local_player = is_local
	name = "Player_%d" % id

	if state_machine:
		state_machine.set_active(true)
		state_machine.set_input_enabled(is_local_player)

	if camera_node.has_method("set_is_local"):
		camera_node.set_is_local(is_local_player)


func set_velocity_from_motion(vel: Vector3) -> void:
	velocity = vel


func _physics_process(_delta: float) -> void:
	move_and_slide()


func apply_remote_input(input_data: Dictionary) -> void:
	if not state_machine:
		return

	var move: Vector3 = input_data.get("move", Vector3.ZERO)
	var do_jump: bool = input_data.get("jump", false)

	# Normalize move vector if needed
	if move.length() > 1.0:
		move = move.normalized()

	# Horizontal movement using the same run_speed as local
	var speed := run_speed
	velocity.x = move.x * speed
	velocity.z = move.z * speed

	# Face movement direction if moving
	if move.length() > 0.1:
		var yaw := atan2(move.x, move.z) + PI
		var basis := global_transform.basis
		basis = Basis(Vector3.UP, yaw)
		global_transform.basis = basis

	# Jump impulse if requested and on the floor
	if do_jump and is_on_floor():
		var jump_gravity := PLAYER_MOVEMENT_STATS.get_jump_gravity()
		var jump_vel := PLAYER_MOVEMENT_STATS.get_jump_velocity(jump_gravity)
		velocity.y = jump_vel

	# Decide animation/state
	var target_state := "Idle"

	if not is_on_floor():
		# In air: distinguish going up vs falling
		target_state = "Jump" if velocity.y > 0.0 else "Fall"
	elif move.length() > 0.1:
		target_state = "Run"

	if state_machine.current_state == null \
	or state_machine.current_state.name != target_state:
		state_machine.change_state_to(target_state)
