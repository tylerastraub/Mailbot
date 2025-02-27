extends Node3D

class_name Level

@export var NPC_scene : PackedScene
@export var max_npc_count : int = 0

var mailboxes : Array
var mailboxes_closed : int = 0

var npc_target_areas : Array
var alive_npcs : Array

var packages : Array

func _ready() -> void:
	SignalManager.npcArrived.connect(_on_npc_arrived)
	SignalManager.mailboxClosed.connect(_on_mailbox_closed)
	SignalManager.packageDelivered.connect(_on_package_delivered)
	SignalManager.packagePickedUp.connect(_on_package_picked_up)
	npc_target_areas = find_children("*", "NPCTargetArea")
	mailboxes = find_children("*", "Mailbox")
	packages = find_children("*", "Package")
	spawn_npcs()
	set_package_destinations()

func set_tutorial_text(text: String):
	var tutorials : Array = find_children("*", "TutorialWindow")
	for tutorial in tutorials:
		tutorial.set_text(text)

func _physics_process(_delta: float) -> void:
	for npc in alive_npcs:
		if npc.is_alive == false:
			alive_npcs.erase(npc)
	
	spawn_npcs()

func spawn_npcs() -> void:
	if alive_npcs.size() < max_npc_count:
		var spawn_pool : Array = npc_target_areas.duplicate()
		while alive_npcs.size() < max_npc_count:
			var targets : Array = npc_target_areas.duplicate()
			var npc : NPC = NPC_scene.instantiate()
			add_child(npc)
			var spawn : NPCTargetArea = targets.pick_random()
			targets.erase(spawn)
			spawn_pool.erase(spawn)
			var goal : NPCTargetArea = targets.pick_random()
			npc.global_position = spawn.global_position
			npc.set_nav_target(goal)
			alive_npcs.push_back(npc)

func set_package_destinations() -> void:
	for package in packages:
		package.destination = npc_target_areas.pick_random()

func _on_npc_arrived(npc: NPC):
	alive_npcs.erase(npc)
	npc.queue_free()

func _on_mailbox_closed():
	mailboxes_closed += 1
	if mailboxes_closed >= mailboxes.size():
		SignalManager.levelComplete.emit()
		print("level complete")

func _on_package_delivered(package: Package):
	packages.erase(package)
	for target in npc_target_areas:
		target.find_child("PackageDeliveryMesh").visible = false

func _on_package_picked_up(package: Package):
	for target in npc_target_areas:
		if package.destination == target:
			target.find_child("PackageDeliveryMesh").visible = true
		else:
			target.find_child("PackageDeliveryMesh").visible = false
