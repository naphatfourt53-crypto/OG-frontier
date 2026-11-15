extends SceneTree
# Renders every screen to tests/out/*.png so a human (or the agent) can check the layout.
# Must run with a real renderer (headless has no framebuffer):
#   Godot_v4.7.2-stable_win64.exe --path . -s tools/screenshots.gd
# The tool never writes the player's save (GameState.skip_save = true).

const OUT_DIR := "res://tests/out/"
const SCENES := "res://scenes/%s.tscn"

var gs: Node
var failures: Array = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	gs = root.get_node_or_null("GameState")
	if gs == null:
		push_error("GameState autoload missing - can't render screens")
		quit(1)
		return
	gs.skip_save = true
	gs.sound_on = false  # keep automation silent
	gs.reset_all()
	gs.load_sample_design()
	gs.seed_value = 424242
	gs.tutorial_seen = true  # keep screen 02 clean; the overlay gets its own shot
	gs.story_seen = true  # the first-visit story plays on the station; its own shot is 12_story
	# Show the new station support in the gallery: some ISS food and gear already loaded.
	gs.station_data = 80
	gs.food_store = 8.0
	gs.buy_prep("scout")
	gs.buy_prep("rad_kit")

	await _shot("01_menu", "menu")
	await _shot("12_story", "story")
	await _shot("13_full_tutorial", "tutorial")
	await _shot("02_station", "station")
	await _shot("03_hangar", "hangar")

	var mission = await _open("mission")
	await _capture("04_mission")
	mission.open_dossier()
	await _frames(2)
	await _capture("14_dossier")
	await _close(mission)

	# Flight: run the sim up to the first event, then show the dialog and its result.
	gs.start_run("moon")
	var res := {}
	var guard := 0
	while guard < 40:
		res = gs.advance()
		guard += 1
		var kind := String(res.get("kind", ""))
		if kind == "nav":
			gs.resolve_nav(1.0)
		elif kind == "burn":
			gs.resolve_burn(1.0)
		elif kind == "event" or kind == "end":
			break
	var flight = await _open("flight")
	await _capture("05_flight")
	if res.get("kind", "") == "event":
		flight.show_event(res["event"])
		await create_timer(0.75).timeout
		await _capture("06_event")
		flight.choose(_best_choice(res["event"]))
		await create_timer(0.75).timeout
		await _capture("07_event_result")
	await _close(flight)

	# T17 in-transit activity overlays (the run is mid-plan; the screens are pure UI).
	var flight_act = await _open("flight")
	flight_act.show_nav(0)
	await _frames(2)
	await _capture("19_nav_sighting")
	flight_act.close_activity()
	flight_act.show_burn()
	await _frames(2)
	await _capture("20_midcourse_burn")
	flight_act.close_activity()
	flight_act.open_schedule()
	await _frames(2)
	await _capture("21_schedule")
	flight_act.close_activity()
	await _close(flight_act)

	# Run to the EVA, screenshot it, then finish the mission and show the report.
	guard = 0
	while guard < 40:
		var r: Dictionary = gs.advance()
		guard += 1
		if r.get("kind", "") == "explore":
			break
		if r.get("kind", "") == "end":
			break
	var explore_node = await _open("explore")
	explore_node.confirm_prep()
	await _frames(2)
	await _capture("08_explore")
	explore_node.end_walk("screenshot: rest panel")
	await _frames(2)
	await _capture("22_rest_panel")
	await _close(explore_node)
	var explore_prep = await _open("explore")
	await _frames(2)
	await _capture("23_prep_panel")
	await _close(explore_prep)
	gs.finish_explore(70.0, {"ice": 2, "regolith": 5, "ilmenite": 1, "helium3": 0}, 5400.0, 1200.0, 75.0)
	guard = 0
	while guard < 40:
		var r2: Dictionary = gs.advance()
		guard += 1
		if r2.get("kind", "") == "event":
			gs.apply_choice(_best_choice(r2["event"]))
		elif r2.get("kind", "") == "end":
			break
	await _shot("09_report", "report")

	# Overlays that are not part of the normal flow.
	var menu = await _open("menu")
	menu.open_settings()
	await _frames(2)
	await _capture("10_settings")
	await _close(menu)

	var station = await _open("station")
	station.open_tutorial()
	await _frames(2)
	await _capture("11_tutorial")
	await _close(station)

	# Station-side rooms with modules built, food growing and gear loaded.
	gs.reset_all()
	gs.station_data = 140
	gs.build_module("greenhouse")
	gs.build_module("lab")
	gs.build_module("exercise")
	gs.ensure_plot()
	gs.tend_plot(8.0)
	gs.food_store = 12.5
	gs.buy_prep("scout")
	gs.buy_prep("rad_kit")
	gs.ore = {"ice": 3, "regolith": 9, "ilmenite": 2, "helium3": 0}
	gs.tutorial_seen = true  # reset_all() cleared it; keep shot 17 on the lobby itself
	await _shot("15_ship", "ship")
	await _shot("16_computer", "computer")
	await _shot("17_station_built", "station")

	# In-flight crew overlay.
	gs.load_sample_design()
	gs.start_run("moon")
	var flight2 = await _open("flight")
	flight2.close_activity()  # the pre-flight checklist auto-opens on a fresh run
	flight2.open_crew()
	await _frames(2)
	await _capture("18_crew")
	await _close(flight2)

	# Phase 2: the walkable station with a hover card, the first-visit story, and the Tech Book tabs.
	gs.story_seen = true  # reset_all() above cleared it; the hover shot must not open the story
	var st_node = await _open("station")
	st_node.close_tutorial()
	st_node._show_hover("Greenhouse", "NOT BUILT. Cost 20 Data - you have 80. Press E or click to build.", Pix.GOOD)
	await _frames(2)
	await _capture("24_station_hover")
	st_node.hover_box.visible = false
	await _close(st_node)
	gs.story_seen = false
	var st_story = await _open("station")
	await _frames(2)
	await _capture("25_station_story_first_visit")
	await _close(st_story)
	gs.story_seen = true
	for tab_name in ["STATION", "SHIP", "FLIGHT", "EVA", "MISSIONS"]:
		var tb = await _open("techbook")
		tb._set_tab(tab_name)
		await _frames(2)
		await _capture("26_techbook_" + tab_name.to_lower())
		await _close(tb)

	if failures.is_empty():
		print("SCREENSHOTS OK -> ", ProjectSettings.globalize_path(OUT_DIR))
		quit(0)
	else:
		print("SCREENSHOTS FAILED: ", failures)
		quit(1)

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _open(scene: String) -> Node:
	var node: Node = load(SCENES % scene).instantiate()
	root.add_child(node)
	await _frames(3)
	return node

func _close(node: Node) -> void:
	node.queue_free()
	await _frames(2)

func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	if img == null or img.is_empty():
		failures.append(name + ": empty image (headless?)")
		return
	var path := ProjectSettings.globalize_path(OUT_DIR + name + ".png")
	var err := img.save_png(path)
	if err != OK:
		failures.append("%s: save_png error %d" % [name, err])
	else:
		print("shot %-14s %dx%d" % [name, img.get_width(), img.get_height()])

func _shot(name: String, scene: String) -> void:
	var node := await _open(scene)
	await _capture(name)
	await _close(node)

# Same "sensible player" heuristic as tests/smoke_test.gd, so the gallery shows a successful run.
func _best_choice(ev: Dictionary) -> int:
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
