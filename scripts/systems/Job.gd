extends RefCounted
class_name Job
# A unit of work a Villager can pick up and perform.

enum Type { BUILD, HARVEST }

# Lower number = higher priority. Explicit dict rather than relying on enum
# declaration order, so reordering Type later can't silently change priority.
const PRIORITY := {
	Type.BUILD: 0,
	Type.HARVEST: 1,
}

var target: Node  # the node to interact with — usually something holding an Interactable child
var target_position: Vector2
var job_type: Type

func _init(p_target: Node, p_target_position: Vector2, p_job_type: Type = Type.HARVEST) -> void:
	target = p_target
	target_position = p_target_position
	job_type = p_job_type

func is_valid() -> bool:
	return is_instance_valid(target)

func get_priority() -> int:
	return PRIORITY.get(job_type, 999)

# Delegates to the target itself — different target types have different
# rules for "can this character actually help with this right now" (a
# ConstructionSite cares whether the villager is carrying anything useful;
# a ResourceNode might care about an equipped tool). A target that doesn't
# define this is assumed always workable.
func can_be_done_by(character: Node) -> bool:
	if target.has_method("can_be_worked_by"):
		return target.can_be_worked_by(character)
	return true
