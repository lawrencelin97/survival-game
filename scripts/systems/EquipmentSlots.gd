extends Node
class_name EquipmentSlots
# Attach as a child of the Player, alongside Inventory. This is deliberately
# separate from Inventory, not a variant of it: equipment is one item per
# category, never stacked, and actively queried by other systems ("does the
# player have an axe equipped") rather than just carried.
#
# WHY keyed by ItemData.Category rather than fixed named slot variables
# (tool_slot, weapon_slot, ...): using the category the item already
# declares means a new equip-able category later (armor, clothing) doesn't
# need a new slot variable added here — the same Dictionary just gains a
# new key the first time something of that category is equipped.

signal equipment_changed(category: ItemData.Category, item: ItemData)

var equipped: Dictionary = {}  # ItemData.Category -> ItemData

func equip(item: ItemData) -> void:
	equipped[item.category] = item
	equipment_changed.emit(item.category, item)

func unequip(category: ItemData.Category) -> void:
	equipped.erase(category)
	equipment_changed.emit(category, null)

func get_equipped(category: ItemData.Category) -> ItemData:
	return equipped.get(category, null)

# Convenience for gameplay checks like "can this player chop this tree" —
# ResourceNode uses this rather than reaching into equipped directly.
func has_tool_with_tag(tag: String) -> bool:
	var tool: ItemData = get_equipped(ItemData.Category.TOOL)
	return tool is ToolData and tool.harvest_tag == tag
