extends Button
class_name StorageSlot
# A Button (not a display-only Panel like InventorySlot) because clicking a
# slot in the storage menu is what moves that stack to the other side.

signal slot_pressed(item: ItemData, amount: int)

var item: ItemData = null
var amount := 0

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if item:
		slot_pressed.emit(item, amount)

func set_slot_data(new_item: ItemData, new_amount: int) -> void:
	item = new_item
	amount = new_amount
	if item == null or amount <= 0:
		icon = null
		text = ""
		return
	icon = item.icon
	text = str(amount) if amount > 1 else ""
