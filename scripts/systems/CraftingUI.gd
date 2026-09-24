extends Control
class_name CraftingUI
# Scene structure:
# CraftingUI (Control, this script — full rect, starts hidden)
#  └─ Panel
#       ├─ TitleLabel (Label — shows the station's station_name)
#       └─ GridContainer (Columns = 5, same layout idea as InventoryUI/BuildMenuUI)
#            (RecipeSlot instances added here at runtime)
#
# WHY this takes a CraftingStation rather than a fixed recipe list: the
# same CraftingUI is reused for every station type (workbench, a future
# forge, etc.) — it just reads whichever station's available_recipes it
# was opened for, the same way BuildMenuUI reads whichever BuildingData
# list it's configured with.

@export var slot_scene: PackedScene  # RecipeSlot.tscn

@onready var grid: GridContainer = $Panel/GridContainer
@onready var title_label: Label = $Panel/TitleLabel

var crafting_manager: CraftingManager
var inventory: Inventory
var _recipes: Array[RecipeData] = []
var _slot_nodes: Array[RecipeSlot] = []

func _ready() -> void:
	visible = false

# Called by Player.open_crafting_menu() whenever the player interacts with
# a CraftingStation.
func open_for(station: CraftingStation, target_inventory: Inventory) -> void:
	inventory = target_inventory
	crafting_manager = CraftingManager.new(inventory)
	if not inventory.inventory_changed.is_connected(_refresh_affordability):
		inventory.inventory_changed.connect(_refresh_affordability)

	title_label.text = station.station_name
	_recipes = station.available_recipes
	_build_slots()
	visible = true

func close() -> void:
	visible = false

func _build_slots() -> void:
	for child in grid.get_children():
		child.queue_free()
	_slot_nodes.clear()
	for recipe in _recipes:
		var slot: RecipeSlot = slot_scene.instantiate()
		grid.add_child(slot)
		slot.set_recipe(recipe)
		slot.pressed.connect(_on_recipe_selected.bind(recipe))
		_slot_nodes.append(slot)
	_refresh_affordability()

func _refresh_affordability() -> void:
	for i in _recipes.size():
		if i >= _slot_nodes.size():
			break
		_slot_nodes[i].set_affordable(crafting_manager.can_craft(_recipes[i]))

func _on_recipe_selected(recipe: RecipeData) -> void:
	crafting_manager.craft(recipe)
	# Deliberately stays open after crafting — same "keep going" feel as
	# the build menu staying open after placing a wall, so crafting several
	# of one item doesn't mean re-opening the menu each time.
