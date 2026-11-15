extends Screen
# Screen - Tech Book. Plain-language pictures and notes for every module, ship part,
# flight activity, suit rule, moon resource and mission. Every number is read from
# data/*.json at runtime; nothing is copied into this file.

var ui: Control
var tab: String = "STATION"
const TABS := ["STATION", "SHIP", "FLIGHT", "EVA", "MISSIONS"]
const ROLE_COL := {"core": Color("4fd1ff"), "habitat": Color("5dff9a"), "hangar": Color("ff8a3d"),
	"control": Color("ffc857"), "bonus": Color("b07bff")}
const PART_WHAT := {
	"cockpit": "protects the crew from radiation",
	"engine": "pushes the ship; a better engine gets more push from each kg of fuel",
	"tank": "holds the fuel for every burn",
	"life": "makes air and water for the crew; recycling saves weight",
	"power": "makes the electricity; solar is cheap but weaker in dust and flares",
	"storage": "carries oxygen, water and food",
	"comms": "sends data home; a better antenna gives more Data from missions",
}
const TAG_REAL := "Real basis"
const TAG_GAME := "Game rule"

func build() -> void:
	star_seed = 33
	ui = Control.new()
	ui.size = Vector2(1280, 720)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	render()

func render() -> void:
	Pix.clear(ui)
	Pix.panel(ui, Vector2(28, 22), Vector2(1224, 676))
	Pix.lbl(ui, "TECH BOOK", Vector2(52, 36), Vector2(500, 40), 32, Pix.EDGE)
	Pix.lbl(ui, "What each thing does, in plain words. Real basis = checked fact. Game rule = invented for play.",
		Vector2(52, 78), Vector2(1100, 22), 14, Pix.DIM)
	var x := 52.0
	for t in TABS:
		var name: String = t
		var b := Pix.btn(ui, name, Vector2(x, 110), Vector2(200, 40), func(): _set_tab(name))
		if name == tab:
			b.modulate = Color(0.5, 1.0, 0.7)
		x += 212.0
	Pix.btn(ui, "< Station", Vector2(1040, 36), Vector2(180, 40), func(): go("station"))
	var entries := _entries_for(tab)
	_layout(entries)
	Pix.lbl(ui, "Tip: the same facts appear as hover cards on the station map.",
		Vector2(52, 668), Vector2(1100, 20), 13, Pix.DIM)

func _set_tab(t: String) -> void:
	tab = t
	render()

# Each entry: {"title": String, "body": String, "col": Color, "tag": String}
func _entries_for(t: String) -> Array:
	var out: Array = []
	match t:
		"STATION":
			for m in GameState.data["station_modules"]:
				var cost := int(m["cost"])
				var cost_txt := "Free" if cost == 0 else "%d Data" % cost
				out.append({"title": "%s  (%s)" % [m["name"], cost_txt], "body": String(m["effect"]),
					"col": ROLE_COL[m["role"]], "tag": TAG_GAME if m.has("bonus") else TAG_REAL})
		"SHIP":
			for p in GameState.data["parts"]:
				var lines: Array = []
				for o in p["options"]:
					lines.append("%s: %d kg, %d Data. %s" % [o["name"], int(o["mass"]), int(o["cost"]), o["info"]])
				out.append({"title": "%s - %s" % [p["name"], PART_WHAT.get(p["id"], "")],
					"body": "\n".join(PackedStringArray(lines)), "col": Pix.EDGE, "tag": TAG_GAME})
		"FLIGHT":
			out = _flight_entries()
		"EVA":
			out = _eva_entries()
		"MISSIONS":
			for m in GameState.data["missions"]:
				var locked: bool = not (bool(m["unlocked"]) or (m["id"] == "mars" and GameState.mars_unlocked))
				var hz: Array = m.get("hazards", [])
				var body := String(m.get("brief", "")) + "\nHazards: " + "; ".join(PackedStringArray(hz))
				if locked:
					body = "LOCKED. Finish the Moon mission first to unlock it.\n" + body
				out.append({"title": String(m["name"]) + ("  [LOCKED]" if locked else ""), "body": body,
					"col": Pix.DIM if locked else Pix.GOOD, "tag": TAG_REAL})
	return out

func _flight_entries() -> Array:
	var act: Dictionary = GameState.activities()["game"]["transit"]
	var win := float(act["nav_sighting"]["window_s"])
	var hold := float(act["midcourse_correction"]["burn_hold_s"])
	var nom := float(act["midcourse_correction"]["nominal_dv_m_s"])
	var per_day := float(act["thermal_roll"]["skip_hull_damage_pct_per_day"])
	var pen := float(act["crew_schedule"]["no_exercise_stamina_capacity_penalty_pct"])
	return [
		{"title": "Star sighting (two during the coast)", "col": Pix.EDGE, "tag": TAG_REAL + " (Apollo 11) / " + TAG_GAME,
			"body": "A moving green circle appears. Hold the mouse inside it for %d seconds. The more time inside, the smaller the error left for the midcourse burn." % int(win)},
		{"title": "Midcourse burn", "col": Pix.ORANGE, "tag": TAG_REAL + " (Apollo 11 used 20.9 ft/s) / " + TAG_GAME,
			"body": "Hold SPACE or the left mouse button until the orange bar fills (%d s). Nominal correction is %.2f m/s. Letting go early, or never pressing, leaves the difference for the next burn." % [int(hold), nom]},
		{"title": "Thermal roll (PTC)", "col": Pix.GOOD, "tag": TAG_REAL + " (Apollo 11 rolled about 0.3 deg/s) / " + TAG_GAME,
			"body": "Keep the roll ON to spread heat evenly over the ship. Skipping it costs %.0f%% hull for every day of coast (game rule)." % per_day},
		{"title": "Crew exercise (0, 1 or 2 hours a day)", "col": Pix.GOOD, "tag": TAG_REAL + " (ISS average 2 h) / " + TAG_GAME,
			"body": "Exercise keeps bones and muscles working. With fewer hours the suit has %.0f%% less energy on the Moon (game rule)." % pen},
		{"title": "Events and crew morale", "col": Pix.WARN, "tag": TAG_GAME,
			"body": "Events ask for a decision. Some choices need crew morale, earned by harvesting greenhouse crops. A locked choice is greyed out."},
	]

func _eva_entries() -> Array:
	var st: Dictionary = Stamina.cfg()
	var cap: Dictionary = st["capacity_btu"]
	var rate: Dictionary = st["rate_btu_per_hr"]
	var out: Array = []
	out.append({"title": "Suit energy (stamina bar)", "col": Pix.EDGE, "tag": TAG_REAL + " (suit data) / " + TAG_GAME,
		"body": "The suit holds %d Btu with Open-loop life support, %d with ECLSS Standard and %d with ECLSS Advanced. The bar drains faster when you walk faster. Empty means the walk ends." % [
			int(cap["open_loop"]), int(cap["eclss_standard"]), int(cap["eclss_advanced"])]})
	out.append({"title": "Paces (keys 1, 2, 3 and Shift)", "col": Pix.EDGE, "tag": TAG_REAL + " (burn rates)",
		"body": "Easy %d, normal %d, hard %d and burst %d Btu per hour. Standing still always drains at the easy rate. Burst can be used for %d seconds per walk." % [
			int(rate["easy"]), int(rate["normal"]), int(rate["hard"]), int(rate["burst"]), int(st["burst_max_s"])]})
	out.append({"title": "Reserve zone", "col": Pix.WARN, "tag": TAG_GAME,
		"body": "The last %d%% of the bar turns red. Walk back to the lander before it empties." % int(float(st["reserve_pct"]) * 100.0)})
	out.append({"title": "Three walks per mission", "col": Pix.GOOD, "tag": TAG_GAME,
		"body": "Each walk has the time set in Settings. Between walks you rest, the suit recharges, and your points carry over."})
	out.append({"title": "Surface tasks", "col": Pix.ORANGE, "tag": "Task names: Artemis III plan / numbers: " + TAG_GAME,
		"body": "F photographs an item before you pick it up (more points). E drills a core at a rock outcrop (hard pace). E at a post places an instrument: it scores on every later walk. Choose 2 of 3 tools before the first walk."})
	var hints := {
		"ice": "Inside the craters. The pit slows you down. Water ice is real: LCROSS measured about 5.6 % water at the south pole.",
		"regolith": "Common grey dust, anywhere on the ground. Apollo crews said it was abrasive.",
		"ilmenite": "Found near rock outcrops. Real mineral; hydrogen can turn it into oxygen (ISRU).",
		"helium3": "Rare, inside a crater. Helium-3 is a game simplification in its value.",
	}
	for k in ["ice", "regolith", "ilmenite", "helium3"]:
		var r: Dictionary = GameState.data["moon_resources"][k]
		out.append({"title": "%s  (%d pts)" % [r["name"], int(r["pts"])], "col": Pix.WARN,
			"tag": TAG_REAL + " (name, mineral)" if k != "helium3" else TAG_GAME, "body": hints[k]})
	return out

# Lays entries out in two columns. Long lists get shorter rows so everything fits.
func _layout(entries: Array) -> void:
	var per_col := int(ceil(entries.size() / 2.0))
	var row_h := minf(120.0, 520.0 / maxf(1.0, float(per_col)))
	for i in entries.size():
		var e: Dictionary = entries[i]
		var col_i := 0 if i < per_col else 1
		var row := i if col_i == 0 else i - per_col
		var x := 52.0 + col_i * 596.0
		var y := 166.0 + row * row_h
		var swatch := ColorRect.new()
		swatch.color = e["col"]
		swatch.position = Vector2(x, y + 4)
		swatch.size = Vector2(12, 12)
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(swatch)
		Pix.lbl(ui, String(e["title"]), Vector2(x + 20, y), Vector2(560, 22), 16, e["col"])
		Pix.lbl(ui, String(e["body"]), Vector2(x + 20, y + 22), Vector2(560, row_h - 26), 13, Pix.TEXT)
		if String(e["tag"]) != "":
			Pix.lbl(ui, "[" + String(e["tag"]) + "]", Vector2(x + 20, y + row_h - 22), Vector2(560, 16), 11, Pix.DIM)

func back_scene() -> String:
	return "station"
