extends Node

const G        := 9.8          
const K_SPRING := 2730.0       
const DX_I     := 0.023        
const DX_F     := 0.0          
const F_FRICT  := 0.4          
const MD       := 0.041        

const STRING_LENGTH : float = 0.7   # [m]

const MB_MIN := 0.0047         
const MB_MAX := 0.300          
const MC_MIN := 0.029          
const MC_MAX := 0.200          


## Stage 0→1: Spring Energy → Initial Velocity of Projectile (Based on Eq. 8 / Eq. 9)
## (1/2) k (Dxi² - Dxf²) - fd*Dx = (1/2)(mb + md) * v1²
static func calc_muzzle_velocity(mb: float) -> float:
	var spring_energy := 0.5 * K_SPRING * (DX_I * DX_I - DX_F * DX_F)
	var friction_work := F_FRICT * DX_I
	var net_energy    := spring_energy - friction_work
	if net_energy <= 0.0:
		return 0.0
	var v1 := sqrt(2.0 * net_energy / (mb + MD))
	return v1


## Stage 1→2: Totally Inelastic Collision (Conservation of Momentum, Eq. 1)
## mb * v1 = (mb + mc) * v2
static func calc_post_collision_velocity(mb: float, mc: float, v1: float) -> float:
	return mb * v1 / (mb + mc)


## Stage 2→3: Maximum Height of The Pendulum Swing (Energy Conservation, Eq. 2)
## (1/2)(mb+mc)v2² = (mb+mc) g Dh
static func calc_delta_h(v2: float) -> float:
	return (v2 * v2) / (2.0 * G)


## Total: mb, mc → Δh (Eq. 9 Complete Calculation)
static func full_calc(mb: float, mc: float) -> Dictionary:
	var v1  := calc_muzzle_velocity(mb)
	var v2  := calc_post_collision_velocity(mb, mc, v1)
	var dh  := calc_delta_h(v2)
	var angle := 0.0
	if dh < STRING_LENGTH:
		angle = acos(1.0 - dh / STRING_LENGTH)
	else:
		angle = PI
	return {
		"v1": v1,
		"v2": v2,
		"delta_h": dh,
		"angle_rad": angle
	}


## For Theoretical Curves: mb Arrange → Δh Arrange
static func theory_curve(mc: float, steps: int = 80) -> Array:
	var points := []
	for i in range(steps + 1):
		var mb := MB_MIN + (MB_MAX - MB_MIN) * float(i) / float(steps)
		var result := full_calc(mb, mc)
		points.append({"mb": mb * 1000.0, "dh": result["delta_h"] * 100.0})  
	return points


## Optimal Mass of Projectile (Eq. 10)
static func optimal_mass(mc: float) -> float:
	return (mc + sqrt(mc * mc + 8.0 * mc * MD)) / 2.0
