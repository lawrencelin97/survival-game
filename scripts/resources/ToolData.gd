extends ItemData
class_name ToolData
# A tool is an equip-able item (category should be set to TOOL) that also
# carries a harvest_tag matching whichever ResourceNodes it's meant to work
# with — "wood" for an axe, "stone" for a pickaxe. Adding a new tool later
# is just a new ToolData resource with a different tag; no ResourceNode or
# EquipmentSlots changes needed for the tag-matching itself.

@export var harvest_tag := ""
