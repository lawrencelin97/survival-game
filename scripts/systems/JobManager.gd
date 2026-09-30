extends Node
# Autoload as "JobManager"
#
# A flat pool of available work, not assigned to anyone until a Villager
# requests one. WHY a pool instead of each job source (e.g. ResourceNode)
# tracking its own "am I claimed" flag: keeping claim state in one place
# means a villager that gets interrupted mid-job (or can't make progress —
# see Villager's stuck-detection) doesn't leave that job stuck claimed
# forever. JobManager just puts it back in the pool for someone else.
#
# WHY jobs currently come only from ResourceNode/ConstructionSite
# registering themselves: this is the simplest source of real work that
# gets villagers doing something end to end. A proper RimWorld-style
# player-designation system would sit in front of this later — it would
# just call add_job() the same way these do now.
#
# Jobs are picked by priority first (Job.PRIORITY), distance second — a
# villager will always prefer an available BUILD job over a HARVEST job,
# even a farther one, as long as it's actually able to do it (see
# Job.can_be_done_by).

signal jobs_changed
signal job_added(job: Job)  # lets a villager react immediately to new work — see Villager._on_job_added

var _available_jobs: Array[Job] = []
var _claimed_jobs: Array[Job] = []

func add_job(job: Job) -> void:
	_available_jobs.append(job)
	jobs_changed.emit()
	job_added.emit(job)

func remove_job(job: Job) -> void:
	_available_jobs.erase(job)
	_claimed_jobs.erase(job)
	jobs_changed.emit()

# Called by an idle Villager. Returns the highest-priority valid job this
# character can actually do, breaking ties by distance — or null if
# there's no workable job available right now.
func request_job(character: Node) -> Job:
	var best: Job = null
	var best_priority := INF
	var best_dist := INF
	for job in _available_jobs:
		if not job.is_valid():
			continue
		if not job.can_be_done_by(character):
			continue
		var priority := job.get_priority()
		var dist = character.global_position.distance_squared_to(job.target_position)
		if priority < best_priority or (priority == best_priority and dist < best_dist):
			best_priority = priority
			best_dist = dist
			best = job

	if best:
		_available_jobs.erase(best)
		_claimed_jobs.append(best)
		jobs_changed.emit()
	return best

# Called by a Villager that couldn't finish a job (interrupted, or no
# progress being made — e.g. it doesn't have the tool the job needs).
# Makes the job available again for a different villager to try.
func release_job(job: Job) -> void:
	if _claimed_jobs.has(job):
		_claimed_jobs.erase(job)
		if job.is_valid():
			_available_jobs.append(job)
		jobs_changed.emit()
