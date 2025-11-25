extends Node3D

@export var player_scene: PackedScene
@export var number_of_players: int = 10
@export var local_player_id: int = 1

var players: Array[Player] = []
var players_by_id: Dictionary = {}

func _ready() -> void:
	spawn_players()


func _process(delta: float) -> void:
	simulate_remote_players(delta)


func spawn_players() -> void:
	for p in players:
		p.queue_free()
	players.clear()
	players_by_id.clear()
	remote_ai.clear() ## ##

	for i in range(number_of_players):
		var id := i + 1
		print("Spawning player id=", id)
		var player: Player = player_scene.instantiate()

		player.position = Vector3(1.1 * i, 0, 0)

		var is_local := (id == local_player_id)

		add_child(player)
		player.setup(id, is_local)
		
		players.append(player)
		players_by_id[id] = player

		####
		if not is_local:
			remote_ai[id] = {
				"state": "idle",
				"time_left": 0.0,
				"dir": Vector3.ZERO,
			}


func get_player(id: int) -> Player:
	return players_by_id.get(id, null)


func apply_remote_input_to_player(player_id: int, input_data: Dictionary) -> void:
	var p = get_player(player_id)
	if p:
		p.apply_remote_input(input_data)


# remote players simulation - just for testing
var remote_ai: Dictionary = {} # id -> { state, time_left, dir }

func simulate_remote_players(delta: float) -> void:
	for id in players_by_id.keys():
		if id == local_player_id:
			continue

		var p: Player = players_by_id[id]

		var ai_state = remote_ai.get(id, null)
		if ai_state == null:
			ai_state = {
				"state": "idle",
				"time_left": 0.0,
				"dir": Vector3.ZERO,
			}
			remote_ai[id] = ai_state

		# Decrease timer
		ai_state.time_left -= delta
		if ai_state.time_left <= 0.0:
			# Pick a new behavior
			var r := randf()
			if r < 0.4:
				# Idle
				ai_state.state = "idle"
				ai_state.dir = Vector3.ZERO
				ai_state.time_left = randf_range(0.5, 2.0)
			elif r < 0.85:
				# Run in a random direction
				ai_state.state = "run"
				var angle := randf_range(0.0, TAU)
				ai_state.dir = Vector3(sin(angle), 0.0, cos(angle))
				ai_state.time_left = randf_range(1.0, 3.0)
			else:
				# Jump (quick action)
				ai_state.state = "jump"
				# Keep last dir or stand still; your choice:
				# ai_state.dir = Vector3.ZERO
				ai_state.time_left = randf_range(0.2, 0.5)

		var input_data := {
			"move": ai_state.dir,
			"jump": ai_state.state == "jump",
		}

		p.apply_remote_input(input_data)
