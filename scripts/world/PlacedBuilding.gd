extends StaticBody2D
class_name PlacedBuilding
# Base class for anything placed via PlacementManager (walls, crafting
# stations, storage, doors later on). Specific building types should
# extend this (scene inheritance, matching your strategy-game preference)
# rather than duplicating scenes — e.g. a CraftingStation scene inherits
# this and adds its own CraftingManager + interaction behavior.

@export var footprint := Vector2i(1, 1)
@export var health: HealthComponent  # optional — assign in scene if buildings can be destroyed

func get_occupied_cells() -> Array[Vector2i]:
	var top_left := GridManager.world_to_grid(global_position)
	return GridManager.get_footprint_cells(top_left, footprint)

func _exit_tree() -> void:
	# Keep the grid clean if a building is destroyed/removed at runtime.
	GridManager.free_multi(get_occupied_cells())
