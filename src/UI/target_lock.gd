extends Control

const MAX_RETICLE_OFFSET : float = 10.0

var reticles : Dictionary

@export var reticle_scene : PackedScene
@export var camera : Camera3D

func _ready() -> void:
	SignalManager.npcTargeting.connect(_on_npc_targeting)
	SignalManager.npcStopTarget.connect(_on_npc_stop_target)
	SignalManager.playerSpawned.connect(_on_player_spawned)

func _on_npc_targeting(npcs: Array) -> void:
	for pair in npcs:
		if pair[1] > 1.0:
			if reticles.has(pair[0]) == false:
				reticles[pair[0]] = reticle_scene.instantiate()
				add_child(reticles[pair[0]])
			var percent : float = (pair[1] - 1.0) / 2.0
			var aabb : AABB = pair[0].find_children("*", "MeshInstance3D").front().get_aabb()
			reticles[pair[0]].adjust_reticle(camera.unproject_position(pair[0].global_position + aabb.get_center()), percent)

func _on_npc_stop_target(npc: NPC) -> void:
	if reticles.has(npc):
		remove_child(reticles[npc])
		reticles[npc].queue_free()
		reticles.erase(npc)

func _on_player_spawned(player: Player):
	camera = player.camera
