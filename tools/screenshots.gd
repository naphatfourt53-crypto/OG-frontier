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

	await _shot("01_menu", "menu")
	await _shot("02_station", "station")
	await _shot("03_hangar", "hangar")
	await _shot("04_mission", "mission")

	# Flight: run the sim up to the first event, then show the dialog and its result.
	gs.start_run("moon")
	var res := {}
	var guard := 0
	while guard < 40:
		res = gs.advance()
		guard += 1
		if res.get("kind", "") == "event" or res.get("kind", "") == "end":
			break
	var flight = await _open("flight")
	await _capture("05_flight")
	if res.get("kind", "") == "event":
		flight.show_event(res["event"])
		await _frames(2)
		await _capture("06_event")
		flight.choose(0)
		await _frames(2)
		await _capture("07_event_result")
	await _close(flight)

	# Run to the EVA, screenshot it, then finish the mission and show the report.
	guard = 0
	while guard < 40:
		var r: Dictionary = gs.advance()
		guard += 1
		if r.get("kind", "") == "explore":
			break
		if r.get("kind", "") == "end":
			break
	await _shot("08_explore", "explore")
	gs.finish_explore(70.0, {"ice": 2, "regolith": 5, "ilmenite": 1, "helium3": 0})
	guard = 0
	while guard < 40:
		var r2: Dictionary = gs.advance()
		guard += 1
		if r2.get("kind", "") == "event":
			gs.apply_choice(0)
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
