extends TileMapLayer
class_name RoomFloorLayer
# Add as a second TileMapLayer, sibling to your ground layer, placed AFTER
# it in the Scene dock (later siblings draw on top). Assign a TileSet with
# a distinct "room floor" tile — this can be the same TileSet resource your
# ground layer uses, just pointing at a different atlas coordinate, or its
# own separate TileSet if you'd rather keep them apart.
#
# WHY this listens to RoomManager.rooms_changed instead of running every
# frame: room topology only changes when a wall goes up or down, and
# RoomManager already emits this signal exactly then (see
# RoomManager._recalculate()). Repainting on every frame would be pure
# waste — this only redraws in response to an actual change.

@export var floor_source_id := 0
@export var floor_atlas_coords := Vector2i(1, 0)  # whichever tile in your TileSet is the "room floor" tile

func _ready() -> void:
	RoomManager.rooms_changed.connect(_on_rooms_changed)
	_on_rooms_changed()  # in case rooms already exist by the time this loads

func _on_rooms_changed() -> void:
	clear()  # safe — this layer only ever holds room-floor tiles, nothing else
	for room in RoomManager.rooms:
		for cell in room.cells:
			set_cell(cell, floor_source_id, floor_atlas_coords)
