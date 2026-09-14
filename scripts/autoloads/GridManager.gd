extends Node
# Autoload as "GridManager" (Project Settings > Autoload)
#
# WHY an autoload singleton instead of a per-scene node:
# Both the placement system (building) and the AI/pathing/harvesting systems
# later on need a single shared source of truth for "what occupies this cell".
# Making it global avoids passing references down through Player -> Placement
# -> World every time, and matches your TeamManager pattern from the strategy
# game (global systems as autoloads, per-instance logic on the nodes themselves).

const CELL_SIZE := 32  # pixels per grid cell — tune to your tile art

# cell (Vector2i) -> occupying node. Presence in this dict means "blocked".
var _occupied: Dictionary = {}


func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(floori(world_pos.x / CELL_SIZE), floori(world_pos.y / CELL_SIZE))


func grid_to_world(cell: Vector2i) -> Vector2:
	# Returns the CENTER of the cell, which is what you want for snapping
	# a sprite's position (assuming centered pivot).
	return Vector2(cell.x * CELL_SIZE + CELL_SIZE / 2.0, cell.y * CELL_SIZE + CELL_SIZE / 2.0)


func is_cell_free(cell: Vector2i) -> bool:
	return not _occupied.has(cell)


func are_cells_free(cells: Array[Vector2i]) -> bool:
	for cell in cells:
		if not is_cell_free(cell):
			return false
	return true


func occupy(cell: Vector2i, node: Node) -> void:
	_occupied[cell] = node
	

func occupy_multi(cells: Array[Vector2i], node: Node) -> void:
	for cell in cells:
		occupy(cell, node)


func free_cell(cell: Vector2i) -> void:
	_occupied.erase(cell)


func free_multi(cells: Array[Vector2i]) -> void:
	for cell in cells:
		free_cell(cell)


func get_occupant(cell: Vector2i) -> Node:
	return _occupied.get(cell, null)


func get_occupied_cells() -> Array:
	return _occupied.keys()


# Given a top-left cell and a footprint size (in cells), returns every cell
# the building would cover. footprint = Vector2i(2, 1) means 2 wide, 1 tall.
func get_footprint_cells(top_left: Vector2i, footprint: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(footprint.x):
		for y in range(footprint.y):
			cells.append(top_left + Vector2i(x, y))
	return cells
