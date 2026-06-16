extends Node3D

@onready var sim_ctrl     : Node          = $SimulationController
@onready var projectile   : Node3D        = $Projectile
@onready var cup_pendulum : Node3D        = $CupPendulum
@onready var spring_gun   : Node3D        = $SpringGun

# UI
@onready var slider_mb    : HSlider       = $UI/ControlPanel/VBox/MassSection/SliderMb
@onready var slider_mc    : HSlider       = $UI/ControlPanel/VBox/MassSection/SliderMc
@onready var label_mb     : Label         = $UI/ControlPanel/VBox/MassSection/LabelMb
@onready var label_mc     : Label         = $UI/ControlPanel/VBox/MassSection/LabelMc
@onready var btn_fire : Button = $UI/StatusBar/BtnFire
@onready var btn_reset    : Button        = $UI/ControlPanel/VBox/BtnReset
@onready var label_result : RichTextLabel = $UI/ResultPanel/VBox/LabelResult
@onready var label_state  : Label         = $UI/StatusBar/LabelState
@onready var graph_panel  : Control       = $UI/GraphPanel
@onready var btn_3d    : Button = $UI/StatusBar/Btn3D
@onready var btn_graph : Button = $UI/StatusBar/BtnGraph


const GUN_TIP := Vector3(-1.1, 0.85, 0.0)
const CUP_POS := Vector3(0.5, 0.85, 0.0)

var _mb_kg      : float = 0.0636
var _mc_kg      : float = 0.0997
var _trial_count: int   = 0


func _ready() -> void:
	slider_mb.min_value = 4.7
	slider_mb.max_value = 300.0
	slider_mb.step      = 0.1
	slider_mb.value     = 63.6

	slider_mc.min_value = 29.0
	slider_mc.max_value = 200.0
	slider_mc.step      = 0.1
	slider_mc.value     = 99.7

	slider_mb.value_changed.connect(_on_mb_changed)
	slider_mc.value_changed.connect(_on_mc_changed)
	btn_fire.pressed.connect(_on_fire)
	btn_reset.pressed.connect(_on_reset)

	sim_ctrl.simulation_started.connect(_on_started)
	sim_ctrl.projectile_fired.connect(_on_fired)
	sim_ctrl.collision_occurred.connect(_on_collision)
	sim_ctrl.pendulum_peaked.connect(_on_peaked)
	sim_ctrl.simulation_finished.connect(_on_finished)

	btn_3d.pressed.connect(func():
		graph_panel.visible = false
		$UI/ControlPanel.visible = false
		$UI/ResultPanel.visible = false
	)
	btn_graph.pressed.connect(func():
		graph_panel.visible = true
		$UI/ControlPanel.visible = true
		$UI/ResultPanel.visible = true
	)

	graph_panel.visible = false
	$UI/ControlPanel.visible = false
	$UI/ResultPanel.visible = false

	graph_panel.update_theory_curve(_mc_kg)
	_update_labels()
	_preview_result()
	label_state.text = "Ready — 🎬 3D View / 📊 Switch to the Graph Button"


func _on_mb_changed(v: float) -> void:
	_mb_kg = v / 1000.0
	_update_labels()
	_preview_result()


func _on_mc_changed(v: float) -> void:
	_mc_kg = v / 1000.0
	_update_labels()
	graph_panel.update_theory_curve(_mc_kg)
	_preview_result()


func _update_labels() -> void:
	label_mb.text = "Mass of Projecile  mb : %.1f g" % (_mb_kg * 1000.0)
	label_mc.text = "Effective Mass of Pendulum  mc : %.1f g" % (_mc_kg * 1000.0)


func _preview_result() -> void:
	var r     := PhysicsConstants.full_calc(_mb_kg, _mc_kg)
	var opt_g := PhysicsConstants.optimal_mass(_mc_kg) * 1000.0
	label_result.text = (
		"[b]Predicted Value (Eq. 9)[/b]\n"
		+ "Initial Velocity  v₁ = %.3f m/s\n"  % r["v1"]
		+ "After The Collision   v₂ = %.4f m/s\n"   % r["v2"]
		+ "Maximum Height Δh = [color=cyan]%.3f cm[/color]\n" % (r["delta_h"] * 100.0)
		+ "Maximum Angle  θ = %.1f°\n"       % rad_to_deg(r["angle_rad"])
		+ "─────────────────\n"
		+ "Optimal mb = [color=orange]%.1f g[/color]" % opt_g
	)

func _on_fire() -> void:
	if not sim_ctrl.is_idle():
		return
	btn_fire.disabled = true
	_trial_count += 1
	sim_ctrl.start_simulation(_mb_kg, _mc_kg)


func _on_reset() -> void:
	sim_ctrl.reset()
	projectile.reset()
	cup_pendulum.reset()
	btn_fire.disabled = false
	_trial_count = 0
	graph_panel.clear_measurements()
	label_state.text = "Initialization Complete"
	_update_labels()
	_preview_result()

func _on_started() -> void:
	label_state.text = "🔧 Spring cocking in progress"
	projectile.setup(_mb_kg, GUN_TIP, CUP_POS)
	if spring_gun.has_method("animate_cock"):
		spring_gun.animate_cock()


func _on_fired(v1: float) -> void:
	label_state.text = "🚀 Fire!  v₁ = %.3f m/s" % v1
	projectile.fire(sim_ctrl.T_FLIGHT)


func _on_collision(v2: float) -> void:
	label_state.text = "💥 Crash!  v₂ = %.4f m/s" % v2
	cup_pendulum.flash_collision()
	cup_pendulum.start_swing(
		sim_ctrl.current_result["angle_rad"],
		sim_ctrl.T_SWING
	)


func _on_peaked(delta_h: float, _angle: float) -> void:
	label_state.text = "📐 Maximum Height:  Δh = %.3f cm" % (delta_h * 100.0)


func _on_finished(result: Dictionary) -> void:
	var dh_cm : float = result["delta_h"] * 100.0
	label_state.text = "✅ Complete (Attempt #%d) | Δh = %.3f cm" % [_trial_count, dh_cm]
	graph_panel.add_measurement(_mb_kg, result["delta_h"])
	btn_fire.disabled = false
	sim_ctrl.reset()


func _on_btn_graph_pressed() -> void:
	graph_panel.visible = true
	$UI/ControlPanel.visible = true
	$UI/ResultPanel.visible = true


func _on_btn_3d_pressed() -> void:
	graph_panel.visible = false
	$UI/ControlPanel.visible = false
	$UI/ResultPanel.visible = false


func _on_btn_fire_pressed() -> void:
	_on_fire()
