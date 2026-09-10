extends Area2D
class_name WorldItemPickup
# Scene structure:
# WorldItemPickup (Area2D, this script)
#  ├─ Sprite2D          (texture set automatically from item.icon)
#  └─ CollisionShape2D  (small radius — this is what detects the player)
#
# WHY body_entered instead of the Interactable/InteractionArea pattern:
# Interactable is for "press E to act on this" (harvest a tree, open a
# door). A dropped log on the ground is the opposite UX — you just walk
# over it and it's collected, no button press. Different enough interaction
# model that reusing Interactable here would fight the pattern rather than
# fit it, so this is its own small self-contained pickup.
#
# Set `item` and `amount` BEFORE adding this to the scene tree (i.e. right
# after instantiate(), before add_child()) so _ready() has real data to
# work with for the sprite.

@export var item: ItemData
@export var amount: int = 1

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if item and item.icon:
		sprite.texture = item.icon
	collision_layer = 0        # pickups don't need to be detected by anything else
	monitoring = true          # this node does the detecting
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.has_node("Inventory"):
		return
	var inventory: Inventory = body.get_node("Inventory")
	var leftover := inventory.add_item(item, amount)
	if leftover <= 0:
		queue_free()
	else:
		# Inventory was full — leave the remainder on the ground instead of
		# silently deleting items the player couldn't actually carry.
		amount = leftover
