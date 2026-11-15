class_name Pix
extends RefCounted
# Pixel-art helpers: palette, UI builders, and ship / star drawing made only from rectangles.
# No external images, so there are no copyright problems.

const BG := Color("0b1026")

# Photographs (NASA, public domain) are optional: if a file is missing or fails to
# import, every photo helper falls back to the code-drawn art so the game still runs.
const NASA_MENU := "res://assets/nasa/as08-14-2383.jpg"
const NASA_LANDER := "res://assets/nasa/as11-40-5927.jpg"
const NASA_ASTRONAUT := "res://assets/nasa/KSC-AS-11-40-5902.jpg"
const NASA_CONTROL := "res://assets/nasa/S69-26301.jpg"

static var _tex_cache: Dictionary = {}
const PANEL := Color("141b3d")
const EDGE := Color("4fd1ff")
const TEXT := Color("e8f1ff")
const DIM := Color("8fa3c9")
const GOOD := Color("5dff9a")
const BAD := Color("ff5d6c")
const WARN := Color("ffc857")
const ORANGE := Color("ff8a3d")

static func make_theme() -> Theme:
	# Shared look for every screen: rounded panels with a soft drop shadow, buttons that
	# lift and brighten on hover and sink when pressed.
	var t := Theme.new()
	var states := {"normal": Color("1b2559"), "hover": Color("2a3a85"), "pressed": Color("0f1740"), "disabled": Color("181c30")}
	for k in states:
		var sb := StyleBoxFlat.new()
		sb.bg_color = states[k]
		sb.set_border_width_all(2)
		sb.border_color = EDGE if k != "disabled" else Color("3a4263")
		if k == "hover":
			sb.border_color = Color("9fe9ff")
		sb.set_corner_radius_all(6)
		sb.shadow_color = Color(0.0, 0.0, 0.0, 0.45) if k != "pressed" else Color(0.0, 0.0, 0.0, 0.1)
		sb.shadow_size = 6 if k != "pressed" else 2
		sb.shadow_offset = Vector2(0, 3) if k != "pressed" else Vector2(0, 1)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		sb.content_margin_top = 6
		sb.content_margin_bottom = 6
		t.set_stylebox(k, "Button", sb)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color("5a6385"))
	t.set_font_size("font_size", "Button", 16)
	t.set_color("font_color", "Label", TEXT)
	t.set_font_size("font_size", "Label", 16)
	var ps := StyleBoxFlat.new()
	ps.bg_color = PANEL
	ps.set_border_width_all(2)
	ps.border_color = Color("2c3a7a")
	ps.set_corner_radius_all(8)
	ps.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	ps.shadow_size = 12
	ps.shadow_offset = Vector2(0, 4)
	t.set_stylebox("panel", "Panel", ps)
	return t

static func lbl(parent: Node, text: String, pos: Vector2, size: Vector2, fsize: int = 16, color: Color = TEXT) -> Label:
	var l := Label.new()
	# Autowrap must be enabled BEFORE assigning size: Control.set_size() clamps to the
	# current minimum size, and an unwrapped Label's minimum width is the whole string.
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.text = text
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	l.position = pos
	l.size = size
	return l

static func btn(parent: Node, text: String, pos: Vector2, size: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	# Every menu button clicks. Looked up at runtime so Pix also works in tools
	# that run without the Sfx autoload.
	b.pressed.connect(func(): sfx("click"))
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

static func sfx(key: String) -> void:
	var loop := Engine.get_main_loop() as SceneTree
	if loop == null:
		return
	var player := loop.root.get_node_or_null("Sfx")
	if player != null:
		player.play(key)

static func panel(parent: Node, pos: Vector2, size: Vector2) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = size
	parent.add_child(p)
	return p

static func clear(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()

static func tex(path: String) -> Texture2D:
	# Cached so redrawing a photo every frame does not touch the resource loader.
	if _tex_cache.has(path):
		return _tex_cache[path]
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path) as Texture2D
	_tex_cache[path] = t
	return t

static func photo(c: CanvasItem, path: String, rect: Rect2, shade: float = 0.0) -> bool:
	# Cover-fit: crop the source to the target aspect so the image is never squashed.
	var t := tex(path)
	if t == null:
		return false
	var ts := t.get_size()
	if ts.x < 1.0 or ts.y < 1.0:
		return false
	var src := Rect2(Vector2.ZERO, ts)
	var target_ar := rect.size.x / maxf(1.0, rect.size.y)
	var src_ar := ts.x / ts.y
	if src_ar > target_ar:
		src.size.x = ts.y * target_ar
		src.position.x = (ts.x - src.size.x) * 0.5
	else:
		src.size.y = ts.x / target_ar
		src.position.y = (ts.y - src.size.y) * 0.5
	c.draw_texture_rect_region(t, rect, src)
	if shade > 0.0:
		c.draw_rect(rect, Color(0.02, 0.03, 0.08, clampf(shade, 0.0, 1.0)))
	return true

static func photo_frame(c: CanvasItem, path: String, rect: Rect2, shade: float = 0.0) -> bool:
	# Framed archival photo. Returns false when the image is unavailable so callers
	# can keep their vector-art layout.
	c.draw_rect(rect.grow(3.0), Color("2c3a7a"))
	c.draw_rect(rect.grow(1.0), Color("8fa3c9"))
	var ok := photo(c, path, rect, shade)
	if not ok:
		c.draw_rect(rect, Color("141b3d"))
	return ok


static func stars(c: Control, seed_v: int, count: int = 120) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, c.size), BG)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for i in count:
		var x := rng.randi() % int(c.size.x)
		var y := rng.randi() % int(c.size.y)
		var s := 2 if rng.randf() < 0.85 else 4
		var col := Color(1, 1, 1, 0.35 + rng.randf() * 0.5)
		c.draw_rect(Rect2(x, y, s, s), col)

static func draw_ship(c: Control, origin: Vector2, design: Dictionary, u: float, flame: bool = false) -> void:
	# origin = top-center of the ship. Ship points up. u = size of one "pixel".
	var ct: int = int(design.get("cockpit", 0))
	var en: int = int(design.get("engine", 0))
	var tk: int = int(design.get("tank", 0))
	var lf: int = int(design.get("life", 0))
	var pw: int = int(design.get("power", 0))
	var st: int = int(design.get("storage", 0))
	var cm: int = int(design.get("comms", 0))
	var nose_cols := [Color("c9d3e8"), Color("9fd0ff"), Color("ffd166")]
	var eng_cols := [Color("8d99ae"), Color("cdb4db"), Color("7bdff2")]
	var body_w: float = 8.0 + 2.0 * tk
	var body_h: float = 8.0 + 4.0 * tk
	var x0 := origin.x
	var y := origin.y
	# antenna on top
	var ah := 3.0 + 2.0 * cm
	c.draw_rect(Rect2(x0 - u * 0.5, y, u, u * ah), Color("e0e0e0"))
	c.draw_rect(Rect2(x0 - u * (1.0 + cm), y, u * (2.0 + 2.0 * cm), u), Color("ffffff"))
	y += u * ah
	# nose (cockpit)
	var rows := [2.0, 4.0, 6.0, 8.0]
	for w in rows:
		c.draw_rect(Rect2(x0 - u * w / 2.0, y, u * w, u), nose_cols[ct])
		y += u
	c.draw_rect(Rect2(x0 - u, y - u * 2.0, u * 2.0, u), Color("1fb6ff"))
	# cabin band (shield thickness)
	c.draw_rect(Rect2(x0 - u * 4.0, y, u * 8.0, u * (1.0 + ct)), nose_cols[ct].darkened(0.25))
	y += u * (1.0 + ct)
	# tank body
	var bx := x0 - u * body_w / 2.0
	c.draw_rect(Rect2(bx, y, u * body_w, u * body_h), Color("f4f1ea"))
	c.draw_rect(Rect2(bx, y, u * 2.0, u * body_h), Color("d8d2c4"))
	c.draw_rect(Rect2(bx, y + u * body_h * 0.5, u * body_w, u), ORANGE)
	var body_top := y
	# side pods: life support (green) and storage (brown)
	var lh := 3.0 + 2.0 * lf
	c.draw_rect(Rect2(bx - u * 3.0, body_top + u, u * 3.0, u * lh), Color("4cc38a"))
	c.draw_rect(Rect2(bx - u * 3.0, body_top + u, u, u * lh), Color("2c8f62"))
	var sh := 3.0 + 2.0 * st
	c.draw_rect(Rect2(bx + u * body_w, body_top + u, u * 3.0, u * sh), Color("b0824f"))
	c.draw_rect(Rect2(bx + u * body_w + u * 2.0, body_top + u, u, u * sh), Color("7c5a33"))
	# power: solar wings or fission rod
	if pw < 2:
		var wl := 8.0 + 6.0 * pw
		var wy := body_top + body_h * u * 0.62
		c.draw_rect(Rect2(bx - u * 3.0 - u * wl, wy, u * wl, u * 4.0), Color("2b5fd9"))
		c.draw_rect(Rect2(bx + u * body_w + u * 3.0, wy, u * wl, u * 4.0), Color("2b5fd9"))
		var i := 0.0
		while i < wl:
			c.draw_rect(Rect2(bx - u * 3.0 - u * wl + u * i, wy, 1.0, u * 4.0), Color("8fb4ff"))
			c.draw_rect(Rect2(bx + u * body_w + u * 3.0 + u * i, wy, 1.0, u * 4.0), Color("8fb4ff"))
			i += 2.0
	else:
		var rx := bx + u * body_w + u * 3.0
		c.draw_rect(Rect2(rx, body_top + body_h * u * 0.7, u * 6.0, u), Color("aaaaaa"))
		c.draw_rect(Rect2(rx + u * 6.0, body_top + body_h * u * 0.7 - u, u * 3.0, u * 3.0), Color("ff7a3d"))
	y += u * body_h
	# engine
	var ecol: Color = eng_cols[en]
	var nrows := [6.0, 5.0, 4.0, 3.0]
	for w in nrows:
		c.draw_rect(Rect2(x0 - u * w / 2.0, y, u * w, u), ecol)
		y += u
	if flame:
		var fl := [3.0, 2.0, 1.0]
		for w in fl:
			c.draw_rect(Rect2(x0 - u * w / 2.0, y, u * w, u * 1.5), Color("ffb84d") if w > 1.0 else Color("fff2b3"))
			y += u * 1.5

static func ship_height(design: Dictionary, u: float) -> float:
	var tk: int = int(design.get("tank", 0))
	var cm: int = int(design.get("comms", 0))
	var ct: int = int(design.get("cockpit", 0))
	return u * ((3.0 + 2.0 * cm) + 4.0 + (1.0 + ct) + (8.0 + 4.0 * tk) + 4.0)
