extends Area2D
class_name Interactable
# WHY a component instead of a base class every interactable extends:
# In RimWorld-likes, "things you can interact with" is a huge, varied set —
# resource nodes, crafting stations, doors, storage, NPCs later on. Forcing
# them all into one inheritance chain gets messy fast (you hit the same
# problem your strategy game's Grunt/Follower split was solving). Instead,
# ANY node — StaticBody2D, CharacterBody2D, whatever — just adds this as a
# child Area2D and connects to `interacted`. This mirrors your component
# pattern from HealthComponent/ShieldComponent in the strategy game.
#
# Setup: add as a child node, put it in the "interactables" group (done
# automatically below), and give its CollisionShape2D a radius covering how
# close the player needs to be.

signal interacted(interactor: Node)

@export var prompt_text := "Interact"
@export var enabled := true

func _ready() -> void:
	add_to_group("interactables")
	collision_layer = 0
	collision_mask = 0
	# Interactables don't need to detect anything themselves — the player's
	# InteractionArea does the detecting. This Area2D just needs to exist
	# in the tree so the player's overlap check can find it via the group.

func interact(interactor: Node) -> void:
	if not enabled:
		return
	interacted.emit(interactor)
