extends Screen
# Screen 0 - Story briefing. Shown once, automatically, on the first visit to the ISS
# (embedded as an overlay by station.gd). The STORY button in the station re-opens it.
signal closed
var embedded: bool = false
# Establishes why the station exists: Earth is overheating and the Helios smelter
# needs ore from every world. English text only, like the rest of the game.

const SLIDES := [
	{
		"kicker": "2031 - THE LAST LAUNCH WINDOW",
		"title": "EARTH IS OUT OF TIME",
		"body": "Heat domes, failed harvests and rising seas have made the planet nearly unlivable. The Helios smelter was meant to cool the atmosphere, but it was never finished.\n\nYour crew is going to the International Space Station with one job: find the ore, finish the smelter, and give Earth one more chance.",
		"note": "The station is the last safe place. Everything you do starts there."
	},
	{
		"kicker": "OG-FRONTIER - OPERATIONS LOBBY",
		"title": "A HOME IN LOW EARTH ORBIT",
		"body": "The ISS is your lobby, your factory and your farm. Grow food in the greenhouse, study samples in the lab, prepare radiation gear and design a ship for each destination.\n\nEvery world holds a different piece of the smelter. The Moon has ice and ilmenite. Mars has CO2, iron and a much longer trip.",
		"note": "Data grows the station. Ore grows the smelter."
	},
	{
		"kicker": "THE LOOP",
		"title": "SCOUT. DESIGN. FLY. RETURN.",
		"body": "Send a scout first to map the landing zone, then build a ship that can pay the delta-v bill. Survive the voyage, collect ore in a limited EVA, and bring it home.\n\nIf you skip the scout, you land on the standard ellipse and get a shorter EVA. Preparation is part of the mission.",
		"note": "The demo ends after the first Moon mission unlocks Mars."
	},
]

var slide: int = 0
var ui: Control

func build() -> void:
	star_seed = 3
	ui = Control.new()
	ui.size = Vector2(1280, 720)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	render()

func render() -> void:
	Pix.clear(ui)
	var s: Dictionary = SLIDES[slide]
	Pix.panel(ui, Vector2(56, 56), Vector2(700, 520))
	Pix.lbl(ui, "OG-FRONTIER // MISSION BRIEFING   %d/%d" % [slide + 1, SLIDES.size()],
		Vector2(84, 76), Vector2(620, 24), 15, Pix.WARN)
	Pix.lbl(ui, String(s["kicker"]), Vector2(84, 108), Vector2(620, 22), 14, Pix.DIM)
	Pix.lbl(ui, String(s["title"]), Vector2(84, 138), Vector2(640, 54), 40, Pix.EDGE)
	Pix.lbl(ui, String(s["body"]), Vector2(84, 210), Vector2(640, 260), 19, Pix.TEXT)
	Pix.lbl(ui, String(s["note"]), Vector2(84, 486), Vector2(640, 50), 15, Pix.DIM)
	# Right-hand "mission patch": Earth under a red heat glow.
	Pix.panel(ui, Vector2(800, 160), Vector2(400, 360))
	Pix.lbl(ui, "HELIOS PROJECT", Vector2(824, 180), Vector2(352, 24), 18, Pix.WARN)
	Pix.lbl(ui, "Earth surface temperature is rising.\nThe smelter is the only plan left.", Vector2(824, 210), Vector2(352, 60), 14, Pix.DIM)
	Pix.lbl(ui, "ORE REQUIRED", Vector2(824, 300), Vector2(352, 20), 14, Pix.WARN)
	Pix.lbl(ui, "Ice + Ilmenite + Regolith + Helium-3\nfrom the Moon. Mars is next.", Vector2(824, 324), Vector2(352, 50), 14, Pix.TEXT)
	# slide dots
	for i in SLIDES.size():
		var col := Pix.EDGE if i == slide else Color("2c3a7a")
		var dot := ColorRect.new()
		dot.color = col
		dot.position = Vector2(84 + i * 26, 548)
		dot.size = Vector2(18, 6)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(dot)
	if slide > 0:
		Pix.btn(ui, "< BACK", Vector2(84, 590), Vector2(160, 48), func(): _move(-1))
	Pix.btn(ui, "BEGIN MISSION >" if slide == SLIDES.size() - 1 else "NEXT >",
		Vector2(260, 590), Vector2(280, 48), _next)
	Pix.btn(ui, "SKIP TO ISS", Vector2(556, 590), Vector2(180, 48), _begin)
	Pix.lbl(ui, "Esc = back   |   Enter = next", Vector2(84, 654), Vector2(400, 20), 13, Pix.DIM)
	Pix.lbl(ui, "Earthrise, Apollo 8 - NASA (public domain)", Vector2(800, 674), Vector2(400, 18), 11, Pix.DIM)

func _move(d: int) -> void:
	slide = clampi(slide + d, 0, SLIDES.size() - 1)
	render()

func _next() -> void:
	if slide >= SLIDES.size() - 1:
		_begin()
	else:
		_move(1)

func _begin() -> void:
	GameState.story_seen = true
	GameState.save_game()
	if embedded:
		closed.emit()
		queue_free()
		return
	go("station")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_next()
	else:
		super._unhandled_input(event)

func back_scene() -> String:
	return "" if embedded else "station"

func draw_extra() -> void:
	# Earth photo, heavily shaded so the text panel stays readable.
	if not Pix.photo(self, Pix.NASA_MENU, Rect2(760, 60, 480, 600), 0.62):
		draw_circle(Vector2(1000, 360), 170, Color("1d4e9e"))
		draw_circle(Vector2(1000, 360), 155, Color("2a7bd4"))
	# Heat glow and a thin smelter ring.
	draw_circle(Vector2(1000, 360), 190, Color(1.0, 0.35, 0.15, 0.10))
	draw_arc(Vector2(1000, 360), 205, 0.0, TAU, 64, Color(1.0, 0.45, 0.2, 0.45), 3.0)
	for i in 8:
		var a := TAU * float(i) / 8.0
		draw_line(Vector2(1000, 360) + Vector2(cos(a), sin(a)) * 212,
			Vector2(1000, 360) + Vector2(cos(a), sin(a)) * 230, Color(1.0, 0.5, 0.25, 0.5), 3.0)
