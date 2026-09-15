extends Node
# Autoload as "RoomManager"
#
# WHY wall cells ARE tracked directly here (unlike GridManager occupancy,
# which this only reads): PlacedBuilding.register/unregister calls happen
# at the exact same _ready()/_exit_tree() points it already uses to update
# GridManager, so the two can't fall out of sync without both breaking
# at once. The alternative — rescanning every occupied cell on the map via
# GridManager.get_occupied_cells() and type-checking each one — costs more
# the bigger your map gets (every tree, every resource node), even though
# only a small fraction of cells are ever walls. Keeping a dedicated,
# incrementally-updated wall set avoids that entirely.
#
# HOW room detection works: flood-fill outward from open cells adjacent to
# a wall. If the fill closes in on itself (hits walls on every side) before
# exceeding MAX_ROOM_SIZE, it's an enclosed room. If it keeps growing past
# the cap without closing, it's leaking out to the unenclosed outdoors —
# same bounded-flood-fill technique RimWorld itself uses for room detection.
# On top of that, _has_fully_connected_boundary additionally requires the
# walls around a room to have no diagonal gaps — see that function for why.

const MAX_ROOM_SIZE := 400  # cells — tune based on how big rooms should be allowed to get

signal rooms_changed

var rooms: Array[Room] = []
var _wall_cells: Dictionary = {}  # Vector2i -> true; kept in sync by PlacedBuilding


class Room:
	var cells: Dictionary = {}  # Vector2i -> true; Dictionary gives O(1) contains() instead of an O(n) array scan

	func get_area() -> int:
		return cells.size()

	func contains(cell: Vector2i) -> bool:
		return cells.has(cell)


# Called by PlacedBuilding._ready() for anything with is_room_boundary set,
# right alongside its GridManager.occupy_multi() call.
func register_wall_cells(cells: Array[Vector2i]) -> void:
	for cell in cells:
		_wall_cells[cell] = true

# Called by PlacedBuilding._exit_tree(), right alongside GridManager.free_multi().
func unregister_wall_cells(cells: Array[Vector2i]) -> void:
	for cell in cells:
		_wall_cells.erase(cell)

# Call this after any wall-like building is placed or removed. Not run
# automatically on a timer — room topology only changes in response to
# specific build events, so recalculating every frame would be wasted work.
func request_recalculate() -> void:
	_recalculate()


func get_room_at(cell: Vector2i) -> Room:
	for room in rooms:
		if room.contains(cell):
			return room
	return null


func _recalculate() -> void:
	rooms.clear()
	var visited: Dictionary = {}

	# Seed flood fills from open cells that touch a wall — anything not
	# adjacent to a wall at all can't be part of an enclosed room anyway.
	var seeds: Dictionary = {}
	for wall_cell in _wall_cells:
		for neighbor in _get_neighbors(wall_cell):
			if not _wall_cells.has(neighbor):
				seeds[neighbor] = true

	for seed in seeds.keys():
		if visited.has(seed):
			continue
		var room := _flood_fill(seed, visited)
		# Sealing off the interior isn't enough on its own — see
		# _has_fully_connected_boundary for why this second check exists.
		if room and _has_fully_connected_boundary(room):
			rooms.append(room)

	rooms_changed.emit()
	print("RoomManager: %d room(s) detected" % rooms.size())  # temporary — replace with a visual overlay later


# WHY this exists separately from the flood fill above: the flood fill only
# proves the interior can't escape. What this checks instead is that there's
# no diagonal gap in the boundary — every interior cell's full 8-cell
# neighborhood (including corners) must be either another interior cell or
# a wall. A true corner where two perpendicular walls only touch diagonally,
# with no actual wall piece filling that corner cell, fails this check —
# which is the "wall corners are required" behavior you wanted.
func _has_fully_connected_boundary(room: Room) -> bool:
	for cell in room.cells:
		for neighbor in _get_neighbors_8(cell):
			if not room.cells.has(neighbor) and not _wall_cells.has(neighbor):
				return false
	return true


func _flood_fill(start: Vector2i, visited: Dictionary) -> Room:
	var open_list: Array[Vector2i] = [start]
	# Doubles as both "cells in this room" and "already enqueued" — one
	# dictionary instead of maintaining an Array and a Dictionary in parallel.
	var region_cells: Dictionary = {start: true}
	var enclosed := true

	while open_list.size() > 0:
		var current: Vector2i = open_list.pop_back()
		if region_cells.size() > MAX_ROOM_SIZE:
			enclosed = false
			break
		for neighbor in _get_neighbors(current):
			if _wall_cells.has(neighbor) or region_cells.has(neighbor):
				continue
			region_cells[neighbor] = true
			open_list.append(neighbor)

	# Mark every cell this fill touched as globally visited regardless of
	# outcome, so a failed (unenclosed) fill doesn't get re-attempted from
	# a different seed inside the same leaking region.
	for cell in region_cells:
		visited[cell] = true

	if not enclosed:
		return null

	var room := Room.new()
	room.cells = region_cells
	return room


func _get_neighbors(cell: Vector2i) -> Array[Vector2i]:
	return [cell + Vector2i.UP, cell + Vector2i.DOWN, cell + Vector2i.LEFT, cell + Vector2i.RIGHT]


func _get_neighbors_8(cell: Vector2i) -> Array[Vector2i]:
	var neighbors := _get_neighbors(cell)
	var diagonals: Array[Vector2i] = [
		cell + Vector2i(1, 1), cell + Vector2i(1, -1),
		cell + Vector2i(-1, 1), cell + Vector2i(-1, -1),
	]
	neighbors.append_array(diagonals)
	return neighbors
