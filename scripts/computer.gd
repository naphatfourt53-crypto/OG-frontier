extends Screen
# Screen - ISS terminal (the "v0.1 computer"). Shows where you are, the mission day,
# the station manifest and the full mission dossiers. This is the diegetic status
# screen the team asked for: a computer you can read, not only a menu.

var ui: Control
var selected: String = "moon"

func build() -> void:
	star_seed = 91
	ui = Control.new()
	ui.size = Vector2(1280, 720)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	refresh()

func refresh() -> void:
	Pix.clear(ui)
	# terminal frame
	Pix.panel(ui, Vector2(28, 24), Vector2(1224, 648))
	Pix.lbl(ui, "ISS TERMINAL  v0.1", Vector2(48, 38), Vector2(500, 32), 24, Pix.GOOD)
	Pix.lbl(ui, "LAST LAUNCH / HELIOS PROJECT", Vector2(48, 70), Vector2(500, 20), 13, Pix.DIM)
	Pix.lbl(ui, "DAY %03d   |   %s   |   LOW EARTH ORBIT" % [GameState.day, GameState.date_text()],
		Vector2(620, 40), Vector2(600, 26), 17, Pix.WARN)
	Pix.lbl(ui, "CREW %d   |   DATA %d   |   FOOD %.1f kg   |   SMELTER %.0f%%" % [
		int(GameState.C["crew"]), GameState.station_data, GameState.food_store, GameState.smelter_pct() * 100.0],
		Vector2(620, 70), Vector2(600, 22), 13, Pix.TEXT)
	# mission file list
	Pix.lbl(ui, "MISSION FILES", Vector2(48, 112), Vector2(260, 22), 16, Pix.WARN)
	var y := 142
	for m in GameState.data["missions"]:
		var unlocked: bool = m["unlocked"] or (m["id"] == "mars" and GameState.mars_unlocked)
		var b := Button.new()
		b.position = Vector2(48, y)
		b.size = Vector2(300, 44)
		b.text = String(m["name"]) if unlocked else "[LOCKED] " + String(m["name"])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 14)
		if selected == String(m["id"]):
			b.modulate = Color(0.5, 1.0, 0.7)
		var mid: String = m["id"]
		b.pressed.connect(func():
			selected = mid
			refresh())
		ui.add_child(b)
		y += 54
	Pix.lbl(ui, "SMELTER ORE", Vector2(48, 284), Vector2(260, 22), 16, Pix.WARN)
	var oy := 312
	for k in ["ice", "regolith", "ilmenite", "helium3"]:
		var r: Dictionary = GameState.data["moon_resources"][k]
		var n := int(GameState.ore.get(k, 0))
		Pix.lbl(ui, "%s  x%d  (%d pts)" % [r["name"], n, n * int(r["pts"])],
			Vector2(48, oy), Vector2(300, 22), 14, Pix.TEXT if n > 0 else Pix.DIM)
		oy += 24
	Pix.lbl(ui, "Target: %d pts" % int(GameState.C.get("smelter_target", 165)),
		Vector2(48, oy + 4), Vector2(300, 20), 13, Pix.DIM)
	# dossier
	var m2: Dictionary = GameState.mission(selected)
	Pix.lbl(ui, String(m2["name"]).to_upper(), Vector2(380, 112), Vector2(540, 30), 22, Pix.EDGE)
	Pix.lbl(ui, String(m2.get("brief", "")), Vector2(380, 146), Vector2(540, 62), 14, Pix.TEXT)
	Pix.lbl(ui, "ENVIRONMENT", Vector2(380, 216), Vector2(540, 18), 13, Pix.WARN)
	Pix.lbl(ui, String(m2.get("environment", "")), Vector2(380, 236), Vector2(540, 44), 13, Pix.TEXT)
	Pix.lbl(ui, "HAZARDS", Vector2(380, 286), Vector2(540, 18), 13, Pix.WARN)
	var hy := 306.0
	for h in m2.get("hazards", []):
		Pix.lbl(ui, "- " + String(h), Vector2(390, hy), Vector2(530, 20), 13, Pix.TEXT)
		hy += 20.0
	Pix.lbl(ui, "RESOURCES", Vector2(380, hy + 6), Vector2(540, 18), 13, Pix.WARN)
	var ry := hy + 26
	for r in m2.get("resources", []):
		Pix.lbl(ui, "- " + String(r), Vector2(390, ry), Vector2(530, 20), 13, Pix.TEXT)
		ry += 20.0
	Pix.lbl(ui, "RECOMMENDED GEAR", Vector2(380, ry + 6), Vector2(540, 18), 13, Pix.WARN)
	var gy := ry + 26
	for g in m2.get("gear", []):
		Pix.lbl(ui, "- " + String(g), Vector2(390, gy), Vector2(530, 20), 13, Pix.TEXT)
		gy += 20.0
	# right column: travel and prep
	Pix.lbl(ui, "FLIGHT DATA", Vector2(950, 112), Vector2(270, 20), 16, Pix.WARN)
	var travel := "Moon: %.0f days planned" % GameState.mission_days(m2) if selected == "moon" else "Mars: %.0f days one way (Hohmann)" % OrbitMath.planet_hohmann_days("earth", "mars")
	Pix.lbl(ui, travel, Vector2(950, 138), Vector2(270, 40), 14, Pix.TEXT)
	Pix.lbl(ui, "SCOUT: %s\nRAD KIT: %s" % [
		"READY" if GameState.prep.get("scout", false) else "not loaded",
		"READY" if GameState.prep.get("rad_kit", false) else "not loaded"],
		Vector2(950, 190), Vector2(270, 44), 14, Pix.GOOD if GameState.prep.get("scout", false) else Pix.DIM)
	Pix.lbl(ui, "ORBIT CHECK", Vector2(950, 246), Vector2(270, 20), 16, Pix.WARN)
	var moon_hohmann := float(OrbitMath.cfg()["reference_trips"]["earth_moon_hohmann_days"])
	Pix.lbl(ui, "Earth-Moon Hohmann: %.2f days\nSolar flux at Mars: %.1f W/m2" % [
		moon_hohmann, OrbitMath.solar_wm2(1.52368)],
		Vector2(950, 272), Vector2(270, 50), 13, Pix.DIM)
	Pix.lbl(ui, "NEXT", Vector2(950, 334), Vector2(270, 20), 16, Pix.WARN)
	Pix.lbl(ui, "Open Mission Control to check the ship, or enter the cabin to load gear.",
		Vector2(950, 360), Vector2(270, 70), 13, Pix.TEXT)
	# actions
	Pix.btn(ui, "MISSION CONTROL >", Vector2(950, 452), Vector2(270, 42), func(): go("mission"))
	Pix.btn(ui, "CREW CABIN", Vector2(950, 502), Vector2(270, 42), func(): go("ship"))
	Pix.btn(ui, "BACK TO ISS", Vector2(950, 552), Vector2(270, 42), func(): go("station"))
	Pix.lbl(ui, "Terminal linked to Mission Control. Data is saved locally.", Vector2(48, 624), Vector2(760, 20), 12, Pix.DIM)

func back_scene() -> String:
	return "station"

func draw_extra() -> void:
	# Scanlines and a soft green glow make the panel read as a CRT terminal.
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.02, 0.06, 0.05, 0.35))
	var y := 0
	while y < 720:
		draw_rect(Rect2(0, y, 1280, 1), Color(0.3, 1.0, 0.6, 0.035))
		y += 4
	draw_rect(Rect2(28, 24, 1224, 3), Color(0.3, 1.0, 0.6, 0.25))
