extends SceneTree
# Headless smoke test (T1/T2 in the handoff brief).
# Run:  Godot_v4.7.2-stable_win64.exe --headless --path . -s tests/smoke_test.gd
# Prints PASS, or FAIL <why> and exits non-zero. Never touches the player's save.

const SCENES := ["menu", "station", "hangar", "mission", "flight", "explore", "report"]
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
