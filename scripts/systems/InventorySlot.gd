extends Button
class_name InventorySlot
# Changed from a display-only Panel to a Button: clicking a slot holding an
# equip-able item (tool/weapon/armor/clothing) now equips it — see
# InventoryUI._on_inventory_slot_pressed(). Non-equip-able items (raw
# resources, building materials) just do nothing on click for now.

signal slot_pressed(item: ItemData)

var item: ItemData = null
var amount := 0

func _ready() -> void:
	pressed.connect(func(): if item: slot_pressed.emit(item))

func set_slot_data(new_item: ItemData, new_amount: int) -> void:
	item = new_item
	amount = new_amount
	if item == null or amount <= 0:
		icon = null
		text = ""
		return
	icon = item.icon
	text = str(amount) if amount > 1 else ""
