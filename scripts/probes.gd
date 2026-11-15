extends Screen
# Screen - Probe Control. The robotic half of the campaign: seven probes, each one flies a
# real Hohmann transit and must wait for its real synodic launch window. On arrival the
# probe waits for an encounter that the player runs here: station-keeping (orbit or landing
# hold) or a gas scoop (choose a depth).

const PLANET_COL := {
	"mars": Color("c8553d"), "venus": Color("e8c27a"), "mercury": Color("9a9a9a"),
	"jupiter": Color("c9a27e"), "saturn": Color("e2cf9b"), "uranus": Color("8fe3ea"), "neptune": Color("3f6fd1"),
}
const ROW_Y := 100.0
const ROW_H := 72.0
const KEEP_CENTER := Vector2(640.0, 360.0)

var ui: Control
var info: Label
var enc: Control = null          # encounter overlay, null when closed
var enc_probe: String = ""
var enc_kind: String = ""
var enc_elapsed: float = 0.0
var enc_inside: float = 0.0
var enc_active: bool = false
var enc_canvas: Control = null
var enc_bar: ColorRect = null
var enc_pos: Vector2 = Vector2.ZERO
var enc_radius: float = 60.0

func build() -> void:
	star_seed = 57
	ui = Control.new()
	ui.size = Vector2(1280, 720)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	refresh()

func _process(delta: float) -> void:
	if enc != null and enc_active:
		_process_encounter(delta)

func refresh() -> void:
	Pix.clear(ui)
	var header: Panel = Pix.panel(ui, Vector2(12, 6), Vector2(1256, 82))
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Pix.lbl(ui, "PROBE CONTROL  |  ROBOTIC CAMPAIGN", Vector2(24, 12), Vector2(760, 34), 26, Pix.EDGE)
	var left: int = Campaign.cfg()["campaign"]["deadline_days"] - GameState.day
	Pix.chip(ui, Vector2(24, 52), "data", "Data %d" % GameState.station_data, Pix.EDGE)
	Pix.chip(ui, Vector2(230, 52), "smelter", "Gas %d" % int(GameState.campaign.get("gas", 0)), Pix.ORANGE)
	Pix.lbl(ui, "DAY %d / %d   |   %d days left" % [GameState.day, int(Campaign.deadline_days()), maxi(0, left)],
		Vector2(640, 20), Vector2(620, 24), 15, Pix.WARN)
	Pix.lbl(ui, "Missions done %d / %d" % [GameState.campaign["done"].size(), GameState.TOTAL_MISSIONS],
		Vector2(640, 48), Vector2(620, 24), 15, Pix.TEXT)
	Pix.lbl(ui, "GUIDE: a probe launches only when its window is open. Flight time is real. Run the encounter when it arrives.",
		Vector2(24, 614), Vector2(1100, 22), 14, Pix.WARN)
	if not GameState.campaign["done"].has("moon"):
		var lock: Panel = Pix.panel(ui, Vector2(200, 240), Vector2(880, 180))
		Pix.glow(lock, Pix.WARN)
		Pix.lbl(ui, "PROBE OFFICE CLOSED", Vector2(230, 270), Vector2(820, 36), 26, Pix.WARN)
		Pix.lbl(ui, "Finish the Moon mission first (Mission Control). The probe office opens after the first crew return.",
			Vector2(230, 320), Vector2(820, 50), 16, Pix.TEXT)
		Pix.btn_ghost(ui, "< Station", Vector2(20, 660), Vector2(150, 40), func(): go("station"))
		return
	var ids := Campaign.probe_ids()
	for i in ids.size():
		_row(ids[i], i)
	_side_panel()
	Pix.btn_ghost(ui, "< Station", Vector2(20, 660), Vector2(150, 40), func(): go("station"))
	Pix.btn_ghost(ui, "WAIT 30 DAYS", Vector2(190, 660), Vector2(170, 40), _wait_30)
	Pix.btn_ghost(ui, "Mission Control >", Vector2(380, 660), Vector2(200, 40), func(): go("mission"))
	info = Pix.lbl(ui, "", Vector2(580, 660), Vector2(410, 44), 13, Pix.TEXT)
	if GameState.campaign_over():
		Pix.btn_primary(ui, "SEE RESULT >", Vector2(1000, 652), Vector2(250, 48), func(): go("endgame"))

func _row(id: String, i: int) -> void:
	var pr: Dictionary = Campaign.probe(id)
	var st: Dictionary = GameState.campaign["probes"][id]
	var state := String(st["state"])
	var y := ROW_Y + float(i) * ROW_H
	var panel: Panel = Pix.panel(ui, Vector2(24, y), Vector2(900, ROW_H - 8))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if state == "pending":
		Pix.glow(panel, Pix.WARN)
	Pix.planet(ui, Vector2(56, y + 32), 16.0, PLANET_COL.get(id, Pix.TEXT))
	var transit := int(ceilf(Campaign.transit_days(id)))
	var kind_txt := "lander" if String(pr["kind"]) == "lander" else ("orbiter" if String(pr["kind"]) == "orbiter" else "gas probe")
	Pix.lbl(ui, String(pr["name"]), Vector2(84, y + 8), Vector2(360, 22), 17, Pix.TEXT)
	Pix.lbl(ui, "%s  |  flight %s (real Hohmann)  |  window every %d d  |  cost %d Data" % [
		kind_txt, _years(transit), int(Campaign.synodic_days(id)), int(pr["data_cost"])],
		Vector2(84, y + 32), Vector2(640, 18), 12, Pix.DIM)
	var status := _status_text(id, st)
	var col := _status_col(state, id)
	Pix.lbl(ui, status, Vector2(84, y + 48), Vector2(640, 18), 13, col)
	var bx := 742.0
	match state:
		"pending":
			Pix.btn_primary(ui, "RUN ENCOUNTER", Vector2(bx, y + 14), Vector2(170, 38), func(): _open_encounter(id))
		"transit", "done":
			pass
		_:
			if GameState.campaign_over():
				pass
			elif Campaign.window_open(id, float(GameState.day)):
				var cost := int(pr["data_cost"])
				if GameState.station_data >= cost and not GameState.campaign_over():
					Pix.btn_primary(ui, "LAUNCH", Vector2(bx, y + 14), Vector2(170, 38), func(): _launch(id))
				else:
					Pix.btn_blocked(ui, "LAUNCH", "need %d Data" % cost, Vector2(bx, y + 14), Vector2(170, 38), func(): _launch(id))
			else:
				Pix.btn_ghost(ui, "WAIT FOR WINDOW", Vector2(bx, y + 14), Vector2(170, 38), func(): _wait_window(id))

func _status_text(id: String, st: Dictionary) -> String:
	match String(st["state"]):
		"transit":
			var left := int(st["arrive_day"]) - GameState.day
			return "IN FLIGHT: arrives on day %d (%d days to go)" % [int(st["arrive_day"]), left]
		"pending":
			return "ARRIVED: the encounter is waiting. Run it to finish the mission."
		"done":
			return "DONE: mission complete."
		"lost":
			if Campaign.window_open(id, float(GameState.day)):
				return "LOST in the last encounter. A window is open now: launch a new one."
			var nxt := int(Campaign.next_window(id, float(GameState.day)))
			return "LOST in the last encounter. Next window: day %d." % nxt
	if Campaign.window_open(id, float(GameState.day)):
		var s := Campaign.synodic_days(id)
		var start := float(GameState.day) - fposmod(float(GameState.day) - Campaign.epoch_day(), s)
		var close := start + float(Campaign.cfg()["campaign"]["window_days"])
		return "WINDOW OPEN now, closes on day %d." % int(close)
	return "Window opens on day %d (in %d days)." % [
		int(Campaign.next_window(id, float(GameState.day))), int(Campaign.next_window(id, float(GameState.day))) - GameState.day]

func _status_col(state: String, id: String) -> Color:
	match state:
		"pending":
			return Pix.WARN
		"transit":
			return Pix.EDGE
		"done":
			return Pix.GOOD
		"lost":
			return Pix.BAD
	return Pix.GOOD if Campaign.window_open(id, float(GameState.day)) else Pix.DIM

func _years(days: int) -> String:
	if days < 730:
		return "%d d" % days
	return "%.1f yr" % (float(days) / 365.256)

func _side_panel() -> void:
	Pix.panel(ui, Vector2(944, 100), Vector2(312, 540))
	Pix.lbl(ui, "CAMPAIGN", Vector2(960, 110), Vector2(280, 22), 18, Pix.EDGE)
	var order: Array = Campaign.cfg()["campaign"]["order"]
	var y := 140.0
	for mid in order:
		var done: bool = GameState.campaign["done"].has(String(mid))
		var label := "Moon (crew)" if mid == "moon" else String(Campaign.probe(String(mid))["name"])
		Pix.lbl(ui, ("[x] " if done else "[ ] ") + label, Vector2(960, y), Vector2(280, 18), 13, Pix.GOOD if done else Pix.DIM)
		y += 22.0
	y += 8.0
	if int(GameState.campaign["end_day"]) > 0:
		Pix.lbl(ui, "Epilogue ends on day %d." % int(GameState.campaign["end_day"]), Vector2(960, y), Vector2(280, 18), 13, Pix.WARN)
		y += 22.0
	Pix.lbl(ui, "LOG", Vector2(960, y + 6), Vector2(280, 20), 14, Pix.WARN)
	var entries: Array = GameState.campaign["log"]
	var from := maxi(0, entries.size() - 9)
	var ly := y + 28.0
	for i in range(from, entries.size()):
		Pix.lbl(ui, String(entries[i]), Vector2(960, ly), Vector2(280, 34), 11, Pix.TEXT)
		ly += 34.0

func _launch(id: String) -> void:
	var r: Dictionary = GameState.launch_probe(id)
	info.text = String(r["text"])
	info.add_theme_color_override("font_color", Pix.GOOD if bool(r["ok"]) else Pix.BAD)
	refresh()

func _wait_window(id: String) -> void:
	var r: Dictionary = GameState.wait_for_window(id)
	info.text = String(r["text"])
	refresh()

func _wait_30() -> void:
	var r: Dictionary = GameState.wait_days(30)
	info.text = String(r["text"])
	refresh()

# ---------- encounters ----------
func _open_encounter(id: String) -> void:
	if enc != null:
		return
	enc_probe = id
	var pr: Dictionary = Campaign.probe(id)
	enc_kind = String(pr["minigame"])
	enc_elapsed = 0.0
	enc_inside = 0.0
	enc_active = enc_kind == "station_keeping"
	enc = Control.new()
	enc.size = Vector2(1280, 720)
	add_child(enc)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.9)
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	enc.add_child(dim)
	Pix.lbl(enc, "ENCOUNTER: %s" % String(pr["name"]).to_upper(), Vector2(40, 24), Vector2(900, 36), 26, Pix.EDGE)
	Pix.lbl(enc, String(pr["info"]), Vector2(40, 62), Vector2(1200, 22), 14, Pix.TEXT)
	if enc_kind == "station_keeping":
		_build_keeping(pr)
	else:
		_build_scoop(pr)

func _build_keeping(pr: Dictionary) -> void:
	var hold := float(pr["hold_s"])
	enc_radius = 40.0 + float(pr["zone_pct"]) * 300.0
	Pix.lbl(enc, "STATION-KEEPING. Keep the cursor inside the moving green zone for %d seconds. Lag or drift loses the orbit." % int(hold),
		Vector2(40, 88), Vector2(1200, 22), 14, Pix.WARN)
	enc_canvas = Control.new()
	enc_canvas.size = Vector2(1280, 720)
	enc_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enc.add_child(enc_canvas)
	enc_canvas.draw.connect(_draw_keeping)
	enc_bar = ColorRect.new()
	enc_bar.color = Color("5dff9a")
	enc_bar.position = Vector2(340, 640)
	enc_bar.size = Vector2(0, 14)
	enc.add_child(enc_bar)
	Pix.panel(enc, Vector2(330, 634), Vector2(620, 26)).mouse_filter = Control.MOUSE_FILTER_IGNORE
	Pix.lbl(enc, "Hold time left: %d s" % int(hold), Vector2(340, 606), Vector2(600, 22), 14, Pix.TEXT)

func _build_scoop(pr: Dictionary) -> void:
	Pix.lbl(enc, "GAS SCOOP. Pick the depth. Deeper gives more gas, but a bad pass costs the whole probe.", Vector2(40, 88), Vector2(1200, 22), 14, Pix.WARN)
	Pix.planet(enc, Vector2(640, 260), 110.0, PLANET_COL.get(String(pr["target"]), Pix.TEXT))
	var y := 430.0
	for d in Campaign.cfg()["gas_depths"]:
		var depth: Dictionary = d
		var b := Pix.btn_primary(enc, "%s   gas %d   risk %d%%" % [depth["name"], int(depth["gas_pts"]), int(round(float(depth["risk"]) * 100.0))],
			Vector2(340, y), Vector2(600, 48), func(): _scoop(String(depth["id"])))
		b.add_theme_font_size_override("font_size", 16)
		Pix.lbl(enc, String(depth["info"]), Vector2(340, y + 50), Vector2(600, 20), 13, Pix.DIM)
		y += 84.0

func _process_encounter(delta: float) -> void:
	var pr: Dictionary = Campaign.probe(enc_probe)
	var hold := float(pr["hold_s"])
	enc_elapsed += delta
	enc_pos = KEEP_CENTER + Vector2(sin(enc_elapsed * 0.9) * 220.0, cos(enc_elapsed * 0.6) * 110.0)
	if get_global_mouse_position().distance_to(enc_pos) <= enc_radius:
		enc_inside += delta
	enc_bar.size.x = 620.0 * clampf(enc_elapsed / hold, 0.0, 1.0)
	if enc_canvas != null:
		enc_canvas.queue_redraw()
	if enc_elapsed >= hold:
		enc_active = false
		_finish_keeping(clampf(enc_inside / maxf(enc_elapsed, 0.001), 0.0, 1.0))

func _draw_keeping() -> void:
	enc_canvas.draw_circle(enc_pos, enc_radius, Color(0.36, 1.0, 0.6, 0.22))
	enc_canvas.draw_arc(enc_pos, enc_radius, 0.0, TAU, 40, Color("5dff9a"), 2.0)
	var m := get_global_mouse_position()
	enc_canvas.draw_line(m - Vector2(10, 0), m + Vector2(10, 0), Color("e8f1ff"), 2.0)
	enc_canvas.draw_line(m - Vector2(0, 10), m + Vector2(0, 10), Color("e8f1ff"), 2.0)

func _finish_keeping(held: float) -> void:
	var outcome: Dictionary = Campaign.keeping_outcome(held)
	_resolve(outcome)

func _scoop(depth_id: String) -> void:
	var outcome: Dictionary = Campaign.scoop_outcome(depth_id, randf())
	_resolve(outcome)

func _resolve(outcome: Dictionary) -> void:
	var r: Dictionary = GameState.resolve_probe(enc_probe, outcome)
	if enc != null:
		enc.queue_free()
		enc = null
	enc_canvas = null
	enc_active = false
	info.text = String(r["text"])
	info.add_theme_color_override("font_color", Pix.GOOD if bool(r["ok"]) else Pix.BAD)
	refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and enc != null:
		get_viewport().set_input_as_handled()
		enc.queue_free()
		enc = null
		enc_canvas = null
		enc_active = false
		return
	super._unhandled_input(event)

func back_scene() -> String:
	return "station"
