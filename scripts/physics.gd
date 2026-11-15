class_name OrbitMath
extends RefCounted
# Orbital mechanics and solar flux. All numbers come from data/physics.json (see Data Book).
# Pure static functions: no scene access, no hidden state. Units are in every name:
# m, s, days, AU, W_m2. Never hardcode gameplay numbers here.

static var _cfg: Dictionary = {}

static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var f := FileAccess.open("res://data/physics.json", FileAccess.READ)
		_cfg = JSON.parse_string(f.get_as_text())
	return _cfg

static func const_f(key: String) -> float:
	return float(cfg()["constants"][key])

# Circular orbit speed v = sqrt(mu / r). r_m in metres, result in m/s.
static func circular_speed(mu_m3_s2: float, r_m: float) -> float:
	return sqrt(mu_m3_s2 / r_m)

# Hohmann transfer time between two circular orbits around one body.
# t = PI * sqrt(a^3 / mu), a = (r1 + r2) / 2. Result in days.
static func hohmann_days(r1_m: float, r2_m: float, mu_m3_s2: float) -> float:
	var a := (r1_m + r2_m) * 0.5
	return PI * sqrt(a * a * a / mu_m3_s2) / const_f("seconds_per_day")

# Delta-v of the two Hohmann burns, in m/s (departure burn + arrival burn).
static func hohmann_dv_m_s(r1_m: float, r2_m: float, mu_m3_s2: float) -> float:
	var a := (r1_m + r2_m) * 0.5
	var v1 := circular_speed(mu_m3_s2, r1_m)
	var v2 := circular_speed(mu_m3_s2, r2_m)
	var vp := sqrt(mu_m3_s2 * (2.0 / r1_m - 1.0 / a))
	var va := sqrt(mu_m3_s2 * (2.0 / r2_m - 1.0 / a))
	return absf(vp - v1) + absf(v2 - va)

# Hohmann transfer between two planets, from semi-major axes in AU. Days.
static func planet_hohmann_days(from_body: String, to_body: String) -> float:
	var au := const_f("au_m")
	var b: Dictionary = cfg()["bodies"]
	return hohmann_days(float(b[from_body]["a_au"]) * au, float(b[to_body]["a_au"]) * au, const_f("mu_sun_m3_s2"))

# Synodic period of two bodies: 1 / |1/P1 - 1/P2|. Days.
static func synodic_days(p1_days: float, p2_days: float) -> float:
	return 1.0 / absf(1.0 / p1_days - 1.0 / p2_days)

# Waiting time at an OUTER planet before the return window opens (conjunction-class round trip).
# Phase angle phi = theta_outer - theta_inner. Result in days.
static func stay_days_outer(inner: String, outer: String) -> float:
	var b: Dictionary = cfg()["bodies"]
	var t := planet_hohmann_days(inner, outer)
	var n_i := TAU / float(b[inner]["period_days"])
	var n_o := TAU / float(b[outer]["period_days"])
	var d := n_o - n_i                       # negative: inner planet is faster
	var phi_a := (PI - n_o * t) + d * t      # phase when we arrive
	var phi_r := n_i * t - PI                # phase needed to leave for home
	var period := TAU / absf(d)
	return fposmod((phi_r - phi_a) / d, period)

static func round_trip_days(inner: String, outer: String) -> float:
	return 2.0 * planet_hohmann_days(inner, outer) + stay_days_outer(inner, outer)

# Sunlight on a surface at r_au from the Sun: S = 1361 / r^2. W/m2.
static func solar_wm2(r_au: float) -> float:
	return const_f("solar_constant_w_m2") / (r_au * r_au)

# Solar array output scales with the same 1/r^2 law. Returns kW for an array rated at 1 AU.
static func solar_array_kw(rated_kw_at_1au: float, r_au: float) -> float:
	return rated_kw_at_1au * solar_wm2(r_au) / const_f("solar_constant_w_m2")

# Consumables for a mission: kg of one resource. rate_kg_per_crew_day from game_data constants.crew_day_kg.
# recycle_fraction is 0..1 (life option water_rec / o2_rec). Food has no recycling: pass 0.
static func consumable_kg(crew: int, days: float, rate_kg_per_crew_day: float, recycle_fraction: float) -> float:
	return float(crew) * days * rate_kg_per_crew_day * (1.0 - recycle_fraction)

# Mission length in days for a chosen transfer. out/back are transfer days, stay is days at target.
static func mission_days(out_days: float, stay_days: float, back_days: float) -> float:
	return out_days + stay_days + back_days
