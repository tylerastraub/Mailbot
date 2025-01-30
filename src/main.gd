extends Node3D

var current_level : int = 2
var loaded_level : Level = null

const LEVEL_PATHS : Array = [
	"res://res/levels/1/level1.tscn",
	"res://res/levels/2/level2.tscn",
	"res://res/levels/3/level3.tscn"
]

# todo:
#- create more levels introducing mechanics
#    - level4: more complex level with more packages
#    - level5: final level, a lot of npcs
#- add in game screen for explaining mechanics
#    - level1: movement and throwing
#    - level2: packages
#    - level3: npcs
#- add score system, kill counter, and corresponding UI for both
#- all sound + music
#- main menu + game over screen
#- polishing or whatever

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
	
	if loaded_level != null:
		remove_child(loaded_level)
		loaded_level.queue_free()
	
	var next_level : PackedScene = load(LEVEL_PATHS[level_number - 1])
	loaded_level = next_level.instantiate()
	add_child(loaded_level)

func _on_level_complete():
	current_level += 1
	call_deferred("load_level", current_level)
