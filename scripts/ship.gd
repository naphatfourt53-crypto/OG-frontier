extends Screen
# Screen - crew cabin on the ISS. This is the "enter your ship" room: grow food,
# study samples, rest, and load gear for the next flight. It is deliberately a room
# with consoles instead of a menu list, so the ship feels lived in.

var ui: Control
var info: Label
var status: Label

func build() -> void:
	star_seed = 12
	ui = Control.new()
	ui.size = Vector2(1280, 720)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	refresh()

func refresh() -> void:
	Pix.clear(ui)
	Pix.lbl(ui, "CREW CABIN - ISS DOCK", Vector2(24, 12), Vector2(600, 34), 26, Pix.EDGE)
	Pix.lbl(ui, "DAY %03d   %s   |   LOW EARTH ORBIT" % [GameState.day, GameState.date_text()],
		Vector2(660, 18), Vector2(590, 24), 15, Pix.WARN)
	status = Pix.lbl(ui, "Data %d   |   Food store %.1f kg   |   Ore %d / %d pts   |   Smelter %.0f%%" % [
		GameState.station_data, GameState.food_store, GameState.smelter_points(),
		int(GameState.C.get("smelter_target", 165)), GameState.smelter_pct() * 100.0],
		Vector2(24, 50), Vector2(1200, 24), 15, Pix.TEXT)
	info = Pix.lbl(ui, "Pick a station in the cabin. Every activity costs one day unless it says otherwise.",
		Vector2(24, 664), Vector2(1220, 44), 15, Pix.DIM)

	_greenhouse_panel()
	_science_panel()
	_locker_panel()
	_galley_panel()
	_bunk_panel()
	_terminal_panel()
	_side_panel()
	queue_redraw()

func _panel_title(pos: Vector2, title: String, sub: String) -> void:
	Pix.panel(ui, pos, Vector2(280, 180))
	Pix.lbl(ui, title, pos + Vector2(14, 10), Vector2(252, 22), 17, Pix.WARN)
	Pix.lbl(ui, sub, pos + Vector2(14, 32), Vector2(252, 34), 12, Pix.DIM)

func _greenhouse_panel() -> void:
	var p := Vector2(40, 92)
	_panel_title(p, "GREENHOUSE", "Lettuce, 28-day cycle. NASA BVAD crop data.")
	if not GameState.has_module("greenhouse"):
		Pix.lbl(ui, "Not installed.\nBuild the Greenhouse at the ISS first.", p + Vector2(14, 70), Vector2(252, 50), 14, Pix.BAD)
		Pix.btn(ui, "BACK TO ISS", p + Vector2(14, 130), Vector2(252, 36), func(): go("station"))
		return
	GameState.ensure_plot()
	var plot: Dictionary = GameState.plots[0]
	var crop := Farm.crop(String(plot["crop"]))
	var ready := Farm.crop_ready(plot)
	Pix.lbl(ui, "%s  day %d / %d%s" % [crop["name"], int(plot["age_days"]), int(crop["growth_days"]),
		"  READY" if ready else ""], p + Vector2(14, 68), Vector2(252, 22), 14, Pix.GOOD if ready else Pix.TEXT)
	Pix.lbl(ui, "Expected harvest: %.2f kg" % GameState.plot_kg(), p + Vector2(14, 90), Vector2(252, 20), 13, Pix.DIM)
	Pix.btn(ui, "TEND +1 DAY", p + Vector2(14, 116), Vector2(120, 34), _tend)
	var h := Pix.btn(ui, "HARVEST", p + Vector2(146, 116), Vector2(120, 34), _harvest)
	h.disabled = not ready

func _science_panel() -> void:
	var p := Vector2(340, 92)
	_panel_title(p, "SCIENCE DESK", "Study the samples brought back from the surface.")
	var bonus := " (+25% lab bonus)" if GameState.has_module("lab") else ""
	Pix.lbl(ui, "Adds %d Data and advances one day%s." % [int(GameState.C.get("study_data", 8)), bonus],
		p + Vector2(14, 70), Vector2(252, 50), 14, Pix.TEXT)
	Pix.btn(ui, "STUDY +1 DAY", p + Vector2(14, 132), Vector2(252, 36), _study)

func _locker_panel() -> void:
	var p := Vector2(640, 92)
	_panel_title(p, "SUIT LOCKER", "Load gear for the next launch. Used once, then spent.")
	var rad := "Radiation blanket: ON" if GameState.prep.get("rad_kit", false) else "Load radiation blanket (%d)" % GameState.prep_cost("rad_kit")
	var sco := "Scout drone: ON" if GameState.prep.get("scout", false) else "Load scout drone (%d)" % GameState.prep_cost("scout")
	var b1 := Pix.btn(ui, rad, p + Vector2(14, 70), Vector2(252, 34), func(): _buy("rad_kit"))
	b1.modulate = Color(0.6, 1.0, 0.7) if GameState.prep.get("rad_kit", false) else Color.WHITE
	var b2 := Pix.btn(ui, sco, p + Vector2(14, 112), Vector2(252, 34), func(): _buy("scout"))
	b2.modulate = Color(0.6, 1.0, 0.7) if GameState.prep.get("scout", false) else Color.WHITE
	Pix.lbl(ui, "Scout data = +25% EVA time.", p + Vector2(14, 152), Vector2(252, 18), 12, Pix.DIM)

func _galley_panel() -> void:
	var p := Vector2(40, 300)
	_panel_title(p, "GALLEY", "Hot meal from the ISS food store.")
	Pix.lbl(ui, "Food store: %.1f kg\nA meal costs 2 kg and lifts crew mood before the flight." % GameState.food_store,
		p + Vector2(14, 70), Vector2(252, 50), 14, Pix.TEXT)
	var b := Pix.btn(ui, "COOK +1 DAY", p + Vector2(14, 132), Vector2(252, 36), _cook)
	b.disabled = GameState.food_store < 2.0

func _bunk_panel() -> void:
	var p := Vector2(340, 300)
	_panel_title(p, "BUNK", "Sleep one full day. The clock never stops.")
	Pix.lbl(ui, "Rest advances the ISS clock. Use it when you want the greenhouse to grow without flying.",
		p + Vector2(14, 70), Vector2(252, 58), 14, Pix.TEXT)
	Pix.btn(ui, "REST +1 DAY", p + Vector2(14, 132), Vector2(252, 36), _rest)

func _terminal_panel() -> void:
	var p := Vector2(640, 300)
	_panel_title(p, "SHIP TERMINAL", "The v0.1 computer: day, location, ore and mission files.")
	Pix.lbl(ui, "Open the terminal to read the full mission dossier and the smelter status.",
		p + Vector2(14, 70), Vector2(252, 50), 14, Pix.TEXT)
	Pix.btn(ui, "OPEN TERMINAL >", p + Vector2(14, 132), Vector2(252, 36), func(): go("computer"))

func _side_panel() -> void:
	Pix.panel(ui, Vector2(960, 92), Vector2(286, 470))
	Pix.lbl(ui, "FLIGHT READINESS", Vector2(978, 106), Vector2(250, 24), 18, Pix.WARN)
	Pix.lbl(ui, "Scout: %s\nRadiation kit: %s\nFood from ISS: %.1f kg\nEVA stamina: %s" % [
		"READY" if GameState.prep.get("scout", false) else "not loaded",
		"READY" if GameState.prep.get("rad_kit", false) else "not loaded",
		GameState.food_store,
		"+10% (Exercise Bay)" if GameState.has_module("exercise") else "standard"],
		Vector2(978, 138), Vector2(250, 90), 14, Pix.TEXT)
	Pix.lbl(ui, "NEXT OBJECTIVE", Vector2(978, 246), Vector2(250, 22), 16, Pix.WARN)
	Pix.lbl(ui, _objective_text(), Vector2(978, 272), Vector2(250, 100), 14, Pix.TEXT)
	Pix.btn(ui, "MISSION CONTROL >", Vector2(978, 390), Vector2(250, 40), func(): go("mission"))
	Pix.btn(ui, "< BACK TO ISS", Vector2(978, 440), Vector2(250, 40), func(): go("station"))
	Pix.btn(ui, "HANGAR", Vector2(978, 490), Vector2(250, 40), func(): go("hangar"))

func _objective_text() -> String:
	if GameState.smelter_pct() >= 1.0:
		return "The Helios smelter has enough ore. Earth has a chance."
	if GameState.ore.get("ice", 0) == 0:
		return "Collect water ice and ilmenite on the Moon. Every sample feeds the smelter."
	return "Keep collecting ore. Helium-3 is the rare piece; check the deep craters."

func _tend() -> void:
	var r := GameState.tend_plot(1.0)
	info.text = String(r["text"])
	refresh()

func _harvest() -> void:
	var r := GameState.harvest_plot()
	info.text = String(r["text"])
	refresh()

func _study() -> void:
	var r := GameState.study_samples()
	info.text = String(r["text"])
	refresh()

func _buy(key: String) -> void:
	var r := GameState.buy_prep(key)
	info.text = String(r["text"])
	refresh()

func _cook() -> void:
	if GameState.food_store < 2.0:
		info.text = "Not enough food in the ISS store."
		return
	GameState.food_store = maxf(0.0, GameState.food_store - 2.0)
	GameState.day += 1
	GameState.save_game()
	info.text = "The crew eats together. Food store: %.1f kg. One day passes." % GameState.food_store
	refresh()

func _rest() -> void:
	var r := GameState.rest_day()
	info.text = String(r["text"])
	refresh()

func back_scene() -> String:
	return "station"

func draw_extra() -> void:
	# Cabin shell: dark ribs, a window with Earth, plant racks and suit lockers.
	draw_rect(Rect2(0, 80, 1280, 640), Color("0a0f1c"))
	draw_rect(Rect2(22, 86, 1236, 596), Color("101a2c"))
	for x in [22, 236, 450, 664, 878, 1092, 1258]:
		draw_rect(Rect2(x, 86, 8, 596), Color("1b2b45"))
		draw_rect(Rect2(x + 8, 86, 2, 596), Color("2c4468"))
	# ceiling lights
	for x in range(80, 1240, 120):
		draw_rect(Rect2(x, 86, 64, 5), Color("4fd1ff"))
	# window over the side panel
	draw_rect(Rect2(992, 118, 220, 120), Color("1b2b45"))
	draw_rect(Rect2(1000, 126, 204, 104), Color("05070e"))
	draw_circle(Vector2(1102, 178), 44, Color("1d4e9e"))
	draw_circle(Vector2(1102, 178), 40, Color("2a7bd4"))
	draw_rect(Rect2(1088, 166, 22, 8), Color("3fae5a"))
	# plant rack (left, behind the greenhouse panel)
	for i in 4:
		draw_rect(Rect2(52 + i * 14, 236 - i * 18, 8, 26), Color("2c8f62"))
		draw_circle(Vector2(56 + i * 14, 232 - i * 18), 8, Color("5dff9a"))
	# suit lockers (right, behind the terminal panel)
	for i in 3:
		draw_rect(Rect2(900 + i * 22, 360, 16, 64), Color("2c3a7a"))
		draw_rect(Rect2(904 + i * 22, 364, 8, 24), Color("8fa3c9"))
