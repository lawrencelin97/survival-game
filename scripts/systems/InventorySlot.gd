extends Panel
class_name InventorySlot
# Scene structure:
# InventorySlot (Panel, this script)
#  ├─ Icon (TextureRect, centered, expand mode "Keep Aspect Centered")
#  └─ AmountLabel (Label, bottom-right anchored)
#
# WHY this is its own tiny scene rather than InventoryUI drawing squares
# directly in code: GridContainer just arranges child *nodes* — it doesn't
# care what they are. Making each slot a real scene means you can visually
# tweak slot styling (borders, hover highlight, drag-and-drop later) in the
# editor instead of hand-writing style boxes in GDScript.

@onready var icon: TextureRect = $Icon
@onready var amount_label: Label = $AmountLabel

func set_slot_data(item: ItemData, amount: int) -> void:
	if item == null or amount <= 0:
		icon.texture = null
		amount_label.text = ""
		return
	icon.texture = item.icon
	amount_label.text = str(amount) if amount > 1 else ""
