extends Node3D

var _start_pos : Vector3 = Vector3.ZERO
var _target_pos : Vector3 = Vector3.ZERO
var _travel_time : float = 0.4
var _elapsed : float = 0.0
var _moving : bool = false
var _visible_mesh : MeshInstance3D
var _mass_kg : float = 0.0


func _ready() -> void:
	_start_pos = position
	if has_node("MeshInstance3D"):
		_visible_mesh = $MeshInstance3D


func setup(mass_kg: float, start: Vector3, target: Vector3) -> void:
	_mass_kg = mass_kg
	_start_pos = start
	_target_pos = target
	position = start
	visible = true

	var t : float = (mass_kg - PhysicsConstants.MB_MIN) / (PhysicsConstants.MB_MAX - PhysicsConstants.MB_MIN)
	var radius : float = lerp(0.015, 0.045, t)
	scale = Vector3.ONE * radius * 40.0
	_update_color(t)


func fire(travel_time: float) -> void:
	_travel_time = travel_time
	_elapsed = 0.0
	_moving = true


func _process(delta: float) -> void:
	if not _moving:
		return
	_elapsed += delta
	var t : float = clamp(_elapsed / _travel_time, 0.0, 1.0)
	position = _start_pos.lerp(_target_pos, t)
	position.y += sin(t * PI) * 0.02
	if t >= 1.0:
		_moving = false
		visible = false


func _update_color(t: float) -> void:
	if _visible_mesh == null:
		return
	var col := Color(0.4 + t * 0.5, 0.6 - t * 0.4, 0.9 - t * 0.6)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = t * 0.6
	mat.roughness = 0.3
	_visible_mesh.material_override = mat


func reset() -> void:
	_moving = false
	visible = false
	position = _start_pos
