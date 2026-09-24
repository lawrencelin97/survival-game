extends Button
class_name RecipeSlot
# Same shape as BuildOptionSlot — a Button using its own built-in icon/text/
# disabled properties rather than child nodes, since there's nothing here
# that needs more than that.

func set_recipe(recipe: RecipeData) -> void:
	icon = recipe.output.item.icon
	text = "%s x%d" % [recipe.output.item.display_name, recipe.output.amount]

func set_affordable(affordable: bool) -> void:
	disabled = not affordable
