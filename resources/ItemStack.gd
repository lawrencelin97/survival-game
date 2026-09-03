extends Resource
class_name ItemStack
# A tiny (item, amount) pair. Recipes and building costs are both just
# "a list of these" — pulling it into its own Resource means RecipeData and
# BuildingData can share the exact same array type instead of each rolling
# their own parallel-array or Dictionary scheme.

@export var item: ItemData
@export var amount: int = 1
