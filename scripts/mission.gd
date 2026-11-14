extends Screen
# Screen 4 - Mission Control: choose mission, read the brief, check the plan, launch.

var ui: Control
var selected: String = "moon"

func build() -> void:
	star_seed = 41
	ui = Control.new()
	ui.size = Vector2(1280, 720)
	add_child(ui)
	refresh()

func refresh() -> void:
	Pix.clear(ui)
	Pix.lbl(ui, "MISSION CONTROL", Vector2(20, 14), Vector2(600, 36), 28, Pix.EDGE)
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
	if selected == "mars":
		var txt := "Mars is unlocked!\nThis prototype ends here. In the full game Mars uses the data from the Game Data Book (4.3 km/s transfer, 6.36 mbar CO2 atmosphere, MOXIE-style oxygen)." if GameState.mars_unlocked else "Complete the Moon mission first to unlock Mars."
		Pix.lbl(ui, txt, Vector2(430, 200), Vector2(800, 120), 18, Pix.GOOD if GameState.mars_unlocked else Pix.DIM)
		Pix.btn(ui, "< Station", Vector2(20, 660), Vector2(150, 40), func(): go("station"))
		return
	# plan table
	var a := GameState.analyze("moon")
	Pix.lbl(ui, "FLIGHT PLAN (each burn includes a %d%% margin)" % int(float(GameState.C["leg_margin"]) * 100.0), Vector2(430, 190), Vector2(820, 22), 15, Pix.WARN)
	var yy := 216
	for leg in m["legs"]:
		Pix.lbl(ui, "%s: %.2f km/s  (failure = %s)" % [leg["name"], float(leg["dv"]), leg["fail"]], Vector2(440, yy), Vector2(800, 22), 15)
		yy += 24
	Pix.lbl(ui, "Total delta-v needed: %.2f km/s   |   your ship: %.2f km/s" % [a["dv_need"], a["dv"]], Vector2(440, yy + 4), Vector2(800, 22), 16, Pix.GOOD if a["dv"] >= a["dv_need"] else Pix.BAD)
	yy += 40
	Pix.lbl(ui, "Note: the LEO -> trans-lunar injection burn (3.2 km/s) is done by the station's booster in this prototype, so the ship only flies the three legs above.", Vector2(440, yy), Vector2(800, 44), 13, Pix.DIM)
	yy += 56
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
	Pix.btn(ui, "< Station", Vector2(20, 660), Vector2(150, 40), func(): go("station"))
	Pix.btn(ui, "Edit ship", Vector2(180, 660), Vector2(150, 40), func(): go("hangar"))
	Pix.btn(ui, "New seed", Vector2(340, 660), Vector2(150, 40), func():
		GameState.new_seed()
		refresh())
	var launch := Pix.btn(ui, "LAUNCH >", Vector2(960, 650), Vector2(290, 56), on_launch)
	launch.disabled = not a["can_launch"]
	if not a["can_launch"]:
		Pix.lbl(ui, "Cannot launch: over budget or over lift limit.", Vector2(700, 668), Vector2(250, 40), 13, Pix.BAD)

func on_launch() -> void:
	GameState.save_game()
	GameState.start_run("moon")
	go("flight")
