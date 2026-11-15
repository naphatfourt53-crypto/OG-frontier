class_name Stamina
extends RefCounted
# EVA stamina bar. One instance per EVA. Data from data/stamina.json (see Data Book).
# Energy unit: Btu. Time: 1 game second = time_scale_h_per_game_s hours (0.1 h).
# drain per game second (Btu) = rate_btu_per_hr * time_scale_h_per_game_s

static var _cfg: Dictionary = {}

static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var f := FileAccess.open("res://data/stamina.json", FileAccess.READ)
		_cfg = JSON.parse_string(f.get_as_text())
	return _cfg

var capacity_btu: float = 0.0
var energy_btu: float = 0.0
var burst_left_s: float = 0.0
var pace: String = "normal"

# life_option_name: the chosen life-support option name ("Open-loop", "ECLSS Standard", "ECLSS Advanced").
# has_exercise: true if the station has the exercise module; false applies the capacity penalty.
static func capacity_for(life_option_name: String, has_exercise: bool) -> float:
	var c := cfg()
	var tier: String = c["life_option_to_tier"].get(life_option_name, "open_loop")
	var cap := float(c["capacity_btu"][tier])
	if not has_exercise:
		cap *= 1.0 - float(c["no_exercise_capacity_penalty_pct"])
	return cap

static func create(life_option_name: String, has_exercise: bool) -> Stamina:
	var s := Stamina.new()
	s.capacity_btu = capacity_for(life_option_name, has_exercise)
	s.energy_btu = s.capacity_btu
	s.burst_left_s = float(cfg()["burst_max_s"])
	return s

static func drain_per_game_s(pace_name: String) -> float:
	var c := cfg()
	return float(c["rate_btu_per_hr"][pace_name]) * float(c["time_scale_h_per_game_s"])

static func speed_mult(pace_name: String) -> float:
	return float(cfg()["pace_speed_mult"][pace_name])

# Seconds of game time until empty if one pace is held from full. Used by tests and tooltips.
static func seconds_to_empty(capacity: float, pace_name: String) -> float:
	return capacity / drain_per_game_s(pace_name)

# Advance by delta game seconds. wanted_pace is the player's choice; returns the pace actually applied
# (burst falls back to "hard" when its budget is spent). is_moving=false drains at the "easy" rate.
func step(delta: float, wanted_pace: String, is_moving: bool) -> String:
	var applied := wanted_pace
	if applied == "burst":
		if burst_left_s <= 0.0:
			applied = "hard"
		else:
			burst_left_s = maxf(0.0, burst_left_s - delta)
	if not is_moving:
		applied = "easy"
	pace = applied
	energy_btu = maxf(0.0, energy_btu - drain_per_game_s(applied) * delta)
	return applied

func fraction() -> float:
	return energy_btu / capacity_btu if capacity_btu > 0.0 else 0.0

func in_reserve() -> bool:
	return fraction() <= float(cfg()["reserve_pct"])

func is_empty() -> bool:
	return energy_btu <= 0.0

# Extra EVA food in kcal for hours spent outside (200 kcal per hour, game time converted to hours).
static func eva_food_kcal(game_seconds: float) -> float:
	var c := cfg()
	return float(c["eva_food_kcal_per_h"]) * game_seconds * float(c["time_scale_h_per_game_s"])
