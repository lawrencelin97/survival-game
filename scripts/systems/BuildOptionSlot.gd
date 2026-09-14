extends Button
class_name BuildOptionSlot
# Unlike InventorySlot (a Panel — purely visual, nothing to click), this is
# a Button directly. Godot's Button already has built-in `icon` and `text`
# properties plus a `disabled` state and a `pressed` signal, so there's no
# need for child Icon/Label nodes the way InventorySlot has — using Button's
# own properties is simpler and gets disabled-state greying for free.

func set_building(building: BuildingData) -> void:
	icon = building.icon
	text = building.display_name

func set_affordable(affordable: bool) -> void:
	disabled = not affordable
