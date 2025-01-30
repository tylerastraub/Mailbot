extends Area3D

class_name NPCTargetArea

var timer : float = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	$PackageDeliveryMesh.visible = false

func _physics_process(delta: float) -> void:
	$PackageDeliveryMesh.get_active_material(0).albedo_color = Color(0.1 + sin(timer) / 2.0, 1.0, 0.1 + sin(timer) / 2.0, 0.3)
	timer += delta * 5

func _on_body_entered(body: Node3D):
	if body is NPC:
		if body.is_alive and body.nav_target == self:
			SignalManager.npcArrived.emit(body as NPC)

func _on_area_entered(area: Area3D):
	if area is Package:
		if area.destination == self:
			SignalManager.packageDelivered.emit(area)
