extends PlacedBuilding
class_name StorageChest
# Scene structure (on top of what PlacedBuilding needs):
# StorageChest (StaticBody2D, PlacedBuilding + this script)
#  ├─ Sprite2D
#  ├─ CollisionShape2D
#  ├─ Interactable (Area2D, Interactable.gd)
#  └─ Inventory (Node, Inventory.gd — set slot_count to the chest's capacity)
#
# WHY the chest just owns an Inventory node instead of a bespoke storage
# class: Inventory was built as a standalone component specifically so
# things other than the player could reuse it. The chest is the first
# thing to do that — all the stacking/add/remove logic already exists.

@export var chest_name := "Storage Chest"

@onready var interactable: Interactable = $Interactable
@onready var storage: Inventory = $Inventory

func _ready() -> void:
	super._ready()
	if is_ghost:
		return
	interactable.interacted.connect(_on_interacted)

func _on_interacted(interactor: Node) -> void:
	if interactor.has_method("open_storage_menu"):
		interactor.open_storage_menu(self)
