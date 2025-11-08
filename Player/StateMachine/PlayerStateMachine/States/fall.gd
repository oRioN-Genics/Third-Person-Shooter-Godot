extends Motion

func _enter() -> void:
    animation_state_changed.emit("Jump")

func _update(delta: float) -> void:
    set_direction()
    calculate_gravity(delta)
    calculate_velocity(speed, direction, PLAYER_MOVEMENT_STATS.in_air_acceleration, delta)

    if is_on_floor():
        finished.emit("Idle")
