extends Character
class_name Villager
# A villager works through Jobs from JobManager autonomously: request a
# job, walk to it, interact with it repeatedly until it's done, then look
# for the next one. Everything about carrying items, equipping tools,
# taking damage, and interacting with things comes from Character — this
# only adds the decision loop that Player gets from keyboard input instead.
#
# KNOWN GAP: movement is a straight line toward the job's target position —
# no obstacle avoidance. A villager can get stuck against a wall or
# building on the way to a job. An AStarGrid2D wired against GridManager's
# occupancy (the same way RoomManager reads it) or Godot's own
# NavigationAgent2D/NavigationRegion2D are the natural next step once this
# becomes a real problem.
#
# KNOWN GAP: "no progress after N attempts, give up" is a generic
# stand-in for "does this villager actually have what a job needs" (e.g.
# an axe for a tree). It works today because every job target is currently
# a ResourceNode with a HealthComponent — a future job type without one
# would always look "stuck" under this check. Worth a real per-job-type
# capability check once job types diversify beyond harvesting.

enum State { IDLE, MOVING_TO_JOB, WORKING }

@export var interact_range := 40.0
@export var stuck_attempts_before_giving_up := 3
@export var think_interval := 0.5  # seconds between idle job-search attempts, so idle villagers aren't polling every frame

var _state := State.IDLE
var _current_job: Job
var _think_timer := 0.0
var _stuck_count := 0

func _physics_process(delta: float) -> void:
	match _state:
		State.IDLE:
			_think_timer -= delta
			if _think_timer <= 0.0:
				_think_timer = think_interval
				_try_find_job()
		State.MOVING_TO_JOB:
			_process_moving(delta)
		State.WORKING:
			_process_working()

func _try_find_job() -> void:
	var job := JobManager.request_job(global_position)
	if job:
		_current_job = job
		_stuck_count = 0
		_state = State.MOVING_TO_JOB

func _process_moving(delta: float) -> void:
	if not _current_job.is_valid():
		_abandon_job()
		return
	if global_position.distance_to(_current_job.target_position) <= interact_range:
		velocity = Vector2.ZERO
		_state = State.WORKING
		return
	move_toward_point(_current_job.target_position, delta)

func _process_working() -> void:
	if not _current_job.is_valid():
		_abandon_job()
		return

	var target_interactable := _get_target_interactable(_current_job.target)
	if target_interactable == null:
		_abandon_job()  # target doesn't expose an Interactable — nothing this villager can do with it
		return

	var health_before := _get_target_health(_current_job.target)
	interact_with(target_interactable)
	var health_after := _get_target_health(_current_job.target)

	if health_after == health_before:
		_stuck_count += 1
		if _stuck_count >= stuck_attempts_before_giving_up:
			_abandon_job()
	else:
		_stuck_count = 0

func _abandon_job() -> void:
	if _current_job:
		JobManager.release_job(_current_job)
	_current_job = null
	_state = State.IDLE

func _get_target_interactable(target: Node) -> Interactable:
	if target.has_node("Interactable"):
		return target.get_node("Interactable")
	return null

func _get_target_health(target: Node) -> float:
	if is_instance_valid(target) and target.has_node("HealthComponent"):
		var health_component: HealthComponent = target.get_node("HealthComponent")
		return health_component.current_health
	return -1.0
