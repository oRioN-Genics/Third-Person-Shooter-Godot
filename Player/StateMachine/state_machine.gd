extends Node
class_name StateMachine

@export var start_state: State

var state_map: Dictionary
var current_state: State = null
var _active: bool = false:
	set = _set_active

func _ready() -> void:
	_create_state_map()
	_initialize(start_state)


func _input(event: InputEvent) -> void:
	if not _active or current_state == null:
		return
	current_state._state_input(event)


func _physics_process(delta: float) -> void:
	if not _active or current_state == null:
		return
	current_state._update(delta)


func _create_state_map() -> void:
	for child: State in get_children():
		child.finished.connect(_change_state)
		state_map[child.name] = child


func _initialize(state: State) -> void:
	current_state = state
	current_state._enter()


func set_active(active: bool) -> void:
	_set_active(active)


func _set_active(value: bool) -> void:
	if _active == value:
		return
		
	_active = value
	set_physics_process(value)
	set_process_input(value)
	
	if not _active:
		current_state = null


func _change_state(state_name: String) -> void:
	if not _active:
		return

	current_state._exit()
	current_state = state_map[state_name]
	current_state._enter()
