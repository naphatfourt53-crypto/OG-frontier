extends Screen
# Screen 2 - ISS hub. The crew member walks the station with WASD or the arrow keys.
# Stand next to a room and press E to enter it (or to build it, if it is a purple "+" slot).
# Every room is also a button, and hovering one shows a picture card with what it does.
# The top line always says what to do next (the first-mission guide).
# The story (first visit) and the tutorial overlay are shown here too.

var info: Label
var ui: Control
var tut_box: Control
var actor: Control
var hover_box: Control
var tut_step: int = 0
var story_box: Node = null
var player: Vector2 = Vector2(640, 345)
var near_id: String = ""
var _rooms: Array = []  # {"m": Dictionary, "rect": Rect2, "built": bool}
var _walls: Array = []  # Rect2 of every visible room: the crew cannot walk through them

const ROLE_COL := {"core": Color("4fd1ff"), "habitat": Color("5dff9a"), "hangar": Color("ff8a3d"),
	"control": Color("ffc857"), "bonus": Color("b07bff")}
const PLAYER_R := 9.0
const WALK_SPEED := 190.0
const NEAR_DIST := 30.0
const BOUNDS := Rect2(20, 112, 1240, 580)

const TUTORIAL := [
	{"title": "1. Walk the station",
	 "body": "You are a crew member on the ISS. Walk with WASD or the arrow keys. Stand next to a room and press E to enter it.\n\nPurple \"+\" slots are rooms you can build. They cost Data, which you earn from missions. Hover any room to see a picture and what it does."},
	{"title": "2. Your first mission: the Moon",
	 "body": "Goal: design a ship in the HANGAR, launch from MISSION CTRL to the MOON, collect ore, and bring it BACK to the ISS.\n\nFor a ship that can fly it, press LOAD SAMPLE DESIGN in the Hangar."},
	{"title": "3. Flight: decide on the way",
	 "body": "The flight log runs by itself and asks you to act at a few points: two star sightings (hold the mouse inside the green circle), one midcourse burn (hold SPACE until the bar fills), and events with choices.\n\nEach one shows a HOW TO on screen. Fewer days, less hull and less supply lost is usually the better choice."},
	{"title": "4. Walk on the Moon",
	 "body": "Walk over ore to pick it up: ice, ilmenite, regolith and helium-3. Press F next to an item to photograph it first (more points). Press E at a rock to drill a core, or at a post to place an instrument.\n\nYou get 3 walks. The suit recharges between walks. Press SPACE to go back to the lander."},
	{"title": "5. Read the report",
	 "body": "The report says why the mission worked or failed. Change the ship in the Hangar, then fly the same seed again to compare.\n\nTECH BOOK (top right of the station) explains every module, part, suit rule and mission."},
]

func build() -> void:
	star_seed = 21
	ui = Control.new()
	ui.size = Vector2(1280, 720)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	refresh()
	tut_box = Control.new()
	tut_box.size = Vector2(1280, 720)
	tut_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tut_box.visible = false
	add_child(tut_box)
	actor = Control.new()
	actor.size = Vector2(1280, 720)
	actor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(actor)
	actor.draw.connect(_draw_actor)
	hover_box = Control.new()
	hover_box.size = Vector2(300, 150)
	hover_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_box.visible = false
	add_child(hover_box)
	if not GameState.story_seen:
		_open_story()
	elif not GameState.tutorial_seen:
		open_tutorial()

func refresh() -> void:
	Pix.clear(ui)
	_rooms.clear()
	_walls.clear()
	var header: Panel = Pix.panel(ui, Vector2(12, 6), Vector2(1256, 96))
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Pix.lbl(ui, "OG-FRONTIER  |  ISS OPERATIONS LOBBY", Vector2(24, 8), Vector2(700, 34), 26, Pix.EDGE)
	Pix.lbl(ui, "DAY %d / %d   |   %s   |   ISS LOW EARTH ORBIT   |   %d DAYS TO EARTH DEADLINE" % [
		GameState.day, int(Campaign.deadline_days()), GameState.date_text(), GameState.days_left()],
		Vector2(24, 42), Vector2(820, 20), 13, Pix.WARN)
	Pix.chip(ui, Vector2(24, 62), "data", "Data %d" % GameState.station_data, Pix.EDGE)
	Pix.chip(ui, Vector2(230, 62), "food", "Food %.1f kg" % GameState.food_store, Pix.GOOD)
	var target := float(GameState.C.get("smelter_target", 165))
	Pix.chip(ui, Vector2(430, 62), "ore", "Ore %d / %d pts" % [GameState.smelter_points(), int(target)],
		Pix.WARN, clampf(float(GameState.smelter_points()) / target, 0.0, 1.0))
	Pix.chip(ui, Vector2(660, 62), "smelter", "Smelter %.0f%%" % (GameState.smelter_pct() * 100.0),
		Pix.ORANGE, GameState.smelter_pct())
	Pix.lbl(ui, "Best score %d" % GameState.best_score, Vector2(900, 62), Vector2(200, 22), 14, Pix.DIM)
	var guide_bg: Panel = Pix.panel(ui, Vector2(206, 612), Vector2(848, 36))
	guide_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Pix.glow(guide_bg, Pix.WARN)
	Pix.lbl(ui, _next_step(), Vector2(218, 618), Vector2(700, 26), 14, Pix.WARN)
	# [Go Now] warps straight to the room the guide is asking for.
	var go_dest := _go_now_dest()
	if go_dest != "":
		Pix.btn_primary(ui, "[Go Now] >", Vector2(928, 614), Vector2(120, 32), func(): go(go_dest))
	for m in GameState.data["station_modules"]:
		var built: bool = GameState.built.has(m["id"])
		var parent_ok: bool = m["parent"] == "" or GameState.built.has(m["parent"])
		if not built and not parent_ok:
			continue
		var center := Vector2(float(m["x"]), float(m["y"]))
		var rect := Rect2(center - Vector2(102, 40), Vector2(204, 80))
		_rooms.append({"m": m, "rect": rect, "built": built})
		_walls.append(rect)
		var b := Button.new()
		b.size = Vector2(198, 48)
		b.position = center - b.size / 2.0
		if built:
			b.text = m["name"]
		else:
			b.text = "+ %s (%d Data)" % [m["name"], int(m["cost"])]
			b.add_theme_font_size_override("font_size", 14)
			b.modulate = Color(0.85, 0.7, 1.0)
		var mm: Dictionary = m
		b.pressed.connect(func(): on_module(mm))
		ui.add_child(b)
		_tip(b, String(m["name"]), _room_body(m, built), ROLE_COL[m["role"]])
	info = Pix.lbl(ui, "Walk with WASD or the arrow keys. Stand next to a room and press E. Hover a room for a picture.",
		Vector2(210, 652), Vector2(840, 26), 15, Pix.DIM)
	Pix.btn(ui, "?", Vector2(1104, 14), Vector2(44, 36), open_tutorial)
	Pix.btn(ui, "Menu", Vector2(1160, 14), Vector2(100, 36), func(): go("menu"))
	# Right-hand column: the rooms that are not on the map, and the reference pages.
	var side := [
		["CREW CABIN", "Crew cabin: load gear for the next flight and check the ship.", "ship"],
		["TERMINAL", "ISS terminal: mission files, dossiers and orbit checks.", "computer"],
		["TECH BOOK", "Tech Book: pictures and plain-language notes on every module, part, suit rule and mission.", "techbook"],
		["PROBES", "Probe Control: launch robotic probes to Mars, Venus, Mercury and the outer planets. Real flight times and launch windows.", "probes"],
	]
	# Narrow column on the far right so it never covers the Relay Array / Solar Wing rooms.
	var y := 110.0
	for s in side:
		var dest: String = s[2]
		var b := Pix.btn(ui, s[0], Vector2(1108, y), Vector2(138, 40), func(): go(dest))
		_tip(b, String(s[0]), String(s[1]), Pix.EDGE)
		y += 46.0
	var story_btn := Pix.btn(ui, "STORY", Vector2(1108, y), Vector2(138, 40), _open_story)
	_tip(story_btn, "STORY", "Replay the 3-slide briefing: why Earth needs the Helios smelter.", Pix.EDGE)
	y += 46.0
	var how_btn := Pix.btn(ui, "HOW TO PLAY", Vector2(1108, y), Vector2(138, 40), open_tutorial)
	_tip(how_btn, "HOW TO PLAY", "The five-page guide: walking, the first mission, flight, the Moon and the report.", Pix.EDGE)
	if GameState.campaign_over():
		Pix.btn_primary(ui, "RESULT >", Vector2(960, 14), Vector2(130, 36), func(): go("endgame"))
	Pix.lbl(ui, "Mission Control, Apollo 9 - NASA", Vector2(1048, 684), Vector2(206, 18), 11, Color(0.55, 0.62, 0.78))
	queue_redraw()

# The first-mission guide: one line that always names the next thing to do.
func _next_step() -> String:
	var total := 0
	for v in GameState.design.values():
		total += int(v)
	if GameState.history.is_empty():
		if total <= 0:
			return "MISSION 1, STEP 1/3: walk to the HANGAR (E), design a ship. Quick start: LOAD SAMPLE DESIGN."
		return "MISSION 1, STEP 2/3: walk to MISSION CTRL (E), launch to the MOON, collect ore, come HOME."
	return "NEXT: read the report. Failed? Fix the ship in the Hangar. Done? Spend Data on rooms (purple +)."

# Where the [Go Now] button sends the player for the current step.
func _go_now_dest() -> String:
	var total := 0
	for v in GameState.design.values():
		total += int(v)
	if GameState.history.is_empty():
		return "hangar" if total <= 0 else "mission"
	return "hangar" if GameState.station_data < 20 else "mission"



func _room_body(m: Dictionary, built: bool) -> String:
	if built:
		return "BUILT.\n" + String(m["effect"])
	var cost := int(m["cost"])
	var have := GameState.station_data
	if have >= cost:
		return "NOT BUILT. Cost %d Data - you have %d. Press E or click to build.\n%s" % [cost, have, m["effect"]]
	return "NOT BUILT. Cost %d Data - you have %d. You need %d more Data from missions.\n%s" % [cost, have, cost - have, m["effect"]]

func on_module(m: Dictionary) -> void:
	var id: String = m["id"]
	if GameState.built.has(id):
		match id:
			"hangar":
				go("hangar")
				return
			"control":
				go("mission")
				return
			"core":
				go("computer")
				return
			"habitat", "greenhouse", "lab", "exercise":
				# These are all rooms inside the crew cabin.
				go("ship")
				return
			_:
				info.text = "%s - %s" % [m["name"], m["effect"]]
	else:
		if GameState.station_data >= int(m["cost"]):
			GameState.build_module(id)
			Sfx.play("build")
			refresh()
			info.text = "Built %s! %s" % [m["name"], m["effect"]]
			info.add_theme_color_override("font_color", Pix.GOOD)
		else:
			info.text = "NOT ENOUGH DATA for %s: you need %d, you have %d. Finish a mission to earn Data." % [
				m["name"], int(m["cost"]), GameState.station_data]
			info.add_theme_color_override("font_color", Pix.BAD)

func back_scene() -> String:
	return "menu"

# ---------- walking, rooms and the E key ----------

func _process(delta: float) -> void:
	if hover_box.visible:
		var mp := get_viewport().get_mouse_position()
		hover_box.position = Vector2(minf(mp.x + 18.0, 960.0), minf(mp.y + 18.0, 560.0))
	var blocked_by_overlay := (tut_box != null and tut_box.visible) or story_box != null
	if not blocked_by_overlay:
		_walk(delta)
	actor.queue_redraw()

func _walk(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1
	if dir != Vector2.ZERO:
		var step := dir.normalized() * WALK_SPEED * delta
		# Move one axis at a time so the crew slides along a wall instead of sticking to it.
		var nx := Vector2(player.x + step.x, player.y)
		if _free(nx):
			player.x = nx.x
		var ny := Vector2(player.x, player.y + step.y)
		if _free(ny):
			player.y = ny.y
	_update_near()

func _free(p: Vector2) -> bool:
	if not BOUNDS.has_point(p):
		return false
	for r in _walls:
		if (r as Rect2).grow(PLAYER_R).has_point(p):
			return false
	return true

func _update_near() -> void:
	near_id = ""
	var best := NEAR_DIST
	for rm in _rooms:
		var d := _rect_dist(player, rm["rect"])
		if d < best:
			best = d
			near_id = String(rm["m"]["id"])

func _rect_dist(p: Vector2, r: Rect2) -> float:
	var q := Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))
	return q.distance_to(p)

func _near_name() -> String:
	for rm in _rooms:
		if String(rm["m"]["id"]) == near_id:
			var verb := "Enter" if bool(rm["built"]) else "Build"
			return "[E] %s %s" % [verb, rm["m"]["name"]]
	return ""

func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_E and near_id != "" and story_box == null \
			and not (tut_box != null and tut_box.visible):
		get_viewport().set_input_as_handled()
		_enter(near_id)
		return
	super._unhandled_input(event)

func _enter(id: String) -> void:
	for rm in _rooms:
		if String(rm["m"]["id"]) == id:
			on_module(rm["m"])
			return

func _draw_actor() -> void:
	# The crew member, drawn on its own layer above the room buttons.
	actor.draw_rect(Rect2(player.x - 7, player.y - 14, 14, 16), Color("f2f2f2"))
	actor.draw_rect(Rect2(player.x - 5, player.y - 21, 10, 8), Color("ffe8b0"))
	actor.draw_rect(Rect2(player.x - 3, player.y - 19, 6, 4), Color("1fb6ff"))
	# The prompt sits in a fixed banner above the guide line, so it never covers a room name.
	if near_id != "":
		var label := _near_name()
		actor.draw_rect(Rect2(20, 574, 360, 28), Color(0.02, 0.03, 0.08, 0.92))
		actor.draw_rect(Rect2(20, 574, 4, 28), Pix.WARN)
		actor.draw_string(ThemeDB.fallback_font, Vector2(34, 593), label,
			HORIZONTAL_ALIGNMENT_LEFT, 340, 15, Pix.WARN)

# ---------- picture cards on hover ----------

func _tip(b: Button, title: String, body: String, col: Color) -> void:
	b.mouse_entered.connect(func(): _show_hover(title, body, col))
	b.mouse_exited.connect(func(): hover_box.visible = false)

func _show_hover(title: String, body: String, col: Color) -> void:
	Pix.clear(hover_box)
	var p: Panel = Pix.panel(hover_box, Vector2.ZERO, Vector2(300, 150))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := Control.new()
	icon.position = Vector2(12, 12)
	icon.size = Vector2(72, 44)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.draw.connect(func(): _draw_icon(icon, col))
	hover_box.add_child(icon)
	Pix.lbl(hover_box, title, Vector2(96, 12), Vector2(196, 44), 16, col)
	Pix.lbl(hover_box, body, Vector2(12, 64), Vector2(276, 80), 13, Pix.TEXT)
	hover_box.visible = true

# A small picture of a module: a lit hull with windows, in the module's colour.
func _draw_icon(c: Control, col: Color) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, c.size), col.darkened(0.55))
	c.draw_rect(Rect2(0, 0, c.size.x, 5), col)
	c.draw_rect(Rect2(0, c.size.y - 5, c.size.x, 5), col)
	for i in 3:
		c.draw_rect(Rect2(10 + i * 22, 14, 12, 12), col.lightened(0.4))

# ---------- story (first visit) ----------

func _open_story() -> void:
	if story_box != null:
		return
	var st: Node = load("res://scenes/story.tscn").instantiate()
	st.set("embedded", true)
	st.closed.connect(_on_story_closed)
	story_box = st
	add_child(st)

func _on_story_closed() -> void:
	story_box = null
	if not GameState.tutorial_seen:
		open_tutorial()

# ---------- tutorial overlay ----------

func open_tutorial() -> void:
	if tut_box == null:
		return
	tut_step = 0
	tut_box.visible = true
	# The crew sprite and room labels are added after the guide box, so they would draw over it.
	tut_box.move_to_front()
	_render_tutorial()

func _render_tutorial() -> void:
	Pix.clear(tut_box)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.86)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	tut_box.add_child(dim)
	Pix.panel(tut_box, Vector2(240, 110), Vector2(800, 520))
	var step: Dictionary = TUTORIAL[tut_step]
	Pix.lbl(tut_box, "HOW TO PLAY  (%d/%d)" % [tut_step + 1, TUTORIAL.size()], Vector2(270, 130), Vector2(500, 26), 16, Pix.WARN)
	Pix.lbl(tut_box, String(step["title"]), Vector2(270, 162), Vector2(740, 40), 28, Pix.EDGE)
	Pix.lbl(tut_box, String(step["body"]), Vector2(270, 218), Vector2(740, 250), 17, Pix.TEXT)
	var last: bool = tut_step >= TUTORIAL.size() - 1
	if tut_step > 0:
		Pix.btn(tut_box, "< Back", Vector2(270, 560), Vector2(150, 48), func(): _tutorial_go(tut_step - 1))
	Pix.btn(tut_box, "DONE" if last else "NEXT >", Vector2(470, 560), Vector2(220, 48), func():
		if last:
			close_tutorial()
		else:
			_tutorial_go(tut_step + 1))
	Pix.btn(tut_box, "Skip", Vector2(730, 560), Vector2(150, 48), close_tutorial)
	Pix.lbl(tut_box, "You can reopen this any time with the ? button (top right).", Vector2(270, 612), Vector2(740, 22), 14, Pix.DIM)

func _tutorial_go(step: int) -> void:
	tut_step = clampi(step, 0, TUTORIAL.size() - 1)
	_render_tutorial()

func close_tutorial() -> void:
	GameState.tutorial_seen = true
	GameState.save_game()
	if tut_box != null:
		tut_box.visible = false
		Pix.clear(tut_box)

func draw_extra() -> void:
	var pos := {}
	for m in GameState.data["station_modules"]:
		pos[m["id"]] = Vector2(float(m["x"]), float(m["y"]))
	# branches first (so the modules draw on top)
	for m in GameState.data["station_modules"]:
		var built: bool = GameState.built.has(m["id"])
		var parent_ok: bool = m["parent"] == "" or GameState.built.has(m["parent"])
		if m["parent"] == "" or (not built and not parent_ok):
			continue
		var a: Vector2 = pos[m["parent"]]
		var b: Vector2 = pos[m["id"]]
		var col := Color("5a7fb8") if built else Color("6b4fa0")
		draw_line(a, b, col, 8.0)
		draw_line(a, b, col.lightened(0.3), 2.0)
	# module bodies
	for m in GameState.data["station_modules"]:
		var built: bool = GameState.built.has(m["id"])
		var parent_ok: bool = m["parent"] == "" or GameState.built.has(m["parent"])
		if not built and not parent_ok:
			continue
		var c: Vector2 = pos[m["id"]]
		var col: Color = ROLE_COL[m["role"]]
		if not built:
			col = Color("6b4fa0")
		draw_rect(Rect2(c.x - 102, c.y - 40, 204, 80), col.darkened(0.55))
		draw_rect(Rect2(c.x - 102, c.y - 40, 204, 6), col)
		draw_rect(Rect2(c.x - 102, c.y + 34, 204, 6), col)
		if m["role"] == "core":
			draw_circle(c, 62, col.darkened(0.5))
			draw_circle(c, 52, col.darkened(0.7))
	# tiny crew icons in the habitat
	var h: Vector2 = pos["habitat"]
	for i in 3:
		draw_rect(Rect2(h.x - 20 + i * 18, h.y - 66, 8, 12), Color("ffd166"))
		draw_rect(Rect2(h.x - 20 + i * 18, h.y - 74, 8, 8), Color("ffe8b0"))
	# Earth in the corner
	draw_circle(Vector2(90, 700), 110, Color("1d4e9e"))
	draw_circle(Vector2(90, 700), 100, Color("2a7bd4"))
	draw_rect(Rect2(50, 620, 40, 10), Color("3fae5a"))
	# archival photo of the real room this screen represents
	Pix.photo_frame(self, Pix.NASA_CONTROL, Rect2(1048, 548, 200, 128), 0.25)
