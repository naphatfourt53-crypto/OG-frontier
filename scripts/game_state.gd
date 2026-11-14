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

func mission_days(m: Dictionary) -> float:
	var t := 0.0
	for k in m["days"]:
		t += float(m["days"][k])
	return t

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
	# consumables
	var days := mission_days(m)
	var crew := float(C["crew"])
	var rate: Dictionary = C["crew_day_kg"]
	var life: Dictionary = opt("life")
	var need := {
		"o2": crew * days * float(rate["o2"]) * (1.0 - float(life["o2_rec"])),
		"water": crew * days * float(rate["water"]) * (1.0 - float(life["water_rec"])),
		"food": crew * days * float(rate["food"])
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
		"power_mult": 1.0, "data_mult": 1.0, "data_raw": 0.0, "explore_pts": 0.0,
		"over": false, "reason": "", "detail": "", "landed": false, "success": false,
		"legs": [], "log": [], "decisions": [], "current_event": {}, "score": 0, "data_gain": 0,
		"min_net": 999.0
	}

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
	var dv := float(leg["dv"]) * (1.0 + float(C["leg_margin"])) * 1000.0
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
	if run["over"]:
		finalize()
		return {"kind": "end"}
	var s: String = STEPS[run["step"]]
	run["step"] += 1
	var m := mission(run["mission"])
	var d: Dictionary = m["days"]
	var text := ""
	match s:
		"coast_out":
			text = _consume(float(d["transit_out"]), "Coast to the Moon")
		"land_day":
			text = _consume(float(d["landing"]), "Landing day")
		"surface":
			text = _consume(float(d["surface"]), "Surface operations")
		"coast_back":
			text = _consume(float(d["transit_back"]), "Coast back to the station")
		"explore":
			return {"kind": "explore"}
		"event":
			var ev: Dictionary = run["events"][run["event_i"]]
			run["event_i"] += 1
			run["current_event"] = ev
			return {"kind": "event", "event": ev}
		"finish":
			run["success"] = true
			_log("Docked with the station. Mission complete.")
			finalize()
			return {"kind": "end"}
		_:
			if s.begins_with("leg:"):
				text = _burn(s.substr(4))
				if s == "leg:landing" and not run["over"]:
					run["landed"] = true
					run["data_raw"] += float(m["base_data"])
	if run["over"]:
		finalize()
		return {"kind": "end", "text": text}
	return {"kind": "info", "text": text, "step": s}

func finish_explore(points: float) -> void:
	run["explore_pts"] = points
	run["data_raw"] += points
	_log("EVA complete: %.0f science points collected." % points)

func apply_choice(i: int) -> String:
	var ev: Dictionary = run["current_event"]
	var ch: Dictionary = ev["choices"][i]
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
		run["hull"] -= float(fx["rad_hull"]) * (1.0 - float(run["a"]["shield"]))
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
	if run["success"] and run["mission"] == "moon":
		mars_unlocked = true
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
	var d := {"station_data": station_data, "built": built.keys(), "mars": mars_unlocked, "best": best_score,
		"history": history, "design": design, "fuel": fuel_pct, "seed": seed_value}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))
		f.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
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
	for k in d.get("design", {}):
		design[k] = int(d["design"][k])
	for id in d.get("built", []):
		built[id] = true

func wipe_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	reset_all()
	new_seed()
