extends Node2D
class_name PlacementManager
# Attach as a child of the Player (or a sibling that follows the mouse —
# your call). Drives the "ghost" preview that snaps to the grid, tints
# red/green based on validity, and confirms placement into a real
# PlacedBuilding on click. Also drives demolish mode — same grid/mouse
# plumbing, opposite action: instead of adding a building, it removes
# whatever occupies the hovered cell. No refund, no health/damage
# involved — this is a direct "player chose to remove it" action, separate
# from anything HealthComponent-based (e.g. future combat damage to walls).
#
# WHY grid-snapped logic lives here rather than on GridManager: GridManager
# only knows "is this cell free" — it has no concept of an in-progress
# placement, ghost sprites, or player-facing input. Keeping that here keeps
# GridManager a pure data/query singleton, same separation you used between
# SiteManager (data) and TacticalMap (UI/input) in the strategy game.

signal placement_confirmed(building: BuildingData, top_left_cell: Vector2i)
signal placement_cancelled
signal building_demolished(building: PlacedBuilding)

@export var valid_color := Color(0, 1, 0, 0.5)
@export var invalid_color := Color(1, 0, 0, 0.5)
@export var demolish_highlight_color := Color(1, 0, 0, 0.4)

var inventory: Inventory
var _current_building: BuildingData
var _ghost: Node2D
var _is_valid := false

var _is_demolishing := false
var _demolish_target: PlacedBuilding = null

func _init(inv: Inventory = null) -> void:
	inventory = inv

func is_placing() -> bool:
	return _current_building != null

func is_demolishing() -> bool:
	return _is_demolishing

func is_active() -> bool:
	return is_placing() or is_demolishing()

func start_placement(building: BuildingData) -> void:
	cancel_demolish()  # the two modes are mutually exclusive
	if _ghost != null:
		cancel_placement()

	_current_building = building
	_ghost = building.scene.instantiate()
	if _ghost is PlacedBuilding:
		_ghost.is_ghost = true  # set before add_child so _ready() sees it and skips GridManager/RoomManager registration
	_ghost.modulate = valid_color
	# Ghosts shouldn't collide or run gameplay logic — strip collision if
	# your PlacedBuilding scenes have any StaticBody2D children.
	_set_ghost_collision_enabled(_ghost, false)
	add_child(_ghost)

func cancel_placement() -> void:
	if _ghost:
		_ghost.queue_free()
		_ghost = null
	_current_building = null
	placement_cancelled.emit()

func start_demolish() -> void:
	if _ghost != null:  # the two modes are mutually exclusive
		cancel_placement()
	_is_demolishing = true

func cancel_demolish() -> void:
	_is_demolishing = false
	_demolish_target = null
	queue_redraw()

# Convenience for callers (e.g. BuildMenuUI closing) that just want
# "stop whatever mode is active" without checking which one it is.
func cancel_all() -> void:
	cancel_placement()
	cancel_demolish()

func _process(_delta: float) -> void:
	if is_placing():
		_process_placement()
	elif is_demolishing():
		_process_demolish()

func _process_placement() -> void:
	var mouse_world := get_global_mouse_position()
	var top_left_cell := GridManager.world_to_grid(mouse_world)
	var cells := GridManager.get_footprint_cells(top_left_cell, _current_building.footprint)

	_ghost.global_position = GridManager.grid_to_world(top_left_cell)

	_is_valid = GridManager.are_cells_free(cells) and (
		inventory == null or inventory.has_all(_current_building.cost)
	)
	_ghost.modulate = valid_color if _is_valid else invalid_color

func _process_demolish() -> void:
	var mouse_world := get_global_mouse_position()
	var cell := GridManager.world_to_grid(mouse_world)
	var occupant := GridManager.get_occupant(cell)
	_demolish_target = occupant if occupant is PlacedBuilding else null
	queue_redraw()

func _draw() -> void:
	if not is_demolishing() or _demolish_target == null:
		return
	var top_left := GridManager.world_to_grid(_demolish_target.global_position)
	var cells := GridManager.get_footprint_cells(top_left, _demolish_target.footprint)
	for cell in cells:
		# _draw() coordinates are local to this node, so convert from world
		# space by subtracting this node's own global_position.
		var local_pos: Vector2 = GridManager.grid_to_world(cell) - global_position
		var half := GridManager.CELL_SIZE / 2.0
		draw_rect(Rect2(local_pos - Vector2(half, half), Vector2(GridManager.CELL_SIZE, GridManager.CELL_SIZE)), demolish_highlight_color)

func confirm_placement() -> bool:
	if not is_placing() or not _is_valid:
		return false

	var mouse_world := get_global_mouse_position()
	var top_left_cell := GridManager.world_to_grid(mouse_world)
	var cells := GridManager.get_footprint_cells(top_left_cell, _current_building.footprint)

	if inventory:
		inventory.remove_all(_current_building.cost)

	var building_instance := _current_building.scene.instantiate()
	building_instance.global_position = GridManager.grid_to_world(top_left_cell)
	GridManager.occupy_multi(cells, building_instance)  # register BEFORE add_child, so RoomManager sees this wall during its own _ready()
	get_tree().current_scene.add_child(building_instance)

	var placed := _current_building

	placement_confirmed.emit(placed, top_left_cell)
	return true

func confirm_demolish() -> bool:
	if not is_demolishing() or _demolish_target == null:
		return false
	var target := _demolish_target
	# queue_free() triggers PlacedBuilding._exit_tree(), which already
	# handles freeing GridManager cells, unregistering wall cells, and
	# triggering a RoomManager recalculation — no duplicate cleanup needed here.
	target.queue_free()
	_demolish_target = null
	queue_redraw()
	building_demolished.emit(target)
	return true

func _set_ghost_collision_enabled(node: Node, enabled: bool) -> void:
	if node is CollisionObject2D:
		node.set_deferred("monitoring", enabled)
		node.set_deferred("monitorable", enabled)
		for i in node.get_shape_owners():
			node.shape_owner_set_disabled(i, not enabled)
	for child in node.get_children():
		_set_ghost_collision_enabled(child, enabled)
