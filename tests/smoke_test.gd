extends SceneTree
# Headless smoke test (T1/T2 in the handoff brief).
# Run:  Godot_v4.7.2-stable_win64.exe --headless --path . -s tests/smoke_test.gd
# Prints PASS, or FAIL <why> and exits non-zero. Never touches the player's save.

const SCENES := ["menu", "story", "tutorial", "station", "ship", "computer", "hangar", "mission", "flight", "explore", "report", "techbook"]
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
	_test_t17()
	_test_t18()
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
		elif kind == "nav":
			gs.resolve_nav(1.0)
		elif kind == "burn":
			gs.resolve_burn(1.0)
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

# ---------- T17 flight activities (plan, nav/burn, roll, schedule, morale) ----------
func _test_t17() -> void:
	gs.reset_all()
	gs.load_sample_design()
	gs.start_run("moon")
	var plan: Array = gs.run["plan"]
	var navs := 0
	var burns := 0
	var day_acc := 0.0
	var act_days: Array = []
	for step in plan:
		if String(step["kind"]) == "consume":
			day_acc += float(step["days"])
		elif String(step["kind"]) == "nav":
			navs += 1
			act_days.append(day_acc)
		elif String(step["kind"]) == "burn":
			burns += 1
			act_days.append(day_acc)
	_check(navs == 2, "plan has exactly 2 nav sightings (got %d)" % navs)
	_check(burns == 1, "plan has exactly 1 midcourse burn (got %d)" % burns)
	_check(act_days.size() == 3, "plan has 3 activity nodes (got %d)" % act_days.size())
	if act_days.size() == 3:
		_check(absf(float(act_days[0]) - 0.246) <= 0.001, "nav0 fires at 0.246 d (got %.3f)" % float(act_days[0]))
		_check(absf(float(act_days[1]) - 0.984) <= 0.001, "nav1 fires at 0.984 d (got %.3f)" % float(act_days[1]))
		_check(absf(float(act_days[2]) - 1.089) <= 0.001, "burn fires at 1.089 d (got %.3f)" % float(act_days[2]))
	# Half-accurate sighting + perfect burn -> penalty cleared.
	gs.resolve_nav(0.5)
	gs.resolve_burn(1.0)
	_check(absf(float(gs.run["dv_penalty_m_s"])) <= 0.001, "perfect burn clears the dv penalty (got %.3f)" % float(gs.run["dv_penalty_m_s"]))
	# Worst case: zero nav accuracy + skipped burn -> penalty = nominal + max error.
	gs.reset_all()
	gs.load_sample_design()
	gs.start_run("moon")
	gs.resolve_nav(0.0)
	gs.resolve_burn(0.0)
	_check(absf(float(gs.run["dv_penalty_m_s"]) - 12.37) <= 0.01, "worst-case penalty is 12.37 m/s (got %.3f)" % float(gs.run["dv_penalty_m_s"]))
	# Skipped thermal roll: same-seed comparison, hull must drop exactly 12 (2%/day x 6 coast days).
	gs.reset_all()
	gs.load_sample_design()
	gs.start_run("moon")
	var rep_on: Dictionary = _play(0, 30.0, true)
	gs.reset_all()
	gs.load_sample_design()
	gs.start_run("moon")
	gs.set_thermal_roll(false)
	var rep_off: Dictionary = _play(0, 30.0, true)
	_check(rep_on.get("success") and rep_off.get("success"), "smart run succeeds with and without the roll")
	_check(absf((float(rep_on.get("hull", 0.0)) - float(rep_off.get("hull", 0.0))) - 12.0) <= 0.5,
		"skipping the roll costs exactly 12 hull (got %.1f)" % (float(rep_on.get("hull", 0.0)) - float(rep_off.get("hull", 0.0))))
	# Exercise hours -> stamina capacity multiplier on arrival.
	gs.reset_all()
	gs.load_sample_design()
	gs.start_run("moon")
	gs.set_exercise_hours(0)
	_check(absf(gs.stamina_capacity_mult() - 0.9) <= 0.001, "0 h exercise -> 0.9 capacity (got %.2f)" % gs.stamina_capacity_mult())
	gs.set_exercise_hours(2)
	_check(absf(gs.stamina_capacity_mult() - 1.0) <= 0.001, "2 h exercise -> 1.0 capacity (got %.2f)" % gs.stamina_capacity_mult())
	# The penalty must come from activities.json, not a hardcoded 0.9.
	var pct := float(gs.activities()["game"]["transit"]["crew_schedule"]["no_exercise_stamina_capacity_penalty_pct"])
	gs.set_exercise_hours(0)
	_check(absf(gs.stamina_capacity_mult() - (1.0 - pct / 100.0)) <= 0.001,
		"capacity penalty reads activities.json (got %.3f, want %.3f)" % [gs.stamina_capacity_mult(), 1.0 - pct / 100.0])
	# Dead-man: the midcourse burn must resolve even if the player never presses anything.
	var flight_packed: PackedScene = load("res://scenes/flight.tscn")
	_check(flight_packed != null, "flight scene loads for the burn dead-man test")
	if flight_packed != null:
		var fnode: Node = flight_packed.instantiate()
		root.add_child(fnode)
		fnode.call("show_burn")
		fnode.call("_process_burn", 7.0)
		_check(bool(gs.run.get("burn_done", false)), "burn auto-resolves when the player never presses")
		_check(absf(float(gs.run.get("dv_penalty_m_s", 0.0)) - 6.37) <= 0.01,
			"skipped burn leaves the full nominal penalty (got %.3f)" % float(gs.run.get("dv_penalty_m_s", 0.0)))
		fnode.queue_free()
	# Morale gates event choices: blocked at 0, allowed at 1.
	gs.reset_all()
	gs.load_sample_design()
	gs.start_run("moon")
	var ice: Dictionary = {}
	for e in gs.data["events"]:
		if String(e["id"]) == "ice":
			ice = e
	_check(not ice.is_empty(), "ice event exists for the morale gate")
	if not ice.is_empty():
		gs.run["current_event"] = ice
		gs.run["morale"] = 0
		var raw_before := float(gs.run["data_raw"])
		var blocked: String = gs.apply_choice(ice["choices"].size() - 1)
		_check(String(blocked).to_lower().contains("morale"), "morale choice is blocked at 0 (got '%s')" % blocked)
		_check(absf(float(gs.run["data_raw"]) - raw_before) <= 0.001, "blocked choice changes nothing")
		gs.run["morale"] = 2
		var allowed: String = gs.apply_choice(ice["choices"].size() - 1)
		_check(not String(allowed).to_lower().contains("morale"), "morale choice allowed at 2")
	gs.reset_all()

# ---------- T18 multi-walk EVA ----------
func _test_t18() -> void:
	gs.reset_all()
	gs.load_sample_design()
	gs.start_run("moon")
	var packed: PackedScene = load("res://scenes/explore.tscn")
	_check(packed != null, "explore scene loads for the walk test")
	if packed != null:
		var node: Node = packed.instantiate()
		root.add_child(node)
		_check(node.is_inside_tree(), "explore scene becomes ready")
		_check(bool(node.get("in_prep")), "prep panel shows before the first walk")
		node.call("confirm_prep")
		var wi = node.get("walk_idx")
		_check(wi != null and int(wi) == 1, "first walk starts at index 1 (got %s)" % str(wi))
		_check(node.get("suit") != null, "a fresh suit exists for walk 1")
		node.call("end_walk", "test reason")
		_check(bool(node.get("in_rest")), "walk 1 ends into the rest panel")
		node.call("begin_walk")
		var wi2 = node.get("walk_idx")
		_check(wi2 != null and int(wi2) == 2, "second walk starts at index 2 (got %s)" % str(wi2))
		node.call("end_walk", "test reason")
		node.call("begin_walk")
		var wi3 = node.get("walk_idx")
		_check(wi3 != null and int(wi3) == 3, "third walk starts at index 3 (got %s)" % str(wi3))
		node.call("end_walk", "test reason")
		_check(bool(node.get("in_final")), "walk 3 ends into the final panel")
		# Hold tasks must require holding: a tap (key never down) cancels.
		var pts_before: float = float(node.get("points"))
		node.call("_start_hold", "core", 0)
		node.call("_process_hold", 2.0)
		_check(String(node.get("hold_kind")) == "", "hold cancels when the key is not down")
		_check(absf(float(node.get("points")) - pts_before) <= 0.001, "cancelled hold grants no points")
		_check(absf(float(node.call("_doc_multiplier")) - float(gs.activities()["game"]["surface"]["tasks"]["document"]["points_multiplier"])) <= 0.001,
			"document multiplier wired to activities.json")
		_check(absf(float(node.call("_core_multiplier")) - float(gs.activities()["game"]["surface"]["tasks"]["core"]["points_multiplier"])) <= 0.001,
			"core multiplier wired to activities.json")
		node.queue_free()
	# Sample mass enters dry mass before the return burn.
	gs.run["dry"] = 100.0
	gs.finish_explore(50.0, {"regolith": 2}, 100.0, 10.0, 60.0, 10.0, [1, 2, 3], 1)
	_check(absf(float(gs.run["dry"]) - 110.0) <= 0.001, "sample mass raises dry mass (got %.1f)" % float(gs.run["dry"]))
	_check(gs.run["walks_log"].size() == 3, "walk log has 3 entries (got %d)" % gs.run["walks_log"].size())
	_check(int(gs.run["deploys"]) == 1, "deploys stored on the run")
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
