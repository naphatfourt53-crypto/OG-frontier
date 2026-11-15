extends Node
# GameState (autoload). Holds data, ship design, station, and runs the mission simulation.
# All numbers come from res://data/game_data.json

const DATA_PATH := "res://data/game_data.json"
const SAVE_PATH := "user://ogfrontier_save.json"
const STEPS := ["coast_out", "event", "leg:loi", "leg:landing", "land_day", "explore",
	"event", "surface", "leg:return", "coast_back", "event", "finish"]

const REASONS := {
	"Starvation": {
		"why": "Food or water ran out before the crew got home.",
		"fix": "Use a bigger Storage locker, or a Life Support unit that recycles water (ISS recovers ~90%)."},
	"Oxygen Depletion": {
		"why": "The crew used all the oxygen on board.",
		"fix": "Bigger Storage locker or better Life Support (O2 recycling). Each person needs ~0.89 kg O2 per day."},
	"Ship Destruction": {
		"why": "The ship was destroyed (hull reached 0, or it crashed because the landing burn had no propellant).",
		"fix": "More shielding in the Cockpit, safer choices during events, and enough delta-v for the landing."},
	"Power Failure": {
		"why": "Power use was higher than power generated, so life support shut down.",
		"fix": "Bigger generator, fission (ignores dust and flares), or lighter-power parts."},
	"Stranded": {
		"why": "The ship ran out of propellant before finishing a burn and cannot return home.",
		"fix": "More propellant, a bigger tank, or a higher-Isp engine. Remember the rocket equation."}
}

var data: Dictionary = {}
var C: Dictionary = {}
var design: Dictionary = {}
var fuel_pct: float = 1.0
var seed_value: int = 0
var station_data: int = 0
var built: Dictionary = {}
var mars_unlocked: bool = false
var best_score: int = 0
var history: Array = []
var run: Dictionary = {}
var last_report: Dictionary = {}
# Player settings (persisted; new keys are optional so old saves still load).
var eva_seconds: float = 60.0
var tutorial_seen: bool = false
var sound_on: bool = true
var story_seen: bool = false
# Station-side progress. `day` is the in-game mission day (1 = arrival at the ISS).
var day: int = 1
var food_store: float = 0.0
var prep: Dictionary = {"rad_kit": false, "scout": false}
var plots: Array = []
var ore: Dictionary = {"ice": 0, "regolith": 0, "ilmenite": 0, "helium3": 0}
# Set by automated tests/screenshot tools so they never overwrite the player's save.
var skip_save: bool = false
# Set by Screen.go() so the next screen knows to fade in from black.
var pending_fade: bool = false
const SAVE_VERSION := 8
const SLOT_COUNT := 3
# 1 crewed Moon mission + 7 robotic probes (Mars, Venus, Mercury, Jupiter, Saturn, Uranus, Neptune).
const TOTAL_MISSIONS := 8
# Campaign state. done: {mission_id: day it was completed}. probes: {probe_id: {state, launch_day, arrive_day}}.
var campaign: Dictionary = {}

var _activities: Dictionary = {}
var harvest_count: int = 0
var water_store: float = 0.0
var nutrient_packs: int = 0
# Three saved ship designs. Each slot is {} (empty) or {"design": {...}, "fuel": float}.
var design_slots: Array = [{}, {}, {}]

func _ready() -> void:
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	data = JSON.parse_string(f.get_as_text())
	f.close()
	C = data["constants"]
	reset_all()
	load_game()
	if seed_value == 0:
		new_seed()

func reset_all() -> void:
	design = {}
	for p in data["parts"]:
		design[p["id"]] = 0
	fuel_pct = 1.0
	station_data = int(C["start_data"])
	built = {}
	for m in data["station_modules"]:
		if m["built"]:
			built[m["id"]] = true
	mars_unlocked = false
	best_score = 0
	history = []
	eva_seconds = 60.0
	tutorial_seen = false
	sound_on = true
	story_seen = false
	day = int(C.get("start_day", 1))
	food_store = 0.0
	prep = {"rad_kit": false, "scout": false}
	plots = []
	ore = {"ice": 0, "regolith": 0, "ilmenite": 0, "helium3": 0}
	harvest_count = 0
	water_store = float(farm_game()["water_kg_start"])
	nutrient_packs = int(farm_game()["nutrient_packs_start"])
	design_slots = [{}, {}, {}]
	campaign_reset()

# ---------- campaign: clock, probes, deadline ----------
func campaign_reset() -> void:
	campaign = {"probes": {}, "done": {}, "gas": 0, "won": false, "lost": false, "end_day": 0, "log": []}
	for id in Campaign.probe_ids():
		campaign["probes"][id] = {"state": "idle", "launch_day": 0, "arrive_day": 0}

func campaign_log(text: String) -> void:
	var entries: Array = campaign["log"]
	entries.append("Day %d: %s" % [day, text])
	while entries.size() > 40:
		entries.pop_front()

# The only way the Earth clock moves. Probes that have arrived become pending.
func advance_days(n: int) -> void:
	if n <= 0:
		return
	day += n
	for id in campaign["probes"]:
		var st: Dictionary = campaign["probes"][id]
		if String(st["state"]) == "transit" and day >= int(st["arrive_day"]):
			st["state"] = "pending"
			campaign_log("%s arrived. Run the encounter in Probe Control." % Campaign.probe(id)["name"])
	_check_end()

func campaign_over() -> bool:
	return bool(campaign.get("won", false)) or bool(campaign.get("lost", false))

# Win: all 8 missions completed, then the 180-day epilogue has passed.
# Lose: the deadline arrives first.
func _check_end() -> void:
	if campaign_over():
		return
	var done: Dictionary = campaign["done"]
	if done.size() >= TOTAL_MISSIONS:
		var last := 0
		for k in done:
			last = maxi(last, int(done[k]))
		campaign["end_day"] = last + int(Campaign.epilogue_days())
		if day >= int(campaign["end_day"]):
			campaign["won"] = true
			campaign_log("All eight missions done. The epilogue is over: Earth is stable.")
			return
	if day >= int(Campaign.deadline_days()):
		campaign["lost"] = true
		campaign_log("The Earth deadline has passed with %d of %d missions done." % [done.size(), TOTAL_MISSIONS])

func days_left() -> int:
	return maxi(0, int(Campaign.deadline_days()) - day)

# Launch a probe in its window. It costs Data and station days, then it flies for the real transit.
func launch_probe(id: String) -> Dictionary:
	var pr: Dictionary = Campaign.probe(id)
	if pr.is_empty():
		return {"ok": false, "text": "Unknown probe."}
	if not campaign["done"].has("moon"):
		return {"ok": false, "text": "Finish the Moon mission first. The probe office opens after it."}
	if campaign_over():
		return {"ok": false, "text": "The campaign is over."}
	var st: Dictionary = campaign["probes"][id]
	if String(st["state"]) != "idle" and String(st["state"]) != "lost":
		return {"ok": false, "text": "%s is already %s." % [pr["name"], String(st["state"])]}
	if not Campaign.window_open(id, float(day)):
		return {"ok": false, "text": "No launch window yet. The next window opens on day %d." % int(Campaign.next_window(id, float(day)))}
	var cost := int(pr["data_cost"])
	if station_data < cost:
		return {"ok": false, "text": "Not enough Data: need %d, have %d. Earn Data by completing missions." % [cost, station_data]}
	station_data -= cost
	var transit := int(ceilf(Campaign.transit_days(id)))
	campaign["probes"][id] = {"state": "transit", "launch_day": day, "arrive_day": day + transit}
	campaign_log("Launched %s, arriving in %d days." % [pr["name"], transit])
	advance_days(int(Campaign.cfg()["campaign"]["launch_station_days"]))
	save_game()
	return {"ok": true, "text": "Launched %s. It arrives on day %d (%d days of flight)." % [pr["name"], int(campaign["probes"][id]["arrive_day"]), transit]}

# Jump to the next launch window for this probe (the clock moves forward).
func wait_for_window(id: String) -> Dictionary:
	var nxt := int(Campaign.next_window(id, float(day)))
	if nxt <= day:
		return {"ok": true, "text": "The window is open now."}
	advance_days(nxt - day)
	save_game()
	return {"ok": true, "text": "Waited %d days. The window is open." % (nxt - day)}

func wait_days(n: int) -> Dictionary:
	advance_days(n)
	save_game()
	return {"ok": true, "text": "Waited %d days." % n}

# The player finished the encounter. outcome = {"success": bool, "gas": int, "text": String}.
func resolve_probe(id: String, outcome: Dictionary) -> Dictionary:
	var st: Dictionary = campaign["probes"][id]
	if String(st["state"]) != "pending":
		return {"ok": false, "text": "No encounter is waiting for this probe."}
	var pr: Dictionary = Campaign.probe(id)
	if bool(outcome["success"]):
		st["state"] = "done"
		station_data += int(pr["reward_data"])
		campaign["gas"] = int(campaign["gas"]) + int(outcome.get("gas", 0))
		campaign["done"][id] = day
		campaign_log("%s: encounter success. +%d Data." % [pr["name"], int(pr["reward_data"])])
		_check_end()
	else:
		st["state"] = "lost"
		campaign_log("%s was lost in the encounter. The next launch window comes one synodic period later (%d days)." % [pr["name"], int(Campaign.synodic_days(id))])
	save_game()
	return {"ok": bool(outcome["success"]), "text": String(outcome["text"])}

# Name of the chosen option for one part, e.g. "Methalox" for the engine.
func _option_name(d: Dictionary, part_id: String) -> String:
	for p in data["parts"]:
		if p["id"] == part_id:
			return String(p["options"][clampi(int(d.get(part_id, 0)), 0, p["options"].size() - 1)]["name"])
	return ""

func slot_name(i: int) -> String:
	var s: Dictionary = design_slots[i]
	if s.is_empty():
		return "Empty"
	var d: Dictionary = s["design"]
	return "%s + %s" % [_option_name(d, "cockpit"), _option_name(d, "engine")]

func save_slot(i: int) -> void:
	design_slots[i] = {"design": design.duplicate(), "fuel": fuel_pct}
	save_game()

# Copies a saved slot into the working design. Returns false for an empty slot.
func load_slot(i: int) -> bool:
	var s: Dictionary = design_slots[i]
	if s.is_empty():
		return false
	design = {}
	for k in s["design"]:
		design[k] = int(s["design"][k])
	fuel_pct = clampf(float(s["fuel"]), 0.0, 1.0)
	save_game()
	return true

func activities() -> Dictionary:
	if _activities.is_empty():
		var f := FileAccess.open("res://data/activities.json", FileAccess.READ)
		_activities = JSON.parse_string(f.get_as_text())
		f.close()
	return _activities

func new_seed() -> void:
	seed_value = randi() % 90000 + 10000

func load_sample_design() -> void:
	for k in data["recommended"]:
		design[k] = int(data["recommended"][k])
	fuel_pct = 0.65

# ---------- lookups ----------
func part(id: String) -> Dictionary:
	for p in data["parts"]:
		if p["id"] == id:
			return p
	return {}

func opt(id: String) -> Dictionary:
	return part(id)["options"][int(design[id])]

func mission(id: String) -> Dictionary:
	for m in data["missions"]:
		if m["id"] == id:
			return m
	return {}

func bonus(key: String) -> float:
	var total := 0.0
	for m in data["station_modules"]:
		if built.has(m["id"]) and m.has("bonus") and m["bonus"].has(key):
			total += float(m["bonus"][key])
	return total

func data_mult_bonus() -> float:
	var v := 1.0
	for m in data["station_modules"]:
		if built.has(m["id"]) and m.has("bonus") and m["bonus"].has("data_mult"):
			v *= float(m["bonus"]["data_mult"])
	return v

func has_module(id: String) -> bool:
	return built.has(id)

# ---------- station clock, smelter, farm and prep ----------

func date_text() -> String:
	# Fixed mission epoch so "today" is part of the fiction, not the player's PC clock.
	var start := int(C.get("start_unix", 0))
	return Time.get_datetime_string_from_unix_time(start + maxi(0, day - 1) * 86400, true).substr(0, 10)

func smelter_points() -> int:
	var total := 0
	for k in ore:
		if data["moon_resources"].has(k):
			total += int(ore[k]) * int(data["moon_resources"][k]["pts"])
	# Gas from the gas-giant probes counts for the Helios smelter too.
	total += int(campaign.get("gas", 0))
	return total

func smelter_pct() -> float:
	return clampf(float(smelter_points()) / float(C.get("smelter_target", 165)), 0.0, 1.0)

func prep_cost(key: String) -> int:
	var p: Dictionary = C.get("prep", {})
	return int(p.get(key + "_cost", 0))

func buy_prep(key: String) -> Dictionary:
	if not prep.has(key):
		return {"ok": false, "text": "Unknown preparation."}
	if bool(prep[key]):
		prep[key] = false
		save_game()
		return {"ok": true, "text": "Removed from the next flight."}
	var cost := prep_cost(key)
	if station_data < cost:
		return {"ok": false, "text": "Not enough Data (need %d, have %d)." % [cost, station_data]}
	station_data -= cost
	prep[key] = true
	save_game()
	var label := "Radiation blanket" if key == "rad_kit" else "Scout drone"
	return {"ok": true, "text": "%s loaded for the next flight." % label}

func ensure_plot() -> void:
	if not plots.is_empty():
		return
	var game: Dictionary = Farm.cfg()["game"]
	var p := Farm.new_plot(String(game["starter_crop"]), float(game["plot_area_m2"]))
	p["water_pct"] = 100.0
	p["nutrient_pct"] = 100.0
	plots.append(p)

func farm_game() -> Dictionary:
	return Farm.cfg()["game"]

# Selecting a crop is allowed only while the plot is empty (day 0).
func set_crop(crop_id: String) -> Dictionary:
	if not has_module("greenhouse"):
		return {"ok": false, "text": "Build the Greenhouse in the Habitat first."}
	ensure_plot()
	if float(plots[0]["age_days"]) > 0.0:
		return {"ok": false, "text": "The plot already has a crop growing. Harvest it before choosing another."}
	var area := float(plots[0]["area_m2"])
	plots[0] = Farm.new_plot(crop_id, area)
	plots[0]["water_pct"] = 100.0
	plots[0]["nutrient_pct"] = 100.0
	save_game()
	return {"ok": true, "text": "Planted %s. It takes %d days to harvest." % [Farm.crop(crop_id)["name"], int(Farm.crop(crop_id)["growth_days"])]}

func water_plot() -> Dictionary:
	if not has_module("greenhouse"):
		return {"ok": false, "text": "Build the Greenhouse in the Habitat first."}
	ensure_plot()
	var kg := float(farm_game()["water_kg_per_refill"])
	if water_store < kg:
		return {"ok": false, "text": "No water in the ISS store (%.1f kg left). Buy more in the Habitat." % water_store}
	water_store -= kg
	plots[0]["water_pct"] = 100.0
	save_game()
	return {"ok": true, "text": "Watered the plot (-%.0f kg). Store: %.1f kg." % [kg, water_store]}

func buy_water() -> Dictionary:
	var g := farm_game()
	var cost := int(g["water_data_cost_per_purchase"])
	if station_data < cost:
		return {"ok": false, "text": "Not enough Data (need %d, have %d)." % [cost, station_data]}
	station_data -= cost
	water_store += float(g["water_kg_per_purchase"])
	save_game()
	return {"ok": true, "text": "Bought %d kg of water for %d Data." % [int(g["water_kg_per_purchase"]), cost]}

func buy_nutrients() -> Dictionary:
	var cost := int(farm_game()["nutrient_data_cost_per_pack"])
	if station_data < cost:
		return {"ok": false, "text": "Not enough Data (need %d, have %d)." % [cost, station_data]}
	station_data -= cost
	nutrient_packs += 1
	save_game()
	return {"ok": true, "text": "Bought 1 nutrient pack for %d Data. Packs: %d." % [cost, nutrient_packs]}

func feed_plot() -> Dictionary:
	if not has_module("greenhouse"):
		return {"ok": false, "text": "Build the Greenhouse in the Habitat first."}
	ensure_plot()
	if nutrient_packs <= 0:
		return {"ok": false, "text": "No nutrient packs. Buy one in the Habitat."}
	nutrient_packs -= 1
	plots[0]["nutrient_pct"] = 100.0
	save_game()
	return {"ok": true, "text": "Added a nutrient pack. Packs left: %d." % nutrient_packs}

# The alert line the greenhouse card shows. Plain words, always one action.
func greenhouse_alert() -> String:
	if not has_module("greenhouse"):
		return "Build the Greenhouse in the Habitat to grow food."
	ensure_plot()
	var p: Dictionary = plots[0]
	var low := float(farm_game()["alert_low_pct"])
	if Farm.crop_ready(p):
		return "READY TO HARVEST: press HARVEST for %.1f kg of fresh food." % plot_kg()
	if float(p["water_pct"]) <= low:
		return "WATER LOW (%d%%): press WATER now, or the crop stops growing." % int(p["water_pct"])
	if float(p["nutrient_pct"]) <= low:
		return "NUTRIENTS LOW (%d%%): press FEED (uses 1 pack). Packs: %d." % [int(p["nutrient_pct"]), nutrient_packs]
	var drop := float(farm_game()["water_meter_drop_per_day"])
	var days_left := int((float(p["water_pct"]) - low) / maxf(drop, 1.0))
	return "All good. Water lasts about %d more days. Growing: day %d of %d." % [
		days_left, int(p["age_days"]), int(Farm.crop(p["crop"])["growth_days"])]

func plot_ready() -> bool:
	if plots.is_empty():
		return false
	return Farm.crop_ready(plots[0])

func plot_kg() -> float:
	if plots.is_empty():
		return 0.0
	return Farm.harvest_kg(plots[0])

func tend_plot(days: float = 1.0) -> Dictionary:
	if not has_module("greenhouse"):
		return {"ok": false, "text": "Build the Greenhouse module at the ISS first."}
	ensure_plot()
	var cfg := Farm.cfg()
	var g: Dictionary = cfg["game"]
	var p: Dictionary = plots[0]
	var n := maxi(1, int(round(days)))
	for i in n:
		# Growth follows the meters of this day: water and nutrients both matter.
		var f := clampf(float(p["water_pct"]) * float(p["nutrient_pct"]) / 10000.0, 0.0, 1.0)
		Farm.advance_plot(p, 1.0, float(cfg["default_ppfd_umol_m2_s"]),
			float(cfg["default_photoperiod_h"]), f)
		p["water_pct"] = maxf(0.0, float(p["water_pct"]) - float(g["water_meter_drop_per_day"]))
		p["nutrient_pct"] = maxf(0.0, float(p["nutrient_pct"]) - float(g["nutrient_meter_drop_per_day"]))
	advance_days(n)
	save_game()
	var state := "READY TO HARVEST" if Farm.crop_ready(p) else "growing"
	return {"ok": true, "text": "%s: day %d of %d (%s). %s" % [
		Farm.crop(p["crop"])["name"], int(p["age_days"]), int(Farm.crop(p["crop"])["growth_days"]), state, greenhouse_alert()]}

func harvest_plot() -> Dictionary:
	if not has_module("greenhouse") or not plot_ready():
		return {"ok": false, "text": "Nothing ready to harvest yet."}
	var kg := plot_kg()
	food_store += kg
	harvest_count += 1
	var crop_id := String(plots[0]["crop"])
	var area := float(plots[0]["area_m2"])
	plots[0] = Farm.new_plot(crop_id, area)
	plots[0]["water_pct"] = 100.0
	plots[0]["nutrient_pct"] = 100.0
	save_game()
	return {"ok": true, "text": "Harvested %.1f kg of %s. ISS food store: %.1f kg." % [kg, Farm.crop(crop_id)["name"], food_store]}

func study_samples() -> Dictionary:
	var gain := int(C.get("study_data", 8))
	if has_module("lab"):
		gain = int(round(gain * 1.25))
	station_data += gain
	advance_days(1)
	save_game()
	return {"ok": true, "text": "Studied the samples (+%d Data, +1 day)." % gain}

func rest_day() -> Dictionary:
	advance_days(1)
	save_game()
	return {"ok": true, "text": "Crew rested. The ISS clock advances one day."}

# A one-day activity performed during the voyage. Costs supplies through _consume().
func crew_activity(kind: String) -> Dictionary:
	if run.is_empty() or bool(run.get("over", false)):
		return {"ok": false, "text": "No flight in progress."}
	var acts: Dictionary = C.get("crew_activities", {})
	if not acts.has(kind):
		return {"ok": false, "text": "Unknown activity."}
	var act: Dictionary = acts[kind]
	var txt := _consume(float(act.get("days", 1.0)), "Crew: " + String(act["name"]))
	if bool(run.get("over", false)):
		return {"ok": false, "text": txt}
	if act.has("food_kg"):
		run["stock"]["food"] += float(act["food_kg"])
	if act.has("data"):
		run["data_raw"] += float(act["data"])
	if act.has("hull"):
		run["hull"] = minf(100.0, float(run["hull"]) + float(act["hull"]))
	_log("%s: %s" % [act["name"], act.get("info", "")])
	return {"ok": true, "text": String(act.get("info", txt))}

func mission_days(m: Dictionary) -> float:
	var t := 0.0
	for k in m["days"]:
		t += float(m["days"][k])
	return t

# ---------- T17: flight plan + in-transit activities ----------

# Data-driven flight plan: consume legs are auto-chained by advance();
# activity nodes pause the run until the player resolves them.
func build_run_plan(m: Dictionary) -> Array:
	var act: Dictionary = activities()["game"]["transit"]
	var out: float = float(m["days"]["transit_out"])
	var nav_frac: Array = act["nav_sighting"]["trigger_fraction_of_trip"]
	var burn_frac: float = float(act["midcourse_correction"]["trigger_fraction_of_trip"])
	return [
		{"kind": "consume", "days": out * float(nav_frac[0]), "label": "Coast to the Moon"},
		{"kind": "nav", "idx": 0},
		{"kind": "consume", "days": out * (float(nav_frac[1]) - float(nav_frac[0])), "label": "Coast to the Moon"},
		{"kind": "nav", "idx": 1},
		{"kind": "consume", "days": out * (burn_frac - float(nav_frac[1])), "label": "Coast to the Moon"},
		{"kind": "burn"},
		{"kind": "consume", "days": out * (1.0 - burn_frac), "label": "Coast to the Moon"},
		{"kind": "event"},
		{"kind": "leg", "id": "loi"},
		{"kind": "leg", "id": "landing"},
		{"kind": "consume", "days": float(m["days"]["landing"]), "label": "Landing day"},
		{"kind": "explore"},
		{"kind": "event"},
		{"kind": "consume", "days": float(m["days"]["surface"]), "label": "Surface operations"},
		{"kind": "leg", "id": "return"},
		{"kind": "consume", "days": float(m["days"]["transit_back"]), "label": "Coast back to the station"},
		{"kind": "event"},
		{"kind": "finish"},
	]

func resolve_nav(accuracy: float) -> String:
	var i := int(run.get("pending_nav", 0))
	while run["nav_acc"].size() <= i:
		run["nav_acc"].append(1.0)
	var acc := clampf(accuracy, 0.0, 1.0)
	run["nav_acc"][i] = acc
	var txt := "Navigation sighting %d: %.0f%% accurate." % [i + 1, acc * 100.0]
	_log(txt)
	return txt

func resolve_burn(hold_fraction: float) -> String:
	var act: Dictionary = activities()["game"]["transit"]
	var nominal: float = float(act["midcourse_correction"]["nominal_dv_m_s"])
	var max_err: float = float(act["nav_sighting"]["max_extra_dv_error_m_s"])
	var r := clampf(hold_fraction, 0.0, 1.2)
	var nav_avg := 1.0
	if not run["nav_acc"].is_empty():
		var s := 0.0
		for a in run["nav_acc"]:
			s += float(a)
		nav_avg = s / float(run["nav_acc"].size())
	var extra := max_err * (1.0 - nav_avg)
	var dv_applied := (nominal + extra) * r
	var m_i := float(run["dry"]) + float(run["prop"])
	var ve := float(opt("engine")["isp"]) * float(C["g0"])
	var need := m_i * (1.0 - exp(-dv_applied / ve))
	var have := float(run["prop"])
	var used := minf(need, have)
	run["prop"] = have - used
	run["dv_penalty_m_s"] = (1.0 - r) * (nominal + extra)
	run["burn_done"] = true
	var txt := "Midcourse burn: %.2f m/s applied, %.2f t propellant used." % [dv_applied, used / 1000.0]
	if r < 1.0:
		txt += " Next burn must make up %.2f m/s." % float(run["dv_penalty_m_s"])
	_log(txt)
	return txt

func set_thermal_roll(on: bool) -> void:
	run["roll_on"] = on

func set_exercise_hours(h: int) -> void:
	run["exercise_hours"] = clampi(h, 0, 2)

func stamina_capacity_mult() -> float:
	if run.is_empty():
		return 1.0
	var crew: Dictionary = activities()["game"]["transit"]["crew_schedule"]
	var healthy_h := int(crew["exercise_hours_options"].back())
	if int(run.get("exercise_hours", healthy_h)) >= healthy_h:
		return 1.0
	return 1.0 - float(crew["no_exercise_stamina_capacity_penalty_pct"]) / 100.0

# Applied exactly once, after the return coast, if the roll was skipped.
func apply_roll_damage() -> void:
	if run.is_empty() or bool(run.get("roll_damage_done", false)) or bool(run.get("roll_on", true)):
		return
	run["roll_damage_done"] = true
	var m := mission(run["mission"])
	var coast := float(m["days"]["transit_out"]) + float(m["days"]["transit_back"])
	var per_day := float(activities()["game"]["transit"]["thermal_roll"]["skip_hull_damage_pct_per_day"])
	var loss := per_day * coast
	run["hull"] = float(run["hull"]) - loss
	_log("Thermal roll skipped: %.1f hull lost to thermal stress." % loss)
	# The hull cannot go below zero, and a hull at zero ends the run like any other hull loss.
	if float(run["hull"]) <= 0.0 and not run["over"]:
		run["hull"] = 0.0
		_fail("Ship Destruction", "Skipping the thermal roll for %.0f days stressed the hull past its limit." % coast)

# ---------- design analysis (used by hangar UI and by the run) ----------
func analyze(mission_id: String = "moon") -> Dictionary:
	var m := mission(mission_id)
	var a := {}
	var dry := 0.0
	var cost := 0.0
	var gen_solar := 0.0
	var gen_other := 0.0
	var use := 0.0
	for p in data["parts"]:
		var o: Dictionary = opt(p["id"])
		dry += float(o["mass"])
		cost += float(o["cost"])
		var pw := float(o["power"])
		if pw >= 0.0:
			if o.get("solar", false):
				gen_solar += pw
			else:
				gen_other += pw
		else:
			use += -pw
	gen_solar += bonus("power_kw")
	# consumables. Food grown at the ISS offsets the food that must be packed from storage.
	var days := mission_days(m)
	var crew := float(C["crew"])
	var rate: Dictionary = C["crew_day_kg"]
	var life: Dictionary = opt("life")
	var food_raw := crew * days * float(rate["food"])
	var food_used := minf(food_store, food_raw)
	var need := {
		"o2": crew * days * float(rate["o2"]) * (1.0 - float(life["o2_rec"])),
		"water": crew * days * float(rate["water"]) * (1.0 - float(life["water_rec"])),
		"food": food_raw - food_used
	}
	var total_need := float(need["o2"]) + float(need["water"]) + float(need["food"])
	var cap := float(opt("storage")["cap_kg"]) + bonus("storage_kg")
	var margin := float(C["supply_margin"])
	var left := cap
	var pack := {}
	for k in ["o2", "water", "food"]:
		var want: float = float(need[k]) * margin
		var got: float = minf(want, left)
		pack[k] = got
		left -= got
	var packed := float(pack["o2"]) + float(pack["water"]) + float(pack["food"])
	dry += packed
	# propellant
	var prop_kg := float(opt("tank")["cap_t"]) * 1000.0 * fuel_pct
	cost += prop_kg / 1000.0 * float(C["prop_cost_per_t"])
	var isp := float(opt("engine")["isp"])
	var ve := isp * float(C["g0"])
	var dv := ve * log((dry + prop_kg) / dry) / 1000.0
	var dv_need := 0.0
	for leg in m["legs"]:
		dv_need += float(leg["dv"])
	dv_need *= (1.0 + float(C["leg_margin"]))
	a["dry_kg"] = dry
	a["prop_kg"] = prop_kg
	a["total_kg"] = dry + prop_kg
	a["mass_cap_kg"] = float(C["mass_cap_kg"]) + bonus("mass_cap_kg")
	a["cost"] = cost
	a["budget"] = float(C["budget"]) + bonus("budget")
	a["gen_solar"] = gen_solar
	a["gen_other"] = gen_other
	a["use"] = use
	a["net"] = gen_solar + gen_other - use
	a["isp"] = isp
	a["dv"] = dv
	a["dv_need"] = dv_need
	a["need"] = need
	a["pack"] = pack
	a["total_need"] = total_need
	a["cap"] = cap
	a["food_store"] = food_store
	a["food_store_used"] = food_used
	a["comm_q"] = minf(1.0, float(opt("comms")["quality"]) + bonus("comms_q"))
	a["shield"] = float(opt("cockpit")["shield"])
	var issues: Array = []
	if a["total_kg"] > a["mass_cap_kg"]:
		issues.append("Too heavy for the dock lift limit")
	if cost > a["budget"]:
		issues.append("Over budget")
	if a["net"] < 0.0:
		issues.append("Power use is higher than generation")
	if dv < dv_need:
		issues.append("Not enough delta-v for the whole mission")
	for k in ["o2", "water", "food"]:
		if float(pack[k]) < float(need[k]):
			issues.append("Storage too small for %s" % k)
	a["issues"] = issues
	a["can_launch"] = (a["total_kg"] <= a["mass_cap_kg"]) and (cost <= a["budget"])
	return a

# ---------- run ----------
func start_run(mission_id: String) -> void:
	var m := mission(mission_id)
	var a := analyze(mission_id)
	var food_used := float(a.get("food_store_used", 0.0))
	food_store = maxf(0.0, food_store - food_used)
	var prep_cfg: Dictionary = C.get("prep", {})
	var rad_mult := float(prep_cfg.get("rad_mult", 1.0)) if bool(prep.get("rad_kit", false)) else 1.0
	var has_scout := bool(prep.get("scout", false))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var space: Array = []
	var surface: Array = []
	for e in data["events"]:
		if e["slot"] == "space":
			space.append(e)
		else:
			surface.append(e)
	var i1: int = rng.randi() % space.size()
	var e1: Dictionary = space[i1]
	var e2: Dictionary = surface[rng.randi() % surface.size()]
	var space2: Array = []
	for e in space:
		if e["id"] != e1["id"]:
			space2.append(e)
	var e3: Dictionary = space2[rng.randi() % space2.size()]
	run = {
		"mission": mission_id, "a": a, "step": 0, "event_i": 0, "events": [e1, e2, e3],
		"day": 0.0, "hull": 100.0, "dry": a["dry_kg"], "prop": a["prop_kg"], "prop0": a["prop_kg"],
		"stock": a["pack"].duplicate(), "stock0": a["pack"].duplicate(),
		"power_mult": 1.0, "data_mult": 1.0, "data_raw": 0.0, "explore_pts": 0.0, "explore_counts": {},
		"over": false, "reason": "", "detail": "", "landed": false, "success": false,
		"legs": [], "log": [], "decisions": [], "current_event": {}, "score": 0, "data_gain": 0,
		"min_net": 999.0, "rad_mult": rad_mult, "scout": has_scout, "food_store_used": food_used,
		"stamina_btu": 0.0, "eva_food_kcal": 0.0, "eva_time": 0.0,
		"plan": build_run_plan(m), "plan_i": 0,
		"nav_acc": [], "pending_nav": 0, "burn_done": false, "dv_penalty_m_s": 0.0,
		"roll_on": true, "roll_damage_done": false, "exercise_hours": 2,
		"morale": mini(3, harvest_count * int(activities()["game"]["transit"]["crew_schedule"].get("morale_gain_per_plant_crop", 1))),
		"walks_log": [], "deploys": 0, "sample_kg": 0.0
	}
	# Fresh food from the ISS greenhouse rides in the galley, so it still has to be
	# eaten. analyze() already removed it from the packed locker; load it into the stock
	# here, otherwise the offset is lost and a short delay starves the crew.
	run["stock"]["food"] += food_used
	# Gear is loaded for this flight only; the player buys it again at the ship.
	prep["rad_kit"] = false
	prep["scout"] = false

func _log(t: String) -> void:
	run["log"].append("Day %.0f: %s" % [run["day"], t])

func _fail(reason: String, detail: String) -> void:
	run["over"] = true
	run["reason"] = reason
	run["detail"] = detail
	_log("GAME OVER - " + reason)

func _consume(days: float, label: String) -> String:
	var m := mission(run["mission"])
	var a: Dictionary = run["a"]
	var life: Dictionary = opt("life")
	var crew := float(C["crew"])
	var rate: Dictionary = C["crew_day_kg"]
	run["day"] += days
	var use_o2 := crew * days * float(rate["o2"]) * (1.0 - float(life["o2_rec"]))
	var use_w := crew * days * float(rate["water"]) * (1.0 - float(life["water_rec"]))
	var use_f := crew * days * float(rate["food"])
	run["stock"]["o2"] -= use_o2
	run["stock"]["water"] -= use_w
	run["stock"]["food"] -= use_f
	var gen: float = float(a["gen_solar"]) * float(run["power_mult"]) + float(a["gen_other"])
	var net: float = gen - float(a["use"])
	run["min_net"] = minf(float(run["min_net"]), net)
	run["power_mult"] = 1.0
	var txt := "%s (%.0f d): O2 %.0f kg, water %.0f kg, food %.0f kg left. Power %+.1f kW." % [
		label, days, maxf(0.0, run["stock"]["o2"]), maxf(0.0, run["stock"]["water"]),
		maxf(0.0, run["stock"]["food"]), net]
	_log(txt)
	if net < 0.0:
		_fail("Power Failure", "Power was %.1f kW short during '%s'." % [-net, label])
	elif run["stock"]["o2"] < 0.0:
		_fail("Oxygen Depletion", "Oxygen ran out during '%s'." % label)
	elif run["stock"]["food"] < 0.0 or run["stock"]["water"] < 0.0:
		_fail("Starvation", "Food or water ran out during '%s'." % label)
	return txt

func _burn(leg_id: String) -> String:
	var m := mission(run["mission"])
	var leg: Dictionary = {}
	for l in m["legs"]:
		if l["id"] == leg_id:
			leg = l
	var ve := float(opt("engine")["isp"]) * float(C["g0"])
	var dv := float(leg["dv"]) * (1.0 + float(C["leg_margin"])) * 1000.0 + float(run.get("dv_penalty_m_s", 0.0))
	run["dv_penalty_m_s"] = 0.0
	var m_i: float = float(run["dry"]) + float(run["prop"])
	var need: float = m_i * (1.0 - exp(-dv / ve))
	var have: float = float(run["prop"])
	var rec := {"name": leg["name"], "dv": leg["dv"], "need_t": need / 1000.0, "have_t": have / 1000.0, "ok": need <= have}
	run["legs"].append(rec)
	if need > have:
		var txt := "%s: needs %.1f t propellant, only %.1f t left." % [leg["name"], need / 1000.0, have / 1000.0]
		_log(txt)
		_fail(String(leg["fail"]), txt)
		return txt
	run["prop"] = have - need
	var txt2 := "%s burn OK: used %.1f t propellant, %.1f t left." % [leg["name"], need / 1000.0, run["prop"] / 1000.0]
	_log(txt2)
	return txt2

func advance() -> Dictionary:
	var guard := 0
	while guard < 60:
		guard += 1
		if run["over"]:
			finalize()
			return {"kind": "end"}
		if int(run["plan_i"]) >= run["plan"].size():
			run["success"] = true
			_log("Docked with the station. Mission complete.")
			finalize()
			return {"kind": "end"}
		var step: Dictionary = run["plan"][run["plan_i"]]
		run["plan_i"] += 1
		var kind := String(step["kind"])
		var m := mission(run["mission"])
		match kind:
			"consume":
				var label := String(step["label"])
				_consume(float(step["days"]), label)
				if label == "Coast back to the station":
					apply_roll_damage()
				continue
			"nav":
				run["pending_nav"] = int(step["idx"])
				return {"kind": "nav", "idx": int(step["idx"])}
			"burn":
				return {"kind": "burn"}
			"event":
				var ev: Dictionary = run["events"][run["event_i"]]
				run["event_i"] += 1
				run["current_event"] = ev
				return {"kind": "event", "event": ev}
			"leg":
				var text := _burn(String(step["id"]))
				if String(step["id"]) == "landing" and not run["over"]:
					run["landed"] = true
					run["data_raw"] += float(m["base_data"])
				if run["over"]:
					finalize()
					return {"kind": "end", "text": text}
				continue
			"explore":
				return {"kind": "explore"}
			"finish":
				run["success"] = true
				_log("Docked with the station. Mission complete.")
				finalize()
				return {"kind": "end"}
	return {"kind": "end"}

func finish_explore(points: float, counts: Dictionary = {}, stamina_btu: float = 0.0, eva_food_kcal: float = 0.0, eva_time: float = 0.0, sample_kg: float = 0.0, walks_log: Array = [], deploys: int = 0) -> void:
	run["explore_pts"] = points
	run["explore_counts"] = counts.duplicate()
	run["stamina_btu"] = stamina_btu
	run["eva_food_kcal"] = eva_food_kcal
	run["eva_time"] = eva_time
	run["data_raw"] += points
	run["dry"] += sample_kg
	run["sample_kg"] = sample_kg
	run["walks_log"] = walks_log.duplicate()
	run["deploys"] = deploys
	for k in counts:
		if ore.has(k):
			ore[k] += int(counts[k])
	_log("EVA complete: %.0f science points collected." % points)

func apply_choice(i: int) -> String:
	var ev: Dictionary = run["current_event"]
	var ch: Dictionary = ev["choices"][i]
	if ch.has("min_morale") and int(run.get("morale", 0)) < int(ch["min_morale"]):
		return "The crew's morale is too low to attempt this choice."
	var fx: Dictionary = ch["fx"]
	run["decisions"].append("%s: %s" % [ev["title"], ch["label"]])
	if fx.has("days"):
		_consume(float(fx["days"]), "Delay (" + String(ev["title"]) + ")")
	if fx.has("supply_pct"):
		for k in ["o2", "water", "food"]:
			run["stock"][k] *= (1.0 + float(fx["supply_pct"]))
	if fx.has("water_kg"):
		run["stock"]["water"] += float(fx["water_kg"])
	if fx.has("prop_pct"):
		run["prop"] *= (1.0 + float(fx["prop_pct"]))
	if fx.has("hull"):
		run["hull"] += float(fx["hull"])
	if fx.has("rad_hull"):
		run["hull"] -= float(fx["rad_hull"]) * (1.0 - float(run["a"]["shield"])) * float(run.get("rad_mult", 1.0))
	if fx.has("power_mult"):
		run["power_mult"] = float(fx["power_mult"])
	if fx.has("data_mult"):
		run["data_mult"] *= float(fx["data_mult"])
	if fx.has("data"):
		run["data_raw"] += float(fx["data"])
	_log("%s -> %s" % [ev["title"], ch["label"]])
	if run["hull"] <= 0.0 and not run["over"]:
		_fail("Ship Destruction", "Hull integrity reached 0 after '%s'." % ev["title"])
	return String(ch["result"])

# ---------- end of run ----------
func finalize() -> void:
	if run.has("done"):
		return
	run["done"] = true
	advance_days(int(round(float(run.get("day", 0.0)))))
	var a: Dictionary = run["a"]
	var gain := float(run["data_raw"]) * float(run["data_mult"]) * (0.5 + 0.5 * float(a["comm_q"])) * data_mult_bonus()
	run["data_gain"] = int(round(gain))
	var left: float = maxf(0.0, float(a["budget"]) - float(a["cost"]))
	run["budget_left"] = left
	if run["success"]:
		run["score"] = int(500 + run["data_gain"] * 8 + maxf(0.0, run["hull"]) * 2 + left)
	else:
		run["score"] = int(run["data_gain"] * 2)
	station_data += int(run["data_gain"])
	best_score = maxi(best_score, int(run["score"]))
	if run["success"] and run["mission"] == "moon" and not campaign["done"].has("moon"):
		campaign["done"]["moon"] = day
		mars_unlocked = true
		_check_end()
	history.append({"score": run["score"], "success": run["success"], "reason": run["reason"], "seed": seed_value})
	while history.size() > 6:
		history.pop_front()
	last_report = run
	save_game()

func build_module(id: String) -> bool:
	for m in data["station_modules"]:
		if m["id"] == id:
			if built.has(id) or not built.has(m["parent"]) or station_data < int(m["cost"]):
				return false
			station_data -= int(m["cost"])
			built[id] = true
			save_game()
			return true
	return false

# ---------- save / load ----------
func save_game() -> void:
	if skip_save:
		return
	var d := {"save_version": SAVE_VERSION,
		"station_data": station_data, "built": built.keys(), "mars": mars_unlocked, "best": best_score,
		"history": history, "design": design, "fuel": fuel_pct, "seed": seed_value,
		"eva": eva_seconds, "tutorial": tutorial_seen, "sound": sound_on,
		"story": story_seen, "day": day, "food": food_store, "prep": prep, "plots": plots, "ore": ore,
		"harvest": harvest_count, "water": water_store, "nutrient_packs": nutrient_packs,
		"slots": design_slots, "campaign": campaign}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))
		f.close()

func load_game() -> void:
	# The game was renamed from "OG-Frontier Prototype" to "OG-FRONTIER", which moves the
	# user:// folder. Read the old save once so teammates keep their progress.
	var path := SAVE_PATH
	if not FileAccess.file_exists(path):
		path = _legacy_save_path()
		if path == "":
			return
	var f := FileAccess.open(path, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(d) != TYPE_DICTIONARY:
		return
	station_data = int(d.get("station_data", station_data))
	mars_unlocked = bool(d.get("mars", false))
	best_score = int(d.get("best", 0))
	history = d.get("history", [])
	fuel_pct = float(d.get("fuel", 1.0))
	seed_value = int(d.get("seed", 0))
	# v1 saves simply lack these keys; the defaults above are the v1 behaviour.
	eva_seconds = clampf(float(d.get("eva", 60.0)), 30.0, 300.0)
	tutorial_seen = bool(d.get("tutorial", false))
	sound_on = bool(d.get("sound", true))
	story_seen = bool(d.get("story", false))
	day = maxi(1, int(d.get("day", 1)))
	food_store = maxf(0.0, float(d.get("food", 0.0)))
	var p = d.get("prep", {})
	if typeof(p) == TYPE_DICTIONARY:
		prep = {"rad_kit": bool(p.get("rad_kit", false)), "scout": bool(p.get("scout", false))}
	var pl = d.get("plots", [])
	if typeof(pl) == TYPE_ARRAY:
		plots = pl
		# v5 plots have no meters: they start full, like a freshly planted bed.
		for old_plot in plots:
			if typeof(old_plot) == TYPE_DICTIONARY:
				if not old_plot.has("water_pct"):
					old_plot["water_pct"] = 100.0
				if not old_plot.has("nutrient_pct"):
					old_plot["nutrient_pct"] = 100.0
	water_store = maxf(0.0, float(d.get("water", float(farm_game()["water_kg_start"]))))
	nutrient_packs = maxi(0, int(d.get("nutrient_packs", int(farm_game()["nutrient_packs_start"]))))
	var o = d.get("ore", {})
	if typeof(o) == TYPE_DICTIONARY:
		for k in ore:
			ore[k] = int(o.get(k, 0))
	harvest_count = maxi(0, int(d.get("harvest", 0)))
	for k in d.get("design", {}):
		design[k] = int(d["design"][k])
	for id in d.get("built", []):
		built[id] = true
	# v6 saves have no slots: they keep the empty defaults.
	var slots = d.get("slots", [])
	if typeof(slots) == TYPE_ARRAY and slots.size() == SLOT_COUNT:
		for i in SLOT_COUNT:
			var s = slots[i]
			if typeof(s) == TYPE_DICTIONARY and s.has("design"):
				design_slots[i] = s
			else:
				design_slots[i] = {}
	# v7 saves have no campaign. Their Moon success was stored in the old "mars" flag.
	var camp = d.get("campaign", null)
	campaign_reset()
	if typeof(camp) == TYPE_DICTIONARY and camp.has("probes") and camp.has("done"):
		var fresh := campaign
		for k in fresh:
			if not camp.has(k):
				camp[k] = fresh[k]
		for id in Campaign.probe_ids():
			if not camp["probes"].has(id):
				camp["probes"][id] = {"state": "idle", "launch_day": 0, "arrive_day": 0}
		campaign = camp
	elif mars_unlocked:
		campaign["done"]["moon"] = day

func _legacy_save_path() -> String:
	var old := OS.get_user_data_dir().get_base_dir().path_join("OG-Frontier Prototype").path_join("ogfrontier_save.json")
	return old if FileAccess.file_exists(old) else ""

func wipe_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	reset_all()
	new_seed()
