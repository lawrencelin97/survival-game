extends Character
class_name Player
# Scene structure expected (build this in the Godot editor):
# Player (CharacterBody2D, this script)
#  ├─ Sprite2D / AnimatedSprite2D
#  ├─ CollisionShape2D
#  ├─ InteractionArea (Area2D, larger radius than the body collider)
#  │    └─ CollisionShape2D
#  ├─ Inventory (Node, Inventory.gd)
#  ├─ EquipmentSlots (Node, EquipmentSlots.gd)
#  ├─ HealthComponent (Node, HealthComponent.gd)
#  ├─ HungerNeed (Node, NeedComponent.gd — set need_name = "hunger")
#  ├─ PlacementManager (Node2D, PlacementManager.gd)
#  ├─ InventoryUILayer (CanvasLayer)
#  │    └─ InventoryUI (Control, InventoryUI.gd — full rect, starts hidden)
#  ├─ BuildMenuUILayer (CanvasLayer)
#  │    └─ BuildMenuUI (Control, BuildMenuUI.gd — full rect, starts hidden)
#  ├─ CraftingUILayer (CanvasLayer)
#  │    └─ CraftingUI (Control, CraftingUI.gd — full rect, starts hidden)
#  └─ StorageUILayer (CanvasLayer)
#       └─ StorageUI (Control, StorageUI.gd — full rect, starts hidden)

@onready var hunger: NeedComponent = $HungerNeed
@onready var placement: PlacementManager = $PlacementManager
@onready var inventory_ui: InventoryUI = $InventoryUILayer/InventoryUI
@onready var build_menu_ui: BuildMenuUI = $BuildMenuUILayer/BuildMenuUI
@onready var crafting_ui: CraftingUI = $CraftingUILayer/CraftingUI
@onready var storage_ui: StorageUI = $StorageUILayer/StorageUI

func _ready() -> void:
	placement.inventory = inventory
	hunger.depleted.connect(_on_hunger_depleted)
	inventory_ui.open_for(inventory, equipment)
	build_menu_ui.set_context(placement, inventory)

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed
	move_and_slide()

	# Single presses (handled below via _try_interact) deliver resources to
	# a ConstructionSite. Holding interact is a different mechanism
	# entirely — checked every physics frame here rather than waiting for a
	# press event — and only does something once a site is already fully
	# resourced, applying this character's work_rate toward its work_cost.
	if Input.is_action_pressed("interact"):
		_try_apply_work(delta)

func _try_apply_work(delta: float) -> void:
	var nearest := find_nearest_interactable()
	if nearest == null:
		return
	var site := nearest.get_parent()
	if site is ConstructionSite and site.is_resourced():
		site.apply_work(work_rate * delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()
	elif event.is_action_pressed("place_confirm") and placement.is_active():
		if placement.is_placing():
			placement.confirm_placement()
		else:
			placement.confirm_demolish()
	elif event.is_action_pressed("place_cancel") and storage_ui.visible:
		storage_ui.close()
	elif event.is_action_pressed("place_cancel") and crafting_ui.visible:
		crafting_ui.close()
	elif event.is_action_pressed("place_cancel") and build_menu_ui.visible:
		build_menu_ui.close()
	elif event.is_action_pressed("build"):
		build_menu_ui.toggle()
	elif event.is_action_pressed("toggle_inventory"):
		inventory_ui.toggle()

func _try_interact() -> void:
	var nearest := find_nearest_interactable()
	if nearest:
		interact_with(nearest)

func open_crafting_menu(station: CraftingStation) -> void:
	crafting_ui.open_for(station, inventory)

func open_storage_menu(chest: StorageChest) -> void:
	storage_ui.open_for(chest, inventory)

func _on_hunger_depleted() -> void:
	health.take_damage(1.0)

# Required input actions (Project Settings > Input Map):
#   move_left, move_right, move_up, move_down
#   interact       (e.g. E)
#   place_confirm  (e.g. Left Click)
#   place_cancel   (e.g. Right Click / Escape)
#   build            (e.g. "1" or "B" — opens/closes the build menu)
#   toggle_inventory (e.g. "I" or Tab)
