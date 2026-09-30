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
#    single presses stop doing anything — instead, HOLDING interact (a
#    player) or a Villager's own construction-job loop calls apply_work()
#    repeatedly until target_building.work_cost is met, at which point this
#    swaps itself out for the real building.
#
# Also registers itself as a JobManager Job (Type.BUILD, higher priority
# than harvesting) so villagers help build it — see can_be_worked_by() for
# how a villager decides whether it's actually able to help right now.

@export var target_building: BuildingData

var delivered: Dictionary = {}  # ItemData -> amount delivered so far
var work_progress := 0.0
var _completing := false
var _job: Job

@onready var interactable: Interactable = $Interactable

func _ready() -> void:
	footprint = target_building.footprint
	for stack in target_building.cost:
		delivered[stack.item] = 0

	var shape := RectangleShape2D.new()
	shape.size = Vector2(footprint) * GridManager.CELL_SIZE
	$CollisionShape2D.shape = shape
	$CollisionShape2D.position = shape.size / 2.0  # global_position is the top-left tile; center the shape over the footprint

	if is_ghost:
		return
	interactable.interacted.connect(_on_interacted)
	_job = Job.new(self, global_position, Job.Type.BUILD)
	JobManager.add_job(_job)
	queue_redraw()

func _exit_tree() -> void:
	if not is_ghost:
		JobManager.remove_job(_job)
	if _completing:
		return  # cells were just handed off to the finished building, not actually vacated
	super._exit_tree()

func is_resourced() -> bool:
	for stack in target_building.cost:
		if delivered.get(stack.item, 0) < stack.amount:
			return false
	return true

func _on_interacted(interactor: Node) -> void:
	if is_resourced():
		return  # nothing left to deliver — finishing it now happens by applying work instead
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

# Called every physics frame a character is actively building this — a
# held key for Player, or Villager's own construction-job handling — once
# is_resourced() is already true.
func apply_work(amount: float) -> bool:
	if not is_resourced():
		return false
	work_progress += amount
	queue_redraw()
	if work_progress >= target_building.work_cost:
		_complete_construction()
		return true
	return false

# Used by Job.can_be_done_by() so a villager with nothing useful to deliver
# skips this job for the next-best one instead of walking over and doing
# nothing — this is the "check if they can do the job" behavior.
func can_be_worked_by(character: Node) -> bool:
	if is_resourced():
		return true  # anyone can apply work once resourced
	if not character.has_node("Inventory"):
		return false
	var inventory: Inventory = character.get_node("Inventory")
	for stack in target_building.cost:
		var still_needed: int = stack.amount - delivered.get(stack.item, 0)
		if still_needed > 0 and inventory.count_item(stack.item) > 0:
			return true  # carrying something this site still needs
	return false

func _complete_construction() -> void:
	_completing = true
	var cells := get_occupied_cells()
	var real_building := target_building.scene.instantiate()
	real_building.global_position = global_position
	GridManager.occupy_multi(cells, real_building)
	get_tree().current_scene.add_child(real_building)
	queue_free()

func _draw() -> void:
	var size := Vector2(footprint) * GridManager.CELL_SIZE
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.3, 0.5, 1.0, 0.5))
	if is_resourced():
		var pct: float = clamp(work_progress / target_building.work_cost, 0.0, 1.0)
		draw_rect(Rect2(Vector2(0, size.y - 6), Vector2(size.x * pct, 6)), Color(1, 1, 0, 0.9))
