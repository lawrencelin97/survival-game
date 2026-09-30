extends Node2D
class_name PlacementManager
# Drives the mouse-following ghost preview (green/red, unchanged) and,
# on confirm, spawns a ConstructionSite instead of the finished building —
# see ConstructionSite.gd for the resource-delivery / work-to-build flow
# that happens after this point. Also drives demolish mode.
#
# WHY there's no cost check here anymore: resources are no longer paid at
# placement time — they're delivered to the ConstructionSite afterward, so
# a blueprint can be placed with nothing in inventory. Validity is now
# purely "is this cell free."

signal placement_confirmed(building: BuildingData, top_left_cell: Vector2i)
signal placement_cancelled
signal building_demolished(building: PlacedBuilding)

@export var valid_color := Color(0, 1, 0, 0.5)
@export var invalid_color := Color(1, 0, 0, 0.5)
@export var demolish_highlight_color := Color(1, 0, 0, 0.4)
@export var construction_site_scene: PackedScene  # ConstructionSite.tscn — one generic scene used for every building type

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
	cancel_demolish()
	if _ghost != null:
		cancel_placement()

	_current_building = building
	_ghost = building.scene.instantiate()
	if _ghost is PlacedBuilding:
		_ghost.is_ghost = true
	_ghost.modulate = valid_color
	_set_ghost_collision_enabled(_ghost, false)
	add_child(_ghost)

func cancel_placement() -> void:
	if _ghost:
		_ghost.queue_free()
		_ghost = null
	_current_building = null
	placement_cancelled.emit()

func start_demolish() -> void:
	if _ghost != null:
		cancel_placement()
	_is_demolishing = true

func cancel_demolish() -> void:
	_is_demolishing = false
	_demolish_target = null
	queue_redraw()

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

	_is_valid = GridManager.are_cells_free(cells)
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
	for cell in _demolish_target.get_occupied_cells():
		var local_pos: Vector2 = GridManager.grid_to_world(cell) - global_position
		var half := GridManager.CELL_SIZE / 2.0
		draw_rect(Rect2(local_pos - Vector2(half, half), Vector2(GridManager.CELL_SIZE, GridManager.CELL_SIZE)), demolish_highlight_color)

func confirm_placement() -> bool:
	if not is_placing() or not _is_valid:
		return false

	var mouse_world := get_global_mouse_position()
	var top_left_cell := GridManager.world_to_grid(mouse_world)
	var cells := GridManager.get_footprint_cells(top_left_cell, _current_building.footprint)

	var site := construction_site_scene.instantiate()
	site.target_building = _current_building
	site.global_position = GridManager.grid_to_world(top_left_cell)
	GridManager.occupy_multi(cells, site)
	get_tree().current_scene.add_child(site)

	var placed := _current_building
	placement_confirmed.emit(placed, top_left_cell)
	return true

func confirm_demolish() -> bool:
	if not is_demolishing() or _demolish_target == null:
		return false
	var target := _demolish_target
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
