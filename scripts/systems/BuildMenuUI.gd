extends Control
class_name BuildMenuUI
# Scene structure:
# BuildMenuUI (Control, this script — full rect, starts hidden)
#  └─ Panel
#       ├─ DemolishButton (Button, hand-placed — not part of the auto-populated grid below)
#       └─ GridContainer (Columns = 5, same layout idea as InventoryUI)
#            (BuildOptionSlot instances added here at runtime)
#
# WHY there's no affordability greying anymore: resources are no longer
# paid at placement time (see PlacementManager/ConstructionSite) — a
# blueprint can be placed with nothing in inventory and resourced later.
# Every listed building is always selectable; whether you can finish it is
# entirely a ConstructionSite concern now, not a build-menu one.

@export var slot_scene: PackedScene  # BuildOptionSlot.tscn
@export var available_buildings: Array[BuildingData] = []

@onready var grid: GridContainer = $Panel/GridContainer
@onready var demolish_button: Button = $Panel/DemolishButton

var placement: PlacementManager
var inventory: Inventory
var _slot_nodes: Array[BuildOptionSlot] = []

func _ready() -> void:
	visible = false
	_build_slots()
	demolish_button.pressed.connect(_on_demolish_pressed)

func _build_slots() -> void:
	for child in grid.get_children():
		child.queue_free()
	_slot_nodes.clear()
	for building in available_buildings:
		var slot: BuildOptionSlot = slot_scene.instantiate()
		grid.add_child(slot)
		slot.set_building(building)
		slot.pressed.connect(_on_building_selected.bind(building))
		_slot_nodes.append(slot)

func set_context(target_placement: PlacementManager, target_inventory: Inventory) -> void:
	placement = target_placement
	inventory = target_inventory

func toggle() -> void:
	visible = not visible
	if not visible:
		close()

func close() -> void:
	visible = false
	placement.cancel_all()

func _on_building_selected(building: BuildingData) -> void:
	if placement == null:
		return
	placement.start_placement(building)

func _on_demolish_pressed() -> void:
	if placement:
		placement.start_demolish()
