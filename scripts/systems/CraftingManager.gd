extends Node
class_name CraftingManager
# Not an autoload on purpose: crafting rules (which station you're at, if
# any) are contextual to whoever's crafting. Instantiate one on the player
# for hand-crafting, and optionally one per crafting station later. Both
# just need a reference to the player's Inventory.

signal crafted(recipe: RecipeData)
signal craft_failed(recipe: RecipeData, reason: String)

var inventory: Inventory

func _init(inv: Inventory = null) -> void:
	inventory = inv

func can_craft(recipe: RecipeData) -> bool:
	return inventory != null and inventory.has_all(recipe.ingredients)

# Instant craft for the foundation — wrap this in a Timer using
# recipe.craft_time once you want crafting to take real time.
func craft(recipe: RecipeData) -> bool:
	if not can_craft(recipe):
		craft_failed.emit(recipe, "missing_ingredients")
		return false
	inventory.remove_all(recipe.ingredients)
	inventory.add_item(recipe.output.item, recipe.output.amount)
	crafted.emit(recipe)
	return true
