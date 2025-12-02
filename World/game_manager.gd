extends Node3D

@export var player_scene: PackedScene
@export var number_of_players: int = 50
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

		player.position = Vector3(2 * i, 0, 0)

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
				"target_dir": Vector3.ZERO,
				"jump_queued": false,
				"sprint": false,
			}


func get_player(id: int) -> Player:
	return players_by_id.get(id, null)


func apply_remote_input_to_player(player_id: int, input_data: Dictionary) -> void:
	var p = get_player(player_id)
	if p:
		p.apply_remote_input(input_data)


# remote players simulation
var remote_ai: Dictionary = {}

func simulate_remote_players(delta: float) -> void:
	for id in players_by_id.keys():
		if id == local_player_id:
			continue

		var p: Player = players_by_id[id]

		var ai_state: Dictionary = remote_ai.get(id, {})
		if ai_state.is_empty():
			ai_state = {
				"state": "idle",
				"time_left": 0.0,
				"dir": Vector3.ZERO,
				"target_dir": Vector3.ZERO,
				"jump_queued": false,
				"sprint": false,
			}
			remote_ai[id] = ai_state

		ai_state["time_left"] -= delta
		if ai_state["time_left"] <= 0.0:
			var r := randf()
			if r < 0.4:
				ai_state["state"] = "idle"
				ai_state["target_dir"] = Vector3.ZERO
				ai_state["time_left"] = randf_range(0.5, 2.0)
				ai_state["jump_queued"] = false
				ai_state["sprint"] = false

			elif r < 0.7:
				ai_state["state"] = "run"
				var angle := randf_range(0.0, TAU)
				ai_state["target_dir"] = Vector3(sin(angle), 0.0, cos(angle))
				ai_state["time_left"] = randf_range(1.0, 3.0)
				ai_state["jump_queued"] = false
				ai_state["sprint"] = false

			elif r < 0.9:
				ai_state["state"] = "sprint"
				var angle2 := randf_range(0.0, TAU)
				ai_state["target_dir"] = Vector3(sin(angle2), 0.0, cos(angle2))
				ai_state["time_left"] = randf_range(0.8, 2.0)
				ai_state["jump_queued"] = false
				ai_state["sprint"] = true

			else:
				ai_state["state"] = "sprint"
				ai_state["time_left"] = randf_range(0.4, 1.0)
				ai_state["jump_queued"] = true
				ai_state["sprint"] = true

				if ai_state["target_dir"] == Vector3.ZERO:
					var angle3 := randf_range(0.0, TAU)
					ai_state["target_dir"] = Vector3(sin(angle3), 0.0, cos(angle3))

		var lerp_factor := 0.12
		var current_dir: Vector3 = ai_state["dir"]
		var target_dir: Vector3 = ai_state["target_dir"]
		ai_state["dir"] = current_dir.lerp(target_dir, lerp_factor)

		var do_jump: bool = ai_state["jump_queued"]
		ai_state["jump_queued"] = false

		var input_data := {
			"move": ai_state["dir"],
			"jump": do_jump,
			"sprint": ai_state.get("sprint", false),
		}

		p.apply_remote_input(input_data)
