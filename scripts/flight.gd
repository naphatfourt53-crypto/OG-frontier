extends Screen
# Screen 5 - Flight: step through the mission. Events ask the player to decide.

var ui: Control
var log_label: Label
var cont_btn: Button
var crew_btn: Button
var event_box: Control
var crew_box: Control
var hud: Control
var ship_t: float = 0.0
var ship_target: float = 0.0
var ended: bool = false
var shake: float = 0.0
var launch_anim: float = 1.2
var event_open: bool = false
var crew_msg: String = "Choose one activity. Each one spends a full day of supplies."

func build() -> void:
	star_seed = 51
	hud = Control.new()
	hud.size = Vector2(1280, 720)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	ui = Control.new()
	ui.size = Vector2(1280, 720)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	event_box = Control.new()
	event_box.size = Vector2(1280, 720)
	# Empty overlays must not eat clicks meant for CONTINUE. show_event() turns this
	# back to STOP while a decision is on screen.
	event_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(event_box)
	crew_box = Control.new()
	crew_box.size = Vector2(1280, 720)
	crew_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crew_box.visible = false
	add_child(crew_box)
	Pix.lbl(ui, "FLIGHT LOG", Vector2(20, 14), Vector2(500, 36), 28, Pix.EDGE)
	Pix.lbl(ui, "Seed %d" % GameState.seed_value, Vector2(1100, 20), Vector2(160, 24), 14, Pix.DIM)
	log_label = Pix.lbl(ui, "", Vector2(20, 330), Vector2(1240, 300), 15, Pix.TEXT)
	crew_btn = Pix.btn(ui, "CREW", Vector2(690, 650), Vector2(170, 52), open_crew)
	crew_btn.tooltip_text = "Spend one day on hydroponics, study or EVA preparation"
	cont_btn = Pix.btn(ui, "CONTINUE >", Vector2(990, 650), Vector2(270, 52), on_continue)
	set_progress()
	ship_t = ship_target
	update_hud()
	show_log()
	if int(GameState.run.get("step", 0)) == 0:
		Sfx.play("launch")

func set_progress() -> void:
	var s: int = int(GameState.run["step"])
	if s <= 5:
		ship_target = float(s) / 5.0
	elif s <= 8:
		ship_target = 1.0
	else:
		ship_target = 1.0 - float(s - 8) / 4.0

func _process(delta: float) -> void:
	ship_t = move_toward(ship_t, ship_target, delta * 0.35)
	launch_anim = maxf(0.0, launch_anim - delta)
	if shake > 0.1:
		shake = move_toward(shake, 0.0, delta * 26.0)
		position = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	elif position != Vector2.ZERO:
		position = Vector2.ZERO
	queue_redraw()

func draw_extra() -> void:
	# Earth (left) and Moon (right), dotted path, ship marker
	draw_circle(Vector2(150, 220), 62, Color("2a7bd4"))
	draw_rect(Rect2(125, 195, 26, 10), Color("3fae5a"))
	draw_circle(Vector2(1130, 220), 38, Color("b8b8b8"))
	draw_circle(Vector2(1118, 210), 8, Color("8a8a8a"))
	draw_circle(Vector2(1142, 232), 6, Color("8a8a8a"))
	var x0 := 230.0
	var x1 := 1080.0
	var i := 0.0
	while i <= 1.0:
		draw_rect(Rect2(lerpf(x0, x1, i), 218, 4, 4), Color(1, 1, 1, 0.3))
		i += 0.02
	var sx := lerpf(x0, x1, ship_t)
	var d := GameState.design
	Pix.draw_ship(self, Vector2(sx, 160), d, 2.0, launch_anim > 0.0)

func update_hud() -> void:
	Pix.clear(hud)
	var r: Dictionary = GameState.run
	var y := 70.0
	var items := [
		["Day", "%.0f" % float(r["day"]), Pix.TEXT],
		["Hull", "%d%%" % int(maxf(0.0, r["hull"])), Pix.GOOD if r["hull"] > 50 else Pix.BAD],
		["Propellant", "%.1f t" % (float(r["prop"]) / 1000.0), Pix.TEXT],
		["O2", "%.0f kg" % maxf(0.0, r["stock"]["o2"]), Pix.TEXT],
		["Water", "%.0f kg" % maxf(0.0, r["stock"]["water"]), Pix.TEXT],
		["Food", "%.0f kg" % maxf(0.0, r["stock"]["food"]), Pix.TEXT]
	]
	var x := 20.0
	for it in items:
		Pix.panel(hud, Vector2(x, 280), Vector2(190, 38))
		Pix.lbl(hud, "%s: %s" % [it[0], it[1]], Vector2(x + 10, 287), Vector2(175, 24), 16, it[2])
		x += 200.0

func show_log() -> void:
	var lines: Array = GameState.run["log"]
	var start: int = maxi(0, lines.size() - 11)
	var t := ""
	for i in range(start, lines.size()):
		t += String(lines[i]) + "\n"
	if t == "":
		t = "Ready for departure. Press CONTINUE to start the coast to the Moon."
	log_label.text = t

func on_continue() -> void:
	var res := GameState.advance()
	set_progress()
	update_hud()
	show_log()
	match res["kind"]:
		"explore":
			go("explore")
		"event":
			show_event(res["event"])
		"end":
			finish_flight()

func finish_flight() -> void:
	ended = true
	crew_btn.disabled = true
	cont_btn.text = "SEE REPORT >"
	cont_btn.pressed.disconnect(on_continue)
	cont_btn.pressed.connect(func(): go("report"))

# ---------- in-flight crew activities ----------

func open_crew() -> void:
	if event_open or ended or bool(GameState.run.get("over", false)):
		return
	crew_box.visible = true
	crew_box.mouse_filter = Control.MOUSE_FILTER_STOP
	render_crew()

func render_crew() -> void:
	Pix.clear(crew_box)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.86)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	crew_box.add_child(dim)
	Pix.panel(crew_box, Vector2(250, 130), Vector2(780, 380))
	Pix.lbl(crew_box, "CREW ACTIVITIES", Vector2(280, 148), Vector2(720, 34), 26, Pix.WARN)
	Pix.lbl(crew_box, "One day costs oxygen, water and food. The voyage clock advances.", Vector2(280, 182), Vector2(720, 20), 13, Pix.DIM)
	Pix.lbl(crew_box, crew_msg, Vector2(280, 206), Vector2(720, 42), 15, Pix.TEXT)
	var acts: Dictionary = GameState.C.get("crew_activities", {})
	var y := 254.0
	for kind in ["grow", "study", "prep"]:
		if not acts.has(kind):
			continue
		var act: Dictionary = acts[kind]
		var effect := ""
		if act.has("food_kg"):
			effect = "+%.0f kg food" % float(act["food_kg"])
		elif act.has("data"):
			effect = "+%.0f science" % float(act["data"])
		elif act.has("hull"):
			effect = "+%.0f%% hull" % float(act["hull"])
		var kk: String = kind
		var b := Pix.btn(crew_box, "%s   (%s)" % [String(act["name"]).to_upper(), effect],
			Vector2(280, y), Vector2(720, 54), func(): do_crew_activity(kk))
		b.add_theme_font_size_override("font_size", 15)
		y += 62.0
	Pix.btn(crew_box, "CLOSE", Vector2(850, 442), Vector2(150, 46), close_crew)

func do_crew_activity(kind: String) -> void:
	var r := GameState.crew_activity(kind)
	crew_msg = String(r["text"])
	update_hud()
	show_log()
	if bool(GameState.run.get("over", false)):
		close_crew()
		finish_flight()
		return
	render_crew()

func close_crew() -> void:
	crew_box.visible = false
	crew_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Pix.clear(crew_box)

func _dim_event_box() -> void:
	# Darken the flight screen behind an event so HUD/log text cannot be mistaken for dialog text.
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.85)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	event_box.add_child(dim)

func show_event(ev: Dictionary) -> void:
	cont_btn.disabled = true
	event_open = true
	Pix.clear(event_box)
	event_box.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim_event_box()
	Pix.panel(event_box, Vector2(240, 130), Vector2(800, 400))
	Pix.lbl(event_box, "! " + String(ev["title"]), Vector2(270, 145), Vector2(740, 36), 28, Pix.WARN)
	var body := Pix.lbl(event_box, String(ev["text"]), Vector2(270, 195), Vector2(740, 80), 18, Pix.TEXT)
	_type_in(body)
	var i := 0
	for ch in ev["choices"]:
		var idx := i
		Pix.btn(event_box, String(ch["label"]), Vector2(270, 300 + i * 70), Vector2(740, 56), func(): choose(idx))
		i += 1

func choose(i: int) -> void:
	var hull_before: float = float(GameState.run["hull"])
	var result := GameState.apply_choice(i)
	if float(GameState.run["hull"]) < hull_before - 0.01:
		shake = 12.0
		Sfx.play("damage")
		_flash_red()
	Pix.clear(event_box)
	_dim_event_box()
	Pix.panel(event_box, Vector2(240, 130), Vector2(800, 300))
	Pix.lbl(event_box, "Result", Vector2(270, 145), Vector2(740, 36), 26, Pix.WARN)
	_type_in(Pix.lbl(event_box, result, Vector2(270, 195), Vector2(740, 100), 20, Pix.TEXT))
	Pix.btn(event_box, "OK", Vector2(270, 340), Vector2(200, 50), func():
		event_open = false
		Pix.clear(event_box)
		event_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cont_btn.disabled = false
		update_hud()
		show_log()
		if GameState.run["over"]:
			on_continue())

func _type_in(label: Label) -> void:
	# Short typewriter reveal; ~12 ms per character, capped so it never blocks the player long.
	label.visible_ratio = 0.0
	var tw := create_tween()
	tw.tween_property(label, "visible_ratio", 1.0, clampf(label.text.length() * 0.012, 0.12, 0.6))

func _flash_red() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 64
	add_child(layer)
	var rect := ColorRect.new()
	rect.color = Color(1.0, 0.12, 0.12, 0.45)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	var tw := create_tween()
	tw.tween_property(rect, "color:a", 0.0, 0.45)
	tw.tween_callback(func(): layer.queue_free())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not cont_btn.disabled and not event_open:
		get_viewport().set_input_as_handled()
		on_continue()
	else:
		super._unhandled_input(event)
