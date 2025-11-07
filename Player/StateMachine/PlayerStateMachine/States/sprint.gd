extends Motion

signal sprint_started
signal sprint_ended

func _enter() -> void:
	sprint_started.emit()
	print(name)

func _state_input(_event: InputEvent) -> void:
	if _event.is_action_pressed("jump"):
		finished.emit("SprintJump")

	if _event.is_action_released("sprint"):
		sprint_ended.emit()
		finished.emit("Run")

func _update(delta: float) -> void:
	set_direction()
	calculate_velocity(sprint_speed, direction, PLAYER_MOVEMENT_STATS.acceleration, delta)

	sprint_remaining -= delta

	if sprint_remaining <= 0:
		sprint_ended.emit()
		finished.emit("Run")

	if direction == Vector3.ZERO:
		sprint_ended.emit()
		finished.emit("Idle")
