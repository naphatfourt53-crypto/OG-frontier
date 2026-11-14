extends Screen
# Screen 5 - Flight: step through the mission. Events ask the player to decide.

var ui: Control
var log_label: Label
var cont_btn: Button
var event_box: Control
var hud: Control
var ship_t: float = 0.0
var ship_target: float = 0.0
var ended: bool = false

func build() -> void:
	star_seed = 51
	hud = Control.new()
	hud.size = Vector2(1280, 720)
	add_child(hud)
	ui = Control.new()
	ui.size = Vector2(1280, 720)
	add_child(ui)
	event_box = Control.new()
	event_box.size = Vector2(1280, 720)
	add_child(event_box)
	Pix.lbl(ui, "FLIGHT LOG", Vector2(20, 14), Vector2(500, 36), 28, Pix.EDGE)
	Pix.lbl(ui, "Seed %d" % GameState.seed_value, Vector2(1100, 20), Vector2(160, 24), 14, Pix.DIM)
	log_label = Pix.lbl(ui, "", Vector2(20, 330), Vector2(1240, 300), 15, Pix.TEXT)
	cont_btn = Pix.btn(ui, "CONTINUE >", Vector2(990, 650), Vector2(270, 52), on_continue)
	set_progress()
	ship_t = ship_target
	update_hud()
	show_log()

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
	Pix.draw_ship(self, Vector2(sx, 160), d, 2.0, false)

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
	cont_btn.text = "SEE REPORT >"
	cont_btn.pressed.disconnect(on_continue)
	cont_btn.pressed.connect(func(): go("report"))

func show_event(ev: Dictionary) -> void:
	cont_btn.disabled = true
	Pix.clear(event_box)
	Pix.panel(event_box, Vector2(240, 130), Vector2(800, 400))
	Pix.lbl(event_box, "! " + String(ev["title"]), Vector2(270, 145), Vector2(740, 36), 28, Pix.WARN)
	Pix.lbl(event_box, String(ev["text"]), Vector2(270, 195), Vector2(740, 80), 18, Pix.TEXT)
	var i := 0
	for ch in ev["choices"]:
		var idx := i
		Pix.btn(event_box, String(ch["label"]), Vector2(270, 300 + i * 70), Vector2(740, 56), func(): choose(idx))
		i += 1

func choose(i: int) -> void:
	var result := GameState.apply_choice(i)
	Pix.clear(event_box)
	Pix.panel(event_box, Vector2(240, 130), Vector2(800, 300))
	Pix.lbl(event_box, "Result", Vector2(270, 145), Vector2(740, 36), 26, Pix.WARN)
	Pix.lbl(event_box, result, Vector2(270, 195), Vector2(740, 100), 20, Pix.TEXT)
	Pix.btn(event_box, "OK", Vector2(270, 340), Vector2(200, 50), func():
		Pix.clear(event_box)
		cont_btn.disabled = false
		update_hud()
		show_log()
		if GameState.run["over"]:
			on_continue())
