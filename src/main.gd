extends Node3D

var current_level = 1

const LEVEL_PATHS : Array = [
	"1/level1.tscn"
]

func _ready() -> void:
	SignalManager.connect("levelComplete", _on_level_complete)
	var ui : PackedScene = load("res://src/UI/ui.tscn")
	add_child(ui.instantiate())
	load_level(current_level)

func _input(event: InputEvent) -> void:
	if (Input.mouse_mode != Input.MOUSE_MODE_CAPTURED) and event is InputEventMouseButton: 
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func load_level(level_number: int):
	if level_number < 1 or level_number > LEVEL_PATHS.size():
		return
	var next_level : PackedScene = load("res://res/levels/" + LEVEL_PATHS[level_number - 1])
	$Level.replace_by(next_level.instantiate())

func _on_level_complete():
	current_level += 1
