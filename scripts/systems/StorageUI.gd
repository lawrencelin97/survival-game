extends Control
class_name StorageUI
# Scene structure:
# StorageUI (Control, this script — full rect, starts hidden)
#  └─ Panel
#       ├─ TitleLabel (Label — shows the chest's name)
#       ├─ ChestGrid (GridContainer, Columns = 5 — the chest's contents)
#       └─ PlayerGrid (GridContainer, Columns = 5 — the player's inventory)
#
# Clicking a stack in the player grid moves it into the chest; clicking a
# stack in the chest grid moves it back. Both grids are just views of an
# Inventory, refreshed off inventory_changed like InventoryUI does.

@export var slot_scene: PackedScene  # StorageSlot.tscn

@onready var title_label: Label = $Panel/TitleLabel
@onready var chest_grid: GridContainer = $Panel/ChestGrid
@onready var player_grid: GridContainer = $Panel/PlayerGrid

var chest_inventory: Inventory
var player_inventory: Inventory
var _chest_slots: Array[StorageSlot] = []
var _player_slots: Array[StorageSlot] = []

func _ready() -> void:
	visible = false

func open_for(chest: StorageChest, target_player_inventory: Inventory) -> void:
	_disconnect_signals()  # in case another chest was still open
	chest_inventory = chest.storage
	player_inventory = target_player_inventory
	chest_inventory.inventory_changed.connect(_refresh)
	player_inventory.inventory_changed.connect(_refresh)

	title_label.text = chest.chest_name
	_build_slots(chest_grid, chest_inventory, _chest_slots, _on_chest_slot_pressed)
	_build_slots(player_grid, player_inventory, _player_slots, _on_player_slot_pressed)
	_refresh()
	visible = true

func close() -> void:
	_disconnect_signals()
	visible = false

func _disconnect_signals() -> void:
	if is_instance_valid(chest_inventory) and chest_inventory.inventory_changed.is_connected(_refresh):
		chest_inventory.inventory_changed.disconnect(_refresh)
	if is_instance_valid(player_inventory) and player_inventory.inventory_changed.is_connected(_refresh):
		player_inventory.inventory_changed.disconnect(_refresh)

func _build_slots(grid: GridContainer, source: Inventory, slot_nodes: Array[StorageSlot], handler: Callable) -> void:
	for child in grid.get_children():
		child.queue_free()
	slot_nodes.clear()
	for i in source.slots.size():
		var slot: StorageSlot = slot_scene.instantiate()
		grid.add_child(slot)
		slot.slot_pressed.connect(handler)
		slot_nodes.append(slot)

func _refresh() -> void:
	# The chest can be demolished while its menu is open — its Inventory
	# is freed with it, so close instead of reading from a dead node.
	if not is_instance_valid(chest_inventory):
		close()
		return
	_fill(_chest_slots, chest_inventory)
	_fill(_player_slots, player_inventory)

func _fill(slot_nodes: Array[StorageSlot], source: Inventory) -> void:
	for i in mini(slot_nodes.size(), source.slots.size()):
		var data: Dictionary = source.slots[i]
		slot_nodes[i].set_slot_data(data.item, data.amount)

func _on_player_slot_pressed(item: ItemData, amount: int) -> void:
	_transfer(item, amount, player_inventory, chest_inventory)

func _on_chest_slot_pressed(item: ItemData, amount: int) -> void:
	_transfer(item, amount, chest_inventory, player_inventory)

# Adds to the destination first and only removes what actually fit, so a
# full destination leaves the rest where it was instead of deleting it.
func _transfer(item: ItemData, amount: int, from: Inventory, to: Inventory) -> void:
	var leftover := to.add_item(item, amount)
	var moved := amount - leftover
	if moved > 0:
		from.remove_item(item, moved)
