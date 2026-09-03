extends Resource
class_name RecipeData

@export var id: String
@export var output: ItemStack
@export var ingredients: Array[ItemStack] = []
@export var craft_time := 1.0  # seconds
@export var required_station := ""  # empty string = craftable by hand, anywhere
