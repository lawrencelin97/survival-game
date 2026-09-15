extends Control
class_name BuildMenuUI
# Scene structure:
# BuildMenuUI (Control, this script — full rect, starts hidden)
#  └─ Panel
#       └─ GridContainer (Columns = 5, same layout idea as InventoryUI)
#            (BuildOptionSlot instances added here at runtime)
#
# WHY affordability checks live here instead of in PlacementManager:
# PlacementManager already checks cost when validating ghost placement
# every frame — that's the authoritative check. This is a second, cheaper
# check purely for greying out menu buttons so the player can see what
# they can afford before even entering placement mode. Duplicating the
# read-only check is fine; the two never need to agree on anything more
# than "can I afford this", and PlacementManager remains the only place
# that actually spends resources.

@export var slot_scene: PackedScene  # BuildOptionSlot.tscn
@export var available_buildings: Array[BuildingData] = []

@onready var grid: GridContainer = $Panel/GridContainer

var placement: PlacementManager
var inventory: Inventory
var _slot_nodes: Array[BuildOptionSlot] = []

func _ready() -> void:
	visible = false
	_build_slots()

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

# Called once from Player._ready(), same idea as Inventory being wired into
# PlacementManager — this menu needs both to check affordability and to
# actually kick off placement.
func set_context(target_placement: PlacementManager, target_inventory: Inventory) -> void:
	placement = target_placement
	inventory = target_inventory
	if inventory and not inventory.inventory_changed.is_connected(_refresh_affordability):
		inventory.inventory_changed.connect(_refresh_affordability)
	_refresh_affordability()

func toggle() -> void:
	visible = not visible
	if visible:
		_refresh_affordability()
	else:
		close()

func close() -> void:
	visible=false
	placement.cancel_placement()

func _refresh_affordability() -> void:
	for i in available_buildings.size():
		if i >= _slot_nodes.size():
			break
		var affordable := inventory == null or inventory.has_all(available_buildings[i].cost)
		_slot_nodes[i].set_affordable(affordable)

func _on_building_selected(building: BuildingData) -> void:
	if placement == null:
		return
	placement.start_placement(building)
