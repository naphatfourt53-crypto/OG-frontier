extends Screen
# Screen 3 - Hangar: pick one option for each of the 7 ship parts. Live numbers on the right.

var ui: Control
var stats: Control
var info: Label
var fuel_label: Label

func build() -> void:
	star_seed = 31
	ui = Control.new()
	ui.size = Vector2(1280, 720)
	add_child(ui)
	stats = Control.new()
	stats.size = Vector2(1280, 720)
	add_child(stats)
	rebuild()

func rebuild() -> void:
	Pix.clear(ui)
	Pix.lbl(ui, "HANGAR - Assemble your ship", Vector2(20, 14), Vector2(700, 36), 28, Pix.EDGE)
	info = Pix.lbl(ui, "Hover an option to read about it.", Vector2(20, 596), Vector2(600, 44), 15, Pix.DIM)
	build_parts()
	build_fuel()
	Pix.btn(ui, "Load sample design", Vector2(20, 660), Vector2(190, 40), on_sample)
	Pix.btn(ui, "< Station", Vector2(220, 660), Vector2(130, 40), func(): go("station"))
	Pix.btn(ui, "Mission Control >", Vector2(1000, 660), Vector2(260, 44), func(): go("mission"))
	refresh_stats()

func build_parts() -> void:
	var y := 62
	for p in GameState.data["parts"]:
		var pid: String = p["id"]
		Pix.lbl(ui, String(p["name"]).to_upper(), Vector2(20, y), Vector2(300, 20), 14, Pix.WARN)
		var i := 0
		for o in p["options"]:
			var b := Button.new()
			b.text = o["name"]
			b.position = Vector2(20 + i * 195, y + 20)
			b.size = Vector2(188, 34)
			b.add_theme_font_size_override("font_size", 14)
			if int(GameState.design[pid]) == i:
				b.modulate = Color(0.5, 1.0, 0.7)
			var idx := i
			var oo: Dictionary = o
			b.pressed.connect(func(): pick(pid, idx))
			b.mouse_entered.connect(func(): info.text = "%s - %s | mass %d kg, power %+.1f kW, cost %d" % [oo["name"], oo["info"], int(oo["mass"]), float(oo["power"]), int(oo["cost"])])
			ui.add_child(b)
			i += 1
		y += 66

func build_fuel() -> void:
	fuel_label = Pix.lbl(ui, "", Vector2(20, 528), Vector2(600, 20), 14, Pix.WARN)
	var s := HSlider.new()
	s.position = Vector2(20, 552)
	s.size = Vector2(580, 24)
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.01
	s.value = GameState.fuel_pct
	s.value_changed.connect(func(v: float):
		GameState.fuel_pct = v
		refresh_stats())
	ui.add_child(s)

func pick(pid: String, idx: int) -> void:
	GameState.design[pid] = idx
	rebuild()

func on_sample() -> void:
	GameState.load_sample_design()
	rebuild()

func line(y: float, text: String, col: Color = Pix.TEXT) -> void:
	Pix.lbl(stats, text, Vector2(1010, y), Vector2(255, 40), 14, col)

func refresh_stats() -> void:
	Pix.clear(stats)
	var a := GameState.analyze("moon")
	fuel_label.text = "Propellant load: %d%% = %.0f t" % [int(GameState.fuel_pct * 100.0), a["prop_kg"] / 1000.0]
	Pix.panel(stats, Vector2(996, 60), Vector2(274, 560))
	Pix.lbl(stats, "SHIP STATS", Vector2(1010, 66), Vector2(250, 24), 18, Pix.EDGE)
	var good := Pix.GOOD
	var bad := Pix.BAD
	var y := 96.0
	line(y, "Mass: %.1f t (limit %.0f t)" % [a["total_kg"] / 1000.0, a["mass_cap_kg"] / 1000.0], good if a["total_kg"] <= a["mass_cap_kg"] else bad)
	y += 26
	line(y, "Budget: %.0f / %.0f" % [a["cost"], a["budget"]], good if a["cost"] <= a["budget"] else bad)
	y += 26
	line(y, "Power: +%.1f - %.1f = %+.1f kW" % [a["gen_solar"] + a["gen_other"], a["use"], a["net"]], good if a["net"] >= 0.0 else bad)
	y += 26
	line(y, "Delta-v: %.2f km/s (need %.2f)" % [a["dv"], a["dv_need"]], good if a["dv"] >= a["dv_need"] else bad)
	y += 26
	line(y, "Isp: %.0f s   Comm quality: %d%%" % [a["isp"], int(a["comm_q"] * 100.0)])
	y += 26
	line(y, "Hull shield: %d%%" % int(a["shield"] * 100.0))
	y += 34
	Pix.lbl(stats, "CONSUMABLES (kg)", Vector2(1010, y), Vector2(250, 20), 14, Pix.WARN)
	y += 22
	for k in ["o2", "water", "food"]:
		var ok: bool = float(a["pack"][k]) >= float(a["need"][k])
		line(y, "%s: %.0f packed / %.0f need" % [String(k).to_upper(), a["pack"][k], a["need"][k]], good if ok else bad)
		y += 22
	line(y, "Storage: %.0f kg capacity" % a["cap"], Pix.DIM)
	y += 34
	if a["issues"].is_empty():
		line(y, "Looks flyable!", good)
	else:
		for t in a["issues"]:
			line(y, "! " + String(t), bad)
			y += 36
	queue_redraw()

func draw_extra() -> void:
	Pix.draw_ship(self, Vector2(800, 150), GameState.design, 6.0, false)
