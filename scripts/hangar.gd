extends Screen
# Screen 3 - Hangar: pick one option for each of the 7 ship parts. Live numbers on the right.

var ui: Control
var stats: Control
var info: Label
var fuel_label: Label
var card: Control
var active_slot: int = 0

func build() -> void:
	star_seed = 31
	ui = Control.new()
	ui.size = Vector2(1280, 720)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	card = Pix.card(self)
	stats = Control.new()
	stats.size = Vector2(1280, 720)
	# The stats layer covers the whole screen but only draws labels. Without IGNORE it
	# swallows every click, which made the hangar look like a static picture.
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stats)
	rebuild()

func rebuild() -> void:
	Pix.clear(ui)
	Pix.lbl(ui, "HANGAR - Assemble your ship", Vector2(20, 14), Vector2(700, 36), 28, Pix.EDGE)
	Pix.lbl(ui, "GUIDE: pick one option per row (* = sample). Green = pass, red = fail. Then Mission Control >",
		Vector2(480, 24), Vector2(780, 22), 14, Pix.WARN)
	info = Pix.lbl(ui, "Hover an option to read about it.", Vector2(20, 596), Vector2(600, 44), 15, Pix.DIM)
	build_parts()
	build_fuel()
	Pix.btn_ghost(ui, "Load sample design", Vector2(20, 660), Vector2(190, 40), on_sample)
	Pix.btn_ghost(ui, "< Station", Vector2(220, 660), Vector2(130, 40), func(): go("station"))
	Pix.btn_ghost(ui, "Crew cabin", Vector2(360, 660), Vector2(140, 40), func(): go("ship"))
	Pix.btn_ghost(ui, "Terminal", Vector2(510, 660), Vector2(120, 40), func(): go("computer"))
	Pix.btn_primary(ui, "Mission Control >", Vector2(1000, 660), Vector2(260, 44), func(): go("mission"))
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
			if int(GameState.data["recommended"][pid]) == i:
				b.text += " *"
				b.tooltip_text = "Recommended option in the sample design"
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
			Pix.card_attach(card, b, String(o["name"]), String(p["name"]), String(o["info"]), Pix.EDGE, _part_rows(p, o))
			i += 1
		y += 66

# Bars in the hover card are relative to the best option of the same part, so the
# player can see at a glance which choice is heavy, strong or expensive.
func _part_rows(part: Dictionary, o: Dictionary) -> Array:
	var mmax := 1.0
	var pmax := 0.001
	var cmax := 1.0
	for x in part["options"]:
		mmax = maxf(mmax, float(x["mass"]))
		pmax = maxf(pmax, absf(float(x["power"])))
		cmax = maxf(cmax, float(x["cost"]))
	var pw := float(o["power"])
	var rows: Array = [
		["Mass", float(o["mass"]) / mmax, "%d kg" % int(o["mass"]), Pix.DIM],
		["Power", absf(pw) / pmax, "%+.1f kW" % pw, Pix.GOOD if pw >= 0.0 else Pix.WARN],
		["Cost", float(o["cost"]) / cmax, "%d Data" % int(o["cost"]), Pix.ORANGE],
	]
	if o.has("isp"):
		var imax := 1.0
		for x in part["options"]:
			imax = maxf(imax, float(x.get("isp", 0.0)))
		rows.append(["Isp", float(o["isp"]) / imax, "%d s" % int(o["isp"]), Pix.EDGE])
	if o.has("shield"):
		rows.append(["Shield", float(o["shield"]), "%d%%" % int(float(o["shield"]) * 100.0), Pix.EDGE])
	return rows

func _process(_delta: float) -> void:
	if card != null and card.visible:
		var mp := get_viewport().get_mouse_position()
		card.position = Vector2(clampf(mp.x + 18.0, 0.0, 960.0), clampf(mp.y + 18.0, 0.0, 480.0))

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

func line(y: float, text: String, col: Color = Pix.TEXT) -> Label:
	return Pix.lbl(stats, text, Vector2(1010, y), Vector2(255, 40), 14, col)

func refresh_stats() -> void:
	Pix.clear(stats)
	var a := GameState.analyze("moon")
	fuel_label.text = "Propellant load: %d%% = %.0f t" % [int(GameState.fuel_pct * 100.0), a["prop_kg"] / 1000.0]
	Pix.panel(stats, Vector2(996, 60), Vector2(274, 560))
	Pix.lbl(stats, "SHIP STATS", Vector2(1010, 66), Vector2(250, 24), 18, Pix.EDGE)
	var good := Pix.GOOD
	var bad := Pix.BAD
	# Station-side support: these change what the ship has to carry and how the EVA goes.
	line(92.0, "ISS food store: %.1f kg" % GameState.food_store, good if GameState.food_store > 0.0 else Pix.DIM)
	line(112.0, "Scout: %s   Rad kit: %s" % [
		"READY" if GameState.prep.get("scout", false) else "-",
		"READY" if GameState.prep.get("rad_kit", false) else "-"],
		good if (GameState.prep.get("scout", false) or GameState.prep.get("rad_kit", false)) else Pix.DIM)
	var y := 148.0
	line(y, "Mass: %.1f t (limit %.0f t)" % [a["total_kg"] / 1000.0, a["mass_cap_kg"] / 1000.0], good if a["total_kg"] <= a["mass_cap_kg"] else bad)
	y += 26
	line(y, "Budget: %.0f / %.0f" % [a["cost"], a["budget"]], good if a["cost"] <= a["budget"] else bad)
	y += 26
	line(y, "Power: +%.1f - %.1f = %+.1f kW" % [a["gen_solar"] + a["gen_other"], a["use"], a["net"]], good if a["net"] >= 0.0 else bad)
	y += 26
	var dv_lbl := line(y, "Delta-v: %.2f km/s (need %.2f)" % [a["dv"], a["dv_need"]], good if a["dv"] >= a["dv_need"] else bad)
	dv_lbl.tooltip_text = "Delta-v (m/s) is how much velocity the ship can change with its propellant.\nIt comes from the rocket equation: dv = Isp * g0 * ln(m0/mf).\nThe mission needs 6.06 km/s including a 10% margin."
	dv_lbl.mouse_entered.connect(func(): info.text = "Delta-v = Isp x g0 x ln(mass full / mass dry). More propellant, a bigger tank or a higher-Isp engine buys more of it.")
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
	_slot_panel()
	queue_redraw()

# Three designs you can keep side by side. Click a slot to load it; SAVE stores the
# design you are editing into that slot.
func _slot_panel() -> void:
	line(494.0, "SHIP SLOTS (3 designs)", Pix.WARN)
	for i in GameState.SLOT_COUNT:
		var yy := 518.0 + float(i) * 28.0
		var idx := i
		var b := Pix.btn_ghost(stats, "%d  %s" % [i + 1, GameState.slot_name(i)], Vector2(1010, yy), Vector2(176, 24),
			func(): _slot_load(idx))
		b.add_theme_font_size_override("font_size", 12)
		if i == active_slot:
			b.modulate = Color(0.6, 1.0, 0.75)
		var s := Pix.btn(stats, "SAVE", Vector2(1192, yy), Vector2(70, 24), func(): _slot_save(idx))
		s.add_theme_font_size_override("font_size", 12)

func _slot_load(i: int) -> void:
	if GameState.load_slot(i):
		active_slot = i
		info.text = "Loaded slot %d: %s." % [i + 1, GameState.slot_name(i)]
		rebuild()
	else:
		info.text = "Slot %d is empty. Set up a ship, then press SAVE next to it." % (i + 1)

func _slot_save(i: int) -> void:
	GameState.save_slot(i)
	active_slot = i
	info.text = "Saved to slot %d: %s." % [i + 1, GameState.slot_name(i)]
	refresh_stats()

func draw_extra() -> void:
	Pix.draw_ship(self, Vector2(800, 150), GameState.design, 6.0, false)

func back_scene() -> String:
	return "station"
