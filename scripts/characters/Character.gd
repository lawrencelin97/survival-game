extends CharacterBody2D
class_name Character
# Shared base for anything that acts like a person in this game. Holds the
# components any character needs (carrying items, wearing equipment,
# having health) and the primitive actions both input-driven (Player) and
# AI-driven (Villager) characters perform the same way: moving toward a
# point, and interacting with an Interactable. Player adds keyboard/mouse
# input and UI wiring on top; Villager adds an AI job loop on top. Neither
# duplicates the components or these two primitives.
#
# Scene structure expected on anything extending this:
# (CharacterBody2D, this script or a script extending it)
#  ├─ Sprite2D / AnimatedSprite2D
#  ├─ CollisionShape2D
#  ├─ InteractionArea (Area2D, larger radius than the body collider)
#  │    └─ CollisionShape2D
#  ├─ Inventory (Node, Inventory.gd)
#  ├─ EquipmentSlots (Node, EquipmentSlots.gd)
#  └─ HealthComponent (Node, HealthComponent.gd)

@export var speed := 120.0

@onready var interaction_area: Area2D = $InteractionArea
@onready var inventory: Inventory = $Inventory
@onready var equipment: EquipmentSlots = $EquipmentSlots
@onready var health: HealthComponent = $HealthComponent

# Moves toward a world position this frame using ordinary CharacterBody2D
# movement — the same call Player's keyboard input and Villager's AI both
# end up making, just fed a different direction each frame.
func move_toward_point(target: Vector2, _delta: float) -> void:
	var to_target := target - global_position
	if to_target.length() <= 2.0:  # close enough — avoid jittering right at the destination
		velocity = Vector2.ZERO
	else:
		velocity = to_target.normalized() * speed
	move_and_slide()

func interact_with(target: Interactable) -> void:
	target.interact(self)

# Finds the nearest Interactable currently overlapping this character's
# InteractionArea. Player uses this for "press E on whatever's nearby";
# Villager doesn't need it (it interacts with a specific known job target
# instead), but it's shared here since it's a generic Character capability.
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
