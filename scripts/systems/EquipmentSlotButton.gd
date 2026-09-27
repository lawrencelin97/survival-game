extends Button
class_name EquipmentSlotButton
# Unlike InventorySlot (created dynamically, one per storage slot),
# EquipmentSlotButton instances are fixed — one per category, always
# present whether empty or filled, since a category either has something
# equipped or is available to equip into. Pressing an occupied slot
# unequips it back to Inventory (handled by whoever creates these, e.g.
# InventoryUI).

@export var category: ItemData.Category

func set_item(item: ItemData) -> void:
	if item:
		icon = item.icon
		text = item.display_name
	else:
		icon = null
		text = _category_label()

func _category_label() -> String:
	match category:
		ItemData.Category.TOOL:
			return "Tool"
		ItemData.Category.WEAPON:
			return "Weapon"
		ItemData.Category.ARMOR:
			return "Armor"
		ItemData.Category.CLOTHING:
			return "Clothing"
		_:
			return "Slot"
