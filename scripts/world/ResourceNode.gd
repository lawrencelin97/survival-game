extends StaticBody2D
class_name ResourceNode
# Scene structure:
# ResourceNode (StaticBody2D, this script)
#  ├─ Sprite2D
#  ├─ CollisionShape2D  (physical body, blocks movement)
#  ├─ Interactable (Area2D, Interactable.gd — separate, larger hit area)
#  └─ HealthComponent (Node, HealthComponent.gd — max_health = hits to deplete)
#
# One script covers both behaviors you want:
#  - Trees/rocks: drop_directly_to_inventory = false, pickup_scene assigned
#    -> spawns a WorldItemPickup on the ground when depleted.
#  - Crops: drop_directly_to_inventory = true
#    -> goes straight into the harvesting player's Inventory, no pickup_scene needed.

@export var drop_item: ItemData
@export var drop_amount_min := 1
@export var drop_amount_max := 3
@export var damage_per_hit := 1.0
@export var drop_directly_to_inventory := false
@export var pickup_scene: PackedScene  # required when drop_directly_to_inventory is false

@onready var interactable: Interactable = $Interactable
@onready var health: HealthComponent = $HealthComponent

var _last_interactor: Node

func _ready() -> void:
	interactable.interacted.connect(_on_interacted)
	health.died.connect(_on_depleted)

func _on_interacted(interactor: Node) -> void:
	_last_interactor = interactor
	health.take_damage(damage_per_hit)

func _on_depleted() -> void:
	if drop_item:
		var amount := randi_range(drop_amount_min, drop_amount_max)
		if drop_directly_to_inventory:
			_give_to_interactor(drop_item, amount)
		else:
			_spawn_pickup(drop_item, amount)
	queue_free()

func _give_to_interactor(item: ItemData, amount: int) -> void:
	if _last_interactor and _last_interactor.has_node("Inventory"):
		var inventory: Inventory = _last_interactor.get_node("Inventory")
		inventory.add_item(item, amount)

func _spawn_pickup(item: ItemData, amount: int) -> void:
	if not pickup_scene:
		push_warning("ResourceNode '%s' has no pickup_scene assigned — drop lost." % name)
		return
	var pickup := pickup_scene.instantiate()
	pickup.item = item
	pickup.amount = amount
	get_tree().current_scene.add_child(pickup)
	pickup.global_position = global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))
