extends Node2D
class_name MapGenerator
# Attach to a plain Node2D in your main scene, e.g. named "MapGenerator".
# Give it references to your TileMap and tree scene in the Inspector, then
# it fills the ground and scatters trees on _ready().
#
# WHY this checks GridManager before placing a tree, rather than just
# picking random cells and hoping: without that check, two trees could land
# on the same cell (visually overlapping), or a tree could spawn in a spot
# you can never build over even after it's harvested and gone — but only if
# ResourceNode didn't clean up its own occupancy on removal, which is why
# that was just added to ResourceNode.gd rather than handled here. This
# script only needs to ask "is this cell free right now" and trust the
# answer.

@export var tilemaplayer: TileMapLayer   # was TileMapap
@export var ground_source_id := 0
@export var ground_atlas_coords := Vector2i(0, 0)
@export var map_width_cells := 40
@export var map_height_cells := 30

@export var tree_scene: PackedScene
@export var tree_count := 20
@export var clear_radius_cells := 3  # keep this many cells around the map center tree-free, for player spawn

@export var shrub_scene: PackedScene
@export var shrub_count := 20

@export var use_random_seed := false
@export var seed_value := 0

func _ready() -> void:
	generate()

func generate() -> void:
	_fill_ground()
	_spawn_trees()
	_spawn_shrubs()

func _fill_ground() -> void:
	if not tilemaplayer:
		push_warning("MapGenerator has no TileMap assigned.")
		return
	for x in range(-map_width_cells,map_width_cells):
		for y in range(-map_height_cells,map_height_cells):
			tilemaplayer.set_cell(Vector2i(x, y), ground_source_id, ground_atlas_coords)

func _spawn_trees() -> void:
	if not tree_scene:
		push_warning("MapGenerator has no tree_scene assigned.")
		return
	
	var rng := RandomNumberGenerator.new()
	if use_random_seed:
		rng.seed = seed_value
	else:
		rng.randomize()

	var center := Vector2.ZERO
	var placed := 0
	var attempts := 0
	var max_attempts := tree_count * 30  # safety net so a crowded map can't infinite-loop

	while placed < tree_count and attempts < max_attempts:
		attempts += 1
		var cell := Vector2i(
			rng.randi_range(-map_width_cells+1, map_width_cells - 1),
			rng.randi_range(-map_height_cells+1, map_height_cells - 1)
		)

		if Vector2(cell).distance_to(center) < clear_radius_cells:
			continue  # keep the player's spawn area clear
		if not GridManager.is_cell_free(cell):
			continue  # something (another tree) is already here

		var tree := tree_scene.instantiate()
		tree.global_position = GridManager.grid_to_world(cell)
		add_child(tree)
		# No need to call GridManager.occupy() here — ResourceNode registers
		# its own cell in _ready() as soon as it's added to the tree above.
		placed += 1

func _spawn_shrubs() -> void:
	if not shrub_scene:
		push_warning("MapGenerator has no shrub_scene assigned.")
		return
	
	var rng := RandomNumberGenerator.new()
	if use_random_seed:
		rng.seed = seed_value
	else:
		rng.randomize()

	var center := Vector2.ZERO
	var placed := 0
	var attempts := 0
	var max_attempts := shrub_count * 30  # safety net so a crowded map can't infinite-loop

	while placed < shrub_count and attempts < max_attempts:
		attempts += 1
		var cell := Vector2i(
			rng.randi_range(-map_width_cells+1, map_width_cells - 1),
			rng.randi_range(-map_height_cells+1, map_height_cells - 1)
		)

		if Vector2(cell).distance_to(center) < clear_radius_cells:
			continue  # keep the player's spawn area clear
		if not GridManager.is_cell_free(cell):
			continue  # something (another tree) is already here

		var shrub := shrub_scene.instantiate()
		shrub.global_position = GridManager.grid_to_world(cell)
		add_child(shrub)
		# No need to call GridManager.occupy() here — ResourceNode registers
		# its own cell in _ready() as soon as it's added to the tree above.
		placed += 1

	if placed < tree_count:
		push_warning("MapGenerator only placed %d/%d trees before running out of attempts — map may be too small or crowded." % [placed, tree_count])
