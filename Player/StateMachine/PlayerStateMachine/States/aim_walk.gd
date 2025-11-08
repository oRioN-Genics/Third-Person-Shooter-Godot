extends Motion

signal aim_entered
signal aim_exited

func _enter() -> void:
	aim_entered.emit()
	animation_state_changed.emit("Walk")

func _state_input(_event: InputEvent) -> void:
	if _event.is_action_pressed("jump"):
		aim_exited.emit()
		finished.emit("Jump")

	if _event.is_action_pressed("sprint") and sprint_remaining > 0.5:
		aim_exited.emit()
		finished.emit("Sprint")

	if _event.is_action_released("aim"):
		aim_exited.emit()
		finished.emit("Run")

func _update(delta: float) -> void:
	set_direction()
	calculate_velocity(aim_speed, direction, PLAYER_MOVEMENT_STATS.acceleration, delta)
	replenish_sprint(delta)

	if direction == Vector3.ZERO:
		finished.emit("AimIdle")

	if not is_on_floor():
		aim_exited.emit()
		finished.emit("Fall")