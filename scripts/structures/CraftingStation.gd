extends PlacedBuilding
class_name CraftingStation
# Framework for any buildable crafting bench (workbench, forge, etc.).
# A concrete station is usually just a scene using this script directly,
# with its own station_name and available_recipes set in the Inspector —
# same as your Wall scene is just PlacedBuilding.gd with is_room_boundary
# checked, no subclass required. Only give a station its own .gd file (as
# a CraftingStation subclass) once it needs genuinely different behavior
# this framework doesn't cover — e.g. a forge with a smelting timer.
#
# Scene structure (on top of what PlacedBuilding already needs):
# CraftingStation (StaticBody2D, PlacedBuilding + this script)
#  ├─ Sprite2D
#  ├─ CollisionShape2D
#  └─ Interactable (Area2D, Interactable.gd — same component your trees use)
#
# WHY this extends PlacedBuilding rather than composing it: a station has
# to be placeable through the exact same BuildMenuUI -> PlacementManager
# pipeline your walls already use, which means it needs footprint, cost,
# and grid occupancy just like any other building. Layering Interactable
# and recipes on top of PlacedBuilding gets that for free instead of
# duplicating placement logic for stations specifically.

@export var station_name := "Workbench"
@export var available_recipes: Array[RecipeData] = []

@onready var interactable: Interactable = $Interactable

func _ready() -> void:
	super._ready()  # keep PlacedBuilding's own setup (room-boundary registration, etc.)
	if is_ghost:
		return
	interactable.interacted.connect(_on_interacted)

func _on_interacted(interactor: Node) -> void:
	if interactor.has_method("open_crafting_menu"):
		interactor.open_crafting_menu(self)
