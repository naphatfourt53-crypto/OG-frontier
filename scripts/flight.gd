extends Screen
# Screen 5 - Flight: step through the mission. Events ask the player to decide.

var ui: Control
var log_label: Label
var cont_btn: Button
var crew_btn: Button
var event_box: Control
var crew_box: Control
var activity_box: Control
var hud: Control
var ship_t: float = 0.0
var ship_target: float = 0.0
var ended: bool = false
var shake: float = 0.0
var launch_anim: float = 1.2
var event_open: bool = false
var crew_msg: String = "Choose one activity. Each one spends a full day of supplies."
# T17 in-transit activities
var nav_active: bool = false
var nav_elapsed: float = 0.0
var nav_inside: float = 0.0
var nav_center: Vector2 = Vector2(640, 300)
var nav_dot: ColorRect
var nav_bar: ColorRect
var nav_status: Label
var burn_active: bool = false
var burn_held: float = 0.0
var burn_elapsed: float = 0.0
var burn_was_holding: bool = false
var burn_bar: ColorRect
var burn_status: Label
var launch_open: bool = false
var comms_left: float = -1.0
var comms_timed_out: bool = false
var comms_label: Label

const NAV_RADIUS := 48.0

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
	activity_box = Control.new()
	activity_box.size = Vector2(1280, 720)
	activity_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	activity_box.visible = false
	add_child(activity_box)
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
	if int(GameState.run.get("plan_i", 0)) == 0:
		Sfx.play("launch")
		open_schedule()

func set_progress() -> void:
	var plan: Array = GameState.run.get("plan", [])
	if plan.is_empty():
		return
	ship_target = clampf(float(GameState.run.get("plan_i", 0)) / float(plan.size()), 0.0, 1.0)

func _process(delta: float) -> void:
	ship_t = move_toward(ship_t, ship_target, delta * 0.35)
	launch_anim = maxf(0.0, launch_anim - delta)
	if shake > 0.1:
		shake = move_toward(shake, 0.0, delta * 26.0)
		position = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	elif position != Vector2.ZERO:
		position = Vector2.ZERO
	if nav_active:
		_process_nav(delta)
	if burn_active:
		_process_burn(delta)
	if comms_left >= 0.0:
		_process_comms(delta)
	queue_redraw()

# ---------- T17 in-transit activities ----------

func _process_nav(delta: float) -> void:
	nav_elapsed += delta
	nav_center = Vector2(640.0 + sin(nav_elapsed * 2.1) * 120.0, 300.0 + cos(nav_elapsed * 1.7) * 70.0)
	if get_global_mouse_position().distance_to(nav_center) < NAV_RADIUS:
		nav_inside += delta
	var win := float(GameState.activities()["game"]["transit"]["nav_sighting"]["window_s"])
	nav_dot.position = nav_center - Vector2(NAV_RADIUS, NAV_RADIUS)
	nav_bar.size.x = 560.0 * clampf(nav_elapsed / win, 0.0, 1.0)
	nav_status.text = "Keep the cursor inside the circle.  %.1f / %.0f s" % [minf(nav_elapsed, win), win]
	if nav_elapsed >= win:
		nav_active = false
		var acc := nav_inside / maxf(nav_elapsed, 0.001)
		_show_activity_result("NAVIGATION SIGHTING", GameState.resolve_nav(acc))

func _process_burn(delta: float) -> void:
	burn_elapsed += delta
	var holding := Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var hold_s := float(GameState.activities()["game"]["transit"]["midcourse_correction"]["burn_hold_s"])
	if holding:
		burn_held += delta
	burn_bar.size.x = 560.0 * clampf(burn_held / hold_s, 0.0, 1.0)
	burn_status.text = "Hold SPACE or the mouse button.  %.1f / %.0f s" % [minf(burn_held, hold_s), hold_s]
	if burn_held >= hold_s:
		_finish_burn()
	elif burn_was_holding and not holding and burn_held > 0.0:
		# Released early: the correction is cut short and the next burn pays for it.
		_finish_burn()
	elif burn_held <= 0.0 and burn_elapsed >= hold_s * 2.0:
		# Dead-man: never pressed - the window passes and the full correction is skipped.
		_finish_burn()
	burn_was_holding = holding

func _finish_burn() -> void:
	burn_active = false
	var hold_s := float(GameState.activities()["game"]["transit"]["midcourse_correction"]["burn_hold_s"])
	var frac := clampf(burn_held / hold_s, 0.0, 1.2)
	_show_activity_result("MIDCOURSE BURN", GameState.resolve_burn(frac))

func _process_comms(delta: float) -> void:
	comms_left -= delta
	if comms_label != null:
		comms_label.text = "Mission control reply in %.0f s - choose before it arrives." % maxf(0.0, comms_left)
	if comms_left <= 0.0:
		comms_left = -1.0
		comms_timed_out = true
		choose(0)

func _dim_activity() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.86)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	activity_box.add_child(dim)

func show_nav(idx: int) -> void:
	event_open = true
	cont_btn.disabled = true
	nav_active = true
	nav_elapsed = 0.0
	nav_inside = 0.0
	activity_box.visible = true
	activity_box.mouse_filter = Control.MOUSE_FILTER_STOP
	Pix.clear(activity_box)
	_dim_activity()
	Pix.panel(activity_box, Vector2(240, 110), Vector2(800, 480))
	Pix.lbl(activity_box, "NAVIGATION SIGHTING  %d/2" % (idx + 1), Vector2(270, 130), Vector2(740, 36), 26, Pix.WARN)
	Pix.lbl(activity_box, "HOW TO: move the mouse so the cursor stays INSIDE the moving green circle. The blue bar fills over 6 seconds. More time inside = a more accurate position fix.",
		Vector2(270, 168), Vector2(740, 40), 14, Pix.TEXT)
	Pix.lbl(activity_box, "Real basis: Apollo 11 navigation sightings (about 6 h and 24 h into the coast). Game rule: 6 s window.",
		Vector2(270, 200), Vector2(740, 20), 12, Pix.DIM)
	nav_dot = ColorRect.new()
	nav_dot.color = Color(0.5, 1.0, 0.8, 0.25)
	nav_dot.size = Vector2(NAV_RADIUS * 2.0, NAV_RADIUS * 2.0)
	nav_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	activity_box.add_child(nav_dot)
	nav_bar = ColorRect.new()
	nav_bar.color = Color("2a7bd4")
	nav_bar.position = Vector2(270, 470)
	nav_bar.size = Vector2(560, 14)
	nav_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	activity_box.add_child(nav_bar)
	nav_status = Pix.lbl(activity_box, "", Vector2(270, 496), Vector2(740, 24), 14, Pix.TEXT)

func show_burn() -> void:
	event_open = true
	cont_btn.disabled = true
	burn_active = true
	burn_held = 0.0
	burn_was_holding = false
	activity_box.visible = true
	activity_box.mouse_filter = Control.MOUSE_FILTER_STOP
	Pix.clear(activity_box)
	_dim_activity()
	Pix.panel(activity_box, Vector2(240, 130), Vector2(800, 440))
	Pix.lbl(activity_box, "MIDCOURSE BURN", Vector2(270, 150), Vector2(740, 36), 26, Pix.WARN)
	Pix.lbl(activity_box, "HOW TO: hold SPACE (or the left mouse button) until the orange bar is full, then let go. Nominal correction: 6.37 m/s. Letting go early leaves the difference to the next burn. Doing nothing skips the burn.",
		Vector2(270, 192), Vector2(740, 44), 14, Pix.TEXT)
	Pix.lbl(activity_box, "Real basis: Apollo 11 midcourse correction (20.9 ft/s). Game rule: 3 s hold.",
		Vector2(270, 236), Vector2(740, 20), 12, Pix.DIM)
	burn_bar = ColorRect.new()
	burn_bar.color = Color("ff8a3d")
	burn_bar.position = Vector2(270, 400)
	burn_bar.size = Vector2(560, 16)
	burn_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	activity_box.add_child(burn_bar)
	burn_status = Pix.lbl(activity_box, "Hold SPACE or the mouse button.", Vector2(270, 430), Vector2(740, 26), 16, Pix.WARN)

func open_schedule() -> void:
	event_open = true
	cont_btn.disabled = true
	launch_open = true
	activity_box.visible = true
	activity_box.mouse_filter = Control.MOUSE_FILTER_STOP
	_render_schedule()

func _render_schedule() -> void:
	Pix.clear(activity_box)
	_dim_activity()
	Pix.panel(activity_box, Vector2(200, 110), Vector2(880, 500))
	Pix.lbl(activity_box, "PRE-FLIGHT CHECKLIST", Vector2(230, 130), Vector2(820, 36), 26, Pix.WARN)
	Pix.lbl(activity_box, "GUIDE: set the two choices below, then press LAUNCH. The flight log then runs day by day. You will be asked to act at the star sightings, the midcourse burn and some events.",
		Vector2(230, 160), Vector2(820, 22), 12, Pix.TEXT)
	Pix.lbl(activity_box, "CREW EXERCISE", Vector2(230, 184), Vector2(400, 24), 16, Pix.WARN)
	Pix.lbl(activity_box, "ISS crews average 2 h of exercise a day. Fewer hours lower EVA stamina on arrival (game rule).",
		Vector2(230, 210), Vector2(820, 30), 13, Pix.DIM)
	for i in 3:
		var h: int = i
		var b := Pix.btn(activity_box, "%d h / day" % h, Vector2(230 + i * 180, 246), Vector2(164, 40), func(): _pick_exercise(h))
		if int(GameState.run.get("exercise_hours", 2)) == h:
			b.modulate = Color(0.5, 1.0, 0.7)
	Pix.lbl(activity_box, "THERMAL ROLL (PTC)", Vector2(230, 312), Vector2(400, 24), 16, Pix.WARN)
	Pix.lbl(activity_box, "A slow roll evens out sunlight and shade. Apollo used about 0.3 deg/s. Skipping it stresses the hull (game rule: -2% per day of coast).",
		Vector2(230, 338), Vector2(820, 30), 13, Pix.DIM)
	Pix.btn(activity_box, _roll_label(), Vector2(230, 374), Vector2(260, 40), func():
		GameState.set_thermal_roll(not bool(GameState.run.get("roll_on", true)))
		_render_schedule())
	Pix.btn(activity_box, "LAUNCH >", Vector2(760, 520), Vector2(260, 50), close_activity)

func _pick_exercise(h: int) -> void:
	GameState.set_exercise_hours(h)
	_render_schedule()

func _roll_label() -> String:
	return "PTC ROLL: ON" if bool(GameState.run.get("roll_on", true)) else "PTC ROLL: OFF"

func _show_activity_result(title: String, text: String) -> void:
	Pix.clear(activity_box)
	_dim_activity()
	Pix.panel(activity_box, Vector2(240, 160), Vector2(800, 360))
	Pix.lbl(activity_box, title, Vector2(270, 176), Vector2(740, 36), 26, Pix.WARN)
	Pix.lbl(activity_box, text, Vector2(270, 232), Vector2(740, 140), 17, Pix.TEXT)
	Pix.btn(activity_box, "OK", Vector2(270, 400), Vector2(220, 50), close_activity)

func close_activity() -> void:
	nav_active = false
	burn_active = false
	launch_open = false
	event_open = false
	Pix.clear(activity_box)
	activity_box.visible = false
	activity_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont_btn.disabled = false
	update_hud()
	show_log()

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
		"nav":
			show_nav(int(res["idx"]))
		"burn":
			show_burn()
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
	comms_timed_out = false
	comms_left = -1.0
	Pix.clear(event_box)
	event_box.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim_event_box()
	Pix.panel(event_box, Vector2(240, 130), Vector2(800, 400))
	Pix.lbl(event_box, "! " + String(ev["title"]), Vector2(270, 145), Vector2(740, 36), 28, Pix.WARN)
	var body := Pix.lbl(event_box, String(ev["text"]), Vector2(270, 195), Vector2(740, 80), 18, Pix.TEXT)
	_type_in(body)
	if String(GameState.mission(String(GameState.run["mission"])).get("class", "")) == "mars":
		comms_left = float(GameState.activities()["game"]["transit"]["delayed_comms_event"]["decision_time_s"])
		comms_label = Pix.lbl(event_box, "Mission control reply in %.0f s - choose before it arrives." % comms_left,
			Vector2(270, 282), Vector2(740, 18), 13, Pix.WARN)
	var i := 0
	for ch in ev["choices"]:
		var idx := i
		var btn := Pix.btn(event_box, String(ch["label"]), Vector2(270, 300 + i * 70), Vector2(740, 56), func(): choose(idx))
		if ch.has("min_morale") and int(GameState.run.get("morale", 0)) < int(ch["min_morale"]):
			btn.disabled = true
			btn.text += "  (needs crew morale)"
		i += 1

func choose(i: int) -> void:
	comms_left = -1.0
	var hull_before: float = float(GameState.run["hull"])
	var result: String = GameState.apply_choice(i)
	if comms_timed_out:
		comms_timed_out = false
		result += "  (no reply from Earth in time)"
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
	if event.is_action_pressed("ui_accept") and not cont_btn.disabled and not event_open \
			and not nav_active and not burn_active and not launch_open:
		get_viewport().set_input_as_handled()
		on_continue()
	else:
		super._unhandled_input(event)
