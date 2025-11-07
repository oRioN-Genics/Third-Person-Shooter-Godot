extends Node3D

@export var character: CharacterBody3D
@export var edge_spring_arm: SpringArm3D
@export var rear_spring_arm: SpringArm3D
@export var camera: Camera3D

@export var camera_alignment_speed: float = 0.4
@export var aim_rear_spring_length: float = 0.5
@export var aim_edge_spring_length: float = 0.8
@export var aim_Speed: float = 0.4
@export var aim_fov: float = 55

@export var sprint_fov: float = 100
@export var sprint_tween_speed: float = 0.5

var camera_rotation: Vector2 = Vector2.ZERO
var mouse_sensitivity: float = 0.001
var max_y_rotation: float = 1.2

var camera_tween: Tween

enum CameraAlignment {LEFT = -1, RIGHT = 1, CENTRE = 0}
var current_camera_alignment: int = CameraAlignment.RIGHT

@onready var default_edge_spring_arm_length: float = edge_spring_arm.spring_length
@onready var default_rear_spring_arm_length: float = rear_spring_arm.spring_length
@onready var default_fov: float = camera.fov

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event is InputEventMouseMotion:
		var mouse_event: Vector2 = event.screen_relative * mouse_sensitivity
		camera_look(mouse_event)

	if event.is_action_pressed("swap_camera_alignment"):
		swap_camera_alignment()

func camera_look(mouse_movement: Vector2) -> void:
	camera_rotation += mouse_movement

	transform.basis = Basis()
	character.transform.basis = Basis()

	character.rotate_object_local(Vector3(0, 1, 0), -camera_rotation.x)
	rotate_object_local(Vector3(1, 0, 0), -camera_rotation.y)

	camera_rotation.y = clamp(camera_rotation.y, -max_y_rotation, max_y_rotation)

func swap_camera_alignment() -> void:
	match current_camera_alignment:
		CameraAlignment.RIGHT:
			set_current_camera_alignment(CameraAlignment.LEFT)
		CameraAlignment.LEFT:
			set_current_camera_alignment(CameraAlignment.RIGHT)
		CameraAlignment.CENTRE:
			return

	var new_pos = default_edge_spring_arm_length * current_camera_alignment
	set_rear_spring_arm_position(new_pos, camera_alignment_speed)

func set_current_camera_alignment(alignment: CameraAlignment) -> void:
	current_camera_alignment = alignment

func set_rear_spring_arm_position(pos: float, speed: float) -> void:
	if camera_tween:
		camera_tween.kill()
	
	camera_tween = get_tree().create_tween()
	camera_tween.set_trans(Tween.TRANS_EXPO)
	camera_tween.set_ease(Tween.EASE_OUT)
	camera_tween.tween_property(edge_spring_arm, "spring_length", pos, speed)

func enter_aim() -> void:
	if camera_tween:
		camera_tween.kill()
	
	camera_tween = get_tree().create_tween().set_parallel()
	camera_tween.set_trans(Tween.TRANS_EXPO)
	camera_tween.set_ease(Tween.EASE_OUT)

	camera_tween.tween_property(camera, "fov", aim_fov, aim_Speed)
	camera_tween.tween_property(edge_spring_arm, "spring_length", aim_edge_spring_length * current_camera_alignment, aim_Speed)
	camera_tween.tween_property(rear_spring_arm, "spring_length", aim_rear_spring_length, aim_Speed)

func exit_aim() -> void:
	if camera_tween:
		camera_tween.kill()
	
	camera_tween = get_tree().create_tween().set_parallel()
	camera_tween.set_trans(Tween.TRANS_EXPO)
	camera_tween.set_ease(Tween.EASE_OUT)

	camera_tween.tween_property(camera, "fov", default_fov, aim_Speed)
	camera_tween.tween_property(edge_spring_arm, "spring_length", default_edge_spring_arm_length * current_camera_alignment, aim_Speed)
	camera_tween.tween_property(rear_spring_arm, "spring_length", default_rear_spring_arm_length, aim_Speed)

func enter_sprint() -> void:
	if camera_tween:
		camera_tween.kill()

	camera_tween = get_tree().create_tween().set_parallel()
	camera_tween.set_trans(Tween.TRANS_EXPO)
	camera_tween.set_ease(Tween.EASE_OUT)

	camera_tween.tween_property(camera, "fov", sprint_fov, sprint_tween_speed)
	camera_tween.tween_property(edge_spring_arm, "spring_length", default_edge_spring_arm_length * current_camera_alignment, aim_Speed)
	camera_tween.tween_property(rear_spring_arm, "spring_length", default_rear_spring_arm_length, aim_Speed)

func exit_sprint() -> void:
	if camera_tween:
		camera_tween.kill()
	
	camera_tween = get_tree().create_tween().set_parallel()
	camera_tween.set_trans(Tween.TRANS_EXPO)
	camera_tween.set_ease(Tween.EASE_OUT)

	camera_tween.tween_property(camera, "fov", default_fov, sprint_tween_speed)
	camera_tween.tween_property(edge_spring_arm, "spring_length", default_edge_spring_arm_length * current_camera_alignment, aim_Speed)
	camera_tween.tween_property(rear_spring_arm, "spring_length", default_rear_spring_arm_length, aim_Speed)


func _on_sprint_sprint_started() -> void:
	enter_sprint()

func _on_sprint_ended() -> void:
	exit_sprint()

func _on_aim_entered() -> void:
	enter_aim()

func _on_aim_exited() -> void:
	exit_aim()
