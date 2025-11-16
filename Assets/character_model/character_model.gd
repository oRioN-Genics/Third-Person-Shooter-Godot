extends Node3D
class_name CharacterModel

@export var animation_tree: AnimationTree
@export var model_scenes: Dictionary = {}
@export var default_model_id: StringName = ""

var current_model: Node3D = null

func _ready() -> void:
	if animation_tree == null:
		animation_tree = $AnimationTree

	if model_scenes.is_empty():
		if has_node("universal_char_model"):
			current_model = $universal_char_model
			_bind_animation_tree()
		else:
			push_warning("model_scenes is empty; runtime model swapping disabled.")
		return
	
	if current_model == null:
		for child in get_children():
			if child == animation_tree:
				continue
			if child is Node3D:
				current_model = child
				break

	set_model(default_model_id)


func set_model(model_id: StringName) -> void:
	if not model_scenes.has(model_id):
		push_warning("Unknown model id: %s" % model_id)
		return

	if current_model != null and is_instance_valid(current_model):
		current_model.queue_free()
		current_model = null

	var scene := model_scenes[model_id] as PackedScene
	if scene == null:
		push_warning("Model '%s' is not a PackedScene" % model_id)
		return

	var instance := scene.instantiate() as Node3D
	if instance == null:
		push_warning("Failed to instantiate model '%s'" % model_id)
		return

	add_child(instance)
	current_model = instance
	current_model.transform = Transform3D.IDENTITY

	_bind_animation_tree()


func _bind_animation_tree() -> void:
	if current_model == null or animation_tree == null:
		return

	var anim_player := current_model.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if anim_player == null:
		push_warning("Current model has no AnimationPlayer node")
		return

	animation_tree.root_node = animation_tree.get_path_to(current_model)
	animation_tree.anim_player = animation_tree.get_path_to(anim_player)


func on_state_machine_animation_state_changed(state: String) -> void:
	animation_tree["parameters/unarmed_movement/transition_request"] = state


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("model_1"):
		set_model("universal")
		print("Swapped to model: universal")

	if Input.is_action_just_pressed("model_2"):
		set_model("alien")
		print("Swapped to model: alien")
