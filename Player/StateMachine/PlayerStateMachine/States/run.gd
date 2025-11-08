extends Motion

func _enter() -> void:
    animation_state_changed.emit("Run")

func _state_input(_event: InputEvent) -> void:
    if _event.is_action_pressed("jump"):
        finished.emit("Jump")

    if _event.is_action_pressed("sprint") and sprint_remaining > PLAYER_MOVEMENT_STATS.minimum_sprint_threshold:
        finished.emit("Sprint")

    if _event.is_action_pressed("aim"):
        finished.emit("AimWalk")

func _update(delta: float) -> void:
    set_direction()
    calculate_velocity(speed, direction, PLAYER_MOVEMENT_STATS.acceleration, delta)
    replenish_sprint(delta)

    if direction == Vector3.ZERO:
        finished.emit("Idle")

    if not is_on_floor():
        finished.emit("Fall")