extends RefCounted
class_name Job
# A unit of work a Villager can pick up and perform. Deliberately minimal —
# just "go here, interact with this thing until it's done." Other job
# types (crafting, hauling, building) can fit this same shape later without
# restructuring JobManager or Villager, since both only care about
# target/target_position, never job-type-specific details.

var target: Node  # the node to interact with — usually something holding an Interactable child, e.g. a ResourceNode
var target_position: Vector2

func _init(p_target: Node, p_target_position: Vector2) -> void:
	target = p_target
	target_position = p_target_position

func is_valid() -> bool:
	return is_instance_valid(target)
