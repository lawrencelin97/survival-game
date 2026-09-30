extends Character
class_name Villager
# A villager works through Jobs from JobManager autonomously: request a
# job, walk to it, work it — indefinitely, if the job is one that never
# naturally finishes (an infinite OreDeposit, say) — until either the
# target becomes invalid on its own (a tree depletes and frees itself) or
# a higher-priority job appears and preempts it. There's no more reactive
# "no progress, give up" check: Job.can_be_done_by() is checked BEFORE a
# job is ever claimed (see JobManager.request_job), so a villager simply
# never picks up work it can't do — nothing left to detect after the fact.
#
# WHY preemption is push (JobManager notifies) rather than pull (villager
# polls "is something better available"): polling for a better job every
# tick just to usually find nothing is wasted work, and was the source of
# the original bug — reactive checks firing on jobs that were actually
# fine, just unmeasurable. Reacting only when JobManager actually has new
# work is both cheaper and correct by construction.
#
# KNOWN GAP: movement is a straight line toward the job's target position —
# no obstacle avoidance. A villager can get stuck against a wall or
# building on the way to a job. An AStarGrid2D wired against GridManager's
# occupancy (the same way RoomManager reads it) or Godot's own
# NavigationAgent2D/NavigationRegion2D are the natural next step once this
# becomes a real problem.
#
# KNOWN GAP: interact_range is a single fixed radius from the job's
# target_position (its origin tile). For a large multi-cell ConstructionSite
# this means a villager touching the middle of the structure but far from
# its origin corner might not be considered "close enough" — a footprint-
# aware range check would be the fix, not implemented here.

enum State { IDLE, MOVING_TO_JOB, WORKING }

@export var interact_range := 40.0
@export var think_interval := 0.5  # seconds between idle job-search attempts, so idle villagers aren't polling every frame

var _state := State.IDLE
var _current_job: Job
var _think_timer := 0.0

func _ready() -> void:
	JobManager.job_added.connect(_on_job_added)

func _physics_process(delta: float) -> void:
	match _state:
		State.IDLE:
			_think_timer_tick(delta)
		State.MOVING_TO_JOB:
			_process_moving(delta)
		State.WORKING:
			_process_working(delta)

func _think_timer_tick(delta: float) -> void:
	_think_timer -= delta
	if _think_timer <= 0.0:
		_think_timer = think_interval
		_try_find_job()

func _try_find_job() -> void:
	var job := JobManager.request_job(self)
	if job:
		_current_job = job
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

func _process_working(delta: float) -> void:
	if not _current_job.is_valid():
		_abandon_job()
		return

	var target := _current_job.target
	if target is ConstructionSite and target.is_resourced():
		# Building is a held/continuous action, not a single interact
		# press — same reason Player checks this separately in
		# _physics_process rather than through the normal interact flow.
		target.apply_work(work_rate * delta)
		return

	var target_interactable := _get_target_interactable(target)
	if target_interactable == null:
		_abandon_job()  # target doesn't expose an Interactable — nothing this villager can do with it
		return
	interact_with(target_interactable)

func _abandon_job() -> void:
	if _current_job:
		JobManager.release_job(_current_job)
	_current_job = null
	_state = State.IDLE

# Called whenever JobManager gets new work, regardless of this villager's
# current state. An idle villager tries for it immediately rather than
# waiting for its next think tick; a working villager only interrupts
# itself for something higher priority than what it's already doing, and
# only if it can actually do the new job.
func _on_job_added(new_job: Job) -> void:
	if _current_job == null:
		_try_find_job()
		return
	if new_job.get_priority() < _current_job.get_priority() and new_job.can_be_done_by(self):
		_abandon_job()
		_try_find_job()

func _get_target_interactable(target: Node) -> Interactable:
	if target.has_node("Interactable"):
		return target.get_node("Interactable")
	return null
