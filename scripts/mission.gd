extends Screen
# Screen 4 - Mission Control: choose mission, read the brief, check the plan, launch.

var ui: Control
var selected: String = "moon"
var dossier_box: Control

func build() -> void:
	star_seed = 41
	ui = Control.new()
	ui.size = Vector2(1280, 720)
	add_child(ui)
	refresh()

func refresh() -> void:
	Pix.clear(ui)
	Pix.lbl(ui, "MISSION CONTROL", Vector2(20, 14), Vector2(600, 36), 28, Pix.EDGE)
	Pix.lbl(ui, "GUIDE: pick a mission (left), read the plan, then LAUNCH. Mission 1 = the Moon: land, collect ore, come HOME.",
		Vector2(330, 24), Vector2(930, 22), 14, Pix.WARN)
	# mission list
	var y := 70
	for m in GameState.data["missions"]:
		var unlocked: bool = m["unlocked"] or (m["id"] == "mars" and GameState.mars_unlocked)
		var b := Button.new()
		b.position = Vector2(20, y)
		b.size = Vector2(380, 50)
		b.text = m["name"] if unlocked else "[LOCKED] " + String(m["name"])
		if selected == m["id"]:
			b.modulate = Color(0.5, 1.0, 0.7)
		var mid: String = m["id"]
		b.pressed.connect(func():
			selected = mid
			refresh())
		ui.add_child(b)
		y += 60
	var m: Dictionary = GameState.mission(selected)
	Pix.lbl(ui, String(m["name"]), Vector2(430, 70), Vector2(800, 34), 24, Pix.WARN)
	Pix.lbl(ui, String(m["brief"]), Vector2(430, 110), Vector2(820, 70), 16, Pix.TEXT)
	_support_panel()
	if selected == "mars":
		var txt := "Mars is unlocked!\nThis prototype ends here. In the full game Mars uses the data from the Game Data Book (4.3 km/s transfer, 6.36 mbar CO2 atmosphere, MOXIE-style oxygen)." if GameState.mars_unlocked else "Complete the Moon mission first to unlock Mars."
		Pix.lbl(ui, txt, Vector2(430, 200), Vector2(800, 120), 18, Pix.GOOD if GameState.mars_unlocked else Pix.DIM)
		Pix.btn(ui, "DETAILS", Vector2(500, 660), Vector2(150, 40), open_dossier)
		Pix.btn(ui, "< Station", Vector2(20, 660), Vector2(150, 40), func(): go("station"))
		return
	# plan table
	var a := GameState.analyze("moon")
	Pix.lbl(ui, "FLIGHT PLAN (each burn includes a %d%% margin)" % int(float(GameState.C["leg_margin"]) * 100.0), Vector2(430, 190), Vector2(820, 22), 15, Pix.WARN)
	var yy := 216
	for leg in m["legs"]:
		Pix.lbl(ui, "%s: %.2f km/s  (failure = %s)" % [leg["name"], float(leg["dv"]), leg["fail"]], Vector2(440, yy), Vector2(800, 22), 15)
		if leg.has("note"):
			Pix.lbl(ui, String(leg["note"]), Vector2(452, yy + 20), Vector2(790, 20), 13, Pix.DIM)
		yy += 46
	Pix.lbl(ui, "Total delta-v needed: %.2f km/s   |   your ship: %.2f km/s" % [a["dv_need"], a["dv"]], Vector2(440, yy + 2), Vector2(800, 22), 16, Pix.GOOD if a["dv"] >= a["dv_need"] else Pix.BAD)
	yy += 34
	Pix.lbl(ui, "Note: the LEO -> trans-lunar injection burn (3.2 km/s) is done by the station's booster in this prototype, so the ship only flies the three legs above.", Vector2(440, yy), Vector2(800, 44), 13, Pix.DIM)
	yy += 52
	Pix.lbl(ui, "CREW: %d   |   DURATION: %.0f days (+ delays)   |   SEED: %d" % [int(GameState.C["crew"]), GameState.mission_days(m), GameState.seed_value], Vector2(440, yy), Vector2(800, 22), 15)
	yy += 34
	if a["issues"].is_empty():
		Pix.lbl(ui, "Pre-flight check: all green.", Vector2(440, yy), Vector2(800, 22), 16, Pix.GOOD)
	else:
		Pix.lbl(ui, "Pre-flight warnings (you may launch anyway and see what happens):", Vector2(440, yy), Vector2(800, 22), 15, Pix.WARN)
		yy += 24
		for t in a["issues"]:
			Pix.lbl(ui, "! " + String(t), Vector2(450, yy), Vector2(800, 22), 15, Pix.BAD)
			yy += 22
	Pix.btn_ghost(ui, "< Station", Vector2(20, 660), Vector2(150, 40), func(): go("station"))
	Pix.btn_ghost(ui, "Edit ship", Vector2(180, 660), Vector2(150, 40), func(): go("hangar"))
	Pix.btn_ghost(ui, "DETAILS", Vector2(340, 660), Vector2(140, 40), open_dossier)
	Pix.btn_ghost(ui, "New seed", Vector2(490, 660), Vector2(140, 40), func():
		GameState.new_seed()
		refresh())
	if a["can_launch"]:
		Pix.btn_primary(ui, "LAUNCH >", Vector2(960, 650), Vector2(290, 56), on_launch)
	else:
		Pix.btn_blocked(ui, "LAUNCH", "over budget or lift limit", Vector2(960, 650), Vector2(290, 56), on_launch)

func on_launch() -> void:
	GameState.save_game()
	GameState.start_run("moon")
	go("flight")

func _support_panel() -> void:
	# Everything the ISS does for this flight, in one place. The player can see the
	# scout/rad-kit/food effects before spending the launch, not only in the report.
	Pix.panel(ui, Vector2(20, 210), Vector2(380, 260))
	Pix.lbl(ui, "STATION SUPPORT", Vector2(36, 222), Vector2(348, 22), 17, Pix.WARN)
	Pix.lbl(ui, "ISS day %03d  |  %s" % [GameState.day, GameState.date_text()],
		Vector2(36, 246), Vector2(348, 20), 13, Pix.DIM)
	var scout: bool = bool(GameState.prep.get("scout", false))
	var rad: bool = bool(GameState.prep.get("rad_kit", false))
	var eva := GameState.eva_seconds * (float(GameState.C["prep"]["scout_time_mult"]) if scout else 1.0)
	var used := 0.0
	if selected == "moon":
		used = float(GameState.analyze("moon").get("food_store_used", 0.0))
	var lines := [
		["Food store: %.1f kg" % GameState.food_store, Pix.TEXT],
		["   offsets %.1f kg of packed food" % used, Pix.GOOD if used > 0.0 else Pix.DIM],
		["Scout drone: %s" % ("READY  (+25%% EVA)" if scout else "not loaded  (standard ellipse)"), Pix.GOOD if scout else Pix.DIM],
		["Radiation blanket: %s" % ("READY  (-40%% flare damage)" if rad else "not loaded"), Pix.GOOD if rad else Pix.DIM],
		["EVA window: %.0f s" % eva, Pix.TEXT],
		["Smelter ore: %d / %d pts (%.0f%%)" % [GameState.smelter_points(),
			int(GameState.C.get("smelter_target", 165)), GameState.smelter_pct() * 100.0], Pix.WARN],
	]
	var y := 274.0
	for pair in lines:
		Pix.lbl(ui, String(pair[0]), Vector2(36, y), Vector2(348, 20), 13, pair[1])
		y += 22.0
	Pix.lbl(ui, "Load gear in the crew cabin.", Vector2(36, 426), Vector2(348, 20), 12, Pix.DIM)

func open_dossier() -> void:
	if dossier_box != null:
		return
	var m: Dictionary = GameState.mission(selected)
	dossier_box = Control.new()
	dossier_box.size = Vector2(1280, 720)
	add_child(dossier_box)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.9)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dossier_box.add_child(dim)
	Pix.panel(dossier_box, Vector2(120, 40), Vector2(1040, 620))
	Pix.lbl(dossier_box, "MISSION DOSSIER", Vector2(150, 58), Vector2(600, 22), 15, Pix.WARN)
	Pix.lbl(dossier_box, String(m["name"]).to_upper(), Vector2(150, 82), Vector2(800, 34), 28, Pix.EDGE)
	Pix.lbl(dossier_box, String(m.get("brief", "")), Vector2(150, 122), Vector2(900, 44), 14, Pix.TEXT)
	Pix.lbl(dossier_box, "ENVIRONMENT", Vector2(150, 176), Vector2(900, 18), 13, Pix.WARN)
	Pix.lbl(dossier_box, String(m.get("environment", "")), Vector2(150, 196), Vector2(900, 44), 14, Pix.TEXT)
	_section_list(dossier_box, "HAZARDS", m.get("hazards", []), 250.0)
	_section_list(dossier_box, "RESOURCES", m.get("resources", []), 352.0)
	_section_list(dossier_box, "RECOMMENDED GEAR", m.get("gear", []), 454.0)
	Pix.lbl(dossier_box, "SCOUT NOTE", Vector2(150, 550), Vector2(900, 18), 13, Pix.WARN)
	Pix.lbl(dossier_box, String(m.get("scout_note", "")), Vector2(150, 570), Vector2(900, 36), 14, Pix.DIM)
	Pix.btn(dossier_box, "CLOSE", Vector2(980, 600), Vector2(150, 44), close_dossier)
	Pix.lbl(dossier_box, "Esc = close", Vector2(150, 620), Vector2(200, 20), 12, Pix.DIM)

func _section_list(parent: Node, title: String, items: Array, y: float) -> void:
	Pix.lbl(parent, title, Vector2(150, y), Vector2(900, 18), 13, Pix.WARN)
	var yy := y + 20.0
	for item in items:
		Pix.lbl(parent, "- " + String(item), Vector2(164, yy), Vector2(880, 20), 13, Pix.TEXT)
		yy += 20.0

func close_dossier() -> void:
	if dossier_box != null:
		dossier_box.queue_free()
		dossier_box = null

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and dossier_box != null:
		get_viewport().set_input_as_handled()
		close_dossier()
		return
	super._unhandled_input(event)

func back_scene() -> String:
	return "station"
