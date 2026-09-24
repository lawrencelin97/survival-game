extends CharacterBody2D
class_name Player
# Scene structure expected (build this in the Godot editor):
# Player (CharacterBody2D, this script)
#  ├─ Sprite2D / AnimatedSprite2D
#  ├─ CollisionShape2D
#  ├─ InteractionArea (Area2D, larger radius than the body collider)
#  │    └─ CollisionShape2D
#  ├─ Inventory (Node, Inventory.gd)
#  ├─ HealthComponent (Node, HealthComponent.gd)
#  ├─ HungerNeed (Node, NeedComponent.gd — set need_name = "hunger")
#  ├─ PlacementManager (Node2D, PlacementManager.gd)
#  ├─ InventoryUILayer (CanvasLayer)
#  │    └─ InventoryUI (Control, InventoryUI.gd — full rect, starts hidden)
#  ├─ BuildMenuUILayer (CanvasLayer)
#  │    └─ BuildMenuUI (Control, BuildMenuUI.gd — full rect, starts hidden)
#  └─ CraftingUILayer (CanvasLayer)
#       └─ CraftingUI (Control, CraftingUI.gd — full rect, starts hidden)

@export var speed := 120.0

@onready var interaction_area: Area2D = $InteractionArea
@onready var inventory: Inventory = $Inventory
@onready var health: HealthComponent = $HealthComponent
@onready var hunger: NeedComponent = $HungerNeed
@onready var placement: PlacementManager = $PlacementManager
@onready var inventory_ui: InventoryUI = $InventoryUILayer/InventoryUI
@onready var build_menu_ui: BuildMenuUI = $BuildMenuUILayer/BuildMenuUI
@onready var crafting_ui: CraftingUI = $CraftingUILayer/CraftingUI

func _ready() -> void:
	# Wire the systems that need each other's references. Doing this here
	# (rather than each system reaching out to find the player) keeps
	# Inventory/PlacementManager reusable for non-player entities later.
	placement.inventory = inventory
	hunger.depleted.connect(_on_hunger_depleted)
	inventory_ui.open_for(inventory)
	build_menu_ui.set_context(placement, inventory)

func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()
	elif event.is_action_pressed("place_confirm") and placement.is_active():
		if placement.is_placing():
			placement.confirm_placement()
		else:
			placement.confirm_demolish()
	elif event.is_action_pressed("place_cancel") and crafting_ui.visible:
		crafting_ui.close()
	elif event.is_action_pressed("place_cancel") and build_menu_ui.visible:
		build_menu_ui.close()
	elif event.is_action_pressed("build"):
		build_menu_ui.toggle()
	elif event.is_action_pressed("toggle_inventory"):
		inventory_ui.toggle()

func _try_interact() -> void:
	var nearest: Interactable = null
	var nearest_dist := INF
	for area in interaction_area.get_overlapping_areas():
		if area is Interactable:
			var dist := global_position.distance_squared_to(area.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = area
	if nearest:
		nearest.interact(self)

# Called by CraftingStation._on_interacted() when the player interacts
# with any crafting bench.
func open_crafting_menu(station: CraftingStation) -> void:
	crafting_ui.open_for(station, inventory)

func _on_hunger_depleted() -> void:
	# Placeholder for RimWorld-style "starving" consequences. For now, just
	# chip away at health while starving — replace with whatever you want.
	health.take_damage(1.0)

# Required input actions (Project Settings > Input Map):
#   move_left, move_right, move_up, move_down
#   interact       (e.g. E)
#   place_confirm  (e.g. Left Click)
#   place_cancel   (e.g. Right Click / Escape)
#   build            (e.g. "1" or "B" — opens/closes the build menu)
#   toggle_inventory (e.g. "I" or Tab)
