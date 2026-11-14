extends Screen
# Screen 2 - Station hub. A branching tree of modules; the tree grows when you spend Data.

var info: Label
var ui: Control
const ROLE_COL := {"core": Color("4fd1ff"), "habitat": Color("5dff9a"), "hangar": Color("ff8a3d"),
	"control": Color("ffc857"), "bonus": Color("b07bff")}

func build() -> void:
	star_seed = 21
	ui = Control.new()
	ui.size = Vector2(1280, 720)
	add_child(ui)
	refresh()

func refresh() -> void:
	Pix.clear(ui)
	Pix.lbl(ui, "ORBITAL STATION", Vector2(24, 14), Vector2(500, 36), 28, Pix.EDGE)
	Pix.lbl(ui, "Data: %d   |   Best score: %d" % [GameState.station_data, GameState.best_score], Vector2(24, 52), Vector2(600, 24), 16, Pix.WARN)
	info = Pix.lbl(ui, "Click a module. Purple '+' slots grow the station - they cost Data earned on missions.", Vector2(24, 660), Vector2(1100, 50), 16, Pix.DIM)
	for m in GameState.data["station_modules"]:
		var built: bool = GameState.built.has(m["id"])
		var parent_ok: bool = m["parent"] == "" or GameState.built.has(m["parent"])
		if not built and not parent_ok:
			continue
		var center := Vector2(float(m["x"]), float(m["y"]))
		var b := Button.new()
		b.size = Vector2(150, 48)
		b.position = center - b.size / 2.0
		if built:
			b.text = m["name"]
		else:
			b.text = "+ %s (%d Data)" % [m["name"], int(m["cost"])]
			b.modulate = Color(0.85, 0.7, 1.0)
		var mm: Dictionary = m
		b.pressed.connect(func(): on_module(mm))
		ui.add_child(b)
	Pix.btn(ui, "Menu", Vector2(1160, 14), Vector2(100, 36), func(): go("menu"))
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
			_:
				info.text = "%s - %s" % [m["name"], m["effect"]]
	else:
		if GameState.station_data >= int(m["cost"]):
			GameState.build_module(id)
			refresh()
			info.text = "Built %s! %s" % [m["name"], m["effect"]]
		else:
			info.text = "Not enough Data for %s (%d needed, you have %d). Complete missions to earn Data." % [m["name"], int(m["cost"]), GameState.station_data]

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
		draw_rect(Rect2(c.x - 84, c.y - 36, 168, 72), col.darkened(0.55))
		draw_rect(Rect2(c.x - 84, c.y - 36, 168, 6), col)
		draw_rect(Rect2(c.x - 84, c.y + 30, 168, 6), col)
		if m["role"] == "core":
			draw_circle(c, 62, col.darkened(0.5))
			draw_circle(c, 52, col.darkened(0.7))
	# tiny crew icons in the habitat
	var h: Vector2 = pos["habitat"]
	for i in 3:
		draw_rect(Rect2(h.x - 20 + i * 18, h.y - 58, 8, 12), Color("ffd166"))
		draw_rect(Rect2(h.x - 20 + i * 18, h.y - 66, 8, 8), Color("ffe8b0"))
	# Earth in the corner
	draw_circle(Vector2(90, 700), 110, Color("1d4e9e"))
	draw_circle(Vector2(90, 700), 100, Color("2a7bd4"))
	draw_rect(Rect2(50, 620, 40, 10), Color("3fae5a"))
