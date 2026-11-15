extends SceneTree
# Headless mirror test for stamina/physics/farm (T10 AC in
# docs/OPENCODE_TASKS_STAMINA_PHYSICS_FARM.md). Same numbers and tolerances
# as tools/check_physics.py. Never touches the player's save.
# Run:  Godot_v4.7.2-stable_win64.exe --headless --path . -s tests/test_stamina_physics_farm.gd

var fails: Array = []
var checks: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, msg: String, got: float, want: float) -> void:
	checks += 1
	if not ok:
		fails.append("%s: got %.4f, want %.4f" % [msg, got, want])
		print("  FAIL ", msg, " got ", got, " want ", want)

func _run() -> void:
	# ---- stamina mirror ----
	_check(absf(Stamina.drain_per_game_s("normal") - 93.0) <= 0.001, "normal pace drain", Stamina.drain_per_game_s("normal"), 93.0)
	_check(absf(Stamina.seconds_to_empty(5550.0, "normal") - 59.7) <= 0.05, "open-loop normal to empty", Stamina.seconds_to_empty(5550.0, "normal"), 59.7)
	_check(absf(Stamina.seconds_to_empty(5550.0, "easy") - 71.15) <= 0.05, "open-loop easy to empty", Stamina.seconds_to_empty(5550.0, "easy"), 71.15)
	_check(absf(Stamina.seconds_to_empty(5550.0, "hard") - 46.25) <= 0.05, "open-loop hard to empty", Stamina.seconds_to_empty(5550.0, "hard"), 46.25)
	_check(absf(Stamina.drain_per_game_s("burst") * 3.0 - 600.0) <= 0.001, "burst 3s budget", Stamina.drain_per_game_s("burst") * 3.0, 600.0)
	_check(absf(Stamina.capacity_for("Open-loop", true) - 5550.0) <= 0.01, "capacity with exercise", Stamina.capacity_for("Open-loop", true), 5550.0)
	_check(absf(Stamina.capacity_for("Open-loop", false) - 4995.0) <= 0.01, "capacity without exercise", Stamina.capacity_for("Open-loop", false), 4995.0)
	_check(absf(Stamina.cfg()["reserve_pct"] * 5550.0 - 832.5) <= 0.01, "reserve threshold", float(Stamina.cfg()["reserve_pct"]) * 5550.0, 832.5)
	_check(absf(Stamina.eva_food_kcal(60.0) - 1200.0) <= 0.01, "eva food 60s", Stamina.eva_food_kcal(60.0), 1200.0)
	# ---- physics mirror ----
	var mu_earth: float = OrbitMath.const_f("mu_earth_m3_s2")
	var leo: float = 6378137.0 + 400000.0
	var moon_dist: float = 384400000.0
	_check(absf(OrbitMath.planet_hohmann_days("earth", "mars") - 258.9) <= 0.1, "earth-mars hohmann", OrbitMath.planet_hohmann_days("earth", "mars"), 258.9)
	_check(absf(OrbitMath.hohmann_days(leo, moon_dist, mu_earth) - 4.98) <= 0.05, "earth-moon hohmann", OrbitMath.hohmann_days(leo, moon_dist, mu_earth), 4.98)
	_check(absf(OrbitMath.solar_wm2(1.52368) - 586.2) <= 0.1, "mars irradiance", OrbitMath.solar_wm2(1.52368), 586.2)
	_check(absf(OrbitMath.solar_wm2(1.0) - 1361.0) <= 0.001, "earth irradiance", OrbitMath.solar_wm2(1.0), 1361.0)
	# ---- farm mirror ----
	_check(absf(Farm.dli(300.0, 16.0) - 17.28) <= 0.001, "dli 300x16", Farm.dli(300.0, 16.0), 17.28)
	_check(absf(Farm.led_power_w_per_m2(300.0, 2.5) - 120.0) <= 0.001, "led w/m2", Farm.led_power_w_per_m2(300.0, 2.5), 120.0)
	_check(absf(Farm.led_kwh_per_m2_day(300.0, 2.5, 16.0) - 1.92) <= 0.001, "led kwh/m2/day", Farm.led_kwh_per_m2_day(300.0, 2.5, 16.0), 1.92)
	var plot: Dictionary = Farm.new_plot("lettuce", 1.0)
	Farm.advance_plot(plot, 28.0, 300.0, 16.0, 1.0)
	_check(Farm.crop_ready(plot), "lettuce ready at 28d", 1.0, 1.0)
	_check(absf(Farm.harvest_kg(plot) - 3.68) <= 0.01, "lettuce full yield", Farm.harvest_kg(plot), 3.68)

	if fails.is_empty():
		print("PASS test_stamina_physics_farm (%d checks)" % checks)
		quit(0)
	else:
		print("FAIL %d check(s):" % fails.size())
		for f in fails:
			print("  - ", f)
		quit(1)
