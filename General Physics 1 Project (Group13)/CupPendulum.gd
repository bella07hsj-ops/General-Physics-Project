extends Node3D

const STRING_LENGTH : float = 0.7


var _pivot: Node3D          
var _cup_mesh: Node3D       
var _target_angle: float = 0.0
var _current_angle: float = 0.0
var _swinging: bool = false
var _swing_time: float = 1.8
var _elapsed: float = 0.0
var _peak_angle: float = 0.0

signal peaked(delta_h: float)


func _ready() -> void:
	_pivot = $Pivot if has_node("Pivot") else self
	_cup_mesh = $Pivot/Cup if has_node("Pivot/Cup") else null


func start_swing(angle_rad: float, swing_duration: float) -> void:
	_target_angle  = angle_rad
	_peak_angle    = angle_rad
	_swing_time    = swing_duration
	_elapsed       = 0.0
	_swinging      = true
	_current_angle = 0.0


func _process(delta: float) -> void:
	if not _swinging:
		return

	_elapsed += delta
	var t : float = clamp(_elapsed / _swing_time, 0.0, 1.0)

	
	var damping := exp(-t * 1.2)
	var angle_t: float
	if t <= 0.5:
		angle_t = _peak_angle * sin(t * PI)
	else:
		angle_t = _peak_angle * sin(t * PI) * damping

	_current_angle = angle_t
	_apply_rotation(angle_t)

	if t >= 0.49 and t <= 0.51 and _swinging:
		var dh := STRING_LENGTH * (1.0 - cos(_peak_angle))
		emit_signal("peaked", dh)

	if t >= 1.0:
		_swinging = false
		_current_angle = 0.0
		_apply_rotation(0.0)


func _apply_rotation(angle: float) -> void:
	if _pivot:
		_pivot.rotation.z = angle


func flash_collision() -> void:
	if _cup_mesh == null:
		return
	var tween := create_tween()
	if _cup_mesh.has_node("MeshInstance3D"):
		var mesh := _cup_mesh.get_node("MeshInstance3D") as MeshInstance3D
		if mesh:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(1.0, 0.6, 0.1)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.4, 0.0)
			mat.emission_energy_multiplier = 2.0
			mesh.material_override = mat
			tween.tween_callback(func():
				mesh.material_override = null
			).set_delay(0.3)


func reset() -> void:
	_swinging = false
	_current_angle = 0.0
	if _pivot:
		_pivot.rotation.z = 0.0
