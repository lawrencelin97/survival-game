extends Resource
class_name BuildingData

@export var id: String
@export var display_name := "Building"
@export var scene: PackedScene  # the PlacedBuilding scene to instantiate
@export var footprint := Vector2i(1, 1)  # cells wide x cells tall
@export var cost: Array[ItemStack] = []
@export var icon: Texture2D
