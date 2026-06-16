extends Node3D

@onready var driver_mesh: Node3D = $DriverMesh

const COCK_RETRACT : float = 0.023
var _cocking : bool = false
var _cock_time : float = 0.0
var _base_driver_pos : Vector3


func _ready() -> void:
	if driver_mesh:
		_base_driver_pos = driver_mesh.position


func animate_cock() -> void:
	_cocking = true
	_cock_time = 0.0


func _process(delta: float) -> void:
	if not _cocking:
		return
	_cock_time += delta

	const TOTAL : float = 0.6
	var t : float = clamp(_cock_time / TOTAL, 0.0, 1.0)

	if driver_mesh:
		if t < 0.5:
			var retract : float = sin(t * PI) * COCK_RETRACT
			driver_mesh.position = _base_driver_pos + Vector3(-retract, 0.0, 0.0)
		else:
			var push : float = 1.0 - (t - 0.5) * 2.0
			driver_mesh.position = _base_driver_pos + Vector3(push * 0.01, 0.0, 0.0)

	if t >= 1.0:
		_cocking = false
		if driver_mesh:
			driver_mesh.position = _base_driver_pos
