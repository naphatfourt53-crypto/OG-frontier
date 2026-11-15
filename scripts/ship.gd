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
	var header: Panel = Pix.panel(ui, Vector2(12, 6), Vector2(1256, 82))
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Pix.lbl(ui, "CREW CABIN - ISS DOCK", Vector2(24, 10), Vector2(600, 34), 26, Pix.EDGE)
	Pix.lbl(ui, "DAY %03d   %s   |   LOW EARTH ORBIT" % [GameState.day, GameState.date_text()],
		Vector2(660, 16), Vector2(590, 24), 15, Pix.WARN)
	Pix.chip(ui, Vector2(24, 52), "data", "Data %d" % GameState.station_data, Pix.EDGE)
	Pix.chip(ui, Vector2(230, 52), "food", "Food %.1f kg" % GameState.food_store, Pix.GOOD)
	var target := float(GameState.C.get("smelter_target", 165))
	Pix.chip(ui, Vector2(430, 52), "ore", "Ore %d / %d pts" % [GameState.smelter_points(), int(target)],
		Pix.WARN, clampf(float(GameState.smelter_points()) / target, 0.0, 1.0))
	Pix.chip(ui, Vector2(660, 52), "smelter", "Smelter %.0f%%" % (GameState.smelter_pct() * 100.0),
		Pix.ORANGE, GameState.smelter_pct())
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

func _panel_title(pos: Vector2, title: String, sub: String, height: float = 180.0) -> void:
	Pix.panel(ui, pos, Vector2(280, height))
	Pix.lbl(ui, title, pos + Vector2(14, 10), Vector2(252, 22), 17, Pix.WARN)
	Pix.lbl(ui, sub, pos + Vector2(14, 32), Vector2(252, 34), 12, Pix.DIM)

func _greenhouse_panel() -> void:
	var p := Vector2(40, 92)
	_panel_title(p, "GREENHOUSE", "Crop, water and nutrients. NASA BVAD crop data.", 352.0)
	if not GameState.has_module("greenhouse"):
		Pix.lbl(ui, "Not installed.\nBuild the Greenhouse at the ISS first.", p + Vector2(14, 70), Vector2(252, 50), 14, Pix.BAD)
		Pix.btn(ui, "BACK TO ISS", p + Vector2(14, 130), Vector2(252, 36), func(): go("station"))
		return
	GameState.ensure_plot()
	var plot: Dictionary = GameState.plots[0]
	var crop := Farm.crop(String(plot["crop"]))
	var ready := Farm.crop_ready(plot)
	var empty := float(plot["age_days"]) <= 0.0
	var title := "%s%s" % [crop["name"], "  READY TO HARVEST" if ready else ("  (empty plot)" if empty else "")]
	Pix.lbl(ui, title, p + Vector2(14, 66), Vector2(252, 20), 14, Pix.GOOD if ready else Pix.TEXT)
	var grow := float(plot["age_days"]) / maxf(1.0, float(crop["growth_days"]))
	_meter(p + Vector2(14, 90), "Growth", grow, Pix.GOOD, "%d/%d d" % [int(plot["age_days"]), int(crop["growth_days"])])
	_meter(p + Vector2(14, 112), "Water", float(plot["water_pct"]) / 100.0, Color("3fa7ff"),
		"%d%%" % int(plot["water_pct"]))
	_meter(p + Vector2(14, 134), "Nutrients", float(plot["nutrient_pct"]) / 100.0, Color("ffc857"),
		"%d%%" % int(plot["nutrient_pct"]))
	Pix.lbl(ui, GameState.greenhouse_alert(), p + Vector2(14, 156), Vector2(252, 30), 11, Pix.WARN)
	if empty:
		Pix.btn_primary(ui, "CHOOSE CROP: %s >" % crop["name"], p + Vector2(14, 190), Vector2(252, 34), _next_crop)
	elif ready:
		Pix.btn_primary(ui, "HARVEST", p + Vector2(14, 190), Vector2(252, 34), _harvest)
	else:
		Pix.btn_ghost(ui, "WATER (1 kg)", p + Vector2(14, 190), Vector2(122, 34), _water)
		Pix.btn_ghost(ui, "FEED (1 pack)", p + Vector2(144, 190), Vector2(122, 34), _feed)
	var wcost := int(GameState.farm_game()["water_data_cost_per_purchase"])
	var pcost := int(GameState.farm_game()["nutrient_data_cost_per_pack"])
	var wkg := int(GameState.farm_game()["water_kg_per_purchase"])
	if GameState.station_data >= wcost:
		Pix.btn_ghost(ui, "BUY WATER: %d Data  (+%d kg)" % [wcost, wkg], p + Vector2(14, 232), Vector2(252, 30), _buy_water)
	else:
		Pix.btn_blocked(ui, "BUY WATER", "need %d Data" % wcost, p + Vector2(14, 232), Vector2(252, 30), _buy_water)
	if GameState.station_data >= pcost:
		Pix.btn_ghost(ui, "BUY NUTRIENT PACK: %d Data" % pcost, p + Vector2(14, 268), Vector2(252, 30), _buy_pack)
	else:
		Pix.btn_blocked(ui, "BUY NUTRIENT PACK", "need %d Data" % pcost, p + Vector2(14, 268), Vector2(252, 30), _buy_pack)
	Pix.btn_ghost(ui, "TEND +1 DAY", p + Vector2(14, 304), Vector2(252, 30), _tend)

func _science_panel() -> void:
	var p := Vector2(340, 92)
	_panel_title(p, "SCIENCE DESK", "Study the samples brought back from the surface.")
	var bonus := "  (+25% Lab)" if GameState.has_module("lab") else ""
	Pix.lbl(ui, "Cost: 1 Day  |  Gain: +%d Data%s" % [int(GameState.C.get("study_data", 8)), bonus],
		p + Vector2(14, 70), Vector2(252, 40), 13, Pix.TEXT)
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
	var p := Vector2(40, 448)
	_panel_title(p, "GALLEY", "Hot meal from the ISS food store.")
	Pix.lbl(ui, "Cost: 2 kg food  |  Gain: crew mood", p + Vector2(14, 70), Vector2(252, 40), 13, Pix.TEXT)
	if GameState.food_store < 2.0:
		Pix.btn_blocked(ui, "COOK +1 DAY", "Need 2.0 kg Food", p + Vector2(14, 132), Vector2(252, 36), _cook)
	else:
		Pix.btn_primary(ui, "COOK +1 DAY", p + Vector2(14, 132), Vector2(252, 36), _cook)

func _bunk_panel() -> void:
	var p := Vector2(340, 448)
	_panel_title(p, "BUNK", "Sleep one full day. The clock never stops.")
	Pix.lbl(ui, "Cost: 1 Day  |  Gain: greenhouse grows", p + Vector2(14, 70), Vector2(252, 40), 13, Pix.TEXT)
	Pix.btn_ghost(ui, "REST +1 DAY", p + Vector2(14, 132), Vector2(252, 36), _rest)

func _terminal_panel() -> void:
	var p := Vector2(640, 448)
	_panel_title(p, "SHIP TERMINAL", "Mission files, dossiers and the smelter status.")
	Pix.lbl(ui, "Cost: free  |  Gain: read the mission files", p + Vector2(14, 70), Vector2(252, 40), 13, Pix.TEXT)
	Pix.btn_ghost(ui, "OPEN TERMINAL >", p + Vector2(14, 132), Vector2(252, 36), func(): go("computer"))

func _side_panel() -> void:
	Pix.panel(ui, Vector2(960, 92), Vector2(286, 470))
	Pix.lbl(ui, "FLIGHT READINESS", Vector2(978, 106), Vector2(250, 24), 18, Pix.WARN)
	Pix.lbl(ui, "Scout: %s\nRadiation kit: %s\nFood from ISS: %.1f kg\nEVA stamina: %s" % [
		"READY" if GameState.prep.get("scout", false) else "not loaded",
		"READY" if GameState.prep.get("rad_kit", false) else "not loaded",
		GameState.food_store,
		"+10% (Exercise Bay)" if GameState.has_module("exercise") else "standard"],
		Vector2(978, 138), Vector2(250, 90), 14, Pix.TEXT)
	var objective := Pix.panel(ui, Vector2(972, 236), Vector2(262, 136))
	Pix.glow(objective, Pix.WARN)
	Pix.lbl(ui, "NEXT OBJECTIVE", Vector2(984, 244), Vector2(240, 22), 16, Pix.WARN)
	Pix.lbl(ui, _objective_text(), Vector2(984, 270), Vector2(240, 96), 14, Pix.TEXT)
	var dest := _objective_dest()
	Pix.btn_primary(ui, "[Go Now] %s >" % ("HANGAR" if dest == "hangar" else "MISSION CONTROL"),
		Vector2(978, 384), Vector2(250, 40), func(): go(dest))
	Pix.btn_ghost(ui, "MISSION CONTROL >", Vector2(978, 430), Vector2(250, 40), func(): go("mission"))
	Pix.btn_ghost(ui, "HANGAR", Vector2(978, 474), Vector2(250, 40), func(): go("hangar"))
	Pix.btn_ghost(ui, "< BACK TO ISS", Vector2(978, 518), Vector2(250, 40), func(): go("station"))

func _ship_parts_chosen() -> int:
	var total := 0
	for v in GameState.design.values():
		total += int(v)
	return total

# The first step of the guide is the hangar; after that, Mission Control.
func _objective_dest() -> String:
	if GameState.history.is_empty() and _ship_parts_chosen() <= 0:
		return "hangar"
	return "mission"

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

# One meter row: name, bar, value. The text sits beside the bar, never on top of it.
func _meter(pos: Vector2, meter_name: String, value: float, col: Color, text: String) -> void:
	Pix.lbl(ui, meter_name, pos + Vector2(0, -2), Vector2(70, 16), 11, Pix.DIM)
	Pix.bar(ui, pos + Vector2(72, 2), Vector2(128, 10), value, col)
	Pix.lbl(ui, text, pos + Vector2(206, -2), Vector2(60, 16), 11, Pix.TEXT)

func _next_crop() -> void:
	var ids: Array = Farm.cfg()["crops"].keys()
	var cur := String(GameState.plots[0]["crop"])
	var next := String(ids[(ids.find(cur) + 1) % ids.size()])
	var r := GameState.set_crop(next)
	info.text = String(r["text"])
	refresh()

func _buy_water() -> void:
	var r := GameState.buy_water()
	info.text = String(r["text"])
	refresh()

func _buy_pack() -> void:
	var r := GameState.buy_nutrients()
	info.text = String(r["text"])
	refresh()

func _water() -> void:
	var r := GameState.water_plot()
	info.text = String(r["text"])
	refresh()

func _feed() -> void:
	var r := GameState.feed_plot()
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
	GameState.advance_days(1)
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
