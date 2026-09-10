extends Node2D
class_name PlacementManager
# Attach as a child of the Player (or a sibling that follows the mouse —
# your call). Drives the "ghost" preview that snaps to the grid, tints
# red/green based on validity, and confirms placement into a real
# PlacedBuilding on click.
#
# WHY grid-snapped logic lives here rather than on GridManager: GridManager
# only knows "is this cell free" — it has no concept of an in-progress
# placement, ghost sprites, or player-facing input. Keeping that here keeps
# GridManager a pure data/query singleton, same separation you used between
# SiteManager (data) and TacticalMap (UI/input) in the strategy game.

signal placement_confirmed(building: BuildingData, top_left_cell: Vector2i)
signal placement_cancelled

@export var valid_color := Color(0, 1, 0, 0.5)
@export var invalid_color := Color(1, 0, 0, 0.5)

var inventory: Inventory
var _current_building: BuildingData
var _ghost: Node2D
var _is_valid := false

func _init(inv: Inventory = null) -> void:
	inventory = inv

func is_placing() -> bool:
	return _current_building != null

func start_placement(building: BuildingData) -> void:
	if _ghost != null:
		cancel_placement()

	_current_building = building
	_ghost = building.scene.instantiate()
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

func _process(_delta: float) -> void:
	if not is_placing():
		return

	var mouse_world := get_global_mouse_position()
	var top_left_cell := GridManager.world_to_grid(mouse_world)
	var cells := GridManager.get_footprint_cells(top_left_cell, _current_building.footprint)

	_ghost.global_position = GridManager.grid_to_world(top_left_cell)

	_is_valid = GridManager.are_cells_free(cells) and (
		inventory == null or inventory.has_all(_current_building.cost)
	)
	_ghost.modulate = valid_color if _is_valid else invalid_color

func confirm_placement() -> bool:
	if not is_placing() or not _is_valid:
		return false

	var mouse_world := get_global_mouse_position()
	var top_left_cell := GridManager.world_to_grid(mouse_world)
	var cells := GridManager.get_footprint_cells(top_left_cell, _current_building.footprint)

	if inventory:
		inventory.remove_all(_current_building.cost)

	var building_instance: Node2D = _current_building.scene.instantiate()
	get_tree().current_scene.add_child(building_instance)
	building_instance.global_position = GridManager.grid_to_world(top_left_cell)
	GridManager.occupy_multi(cells, building_instance)

	var placed := _current_building
	_ghost.queue_free()
	_ghost = null
	_current_building = null
	placement_confirmed.emit(placed, top_left_cell)
	return true

func _set_ghost_collision_enabled(node: Node, enabled: bool) -> void:
	if node is CollisionObject2D:
		node.set_deferred("monitoring", enabled)
		node.set_deferred("monitorable", enabled)
		for i in node.get_shape_owners():
			node.shape_owner_set_disabled(i, not enabled)
	for child in node.get_children():
		_set_ghost_collision_enabled(child, enabled)
