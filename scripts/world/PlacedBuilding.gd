extends StaticBody2D
class_name PlacedBuilding
# Base class for anything placed via PlacementManager (walls, crafting
# stations, storage, doors later on). Specific building types should
# extend this (scene inheritance, matching your strategy-game preference)
# rather than duplicating scenes — e.g. a CraftingStation scene inherits
# this and adds its own CraftingManager + interaction behavior.

@export var footprint := Vector2i(1, 1)
@export var health: HealthComponent  # optional — assign in scene if buildings can be destroyed
@export var is_room_boundary := false  # true for walls/doors — RoomManager treats these cells as enclosing edges
@export var is_ghost := false  # true only for PlacementManager's preview instance — skips all real side effects below

func get_occupied_cells() -> Array[Vector2i]:
	var top_left := GridManager.world_to_grid(global_position)
	return GridManager.get_footprint_cells(top_left, footprint)

func _ready() -> void:
	if is_ghost:
		return
	if is_room_boundary:
		# Registering directly here (rather than RoomManager rescanning
		# GridManager's full occupant list) keeps room recalculation cost
		# tied to wall count, not total map object count.
		RoomManager.register_wall_cells(get_occupied_cells())
		RoomManager.request_recalculate()

func _exit_tree() -> void:
	if is_ghost:
		return
	# Keep the grid clean if a building is destroyed/removed at runtime.
	GridManager.free_multi(get_occupied_cells())
	if is_room_boundary:
		RoomManager.unregister_wall_cells(get_occupied_cells())
		RoomManager.request_recalculate()
