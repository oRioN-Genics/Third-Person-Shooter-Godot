extends Node3D

@export var player_scene: PackedScene
@export var number_of_players: int = 2

var players: Array = []

func _ready() -> void:
	spawn_players()


func spawn_players() -> void:
	for p in players:
		p.queue_free()
	players.clear()

	for i in range(number_of_players):
		var player: CharacterBody3D = player_scene.instantiate()

		player.position = Vector3(2 * i, 0, 0)

		player.is_local_player = (i == 1)

		add_child(player)
		players.append(player)
