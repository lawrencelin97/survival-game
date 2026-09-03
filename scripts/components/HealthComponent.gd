extends Node
class_name HealthComponent
# Same component you already used in the strategy game (characters,
# structures, barriers) — reused here for the player, resource nodes
# (trees/rocks that "die" when depleted), and later enemies/animals.

signal health_changed(current: float, max: float)
signal died

@export var max_health := 100.0
var current_health: float

func _ready() -> void:
	current_health = max_health

func take_damage(amount: float) -> void:
	if current_health <= 0:
		return
	current_health = max(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		died.emit()

func heal(amount: float) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func is_dead() -> bool:
	return current_health <= 0
