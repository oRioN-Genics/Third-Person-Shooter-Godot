extends Motion

func _enter() -> void:
    animation_state_changed.emit("Jump")
    jump()

func _update(delta: float) -> void:
    set_direction()
    calculate_gravity(delta)
    calculate_velocity(speed, direction, PLAYER_MOVEMENT_STATS.in_air_acceleration, delta)

    if velocity.y <= 0:
        finished.emit("Fall")

func jump() -> void:
    velocity.y = jump_velocity
