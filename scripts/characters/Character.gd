extends CharacterBody2D
class_name Character
# Shared base for anything that acts like a person in this game. Holds the
# components any character needs (carrying items, wearing equipment,
# having health) and the primitive actions both input-driven (Player) and
# AI-driven (Villager) characters perform the same way: moving toward a
# point, and interacting with an Interactable. Player adds keyboard/mouse
# input and UI wiring on top; Villager adds an AI job loop on top. Neither
# duplicates the components or these two primitives.

@export var speed := 100.0
@export var work_rate := 5.0  # units of construction work applied per second while building (see ConstructionSite.apply_work)

@onready var interaction_area: Area2D = $InteractionArea
@onready var inventory: Inventory = $Inventory
@onready var equipment: EquipmentSlots = $EquipmentSlots
@onready var health: HealthComponent = $HealthComponent

func move_toward_point(target: Vector2, _delta: float) -> void:
	var to_target := target - global_position
	if to_target.length() <= 2.0:
		velocity = Vector2.ZERO
	else:
		velocity = to_target.normalized() * speed
	move_and_slide()

func interact_with(target: Interactable) -> void:
	target.interact(self)

func find_nearest_interactable() -> Interactable:
	var nearest: Interactable = null
	var nearest_dist := INF
	for area in interaction_area.get_overlapping_areas():
		if area is Interactable:
			var dist := global_position.distance_squared_to(area.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = area
	return nearest
