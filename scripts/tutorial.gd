extends Screen
# Screen - full "How to play" tutorial. Reachable from the menu, the station ? button
# and the ship. The short first-run overlay still exists on the station for speed.

const SLIDES := [
	{
		"title": "1. THE ISS IS YOUR LOBBY",
		"body": "Every run starts at the ISS. Coloured modules are already built. Purple '+' slots cost Data and grow the station.\n\nGreenhouse = food. Science Lab = more Data. Exercise Bay = more EVA stamina. Cargo Bay, Heavy Dock, Relay and Solar Wing make the next ship better.\n\nData is earned by flying missions and studying samples.",
		"hint": "Click a module. Built modules open their screen; purple slots ask to be built."
	},
	{
		"title": "2. ENTER YOUR SHIP",
		"body": "The SHIP button opens the crew cabin. Inside you can tend the greenhouse, study samples, rest, or load gear for the next flight.\n\nThe Radiation blanket cuts solar-flare hull damage. The Scout drone maps the landing zone and gives you +25% EVA time. Both cost Data and are used on the next launch only.",
		"hint": "If you skip the scout, the EVA is shorter. Preparation is part of the mission."
	},
	{
		"title": "3. DESIGN THE SHIP",
		"body": "The Hangar has seven parts, three options each. Watch Mass (dock lift limit), Budget, Power (net kW) and Delta-v.\n\nGreen numbers pass; red numbers fail. The '*' marks the recommended option. 'Load sample design' gives you a ship that can fly the Moon.\n\nHover any option to read what it does.",
		"hint": "Delta-v comes from the rocket equation: dv = Isp * g0 * ln(mass full / mass dry)."
	},
	{
		"title": "4. READ THE MISSION DOSSIER",
		"body": "Mission Control shows the flight plan, the hazards and the resources at the destination. Open DETAILS for the full dossier: environment, hazards, ore and the gear the crew should carry.\n\nCheck the pre-flight warnings before you launch. You may launch anyway and learn from the report.",
		"hint": "The Moon dossier is the demo mission. Mars is a data-only preview."
	},
	{
		"title": "5. FLY THE MISSION",
		"body": "During the voyage random events ask for a decision. Every choice trades time, supplies, hull or data.\n\nThe CREW button lets you spend one day on hydroponics (+2 kg food), study (+5 science) or EVA preparation (+8% hull). The cost is real: one day of oxygen, water and food.",
		"hint": "A saved day is not free. Read the log; it tells you exactly what changed."
	},
	{
		"title": "6. WALK, SAMPLE, REPORT",
		"body": "On the Moon, WASD or arrows move. Ice and helium-3 sit in dark craters and slow you down. SPACE returns to the lander early.\n\nThe suit has a stamina bar: 1 = easy, 2 = normal, 3 = hard, Shift = burst. Empty suit = EVA over. Collect ore for the Helios smelter, then read the report to see why the mission worked or failed.",
		"hint": "Run the same seed again after changing the ship to compare fairly."
	},
]

var slide: int = 0
var ui: Control

func build() -> void:
	star_seed = 5
	ui = Control.new()
	ui.size = Vector2(1280, 720)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	render()

func render() -> void:
	Pix.clear(ui)
	var s: Dictionary = SLIDES[slide]
	Pix.panel(ui, Vector2(56, 48), Vector2(780, 520))
	Pix.lbl(ui, "HOW TO PLAY  //  %d OF %d" % [slide + 1, SLIDES.size()],
		Vector2(84, 68), Vector2(700, 24), 15, Pix.WARN)
	Pix.lbl(ui, String(s["title"]), Vector2(84, 100), Vector2(720, 48), 34, Pix.EDGE)
	Pix.lbl(ui, String(s["body"]), Vector2(84, 164), Vector2(720, 300), 18, Pix.TEXT)
	Pix.lbl(ui, String(s["hint"]), Vector2(84, 478), Vector2(720, 52), 15, Pix.GOOD)
	for i in SLIDES.size():
		var col := Pix.EDGE if i == slide else Color("2c3a7a")
		var dot := ColorRect.new()
		dot.color = col
		dot.position = Vector2(84 + i * 24, 530)
		dot.size = Vector2(16, 6)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(dot)
	if slide > 0:
		Pix.btn(ui, "< BACK", Vector2(84, 578), Vector2(150, 46), func(): _move(-1))
	Pix.btn(ui, "ENTER ISS >" if slide == SLIDES.size() - 1 else "NEXT >",
		Vector2(250, 578), Vector2(250, 46), _next)
	Pix.btn(ui, "SKIP", Vector2(516, 578), Vector2(140, 46), _finish)
	Pix.lbl(ui, "Esc = back   |   Enter = next", Vector2(84, 642), Vector2(400, 20), 13, Pix.DIM)
	# Right-hand illustration: the ship you are learning to build.
	Pix.panel(ui, Vector2(880, 120), Vector2(320, 440))
	Pix.lbl(ui, "YOUR SHIP", Vector2(904, 140), Vector2(272, 24), 18, Pix.WARN)
	var canvas := Control.new()
	canvas.position = Vector2(880, 120)
	canvas.size = Vector2(320, 400)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(canvas)
	canvas.draw.connect(func(): Pix.draw_ship(canvas, Vector2(160, 70), GameState.design, 4.5, false))
	Pix.lbl(ui, "7 parts. One mission.", Vector2(904, 500), Vector2(272, 22), 14, Pix.DIM)
	queue_redraw()

func _move(d: int) -> void:
	slide = clampi(slide + d, 0, SLIDES.size() - 1)
	render()

func _next() -> void:
	if slide >= SLIDES.size() - 1:
		_finish()
	else:
		_move(1)

func _finish() -> void:
	GameState.story_seen = true
	GameState.save_game()
	go("station")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_next()
	else:
		super._unhandled_input(event)

func back_scene() -> String:
	return "menu"
