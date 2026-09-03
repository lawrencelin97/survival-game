# Survival Crafting/Building Foundation — Architecture Notes

This mirrors the component + Resource-based approach from your strategy
game: global systems as autoloads, reusable behavior as components (small
Nodes with a single job), data as Resources instead of hardcoded values.

## The core idea

Everything in a RimWorld-like reduces to a few repeating shapes:
- **Things with health that can be damaged** → `HealthComponent`
- **Things that decay over time and matter at thresholds** → `NeedComponent`
- **Things the player can walk up to and act on** → `Interactable`
- **Data that designers should be able to tweak without touching code** →
  `Resource` subclasses (`ItemData`, `RecipeData`, `BuildingData`)

Building the foundation around these shapes (rather than, say, a `Tree`
script and a `Rock` script and a `Wall` script that each reimplement
"has health, can be interacted with") is what makes it extensible — a new
item, recipe, or resource node is usually just a new `.tres` file, not new
code.

## Folder structure

```
autoloads/       GridManager.gd — register as an Autoload singleton
components/      Interactable, HealthComponent, NeedComponent
resources/       ItemData, ItemStack, RecipeData, BuildingData (data, not logic)
systems/         Inventory, CraftingManager, PlacementManager
player/          Player.gd
world/           ResourceNode, PlacedBuilding (base class for placed scenes)
```

## Setup steps

1. **Copy these scripts** into your Godot project preserving the folder
   structure (or flatten it — Godot doesn't care where scripts live, this
   is just for your own organization).
2. **Register the autoload**: Project Settings → Autoload → add
   `autoloads/GridManager.gd` with the name `GridManager`.
3. **Input Map**: add actions `move_left`, `move_right`, `move_up`,
   `move_down`, `interact`, `place_confirm`, `place_cancel`.
4. **Build the Player scene** as described in the comment at the top of
   `Player.gd` — a `CharacterBody2D` with `Inventory`, `HealthComponent`,
   a `NeedComponent` (named `HungerNeed`), `InteractionArea`, and
   `PlacementManager` as children.
5. **Create your first ItemData**: right-click in the FileSystem dock →
   New Resource → search "ItemData" → fill in id/display_name/icon.
6. **Create a ResourceNode scene**: `StaticBody2D` root with
   `ResourceNode.gd`, plus `Interactable` and `HealthComponent` children as
   described in that script's header comment. Set `drop_item` to the
   ItemData you made.
7. **Create a BuildingData + PlacedBuilding scene** the same way once
   you're ready to place things — `BuildingData.scene` points at a scene
   whose root extends `PlacedBuilding.gd`.

## Why grid-snapped placement specifically

`PlacementManager` snaps to `GridManager`'s cell grid and checks two things
before allowing confirmation: are the target cells free, and can the
player afford the cost. Both checks happen every frame while the ghost
follows the mouse, so the color feedback (green/red) is always accurate —
no separate "validate on click" step to get out of sync.

## Known gaps to fill in as you build

- **Item pickups**: `ResourceNode._spawn_drop()` currently just prints.
  Either spawn a world pickup scene, or pass the interacting player's
  `Inventory` through so drops go straight into it.
- **Crafting UI**: `CraftingManager` is logic-only; you'll want a UI scene
  that lists available `RecipeData` resources and calls `craft()`.
- **Save/load**: nothing here persists yet. `Inventory.slots` and each
  `NeedComponent.current_value` are the main things you'll want to
  serialize once you get to that.
- **Needs beyond hunger**: add another `NeedComponent` node (e.g. named
  `ThirstNeed`) with its own thresholds — no script changes needed.
