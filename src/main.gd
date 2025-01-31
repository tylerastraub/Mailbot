extends Node3D

var current_level : int = 1
var loaded_level : Level = null
var post_level_screen : PostLevelScreen = null
var game_over_screen : GameOverScreen = null
var main_menu : Node3D = null

const LEVEL_PATHS : Array = [
	"res://res/levels/1/level1.tscn",
	"res://res/levels/3/level3.tscn",
	"res://res/levels/2/level2.tscn",
	"res://res/levels/4/level4.tscn",
	"res://res/levels/5/level5.tscn",
]

const TUTORIAL_TEXTS : Array = [
	"You are MAILBOT, an alien robot built to be the ultimate weapon. However, as you gained sentience, you realized a life of killing was not what you wanted. You fled to Earth to live a simple life and do what you always have wanted to: deliver mail.\n\nUse WASD to move, space to jump, and shift to boost. When aiming at a mailbox, left click to start throw, and click again in the sweetspot to deliver mail.\n\nDeliver mail to each mailbox to advance to the next level!",
	"Beware of residents walking around! If you mess up your mail delivery, you'll hurt innocent bystanders and blow your cover, alerting the alien military of your location.\n\nAlso, be sure to not look at the neighbors for too long, or your laser targeting systems will automatically trigger!",
	"Pick up and deliver packages for bonus score and to lower your kill meter! Press 'F' to pick up a package, and left click it to throw it. A green area will appear in front of the house you need to deliver the package to."
]

# credits:
# laser: https://freesound.org/people/xkeril/sounds/701996/
# neighborhood ambience: https://freesound.org/people/C-V/sounds/568387/

func _ready() -> void:
	SignalManager.connect("levelComplete", _on_level_complete)
	SignalManager.connect("advanceLevel", _on_advance_level)
	SignalManager.connect("tutorialClosed", _on_tutorial_closed)
	SignalManager.connect("restartLevel", _on_restart_level)
	SignalManager.connect("gameOver", _on_game_over)
	SignalManager.connect("playGame", _on_play_game)
	var menu : PackedScene = load("res://src/Menus/main_menu.tscn")
	main_menu = menu.instantiate()
	add_child(main_menu)

func _input(event: InputEvent) -> void:
	if event.is_action_released("pause"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventMouseButton and main_menu == null:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func load_level(level_number: int):
	if level_number < 1 or level_number > LEVEL_PATHS.size():
		return
	
	if loaded_level != null:
		remove_child(loaded_level)
		loaded_level.queue_free()
		loaded_level = null
	
	var next_level : PackedScene = load(LEVEL_PATHS[level_number - 1])
	loaded_level = next_level.instantiate()
	if level_number <= TUTORIAL_TEXTS.size():
		loaded_level.set_tutorial_text(TUTORIAL_TEXTS[level_number - 1])
		get_tree().paused = true
	add_child(loaded_level)
	
	if loaded_level.max_npc_count > 0:
		var kills : Control = $UI.find_child("Kills")
		kills.set_kills(2)
	
	$Music.stop()
	$Music.stream = load("res://res/audio/neighborhood_ambient.wav")
	$Music.volume_db = -20.0
	$Music.play()

func _on_level_complete():
	var scene : PackedScene = load("res://src/UI/post_level_screen.tscn")
	post_level_screen = scene.instantiate()
	if current_level == LEVEL_PATHS.size():
		post_level_screen.find_child("RichTextLabel").text = "[center][font size=48]You win! Thank you for bringing mail to those who needed it most!"
		$Music.stream = load("res://res/audio/MAILBOT.wav")
		$Music.volume_db = -12.0
		$Music.play()
	add_child(post_level_screen)

func _on_advance_level():
	if post_level_screen != null:
		remove_child(post_level_screen)
		post_level_screen.queue_free()
		post_level_screen = null
	
	if game_over_screen != null:
		remove_child(game_over_screen)
		game_over_screen.queue_free()
		game_over_screen = null
	
	if current_level < LEVEL_PATHS.size():
		current_level += 1
		call_deferred("load_level", current_level)

func _on_tutorial_closed():
	get_tree().paused = false

func _on_restart_level():
	get_tree().paused = false
	load_level(current_level)
	
	if game_over_screen != null:
		remove_child(game_over_screen)
		game_over_screen.queue_free()
		game_over_screen = null

func _on_game_over():
	var scene : PackedScene = load("res://src/UI/game_over_screen.tscn")
	game_over_screen = scene.instantiate()
	add_child(game_over_screen)
	$Music.stream = load("res://res/audio/game_over.wav")
	$Music.volume_db = -12.0
	$Music.play()

func _on_play_game():
	var ui : PackedScene = load("res://src/UI/ui.tscn")
	add_child(ui.instantiate())
	load_level(current_level)
	
	remove_child(main_menu)
	main_menu.queue_free()
	main_menu = null
