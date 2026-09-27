extends Control
class_name InventoryUI
# Scene structure:
# InventoryUI (Control, this script — set to full rect, start hidden)
#  └─ Panel
#       ├─ EquipmentGrid (GridContainer — one fixed EquipmentSlotButton per category)
#       └─ GridContainer (Columns = 5 — dynamically populated InventorySlot instances)
#
# WHY equipment slots live in the same panel as storage rather than a
# separate window: equipping is fundamentally "move an item from one of
# these slots to one of those slots" — keeping both grids in one screen is
# what makes click-to-equip/click-to-unequip make sense as a single
# interaction, the same way most inventory+equipment screens work.

@export var inventory_slot_scene: PackedScene  # InventorySlot.tscn
@export var equipment_slot_scene: PackedScene  # EquipmentSlotButton.tscn
@export var equipment_categories: Array[ItemData.Category] = [
	ItemData.Category.TOOL, ItemData.Category.WEAPON,
	ItemData.Category.ARMOR, ItemData.Category.CLOTHING,
]

@onready var inventory_grid: GridContainer = $Panel/InventoryGrid
@onready var equipment_grid: GridContainer = $Panel/EquipmentGrid

var inventory: Inventory
var equipment: EquipmentSlots
var _slot_nodes: Array[InventorySlot] = []
var _equipment_slot_nodes: Dictionary = {}  # ItemData.Category -> EquipmentSlotButton

func _ready() -> void:
	visible = false

func open_for(target_inventory: Inventory, target_equipment: EquipmentSlots) -> void:
	inventory = target_inventory
	equipment = target_equipment
	if not inventory.inventory_changed.is_connected(_refresh):
		inventory.inventory_changed.connect(_refresh)
	if not equipment.equipment_changed.is_connected(_on_equipment_changed):
		equipment.equipment_changed.connect(_on_equipment_changed)
	_build_equipment_slots()
	_build_slots()
	_refresh()

func _build_equipment_slots() -> void:
	for child in equipment_grid.get_children():
		child.queue_free()
	_equipment_slot_nodes.clear()
	for category in equipment_categories:
		var slot: EquipmentSlotButton = equipment_slot_scene.instantiate()
		slot.category = category
		equipment_grid.add_child(slot)
		slot.pressed.connect(_on_equipment_slot_pressed.bind(category))
		slot.set_item(equipment.get_equipped(category))
		_equipment_slot_nodes[category] = slot

func _build_slots() -> void:
	for child in inventory_grid.get_children():
		child.queue_free()
	_slot_nodes.clear()
	for i in inventory.slots.size():
		var slot: InventorySlot = inventory_slot_scene.instantiate()
		inventory_grid.add_child(slot)
		slot.slot_pressed.connect(_on_inventory_slot_pressed)
		_slot_nodes.append(slot)

func _refresh() -> void:
	for i in inventory.slots.size():
		if i >= _slot_nodes.size():
			break
		var data: Dictionary = inventory.slots[i]
		_slot_nodes[i].set_slot_data(data.item, data.amount)

func _on_equipment_changed(category: ItemData.Category, item: ItemData) -> void:
	if _equipment_slot_nodes.has(category):
		_equipment_slot_nodes[category].set_item(item)

# Clicking a storage slot holding an equip-able item moves it into that
# category's equipment slot, swapping back whatever was equipped there (if
# anything) into storage.
func _on_inventory_slot_pressed(item: ItemData) -> void:
	if not equipment_categories.has(item.category):
		return  # raw resources, building materials, etc. — not equip-able
	if not inventory.remove_item(item, 1):
		return
	var previous := equipment.get_equipped(item.category)
	equipment.equip(item)
	if previous:
		inventory.add_item(previous, 1)

# Clicking a filled equipment slot unequips it back into storage.
func _on_equipment_slot_pressed(category: ItemData.Category) -> void:
	var item := equipment.get_equipped(category)
	if item == null:
		return
	equipment.unequip(category)
	inventory.add_item(item, 1)

func toggle() -> void:
	visible = not visible
	if visible:
		_refresh()  # catch up on anything that changed while closed
