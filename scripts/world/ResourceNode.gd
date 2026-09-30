extends StaticBody2D
class_name ResourceNode
# Scene structure:
# ResourceNode (StaticBody2D, this script)
#  ├─ Sprite2D
#  ├─ CollisionShape2D  (physical body, blocks movement)
#  ├─ Interactable (Area2D, Interactable.gd — separate, larger hit area)
#  └─ HealthComponent (Node, HealthComponent.gd — max_health = hits to deplete)
#
# One script covers three behaviors:
#  - Trees: drop_directly_to_inventory = false, pickup_scene assigned,
#    harvest_tag = "wood", requires_tool = true
#    -> can't be damaged at all without a ToolData tagged "wood" (an axe) equipped.
#  - Rocks: harvest_tag = "stone", requires_tool = false, tool_yield_bonus = 2.0
#    -> harvestable by hand, but yields more with a ToolData tagged "stone" (a pickaxe) equipped.
#  - Crops: drop_directly_to_inventory = true, harvest_tag left empty
#    -> goes straight into the harvesting player's Inventory, no tool involved.

@export var drop_item: ItemData
@export var drop_amount_min := 1
@export var drop_amount_max := 3
@export var damage_per_hit := 1.0
@export var drop_directly_to_inventory := false
@export var pickup_scene: PackedScene  # required when drop_directly_to_inventory is false

@export var harvest_tag := ""  # e.g. "wood", "stone" — matches a ToolData's harvest_tag; empty means no tool interacts with this
@export var requires_tool := false  # true = can't be damaged at all without a matching tool equipped (e.g. trees need an axe)
@export var tool_yield_bonus := 1.0  # multiplier on drop amount when the equipped tool's tag matches (independent of requires_tool)

@onready var interactable: Interactable = $Interactable
@onready var health: HealthComponent = $HealthComponent

var _last_interactor: Node
var _job: Job

func _ready() -> void:
	interactable.interacted.connect(_on_interacted)
	health.died.connect(_on_depleted)
	GridManager.occupy(GridManager.world_to_grid(global_position), self)
	_job = Job.new(self, global_position, Job.Type.HARVEST)
	JobManager.add_job(_job)

func _exit_tree() -> void:
	GridManager.free_cell(GridManager.world_to_grid(global_position))
	JobManager.remove_job(_job)

func _on_interacted(interactor: Node) -> void:
	if requires_tool and not _has_matching_tool(interactor):
		return  # e.g. no axe equipped — can't even start damaging a tree
	_last_interactor = interactor
	health.take_damage(damage_per_hit)

func _has_matching_tool(interactor: Node) -> bool:
	if harvest_tag == "" or not interactor.has_node("EquipmentSlots"):
		return false
	var equipment: EquipmentSlots = interactor.get_node("EquipmentSlots")
	return equipment.has_tool_with_tag(harvest_tag)

func _on_depleted() -> void:
	if drop_item:
		var amount := randi_range(drop_amount_min, drop_amount_max)
		if _last_interactor and _has_matching_tool(_last_interactor):
			amount = int(round(amount * tool_yield_bonus))
		if drop_directly_to_inventory:
			_give_to_interactor(drop_item, amount)
		else:
			_spawn_pickup(drop_item, amount)
	queue_free()

func _give_to_interactor(item: ItemData, amount: int) -> void:
	if _last_interactor and _last_interactor.has_node("Inventory"):
		var inventory: Inventory = _last_interactor.get_node("Inventory")
		inventory.add_item(item, amount)

func _spawn_pickup(item: ItemData, amount: int) -> void:
	if not pickup_scene:
		push_warning("ResourceNode '%s' has no pickup_scene assigned — drop lost." % name)
		return
	var pickup := pickup_scene.instantiate()
	pickup.item = item
	pickup.amount = amount
	get_tree().current_scene.add_child(pickup)
	pickup.global_position = global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))

# Used by Job.can_be_done_by() so a villager without the required tool
# never claims this job in the first place, rather than getting stuck on
# it after the fact.
func can_be_worked_by(character: Node) -> bool:
	if not requires_tool:
		return true
	return _has_matching_tool(character)
