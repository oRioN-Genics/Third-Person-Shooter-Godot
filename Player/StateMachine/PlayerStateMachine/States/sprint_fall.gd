extends Motion

signal sprint_ended

func _enter() -> void:
	animation_state_changed.emit("Jump")

func _update(delta: float) -> void:
	set_direction()
	calculate_gravity(delta)
	calculate_velocity(sprint_speed, direction, PLAYER_MOVEMENT_STATS.in_air_acceleration, delta)

	if is_on_floor():
		if Input.is_action_pressed("sprint"):
			finished.emit("Sprint")
		elif direction != Vector3.ZERO:
			sprint_ended.emit()
			finished.emit("Run")
		else:
			sprint_ended.emit()
			finished.emit("Idle")