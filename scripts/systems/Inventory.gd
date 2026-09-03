extends Node
class_name Inventory
# Attach as a child of the Player. Kept separate from Player.gd itself so
# crafting stations, storage chests, or trade later on can reuse the exact
# same class instead of the player script owning inventory logic directly.

signal inventory_changed

@export var slot_count := 20

# Each slot: { "item": ItemData, "amount": int }. Empty slots are left out
# of the array conceptually but we keep fixed-size for a simple grid UI —
# empty slot = { "item": null, "amount": 0 }.
var slots: Array[Dictionary] = []

func _ready() -> void:
	slots.resize(slot_count)
	for i in slot_count:
		slots[i] = {"item": null, "amount": 0}

# Returns the amount that did NOT fit (0 if everything was added).
func add_item(item: ItemData, amount: int) -> int:
	var remaining := amount

	# First pass: top up existing partial stacks of the same item.
	for slot in slots:
		if remaining <= 0:
			break
		if slot.item == item and slot.amount < item.max_stack:
			var space: int = item.max_stack - slot.amount
			var add: int = min(space, remaining)
			slot.amount += add
			remaining -= add

	# Second pass: fill empty slots.
	for slot in slots:
		if remaining <= 0:
			break
		if slot.item == null:
			var add: int = min(item.max_stack, remaining)
			slot.item = item
			slot.amount = add
			remaining -= add

	if remaining < amount:
		inventory_changed.emit()
	return remaining

func has_item(item: ItemData, amount: int) -> bool:
	return count_item(item) >= amount

func count_item(item: ItemData) -> int:
	var total := 0
	for slot in slots:
		if slot.item == item:
			total += slot.amount
	return total

# Returns true if it successfully removed the full amount (all-or-nothing —
# check has_item first if you need to guard against partial removal).
func remove_item(item: ItemData, amount: int) -> bool:
	if not has_item(item, amount):
		return false
	var remaining := amount
	for slot in slots:
		if remaining <= 0:
			break
		if slot.item == item:
			var take: int = min(slot.amount, remaining)
			slot.amount -= take
			remaining -= take
			if slot.amount <= 0:
				slot.item = null
				slot.amount = 0
	inventory_changed.emit()
	return true

func has_all(costs: Array[ItemStack]) -> bool:
	for stack in costs:
		if not has_item(stack.item, stack.amount):
			return false
	return true

func remove_all(costs: Array[ItemStack]) -> void:
	for stack in costs:
		remove_item(stack.item, stack.amount)
