class_name Farm
extends RefCounted
# Greenhouse crops and lamp power. Data from data/farm.json (NASA BVAD values, see Data Book).
# A plot is a plain Dictionary so it saves to JSON without extra code:
#   {"crop": "lettuce", "area_m2": 1.0, "age_days": 0.0, "light_sum": 0.0, "water_sum": 0.0}

static var _cfg: Dictionary = {}

static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var f := FileAccess.open("res://data/farm.json", FileAccess.READ)
		_cfg = JSON.parse_string(f.get_as_text())
	return _cfg

static func crop(id: String) -> Dictionary:
	return cfg()["crops"][id]

# Daily light integral, mol per m2 per day: PPFD (umol/m2/s) * hours * 3600 / 1e6.
static func dli(ppfd_umol_m2_s: float, photoperiod_h: float) -> float:
	return ppfd_umol_m2_s * photoperiod_h * 3600.0 / 1000000.0

# Electrical lamp power per m2 of crop, W/m2 = PPFD / efficacy (umol per joule).
static func led_power_w_per_m2(ppfd_umol_m2_s: float, efficacy_umol_per_j: float) -> float:
	return ppfd_umol_m2_s / efficacy_umol_per_j

# Lamp energy per m2 per day, kWh: W/m2 * photoperiod hours / 1000.
static func led_kwh_per_m2_day(ppfd_umol_m2_s: float, efficacy_umol_per_j: float, photoperiod_h: float) -> float:
	return led_power_w_per_m2(ppfd_umol_m2_s, efficacy_umol_per_j) * photoperiod_h / 1000.0

# Light factor 0..1. game rule: linear until the crop's target DLI. DLI target null -> 1.0.
static func light_factor(crop_id: String, dli_actual: float) -> float:
	var target = crop(crop_id)["dli_mol_m2_d"]
	if target == null:
		return 1.0
	return minf(1.0, dli_actual / float(target))

static func new_plot(crop_id: String, area_m2: float) -> Dictionary:
	return {"crop": crop_id, "area_m2": area_m2, "age_days": 0.0, "light_sum": 0.0, "water_sum": 0.0}

# Advance one plot by `days`. water_factor 0..1 (1 = fully watered).
static func advance_plot(plot: Dictionary, days: float, ppfd_umol_m2_s: float, photoperiod_h: float, water_factor: float) -> void:
	var f := light_factor(plot["crop"], dli(ppfd_umol_m2_s, photoperiod_h))
	plot["age_days"] = float(plot["age_days"]) + days
	plot["light_sum"] = float(plot["light_sum"]) + f * days
	plot["water_sum"] = float(plot["water_sum"]) + clampf(water_factor, 0.0, 1.0) * days

static func crop_ready(plot: Dictionary) -> bool:
	return float(plot["age_days"]) >= float(crop(plot["crop"])["growth_days"])

# Yield in kg of fresh edible mass for the whole plot, from the day-averaged light and water factors.
# kg = edible g fw/m2/d * growth days * f_light * f_water * area / 1000
static func harvest_kg(plot: Dictionary) -> float:
	var c := crop(plot["crop"])
	var age := maxf(float(plot["age_days"]), 0.0001)
	var f_light := float(plot["light_sum"]) / age
	var f_water := float(plot["water_sum"]) / age
	return float(c["edible_g_fw_m2_d"]) * float(c["growth_days"]) * f_light * f_water * float(plot["area_m2"]) / 1000.0
