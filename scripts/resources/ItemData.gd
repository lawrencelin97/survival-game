extends Resource
class_name ItemData
# WHY a Resource instead of e.g. a big enum + match statement or a JSON file:
# Same reasoning as UnitLoadout in the strategy game — Resources are
# Inspector-editable (a designer, even future-you, can create a new item by
# right-clicking > New Resource, no code touched), they save as individual
# .tres files you can version-control per-item, and other Resources
# (RecipeData, BuildingData) can reference them directly instead of storing
# fragile string IDs everywhere.

enum Category { RAW_RESOURCE, TOOL, BUILDING_MATERIAL, CONSUMABLE, MISC, WEAPON, ARMOR, CLOTHING }
# WEAPON/ARMOR/CLOTHING are appended at the end, not inserted after TOOL —
# Godot saves an enum's value as a plain integer in .tres files, so
# inserting them earlier would silently shift BUILDING_MATERIAL/CONSUMABLE/
# MISC's saved values on every item resource that already exists.

@export var id: String  # unique string key, e.g. "wood_log" — used for saving
@export var display_name := "Item"
@export var icon: Texture2D
@export var category: Category = Category.RAW_RESOURCE
@export var max_stack := 99
@export_multiline var description := ""
