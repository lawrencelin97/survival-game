extends StaticBody2D
class_name OreDeposit
# Scene structure:
# OreDeposit (StaticBody2D, this script)
#  ├─ Sprite2D
#  ├─ CollisionShape2D  (physical body, blocks movement — same as ResourceNode)
#  └─ Interactable (Area2D, Interactable.gd — same component your trees use)
#
# WHY this isn't a variant of ResourceNode: ResourceNode is built entirely
# around depleting and disappearing (HealthComponent, _on_depleted ->
# queue_free). This models Factorio's oil wells instead — a fixed place you
# interact with that yields a resource indefinitely. No health, no
# richness multiplier, no destruction — there's no depleting behavior to
# share with ResourceNode, so this is simpler, not derived from it.
#
# Since this reuses the same Interactable component trees do, no changes
# to Player.gd are needed — _try_interact() already handles anything in
# the "interactables" group.

@export var yield_item: ItemData
@export var yield_amount := 1

@onready var interactable: Interactable = $Interactable

func _ready() -> void:
	interactable.interacted.connect(_on_interacted)

func _on_interacted(interactor: Node) -> void:
	if not interactor.has_node("Inventory"):
		return
	var inventory: Inventory = interactor.get_node("Inventory")
	inventory.add_item(yield_item, yield_amount)
