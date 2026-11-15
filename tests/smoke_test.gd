extends SceneTree
# Headless smoke test (T1/T2 in the handoff brief).
# Run:  Godot_v4.7.2-stable_win64.exe --headless --path . -s tests/smoke_test.gd
# Prints PASS, or FAIL <why> and exits non-zero. Never touches the player's save.

const SCENES := ["menu", "story", "tutorial", "station", "ship", "computer", "hangar", "mission", "flight", "explore", "report"]
const REASONS := ["Starvation", "Oxygen Depletion", "Ship Destruction", "Power Failure", "Stranded"]
const GOLDEN := "res://tests/golden.json"
const TOL := 0.01
const MAX_STEPS := 200

var gs: Node
var fails: Array = []
var checks: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		fails.append(msg)
		print("  FAIL ", msg)

func _run() -> void:
	gs = root.get_node_or_null("GameState")
	if gs == null:
		print("FAIL GameState autoload is missing")
		quit(1)
		return
	gs.skip_save = true
	gs.reset_all()
	gs.seed_value = 424242  # deterministic event set so a failure always reproduces

	_test_sample_run()
	_test_smart_run()
	_test_scenes()
	_test_weak_run()
	_test_new_systems()
	_test_golden()

	if fails.is_empty():
		print("PASS smoke_test (%d checks)" % checks)
		quit(0)
	else:
		print("FAIL %d check(s):" % fails.size())
		for f in fails:
			print("  - ", f)
		quit(1)

# ---------- runs ----------

func _play(choice: int, explore_pts: float, smart: bool = false) -> Dictionary:
	var guard := 0
	while guard < MAX_STEPS:
		guard += 1
		var res: Dictionary = gs.advance()
		var kind := String(res.get("kind", ""))
		if kind == "explore":
			gs.finish_explore(explore_pts)
		elif kind == "event":
			var ev: Dictionary = res["event"]
			gs.apply_choice(_smart_choice(ev) if smart else choice)
		elif kind == "end":
			break
	_check(guard < MAX_STEPS, "run finished without hitting the step guard")
	return gs.last_report

# A cheap "sensible player": avoid losing days, hull, or data when a free option exists.
func _smart_choice(ev: Dictionary) -> int:
	var best := 0
	var best_cost := 1.0e9
	var choices: Array = ev["choices"]
	for i in choices.size():
		var fx: Dictionary = choices[i]["fx"]
		var cost := 0.0
		if fx.has("days"):
			cost += float(fx["days"]) * 12.0
		if fx.has("supply_pct"):
			cost += -float(fx["supply_pct"]) * 40.0
		if fx.has("hull"):
			cost += -float(fx["hull"])
		if fx.has("rad_hull"):
			cost += float(fx["rad_hull"])
		if fx.has("prop_pct"):
			cost += -float(fx["prop_pct"]) * 100.0
		if fx.has("data_mult"):
			cost += (1.0 - float(fx["data_mult"])) * 15.0
		if cost < best_cost:
			best_cost = cost
			best = i
	return best

func _test_smart_run() -> void:
	gs.reset_all()
	gs.load_sample_design()
	gs.start_run("moon")
	var rep: Dictionary = _play(0, 60.0, true)
	_check(bool(rep.get("success", false)), "sample design wins with sensible choices (got '%s')" % rep.get("reason", ""))
	print("  smart run: success=%s score=%s data=%s" % [rep.get("success"), rep.get("score"), rep.get("data_gain")])

func _test_sample_run() -> void:
	gs.reset_all()
	gs.load_sample_design()
	gs.start_run("moon")
	var rep: Dictionary = _play(0, 30.0)
	_check(not rep.is_empty(), "sample design produced a report")
	_check(rep.has("score"), "sample report has a score")
	_check(int(rep.get("score", -1)) > 0, "sample score is positive")
	_check(rep.has("data_gain"), "sample report has data_gain")
	print("  sample run: success=%s score=%s data=%s" % [rep.get("success"), rep.get("score"), rep.get("data_gain")])

func _test_weak_run() -> void:
	gs.reset_all()
	gs.load_sample_design()
	gs.fuel_pct = 0.25
	gs.start_run("moon")
	var rep: Dictionary = _play(1, 10.0)
	_check(not bool(rep.get("success", true)), "weak design fails the mission")
	var reason := String(rep.get("reason", ""))
	_check(REASONS.has(reason), "weak failure reason is one of the five (got '%s')" % reason)
	print("  weak run: reason=%s" % reason)

# ---------- scenes ----------

func _test_scenes() -> void:
	for name in SCENES:
		var packed: PackedScene = load("res://scenes/%s.tscn" % name)
		_check(packed != null, "scene %s.tscn loads" % name)
		if packed == null:
			continue
		var node: Node = packed.instantiate()
		root.add_child(node)
		_check(node.is_inside_tree(), "scene %s becomes ready" % name)
		node.queue_free()
	_check(true, "")

# ---------- new station / EVA systems ----------

func _test_new_systems() -> void:
	gs.reset_all()
	gs.station_data = 200
	# Greenhouse + farm: build it, advance a full lettuce cycle, harvest into the food store.
	_check(gs.build_module("greenhouse"), "greenhouse can be built with Data")
	gs.ensure_plot()
	var p: Dictionary = gs.plots[0]
	var before_age := float(p["age_days"])
	var tr: Dictionary = gs.tend_plot(30.0)
	_check(bool(tr.get("ok", false)), "tending the greenhouse plot succeeds")
	_check(float(gs.plots[0]["age_days"]) > before_age, "greenhouse plot ages when tended")
	_check(gs.plot_ready(), "lettuce plot is ready after a full cycle")
	var food_before: float = gs.food_store
	var hr: Dictionary = gs.harvest_plot()
	_check(bool(hr.get("ok", false)), "harvest succeeds when the plot is ready")
	_check(gs.food_store > food_before, "harvest adds food to the ISS store")

	# Prep gear costs Data and is consumed by the next launch.
	gs.station_data = 100
	var data_before: int = gs.station_data
	var pr: Dictionary = gs.buy_prep("scout")
	_check(bool(pr.get("ok", false)), "scout drone can be loaded in the cabin")
	_check(gs.station_data == data_before - gs.prep_cost("scout"), "scout costs the configured Data")
	_check(bool(gs.prep.get("scout", false)), "scout flag is set for the next flight")

	# Food from the ISS reduces packed food; the scout survives into the run state.
	gs.load_sample_design()
	gs.food_store = 0.0
	var dry: Dictionary = gs.analyze("moon")
	gs.food_store = 60.0
	var with_food: Dictionary = gs.analyze("moon")
	_check(float(with_food["need"]["food"]) <= float(dry["need"]["food"]),
		"ISS food store reduces the packed-food requirement")
	_check(float(with_food["food_store_used"]) > 0.0, "analysis reports how much ISS food is used")
	var fs_before: float = gs.food_store
	gs.start_run("moon")
	_check(bool(gs.run.get("scout", false)), "scout drone is carried into the flight")
	_check(float(gs.run.get("rad_mult", 1.0)) <= 1.0, "radiation multiplier is stored on the run")
	_check(gs.food_store < fs_before, "launch consumes the ISS food that offsets packed food")
	_check(absf(float(gs.run["stock"]["food"]) - (float(with_food["pack"]["food"]) + float(with_food["food_store_used"]))) < 0.01,
		"the offset ISS food is loaded aboard instead of being lost")
	_check(not bool(gs.prep.get("scout", true)), "prep gear is spent at launch")

	# In-flight activity spends supplies but returns the advertised benefit.
	var raw_before := float(gs.run["data_raw"])
	var day_before := float(gs.run["day"])
	var cr: Dictionary = gs.crew_activity("study")
	_check(bool(cr.get("ok", false)), "crew can study during the flight")
	_check(float(gs.run["data_raw"]) > raw_before, "studying in flight adds science")
	_check(float(gs.run["day"]) > day_before, "a crew activity advances the flight clock")

	# Stamina numbers and the exercise penalty come from the data files.
	var full := Stamina.capacity_for("ECLSS Advanced", true)
	var no_gym := Stamina.capacity_for("ECLSS Advanced", false)
	_check(full > no_gym, "exercise module raises EVA stamina capacity")
	_check(Stamina.eva_food_kcal(60.0) > 0.0, "EVA time converts to extra food energy")

	# Dossiers must be complete for both mission files.
	for mid in ["moon", "mars"]:
		var m: Dictionary = gs.mission(mid)
		for key in ["environment", "hazards", "resources", "gear", "scout_note"]:
			_check(m.has(key) and not (typeof(m[key]) == TYPE_ARRAY and m[key].is_empty()),
				"mission %s dossier has %s" % [mid, key])
	_check(gs.SAVE_VERSION >= 4, "save version covers story/day/food/prep fields")
	gs.reset_all()

# ---------- parity with tools/balance_check.py ----------
func _flat(a: Dictionary) -> Dictionary:
	return {
		"dry_kg": a["dry_kg"], "prop_kg": a["prop_kg"], "total_kg": a["total_kg"],
		"mass_cap_kg": a["mass_cap_kg"], "cost": a["cost"], "budget": a["budget"],
		"net": a["net"], "isp": a["isp"], "dv": a["dv"], "dv_need": a["dv_need"],
		"comm_q": a["comm_q"], "shield": a["shield"], "cap": a["cap"],
		"o2_need": a["need"]["o2"], "water_need": a["need"]["water"], "food_need": a["need"]["food"],
		"o2_pack": a["pack"]["o2"], "water_pack": a["pack"]["water"], "food_pack": a["pack"]["food"],
	}

func _test_golden() -> void:
	if not FileAccess.file_exists(GOLDEN):
		_check(false, "tests/golden.json is missing (run: python tools/balance_check.py --emit-golden)")
		return
	var f := FileAccess.open(GOLDEN, FileAccess.READ)
	var g = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(g) != TYPE_DICTIONARY:
		_check(false, "tests/golden.json is not valid JSON")
		return
	gs.reset_all()
	var cases: Array = g["cases"]
	_check(cases.size() > 0, "golden file has cases")
	for case in cases:
		var case_name := String(case["name"])
		for k in case["design"]:
			gs.design[k] = int(case["design"][k])
		gs.fuel_pct = float(case["fuel"])
		var have := _flat(gs.analyze("moon"))
		for key in case["expect"]:
			var want := float(case["expect"][key])
			var got := float(have.get(key, 0.0))
			var tol := maxf(TOL * absf(want), 0.001)
			_check(absf(got - want) <= tol,
				"golden %s.%s: gdscript %.4f vs python %.4f" % [case_name, key, got, want])
	print("  parity checked %d design(s)" % cases.size())
