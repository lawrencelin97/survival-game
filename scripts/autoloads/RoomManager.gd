extends Node
# Autoload as "RoomManager"
#
# WHY this has no wall-tracking dictionary of its own: GridManager already
# knows what occupies every cell. Keeping a second "wall cells" dictionary
# here would mean remembering to update two places in sync every time a
# wall goes up or comes down — exactly the kind of duplicated state this
# project has avoided everywhere else (GridManager itself is the single
# source of truth for occupancy). Instead, this just asks GridManager which
# cells are occupied, and checks each occupant's is_room_boundary flag.
#
# HOW room detection works: flood-fill outward from open cells adjacent to
# a wall. If the fill closes in on itself (hits walls on every side) before
# exceeding MAX_ROOM_SIZE, it's an enclosed room. If it keeps growing past
# the cap without closing, it's leaking out to the unenclosed outdoors —
# same bounded-flood-fill technique RimWorld itself uses for room detection.

const MAX_ROOM_SIZE := 400  # cells — tune based on how big rooms should be allowed to get

signal rooms_changed

var rooms: Array[Room] = []


class Room:
	var cells: Array[Vector2i] = []

	func get_area() -> int:
		return cells.size()

	func contains(cell: Vector2i) -> bool:
		return cell in cells


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
	var wall_cells := _get_wall_cells()
	var visited: Dictionary = {}

	# Seed flood fills from open cells that touch a wall — anything not
	# adjacent to a wall at all can't be part of an enclosed room anyway.
	var seeds: Dictionary = {}
	for wall_cell in wall_cells:
		for neighbor in _get_neighbors(wall_cell):
			if not wall_cells.has(neighbor):
				seeds[neighbor] = true

	for seed in seeds.keys():
		if visited.has(seed):
			continue
		var room := _flood_fill(seed, wall_cells, visited)
		# Sealing off the interior isn't enough on its own — see
		# _has_fully_connected_boundary for why this second check exists.
		if room and _has_fully_connected_boundary(room, wall_cells):
			rooms.append(room)

	rooms_changed.emit()
	print("RoomManager: %d room(s) detected" % rooms.size())  # temporary — replace with a visual overlay later


func _has_fully_connected_boundary(room: Room, wall_cells: Dictionary) -> bool:
	for cell in room.cells:
		for neighbor in _get_neighbors_8(cell):
			if not room.cells.has(neighbor) and not wall_cells.has(neighbor):
				return false
	return true



func _get_wall_cells() -> Dictionary:
	var walls: Dictionary = {}
	for cell in GridManager.get_occupied_cells():
		var occupant := GridManager.get_occupant(cell)
		if occupant is PlacedBuilding and occupant.is_room_boundary:
			walls[cell] = true
	return walls


func _flood_fill(start: Vector2i, wall_cells: Dictionary, visited: Dictionary) -> Room:
	var open_list: Array[Vector2i] = [start]
	var local_visited: Dictionary = {start: true}
	var region_cells: Array[Vector2i] = []
	var enclosed := true

	while open_list.size() > 0:
		var current: Vector2i = open_list.pop_back()
		region_cells.append(current)
		if region_cells.size() > MAX_ROOM_SIZE:
			enclosed = false
			break
		for neighbor in _get_neighbors(current):
			if wall_cells.has(neighbor) or local_visited.has(neighbor):
				continue
			local_visited[neighbor] = true
			open_list.append(neighbor)

	# Mark every cell this fill touched as globally visited regardless of
	# outcome, so a failed (unenclosed) fill doesn't get re-attempted from
	# a different seed inside the same leaking region.
	for cell in local_visited:
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
