extends StaticBody2D
class_name ResourceNode
# Scene structure:
# ResourceNode (StaticBody2D, this script)
#  ├─ Sprite2D
#  ├─ CollisionShape2D  (physical body, blocks movement)
#  ├─ Interactable (Area2D, Interactable.gd — separate, larger hit area)
#  └─ HealthComponent (Node, HealthComponent.gd — max_health = hits to deplete)
#
# WHY it "dies" via HealthComponent instead of a simple counter: this keeps
# resource nodes consistent with everything else in the game that can be
# damaged (player, later on: enemies, buildings under attack). One damage
# pipeline, reused everywhere, same as your strategy game's components.

@export var drop_item: ItemData
@export var drop_amount_min := 1
@export var drop_amount_max := 3
@export var damage_per_hit := 1.0

@onready var interactable: Interactable = $Interactable
@onready var health: HealthComponent = $HealthComponent

func _ready() -> void:
	interactable.interacted.connect(_on_interacted)
	health.died.connect(_on_depleted)

func _on_interacted(interactor: Node) -> void:
	health.take_damage(damage_per_hit)
	print("hi")

func _on_depleted() -> void:
	if drop_item:
		var amount := randi_range(drop_amount_min, drop_amount_max)
		# Look for an Inventory on whoever last interacted — simplest is to
		# have the player check `has_method` or just grab their Inventory
		# child directly if you always know it's the player harvesting.
		# Left generic here since drops may later spawn as world pickups
		# instead of going straight to inventory.
		_spawn_drop(drop_item, amount)
	queue_free()

func _spawn_drop(item: ItemData, amount: int) -> void:
	# Placeholder — for the foundation, we just print. Swap this for
	# instancing a WorldItemPickup scene once you have one, or for directly
	# calling inventory.add_item() if you pass the interactor's Inventory
	# through instead.
	print("Dropped %d x %s" % [amount, item.display_name])
