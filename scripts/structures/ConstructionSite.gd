extends PlacedBuilding
class_name ConstructionSite
# Scene structure:
# ConstructionSite (StaticBody2D, PlacedBuilding + this script)
#  ├─ CollisionShape2D  (shape/size set dynamically in _ready() to match target_building.footprint)
#  └─ Interactable (Area2D, Interactable.gd)
#
# One generic scene stands in for every building type under construction —
# there's no per-building "half-built" art. Its footprint, collision, and
# visual are all sized dynamically from whichever BuildingData it's
# building toward.
#
# TWO-PHASE INTERACTION:
#  - Single interact presses (Interactable.interacted, the existing
#    once-per-press system) deliver resources from the interactor's
#    Inventory, as much of each missing ingredient as they're carrying.
#  - Once every ingredient is fully delivered (is_resourced() == true),
#    single presses stop doing anything — instead, HOLDING interact calls
#    apply_work() every physics frame (see Player._physics_process, which
#    checks Input.is_action_pressed continuously rather than waiting for
#    a press event) until target_building.work_cost is met, at which point
#    this swaps itself out for the real building.
#
# WHY this is a separate class from the real building rather than the real
# building just starting "unfinished": the real building's own scene might
# have interaction behavior (CraftingStation opens a menu, StorageChest
# opens storage) that shouldn't be reachable before it actually exists.
# Keeping construction entirely separate means the real building never has
# to check "am I actually finished yet."

@export var target_building: BuildingData

var delivered: Dictionary = {}  # ItemData -> amount delivered so far
var work_progress := 0.0
var _completing := false

@onready var interactable: Interactable = $Interactable

func _ready() -> void:
	footprint = target_building.footprint
	for stack in target_building.cost:
		delivered[stack.item] = 0

	var shape := RectangleShape2D.new()
	shape.size = Vector2(footprint) * GridManager.CELL_SIZE
	$CollisionShape2D.shape = shape
	$CollisionShape2D.position = shape.size / 2.0  # global_position is the top-left tile; center the shape over the footprint
	
	JobManager.add_job(Job.new(self, global_position))
	
	if is_ghost:
		return
	interactable.interacted.connect(_on_interacted)
	queue_redraw()

func is_resourced() -> bool:
	for stack in target_building.cost:
		if delivered.get(stack.item, 0) < stack.amount:
			return false
	return true

func _on_interacted(interactor: Node) -> void:
	if is_resourced():
		return  # nothing left to deliver — finishing it now happens by holding interact instead
	if not interactor.has_node("Inventory"):
		return
	var inventory: Inventory = interactor.get_node("Inventory")
	for stack in target_building.cost:
		var still_needed: int = stack.amount - delivered.get(stack.item, 0)
		if still_needed <= 0:
			continue
		var have := inventory.count_item(stack.item)
		var to_deliver: int = min(still_needed, have)
		if to_deliver > 0:
			inventory.remove_item(stack.item, to_deliver)
			delivered[stack.item] = delivered.get(stack.item, 0) + to_deliver
	queue_redraw()

# Called every physics frame a character holds interact while this is the
# nearest Interactable and is_resourced() is already true.
func apply_work(amount: float) -> bool:
	if not is_resourced():
		return false
	work_progress += amount
	queue_redraw()
	if work_progress >= target_building.work_cost:
		_complete_construction()
		return true
	return false

func _complete_construction() -> void:
	_completing = true
	var cells := get_occupied_cells()
	var real_building := target_building.scene.instantiate()
	real_building.global_position = global_position
	GridManager.occupy_multi(cells, real_building)  # hand these cells to the finished building before this site frees them
	get_tree().current_scene.add_child(real_building)
	queue_free()

func _exit_tree() -> void:
	if _completing:
		return  # cells were just handed off above, not actually vacated
	super._exit_tree()

func _draw() -> void:
	var size := Vector2(footprint) * GridManager.CELL_SIZE
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.3, 0.5, 1.0, 0.5))
	if is_resourced():
		var pct: float = clamp(work_progress / target_building.work_cost, 0.0, 1.0)
		draw_rect(Rect2(Vector2(0, size.y - 6), Vector2(size.x * pct, 6)), Color(1, 1, 0, 0.9))
