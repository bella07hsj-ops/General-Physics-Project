extends Node

signal simulation_started
signal projectile_fired(v1: float)
signal collision_occurred(v2: float)
signal pendulum_peaked(delta_h: float, angle_rad: float)
signal simulation_finished(result: Dictionary)

enum SimState { IDLE, COCKING, FIRING, IN_FLIGHT, COLLIDING, SWINGING, PEAKED, DONE }

var state: SimState = SimState.IDLE
var current_mb: float = 0.0
var current_mc: float = 0.0
var current_result: Dictionary = {}
var measurement_log: Array = []   

# Animation Timer
var _timer: float = 0.0

const T_COCK    := 0.6
const T_FLIGHT  := 0.4
const T_COLLIDE := 0.15
const T_SWING   := 1.8


func start_simulation(mb_kg: float, mc_kg: float) -> void:
	if state != SimState.IDLE:
		return
	current_mb = mb_kg
	current_mc = mc_kg
	current_result = PhysicsConstants.full_calc(mb_kg, mc_kg)
	state = SimState.COCKING
	_timer = 0.0
	emit_signal("simulation_started")


func _process(delta: float) -> void:
	if state == SimState.IDLE or state == SimState.DONE:
		return
	_timer += delta

	match state:
		SimState.COCKING:
			if _timer >= T_COCK:
				state = SimState.FIRING
				_timer = 0.0

		SimState.FIRING:
			if _timer >= 0.05:
				state = SimState.IN_FLIGHT
				_timer = 0.0
				emit_signal("projectile_fired", current_result["v1"])

		SimState.IN_FLIGHT:
			if _timer >= T_FLIGHT:
				state = SimState.COLLIDING
				_timer = 0.0
				emit_signal("collision_occurred", current_result["v2"])

		SimState.COLLIDING:
			if _timer >= T_COLLIDE:
				state = SimState.SWINGING
				_timer = 0.0

		SimState.SWINGING:
			if _timer >= T_SWING:
				state = SimState.PEAKED
				_timer = 0.0
				emit_signal("pendulum_peaked",
					current_result["delta_h"],
					current_result["angle_rad"])

		SimState.PEAKED:
			if _timer >= 0.8:
				state = SimState.DONE
				_log_result()
				emit_signal("simulation_finished", current_result)

		SimState.DONE:
			pass


func reset() -> void:
	state = SimState.IDLE
	_timer = 0.0


func _log_result() -> void:
	measurement_log.append({
		"mb": current_mb,
		"mc": current_mc,
		"delta_h": current_result["delta_h"]
	})


func get_measurements_for_current() -> Array:
	var results := []
	for m in measurement_log:
		if abs(m["mb"] - current_mb) < 0.001 and abs(m["mc"] - current_mc) < 0.001:
			results.append(m["delta_h"])
	return results


func get_phase_progress() -> float:
	match state:
		SimState.COCKING:   return clamp(_timer / T_COCK, 0.0, 1.0)
		SimState.IN_FLIGHT: return clamp(_timer / T_FLIGHT, 0.0, 1.0)
		SimState.SWINGING:  return clamp(_timer / T_SWING, 0.0, 1.0)
		_: return 1.0


func is_idle() -> bool:
	return state == SimState.IDLE or state == SimState.DONE
