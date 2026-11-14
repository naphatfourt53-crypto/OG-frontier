extends Screen
# Screen 6 - Moon walk: 60 seconds. Collect samples (yellow) and ice (blue, inside dark craters, slows you down).

const TIME_LIMIT := 60.0
const ICE_PTS := 15.0
const SAMPLE_PTS := 5.0

var t_left: float = TIME_LIMIT
var pl: Vector2 = Vector2(640, 380)
var points: float = 0.0
var craters: Array = []
var ice: Array = []
var samples: Array = []
var done: bool = false
var ui: Control
var hud_label: Label

func build() -> void:
	star_seed = 61
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.seed_value
	for i in 3:
		var c := Vector2(220 + i * 420 + rng.randi() % 80, 200 + rng.randi() % 320)
		craters.append({"pos": c, "r": 90.0 + rng.randf() * 30.0})
		for j in 2:
			var ang := rng.randf() * TAU
			var rr := rng.randf() * 55.0
			ice.append(c + Vector2(cos(ang), sin(ang)) * rr)
	for i in 14:
		var p := Vector2(60 + rng.randi() % 1160, 110 + rng.randi() % 540)
		if not in_crater(p):
			samples.append(p)
	ui = Control.new()
	ui.size = Vector2(1280, 720)
	add_child(ui)
	Pix.lbl(ui, "MOON WALK - collect ice and samples!", Vector2(20, 12), Vector2(700, 32), 24, Pix.EDGE)
	Pix.lbl(ui, "WASD / arrows to move. Dark craters hide ICE (15 pts) but slow you. Samples = 5 pts. SPACE = return to lander early.", Vector2(20, 46), Vector2(1100, 24), 14, Pix.DIM)
	hud_label = Pix.lbl(ui, "", Vector2(980, 12), Vector2(280, 30), 22, Pix.WARN)

func in_crater(p: Vector2) -> bool:
	for c in craters:
		if p.distance_to(c["pos"]) < float(c["r"]):
			return true
	return false

func _process(delta: float) -> void:
	if done:
		return
	t_left -= delta
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1
	var speed := 240.0
	if in_crater(pl):
		speed = 120.0
	pl += dir.normalized() * speed * delta
	pl.x = clampf(pl.x, 40.0, 1240.0)
	pl.y = clampf(pl.y, 90.0, 690.0)
	for p in samples.duplicate():
		if pl.distance_to(p) < 24.0:
			samples.erase(p)
			points += SAMPLE_PTS
	for p in ice.duplicate():
		if pl.distance_to(p) < 24.0:
			ice.erase(p)
			points += ICE_PTS
	hud_label.text = "Time %02d   Points %d" % [int(maxf(0.0, t_left)), int(points)]
	if t_left <= 0.0 or Input.is_key_pressed(KEY_SPACE):
		finish()
	queue_redraw()

func finish() -> void:
	done = true
	Pix.panel(ui, Vector2(380, 230), Vector2(520, 220))
	Pix.lbl(ui, "EVA over", Vector2(410, 245), Vector2(460, 36), 28, Pix.WARN)
	Pix.lbl(ui, "You collected %d science points. The crew returns to the lander." % int(points), Vector2(410, 295), Vector2(460, 60), 18)
	Pix.btn(ui, "BACK TO SHIP >", Vector2(410, 380), Vector2(260, 50), func():
		GameState.finish_explore(points)
		go("flight"))
	queue_redraw()

func draw_extra() -> void:
	draw_rect(Rect2(0, 80, 1280, 640), Color("6e6e78"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 160:
		draw_rect(Rect2(rng.randi() % 1280, 80 + rng.randi() % 640, 4, 4), Color("5a5a64"))
	for c in craters:
		draw_circle(c["pos"], float(c["r"]), Color("2b2b36"))
		draw_circle(c["pos"], float(c["r"]) - 10.0, Color("1c1c26"))
	for p in ice:
		draw_rect(Rect2(p.x - 7, p.y - 7, 14, 14), Color("7fe3ff"))
		draw_rect(Rect2(p.x - 3, p.y - 3, 6, 6), Color.WHITE)
	for p in samples:
		draw_rect(Rect2(p.x - 6, p.y - 6, 12, 12), Color("ffd166"))
	# lander
	draw_rect(Rect2(620, 370, 40, 8), Color("cfcfcf"))
	# astronaut
	draw_rect(Rect2(pl.x - 8, pl.y - 18, 16, 20), Color("f2f2f2"))
	draw_rect(Rect2(pl.x - 6, pl.y - 26, 12, 10), Color("ffe8b0"))
	draw_rect(Rect2(pl.x - 4, pl.y - 24, 8, 5), Color("1fb6ff"))
