extends Screen
# Screen 2 - Station hub. A branching tree of modules; the tree grows when you spend Data.
# Also hosts the first-run tutorial overlay (re-openable with the ? button).

var info: Label
var ui: Control
var tut_box: Control
var tut_step: int = 0
const ROLE_COL := {"core": Color("4fd1ff"), "habitat": Color("5dff9a"), "hangar": Color("ff8a3d"),
	"control": Color("ffc857"), "bonus": Color("b07bff")}

const TUTORIAL := [
	{"title": "1. This station is home",
	 "body": "The ISS is the last safe place for the crew. Coloured modules are built; purple \"+\" slots cost Data to grow.\n\nData comes from missions. Spend it on a Greenhouse (+storage), Science Lab (more Data), Cargo Bay (+budget), Heavy Dock (+lift limit), Relay Array (+comms) or Solar Wing (+power)."},
	{"title": "2. Hangar: design the ship",
	 "body": "Seven parts, three options each: Cockpit, Engine, Fuel Tank, Life Support, Power, Storage, Antenna.\n\nWatch Mass (lift limit), Power (net kW), Budget and Delta-v. Green numbers pass, red numbers fail. \"Load sample design\" gives you a ship that can fly the Moon mission."},
	{"title": "3. Mission Control: fly it",
	 "body": "Read the flight plan, then LAUNCH. During the trip random events ask for a decision: saving a day can cost supplies, saving supplies can cost data.\n\nThen walk the Moon, collect samples, return, and read the report. It tells you exactly why the mission worked or failed - and you can edit the ship and rerun the same seed."},
]

func build() -> void:
	star_seed = 21
	ui = Control.new()
	ui.size = Vector2(1280, 720)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	refresh()
	tut_box = Control.new()
	tut_box.size = Vector2(1280, 720)
	tut_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tut_box.visible = false
	add_child(tut_box)
	if not GameState.tutorial_seen:
		open_tutorial()

func refresh() -> void:
	Pix.clear(ui)
	Pix.lbl(ui, "ISS LAST LAUNCH - OPERATIONS LOBBY", Vector2(24, 8), Vector2(700, 34), 26, Pix.EDGE)
	Pix.lbl(ui, "DAY %03d   |   %s   |   ISS LOW EARTH ORBIT   |   EARTH: CRITICAL" % [GameState.day, GameState.date_text()],
		Vector2(24, 42), Vector2(820, 20), 13, Pix.WARN)
	Pix.lbl(ui, "Data %d   |   Food %.1f kg   |   Ore %d/%d pts   |   Smelter %.0f%%   |   Best score %d" % [
		GameState.station_data, GameState.food_store, GameState.smelter_points(),
		int(GameState.C.get("smelter_target", 165)), GameState.smelter_pct() * 100.0, GameState.best_score],
		Vector2(24, 62), Vector2(900, 20), 13, Pix.TEXT)
	info = Pix.lbl(ui, "Click a module. Purple '+' slots grow the station - they cost Data earned on missions.", Vector2(210, 660), Vector2(800, 50), 16, Pix.DIM)
	for m in GameState.data["station_modules"]:
		var built: bool = GameState.built.has(m["id"])
		var parent_ok: bool = m["parent"] == "" or GameState.built.has(m["parent"])
		if not built and not parent_ok:
			continue
		var center := Vector2(float(m["x"]), float(m["y"]))
		var b := Button.new()
		b.size = Vector2(198, 48)
		b.position = center - b.size / 2.0
		if built:
			b.text = m["name"]
		else:
			b.text = "+ %s (%d Data)" % [m["name"], int(m["cost"])]
			b.add_theme_font_size_override("font_size", 14)
			b.modulate = Color(0.85, 0.7, 1.0)
		var mm: Dictionary = m
		b.pressed.connect(func(): on_module(mm))
		ui.add_child(b)
	Pix.btn(ui, "?", Vector2(1104, 14), Vector2(44, 36), open_tutorial)
	Pix.btn(ui, "Menu", Vector2(1160, 14), Vector2(100, 36), func(): go("menu"))
	# Right-hand column: the two rooms the brief asks for plus the full tutorial.
	Pix.btn(ui, "CREW CABIN", Vector2(1040, 110), Vector2(206, 40), func(): go("ship"))
	Pix.btn(ui, "TERMINAL", Vector2(1040, 158), Vector2(206, 40), func(): go("computer"))
	Pix.btn(ui, "HOW TO PLAY", Vector2(1040, 206), Vector2(206, 40), func(): go("tutorial"))
	Pix.lbl(ui, "Mission Control, Apollo 9 - NASA", Vector2(1048, 684), Vector2(206, 18), 11, Color(0.55, 0.62, 0.78))
	queue_redraw()

func on_module(m: Dictionary) -> void:
	var id: String = m["id"]
	if GameState.built.has(id):
		match id:
			"hangar":
				go("hangar")
				return
			"control":
				go("mission")
				return
			"core":
				go("computer")
				return
			"habitat", "greenhouse", "lab", "exercise":
				# These are all rooms inside the crew cabin.
				go("ship")
				return
			_:
				info.text = "%s - %s" % [m["name"], m["effect"]]
	else:
		if GameState.station_data >= int(m["cost"]):
			GameState.build_module(id)
			Sfx.play("build")
			refresh()
			info.text = "Built %s! %s" % [m["name"], m["effect"]]
		else:
			info.text = "Not enough Data for %s (%d needed, you have %d). Complete missions to earn Data." % [m["name"], int(m["cost"]), GameState.station_data]

func back_scene() -> String:
	return "menu"

# ---------- tutorial overlay ----------

func open_tutorial() -> void:
	if tut_box == null:
		return
	tut_step = 0
	tut_box.visible = true
	_render_tutorial()

func _render_tutorial() -> void:
	Pix.clear(tut_box)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.86)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	tut_box.add_child(dim)
	Pix.panel(tut_box, Vector2(260, 130), Vector2(760, 460))
	var step: Dictionary = TUTORIAL[tut_step]
	Pix.lbl(tut_box, "HOW TO PLAY  (%d/%d)" % [tut_step + 1, TUTORIAL.size()], Vector2(290, 150), Vector2(500, 26), 16, Pix.WARN)
	Pix.lbl(tut_box, String(step["title"]), Vector2(290, 184), Vector2(700, 40), 28, Pix.EDGE)
	Pix.lbl(tut_box, String(step["body"]), Vector2(290, 236), Vector2(700, 220), 17, Pix.TEXT)
	var last: bool = tut_step >= TUTORIAL.size() - 1
	if tut_step > 0:
		Pix.btn(tut_box, "< Back", Vector2(290, 500), Vector2(150, 48), func(): _tutorial_go(tut_step - 1))
	Pix.btn(tut_box, "DONE" if last else "NEXT >", Vector2(480, 500), Vector2(220, 48), func():
		if last:
			close_tutorial()
		else:
			_tutorial_go(tut_step + 1))
	Pix.btn(tut_box, "Skip", Vector2(720, 500), Vector2(150, 48), close_tutorial)
	Pix.lbl(tut_box, "You can reopen this any time with the ? button (top right).", Vector2(290, 552), Vector2(700, 24), 14, Pix.DIM)

func _tutorial_go(step: int) -> void:
	tut_step = clampi(step, 0, TUTORIAL.size() - 1)
	_render_tutorial()

func close_tutorial() -> void:
	GameState.tutorial_seen = true
	GameState.save_game()
	if tut_box != null:
		tut_box.visible = false
		Pix.clear(tut_box)

func draw_extra() -> void:
	var pos := {}
	for m in GameState.data["station_modules"]:
		pos[m["id"]] = Vector2(float(m["x"]), float(m["y"]))
	# branches first (so the modules draw on top)
	for m in GameState.data["station_modules"]:
		var built: bool = GameState.built.has(m["id"])
		var parent_ok: bool = m["parent"] == "" or GameState.built.has(m["parent"])
		if m["parent"] == "" or (not built and not parent_ok):
			continue
		var a: Vector2 = pos[m["parent"]]
		var b: Vector2 = pos[m["id"]]
		var col := Color("5a7fb8") if built else Color("6b4fa0")
		draw_line(a, b, col, 8.0)
		draw_line(a, b, col.lightened(0.3), 2.0)
	# module bodies
	for m in GameState.data["station_modules"]:
		var built: bool = GameState.built.has(m["id"])
		var parent_ok: bool = m["parent"] == "" or GameState.built.has(m["parent"])
		if not built and not parent_ok:
			continue
		var c: Vector2 = pos[m["id"]]
		var col: Color = ROLE_COL[m["role"]]
		if not built:
			col = Color("6b4fa0")
		draw_rect(Rect2(c.x - 102, c.y - 40, 204, 80), col.darkened(0.55))
		draw_rect(Rect2(c.x - 102, c.y - 40, 204, 6), col)
		draw_rect(Rect2(c.x - 102, c.y + 34, 204, 6), col)
		if m["role"] == "core":
			draw_circle(c, 62, col.darkened(0.5))
			draw_circle(c, 52, col.darkened(0.7))
	# tiny crew icons in the habitat
	var h: Vector2 = pos["habitat"]
	for i in 3:
		draw_rect(Rect2(h.x - 20 + i * 18, h.y - 66, 8, 12), Color("ffd166"))
		draw_rect(Rect2(h.x - 20 + i * 18, h.y - 74, 8, 8), Color("ffe8b0"))
	# Earth in the corner
	draw_circle(Vector2(90, 700), 110, Color("1d4e9e"))
	draw_circle(Vector2(90, 700), 100, Color("2a7bd4"))
	draw_rect(Rect2(50, 620, 40, 10), Color("3fae5a"))
	# archival photo of the real room this screen represents
	Pix.photo_frame(self, Pix.NASA_CONTROL, Rect2(1048, 548, 200, 128), 0.25)
