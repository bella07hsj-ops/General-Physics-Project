extends Control

var _theory_points : Array = []
var _measured_points : Array = []
var _current_mc : float = 0.0997

const MARGIN_L : float = 55.0
const MARGIN_R : float = 20.0
const MARGIN_T : float = 20.0
const MARGIN_B : float = 45.0

var _x_max : float = 300.0
var _y_max : float = 20.0


func _ready() -> void:
	update_theory_curve(_current_mc)


func update_theory_curve(mc_kg: float) -> void:
	_current_mc = mc_kg
	_theory_points = PhysicsConstants.theory_curve(mc_kg, 100)
	var max_dh : float = 0.0
	for p in _theory_points:
		if p["dh"] > max_dh:
			max_dh = p["dh"]
	_y_max = max(max_dh * 1.3, 5.0)
	queue_redraw()


func add_measurement(mb_kg: float, dh_m: float) -> void:
	_measured_points.append({"mb_g": mb_kg * 1000.0, "dh_cm": dh_m * 100.0})
	queue_redraw()


func clear_measurements() -> void:
	_measured_points.clear()
	queue_redraw()


func _draw() -> void:
	var w : float = size.x
	var h : float = size.y
	var plot_w : float = w - MARGIN_L - MARGIN_R
	var plot_h : float = h - MARGIN_T - MARGIN_B

	draw_rect(Rect2(0, 0, w, h), Color(0.08, 0.10, 0.14))
	draw_rect(Rect2(MARGIN_L, MARGIN_T, plot_w, plot_h), Color(0.05, 0.07, 0.10))

	_draw_grid(plot_w, plot_h)

	draw_line(Vector2(MARGIN_L, MARGIN_T), Vector2(MARGIN_L, MARGIN_T + plot_h), Color(0.7, 0.7, 0.7), 1.5)
	draw_line(Vector2(MARGIN_L, MARGIN_T + plot_h), Vector2(MARGIN_L + plot_w, MARGIN_T + plot_h), Color(0.7, 0.7, 0.7), 1.5)

	_draw_labels(plot_w, plot_h)
	_draw_theory_curve(plot_w, plot_h)
	_draw_optimal_line(plot_w, plot_h)
	_draw_measured_points(plot_w, plot_h)


func _draw_grid(pw: float, ph: float) -> void:
	var grid_col := Color(0.2, 0.22, 0.28)
	for xi in range(0, 7):
		var xv : float = xi * 50.0
		var sx : float = MARGIN_L + (xv / _x_max) * pw
		draw_line(Vector2(sx, MARGIN_T), Vector2(sx, MARGIN_T + ph), grid_col, 1.0)
	for yi in range(0, 6):
		var yv : float = yi * (_y_max / 5.0)
		var sy : float = MARGIN_T + ph - (yv / _y_max) * ph
		draw_line(Vector2(MARGIN_L, sy), Vector2(MARGIN_L + pw, sy), grid_col, 1.0)


func _draw_labels(pw: float, ph: float) -> void:
	var font := ThemeDB.fallback_font
	var fs : int = 11

	for xi in range(0, 7):
		var xv : float = xi * 50.0
		var sx : float = MARGIN_L + (xv / _x_max) * pw
		draw_string(font, Vector2(sx - 12, MARGIN_T + ph + 16), str(int(xv)) + "g", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.75, 0.75, 0.75))

	for yi in range(0, 6):
		var yv : float = yi * (_y_max / 5.0)
		var sy : float = MARGIN_T + ph - (yv / _y_max) * ph
		draw_string(font, Vector2(4, sy + 4), "%.1f" % yv, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.75, 0.75, 0.75))

	draw_string(font, Vector2(MARGIN_L + pw * 0.5 - 40, MARGIN_T + ph + 36), "Mass of Projectile mb (g)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.9, 0.9, 0.9))
	draw_string(font, Vector2(2, MARGIN_T + ph * 0.5 - 20), "Δh", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.9, 0.9, 0.9))
	draw_string(font, Vector2(2, MARGIN_T + ph * 0.5 - 5), "(cm)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.7, 0.7, 0.7))

	draw_line(Vector2(MARGIN_L + pw - 110, MARGIN_T + 10), Vector2(MARGIN_L + pw - 85, MARGIN_T + 10), Color(0.2, 0.85, 0.75), 2.0)
	draw_string(font, Vector2(MARGIN_L + pw - 80, MARGIN_T + 15), "Theory (Eq.9)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.2, 0.85, 0.75))
	draw_circle(Vector2(MARGIN_L + pw - 100, MARGIN_T + 28), 4.0, Color(1.0, 0.85, 0.1))
	draw_string(font, Vector2(MARGIN_L + pw - 90, MARGIN_T + 33), "Measurement Value", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.85, 0.1))


func _draw_theory_curve(pw: float, ph: float) -> void:
	if _theory_points.size() < 2:
		return
	var col := Color(0.2, 0.85, 0.75)
	for i in range(_theory_points.size() - 1):
		var p0 : Dictionary = _theory_points[i]
		var p1 : Dictionary = _theory_points[i + 1]
		var x0 : float = MARGIN_L + (p0["mb"] / _x_max) * pw
		var y0 : float = MARGIN_T + ph - (p0["dh"] / _y_max) * ph
		var x1 : float = MARGIN_L + (p1["mb"] / _x_max) * pw
		var y1 : float = MARGIN_T + ph - (p1["dh"] / _y_max) * ph
		y0 = clamp(y0, MARGIN_T, MARGIN_T + ph)
		y1 = clamp(y1, MARGIN_T, MARGIN_T + ph)
		draw_line(Vector2(x0, y0), Vector2(x1, y1), col, 2.0)


func _draw_optimal_line(pw: float, ph: float) -> void:
	var mb_opt : float = PhysicsConstants.optimal_mass(_current_mc)
	var x_opt : float = MARGIN_L + (mb_opt * 1000.0 / _x_max) * pw
	if x_opt < MARGIN_L or x_opt > MARGIN_L + pw:
		return
	draw_dashed_line(Vector2(x_opt, MARGIN_T), Vector2(x_opt, MARGIN_T + ph), Color(1.0, 0.5, 0.2, 0.7), 1.5, 6.0)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(x_opt + 3, MARGIN_T + 14), "Optimal mb", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.6, 0.3))


func _draw_measured_points(pw: float, ph: float) -> void:
	for pt in _measured_points:
		var sx : float = MARGIN_L + (pt["mb_g"] / _x_max) * pw
		var sy : float = MARGIN_T + ph - (pt["dh_cm"] / _y_max) * ph
		sy = clamp(sy, MARGIN_T, MARGIN_T + ph)
		draw_circle(Vector2(sx, sy), 5.0, Color(1.0, 0.85, 0.1))
		draw_arc(Vector2(sx, sy), 5.0, 0, TAU, 16, Color(0.9, 0.6, 0.0), 1.5)
		
