extends Node3D

@export var player_scene: PackedScene
@export var number_of_players: int = 4
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


func get_player(id: int) -> Player:
	return players_by_id.get(id, null)


func apply_remote_input_to_player(player_id: int, input_data: Dictionary) -> void:
	var p = get_player(player_id)
	if p:
		p.apply_remote_input(input_data)


func simulate_remote_players(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0

	for id in players_by_id.keys():
		if id == local_player_id:
			continue

		var p = players_by_id[id]

		var dir := Vector3(
			sin(t + float(id)),
			0.0,
			cos(t + float(id))
		)

		var input_data := {
			"move": dir
		}

		p.apply_remote_input(input_data)
