extends Node
class_name NeedComponent
# WHY one generic "need" component instead of a dedicated HungerComponent:
# You said minimal for now (health + hunger) but likely to expand later
# (temperature, sleep, mood — RimWorld's actual need bars). If hunger gets
# its own bespoke script, adding thirst/temperature later means either
# duplicating that script three times or refactoring under pressure. A need
# is really just "a value that decays over time and does something at
# thresholds" — hunger, thirst, temperature, and sleep all fit that shape.
#
# To add a new need later: add a NeedComponent node to the player, set
# need_name/decay_rate/thresholds in the Inspector, connect its signals.
# No new script required.

signal value_changed(current: float, max: float)
signal became_critical
signal became_normal
signal depleted

@export var need_name := "hunger"
@export var max_value := 100.0
@export var decay_per_second := 0.15  # ~11 min from full to empty; tune freely
@export var critical_threshold := 20.0
@export var starts_full := true

var current_value: float
var _was_critical := false

func _ready() -> void:
	current_value = max_value if starts_full else 0.0

func _process(delta: float) -> void:
	if current_value <= 0.0:
		return
	current_value = max(0.0, current_value - decay_per_second * delta)
	value_changed.emit(current_value, max_value)
	_check_threshold()
	if current_value <= 0.0:
		depleted.emit()

func restore(amount: float) -> void:
	current_value = min(max_value, current_value + amount)
	value_changed.emit(current_value, max_value)
	_check_threshold()

func _check_threshold() -> void:
	var is_critical := current_value <= critical_threshold
	if is_critical and not _was_critical:
		became_critical.emit()
	elif not is_critical and _was_critical:
		became_normal.emit()
	_was_critical = is_critical
