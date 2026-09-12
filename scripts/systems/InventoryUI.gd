extends Control
class_name InventoryUI
# Scene structure:
# InventoryUI (Control, this script — set to full rect, start hidden)
#  └─ Panel
#       └─ GridContainer (Columns = 5, matching the mockup layout)
#            (InventorySlot instances added here at runtime)
#
# WHY this reads from Inventory via a signal instead of polling every frame:
# Inventory already emits `inventory_changed` whenever slots are added to or
# removed from. Connecting to that means the UI only redraws on actual
# change, and — more importantly — it means InventoryUI never needs its own
# copy of inventory state; it's a pure reflection of Inventory.slots.

@export var slot_scene: PackedScene  # InventorySlot.tscn

@onready var grid: GridContainer = $Panel/GridContainer

var inventory: Inventory
var _slot_nodes: Array[InventorySlot] = []

func _ready() -> void:
	visible = false

func open_for(target_inventory: Inventory) -> void:
	inventory = target_inventory
	if not inventory.inventory_changed.is_connected(_refresh):
		inventory.inventory_changed.connect(_refresh)
	_build_slots()
	_refresh()

func _build_slots() -> void:
	for child in grid.get_children():
		child.queue_free()
	_slot_nodes.clear()
	for i in inventory.slots.size():
		var slot: InventorySlot = slot_scene.instantiate()
		grid.add_child(slot)
		_slot_nodes.append(slot)

func _refresh() -> void:
	for i in inventory.slots.size():
		if i >= _slot_nodes.size():
			break
		var data: Dictionary = inventory.slots[i]
		_slot_nodes[i].set_slot_data(data.item, data.amount)

func toggle() -> void:
	visible = not visible
	if visible:
		_refresh()  # catch up on anything that changed while closed
