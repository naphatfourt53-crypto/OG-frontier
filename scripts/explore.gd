extends Screen
# Screen 6 - Moon walk. Collect four surface resources (rarity and points live in game_data.json).
# Ice and helium-3 sit inside dark craters (slow you down); ilmenite sits near rock outcrops.

var t_left: float = 60.0
var t_total: float = 60.0
var pl: Vector2 = Vector2(640, 380)
var points: float = 0.0
var counts: Dictionary = {}
var craters: Array = []
var outcrops: Array = []
var items: Array = []
var done: bool = false
var res: Dictionary = {}
var suit: Stamina
var pace_wanted: String = "normal"
var ui: Control
var overlay: Control
var hud_label: Label
var count_label: Label
var info: Label
# T18 multi-walk state
var walks_total: int = 3
var walk_idx: int = 0
var in_rest: bool = false
var in_final: bool = false
var walk_points: Array = []
var _walk_start_pts: float = 0.0
var total_elapsed: float = 0.0
var total_btu: float = 0.0
var _life_name: String = "Open-loop"
var _time_mult: float = 1.0
# T18 surface tasks
var in_prep: bool = false
var tools: Array = ["camera", "drill"]
var hold_kind: String = ""
var task_hold: float = 0.0
var hold_idx: int = -1
var core_done: Array = []
var deploy_sites: Array = []
var deploy_used: Array = []
var deployed_count: int = 0
var jettison_open: bool = false
var keep_flags: Dictionary = {"ice": true, "regolith": true, "ilmenite": true, "helium3": true}
var _final_reason: String = "The EVA clock ran out."
var _task_key_was_down: bool = false

const DOC_RANGE := 40.0
const TASK_RANGE := 60.0

const GROUND_TOP := 104.0
const SPEED := 240.0
const SLOW_SPEED := 120.0
const PICKUP := 26.0

func build() -> void:
	star_seed = 61
	var scout := false
	if not GameState.run.is_empty():
		scout = bool(GameState.run.get("scout", false))
	else:
		scout = bool(GameState.prep.get("scout", false))
	_time_mult = float(GameState.C.get("prep", {}).get("scout_time_mult", 1.25)) if scout else 1.0
	_life_name = String(GameState.opt("life").get("name", "Open-loop"))
	walks_total = maxi(1, int(GameState.activities()["game"]["surface"].get("eva_count_default", 3)))
	res = GameState.data["moon_resources"]
	for k in res:
		counts[k] = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.seed_value
	for i in 3:
		craters.append({
			"pos": Vector2(220 + i * 420 + rng.randi() % 80, 230 + rng.randi() % 300),
			"r": 100.0 + rng.randf() * 40.0})
	for i in 3:
		outcrops.append(Vector2(160 + rng.randi() % 960, 180 + rng.randi() % 420))
	_spawn(rng)
	ui = Control.new()
	ui.size = Vector2(1280, 720)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	overlay = Control.new()
	overlay.size = Vector2(1280, 720)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	Pix.lbl(ui, "MOON WALK - sample the south pole", Vector2(20, 10), Vector2(700, 32), 24, Pix.EDGE)
	Pix.lbl(ui, "WASD / arrows to move. 1 easy / 2 normal / 3 hard / Shift burst. SPACE returns to the lander. F photograph  E drill/deploy.",
		Vector2(20, 42), Vector2(1100, 22), 14, Pix.DIM)
	count_label = Pix.lbl(ui, "", Vector2(20, 70), Vector2(760, 24), 16, Pix.WARN)
	hud_label = Pix.lbl(ui, "", Vector2(900, 10), Vector2(360, 28), 20, Pix.WARN)
	hud_label.mouse_filter = Control.MOUSE_FILTER_STOP  # so the tooltip can show
	hud_label.tooltip_text = "Game model. Burn rates come from Apollo and ISS suit data; capacity tiers above Open-loop are game values."
	info = Pix.lbl(ui, "", Vector2(760, 66), Vector2(500, 30), 14, Pix.DIM)
	deploy_sites = [Vector2(180, 620), Vector2(640, 640), Vector2(1100, 610)]
	_show_prep_panel()

# ---------- T18 surface tasks ----------

func _show_prep_panel() -> void:
	in_prep = true
	done = true  # freeze the walk behind the panel
	Pix.clear(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.86)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)
	Pix.panel(overlay, Vector2(300, 130), Vector2(680, 440))
	Pix.lbl(overlay, "EVA PREP - CHOOSE 2 TOOLS", Vector2(330, 148), Vector2(620, 36), 26, Pix.WARN)
	Pix.lbl(overlay, "GUIDE: WASD walks. Walk onto ore to pick it up. F photographs an item (x1.5 points, do it before pickup). E drills a rock or places an instrument at a post. SPACE returns to the lander. Task names: Artemis III plan. Numbers: Game rule.",
		Vector2(330, 184), Vector2(620, 40), 12, Pix.TEXT)
	var descs := {
		"camera": "CAMERA - photograph a sample site before collecting (x1.5 points)",
		"drill": "DRILL - core samples at rock outcrops (x2.0 points, hard pace)",
		"meter": "METER - deploy instruments (+3 points on every later walk)"
	}
	var y := 230.0
	for tool in ["camera", "drill", "meter"]:
		var t: String = tool
		var b := Pix.btn(overlay, "%s  %s" % [t.to_upper(), "SELECTED" if t in tools else ""],
			Vector2(330, y), Vector2(620, 44), func(): _toggle_tool(t))
		b.add_theme_font_size_override("font_size", 14)
		if t in tools:
			b.modulate = Color(0.5, 1.0, 0.7)
		Pix.lbl(overlay, String(descs[t]), Vector2(350, y + 48), Vector2(580, 20), 12, Pix.DIM)
		y += 82.0
	Pix.lbl(overlay, "Choose exactly 2 of 3 tools.", Vector2(330, 478), Vector2(620, 20), 13, Pix.DIM)
	Pix.btn(overlay, "CONFIRM >", Vector2(700, 512), Vector2(220, 46), confirm_prep)

func _toggle_tool(t: String) -> void:
	if t in tools:
		if tools.size() > 1:
			tools.erase(t)
	elif tools.size() < 2:
		tools.append(t)
	_show_prep_panel()

func confirm_prep() -> void:
	if tools.size() != 2:
		return
	in_prep = false
	Pix.clear(overlay)
	begin_walk()

func _nearest_item(radius: float) -> int:
	var best := -1
	var best_d := radius
	for i in items.size():
		var it: Dictionary = items[i]
		if pl.distance_to(it["pos"]) < best_d:
			best_d = pl.distance_to(it["pos"])
			best = i
	return best

func _nearest_outcrop(radius: float) -> int:
	var best := -1
	var best_d := radius
	for i in outcrops.size():
		if i in core_done:
			continue
		if pl.distance_to(outcrops[i]) < best_d:
			best_d = pl.distance_to(outcrops[i])
			best = i
	return best

func _nearest_deploy_site(radius: float) -> int:
	var best := -1
	var best_d := radius
	for i in deploy_sites.size():
		if i in deploy_used:
			continue
		if pl.distance_to(deploy_sites[i]) < best_d:
			best_d = pl.distance_to(deploy_sites[i])
			best = i
	return best

func _task_seconds(kind: String) -> float:
	return float(GameState.activities()["game"]["surface"]["tasks"][kind]["time_s"])

func _start_hold(kind: String, idx: int) -> void:
	hold_kind = kind
	hold_idx = idx
	task_hold = 0.0

func _process_hold(delta: float) -> void:
	var key_ok := Input.is_key_pressed(KEY_F) if hold_kind == "document" else Input.is_key_pressed(KEY_E)
	if not key_ok:
		# The task only counts while the key is held; releasing cancels it.
		info.text = "Cancelled."
		hold_kind = ""
		task_hold = 0.0
		hold_idx = -1
		return
	task_hold += delta
	var pace := "hard" if hold_kind == "core" else "easy"
	var applied := suit.step(delta, pace, false)
	hud_label.text = "WALK %d/%d  Time %02d  Stamina %d%%  %s" % [
		walk_idx, walks_total, int(maxf(0.0, t_left)), int(suit.fraction() * 100.0), String(applied).to_upper()]
	var label: String = {"document": "Photographing", "core": "Drilling core", "deploy": "Deploying"}.get(hold_kind, "Working")
	info.text = "%s... %d%%" % [label, int(minf(1.0, task_hold / _task_seconds(hold_kind)) * 100.0)]
	if task_hold >= _task_seconds(hold_kind):
		_complete_hold()

func _complete_hold() -> void:
	match hold_kind:
		"document":
			if hold_idx >= 0 and hold_idx < items.size():
				items[hold_idx]["documented"] = true
				info.text = "Sample site photographed. Collect it for x1.5 points."
		"core":
			if hold_idx >= 0 and hold_idx < outcrops.size() and not (hold_idx in core_done):
				core_done.append(hold_idx)
				var bonus := _core_multiplier() * float(res["regolith"]["pts"])
				points += bonus
				info.text = "Core sample drilled: +%d pts." % int(bonus)
		"deploy":
			if hold_idx >= 0 and hold_idx < deploy_sites.size() and not (hold_idx in deploy_used):
				deploy_used.append(hold_idx)
				deployed_count += 1
				info.text = "Instrument deployed. +3 pts on every later walk."
	hold_kind = ""
	task_hold = 0.0
	hold_idx = -1

func _check_hold_keys() -> void:
	var e_down := Input.is_key_pressed(KEY_E)
	var f_down := Input.is_key_pressed(KEY_F)
	if not _task_key_was_down:
		if e_down:
			var site := _nearest_deploy_site(TASK_RANGE)
			if site >= 0:
				_start_hold("deploy", site)
				_task_key_was_down = true
				return
			var outcrop := _nearest_outcrop(TASK_RANGE)
			if outcrop >= 0 and "drill" in tools:
				_start_hold("core", outcrop)
				_task_key_was_down = true
				return
		if f_down and "camera" in tools:
			var it := _nearest_item(DOC_RANGE)
			if it >= 0 and not bool(items[it].get("documented", false)):
				_start_hold("document", it)
				_task_key_was_down = true
				return
	_task_key_was_down = e_down or f_down

func _doc_multiplier() -> float:
	return float(GameState.activities()["game"]["surface"]["tasks"]["document"]["points_multiplier"])

func _core_multiplier() -> float:
	return float(GameState.activities()["game"]["surface"]["tasks"]["core"]["points_multiplier"])

# ---------- T18 walk lifecycle ----------

func begin_walk() -> void:
	walk_idx += 1
	in_rest = false
	in_final = false
	done = false
	jettison_open = false
	Pix.clear(overlay)
	core_done.clear()
	t_left = GameState.eva_seconds * _time_mult
	t_total = t_left
	if walk_idx > 1:
		var bonus := deployed_count * int(GameState.activities()["game"]["surface"]["tasks"]["deploy"]["points_per_later_eva"])
		points += float(bonus)
		if bonus > 0:
			info.text = "Deployed instruments: +%d pts this walk." % bonus
	_walk_start_pts = points
	suit = Stamina.create(_life_name, GameState.has_module("exercise"), GameState.stamina_capacity_mult())

func end_walk(reason: String) -> void:
	if done:
		return
	done = true
	hold_kind = ""
	task_hold = 0.0
	hold_idx = -1
	var elapsed := clampf(t_total - maxf(0.0, t_left), 0.0, t_total)
	total_elapsed += elapsed
	total_btu += suit.capacity_btu - suit.energy_btu
	walk_points.append(points - _walk_start_pts)
	_final_reason = reason
	if walk_idx < walks_total:
		_show_rest_panel(reason)
	else:
		_show_final_panel(reason)

func _show_rest_panel(reason: String) -> void:
	in_rest = true
	Pix.clear(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.86)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)
	Pix.panel(overlay, Vector2(340, 160), Vector2(600, 380))
	Pix.lbl(overlay, "WALK %d/%d COMPLETE" % [walk_idx, walks_total], Vector2(370, 176), Vector2(540, 36), 26, Pix.WARN)
	Pix.lbl(overlay, reason, Vector2(370, 216), Vector2(540, 26), 15, Pix.DIM)
	Pix.lbl(overlay, "This walk: %d science points. Running total: %d pts." % [int(walk_points.back()), int(points)],
		Vector2(370, 248), Vector2(540, 30), 16, Pix.TEXT)
	Pix.lbl(overlay, "Suit recharged during the rest. Collected samples stay on the surface.",
		Vector2(370, 284), Vector2(540, 24), 14, Pix.DIM)
	Pix.btn(overlay, "NEXT WALK %d/%d >" % [walk_idx + 1, walks_total], Vector2(370, 380), Vector2(280, 50), func():
		begin_walk())

func _show_final_panel(reason: String) -> void:
	in_final = true
	Pix.clear(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.86)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)
	Pix.panel(overlay, Vector2(340, 120), Vector2(600, 460))
	Pix.lbl(overlay, "EVA OVER", Vector2(370, 136), Vector2(540, 36), 28, Pix.WARN)
	Pix.lbl(overlay, reason, Vector2(370, 176), Vector2(540, 26), 15, Pix.DIM)
	var food_kcal := Stamina.eva_food_kcal(total_elapsed)
	Pix.lbl(overlay, "%d science points in %d s over %d walks. Suit energy used %d Btu (~%d kcal of extra food)." % [
		int(points), int(total_elapsed), walks_total, int(total_btu), int(food_kcal)],
		Vector2(370, 206), Vector2(540, 46), 16, Pix.TEXT)
	var walks_txt := "Points by walk: "
	for i in walk_points.size():
		walks_txt += ("%d" % int(walk_points[i])) + ("  |  " if i < walk_points.size() - 1 else "")
	Pix.lbl(overlay, walks_txt, Vector2(370, 258), Vector2(540, 22), 14, Pix.DIM)
	var y := 288.0
	for k in ["ice", "regolith", "ilmenite", "helium3"]:
		Pix.lbl(overlay, "%s  x%d  = %d pts" % [String(res[k]["name"]), int(counts.get(k, 0)), int(counts.get(k, 0)) * int(res[k]["pts"])],
			Vector2(370, y), Vector2(300, 22), 15, Pix.DIM)
		y += 22.0
	Pix.lbl(overlay, "Samples: %d pieces (%.0f kg). Mass counts against the return burn." % [_piece_total(), _sample_kg()],
		Vector2(370, 396), Vector2(540, 22), 14, Pix.DIM)
	Pix.btn(overlay, "JETTISON SAMPLES", Vector2(370, 448), Vector2(250, 50), func(): _show_jettison())
	Pix.btn(overlay, "BACK TO SHIP >", Vector2(640, 448), Vector2(210, 50), func():
		GameState.finish_explore(points, counts, total_btu, food_kcal, total_elapsed, _sample_kg(), walk_points.duplicate(), deployed_count)
		go("flight"))

func _piece_total() -> int:
	var total := 0
	for k in counts:
		total += int(counts[k])
	return total

func _sample_kg() -> float:
	return float(_piece_total()) * float(GameState.activities()["game"]["surface"].get("sample_kg_per_piece", 5.0))

func _show_jettison() -> void:
	jettison_open = true
	Pix.clear(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.86)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)
	Pix.panel(overlay, Vector2(320, 130), Vector2(640, 460))
	Pix.lbl(overlay, "JETTISON SAMPLES", Vector2(350, 148), Vector2(580, 36), 26, Pix.WARN)
	Pix.lbl(overlay, "Lighter is safer, but dropped samples lose their science. Real basis: Apollo 17 returned 110.4 kg.",
		Vector2(350, 190), Vector2(580, 30), 13, Pix.DIM)
	var y := 240.0
	var any := false
	for k in ["ice", "regolith", "ilmenite", "helium3"]:
		if int(counts.get(k, 0)) <= 0:
			continue
		any = true
		var kk: String = k
		var b := Pix.btn(overlay, "%s x%d: %s" % [String(res[k]["name"]), int(counts[k]), "KEEP" if bool(keep_flags[k]) else "DROP"],
			Vector2(350, y), Vector2(580, 44), func(): _toggle_keep(kk))
		if not bool(keep_flags[kk]):
			b.modulate = Color(1.0, 0.5, 0.5)
		y += 52.0
	if not any:
		Pix.lbl(overlay, "No samples on board.", Vector2(350, y), Vector2(580, 24), 14, Pix.DIM)
		y += 40.0
	Pix.btn(overlay, "DONE", Vector2(700, 516), Vector2(200, 46), func():
		_apply_jettison())

func _toggle_keep(k: String) -> void:
	keep_flags[k] = not bool(keep_flags[k])
	_show_jettison()

func _apply_jettison() -> void:
	for k in keep_flags:
		if not bool(keep_flags[k]) and int(counts.get(k, 0)) > 0:
			points -= float(counts[k]) * float(res[k]["pts"])
			counts[k] = 0
	jettison_open = false
	_show_final_panel(_final_reason)

func _spawn(rng: RandomNumberGenerator) -> void:
	# Ice: inside craters.
	for i in int(res["ice"]["count"]):
		items.append(_item("ice", _in_crater_point(rng)))
	# Helium-3: at most one per run, deep inside a crater.
	items.append(_item("helium3", _in_crater_point(rng)))
	# Ilmenite: near rock outcrops.
	for i in int(res["ilmenite"]["count"]):
		var o: Vector2 = outcrops[rng.randi() % outcrops.size()]
		var p := o + Vector2(rng.randf_range(36.0, 70.0) * (1 if rng.randf() < 0.5 else -1), rng.randf_range(-50.0, 50.0))
		items.append(_item("ilmenite", _clamp_ground(p)))
	# Regolith: common, anywhere that is not a crater.
	for i in int(res["regolith"]["count"]):
		var p := Vector2(0, 0)
		for attempt in 20:
			p = Vector2(60 + rng.randi() % 1160, GROUND_TOP + 40 + rng.randi() % 500)
			if not in_crater(p):
				break
		items.append(_item("regolith", p))

func _item(type: String, p: Vector2) -> Dictionary:
	return {"type": type, "pos": p, "pts": float(res[type]["pts"]), "slow": type == "ice" or type == "helium3", "documented": false}

func _in_crater_point(rng: RandomNumberGenerator) -> Vector2:
	var c: Dictionary = craters[rng.randi() % craters.size()]
	var ang := rng.randf() * TAU
	var rr := rng.randf() * (float(c["r"]) * 0.7)
	return _clamp_ground(Vector2(c["pos"]) + Vector2(cos(ang), sin(ang)) * rr)

func _clamp_ground(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, 40.0, 1240.0), clampf(p.y, GROUND_TOP + 30.0, 690.0))

func in_crater(p: Vector2) -> bool:
	for c in craters:
		if p.distance_to(c["pos"]) < float(c["r"]):
			return true
	return false

func _process(delta: float) -> void:
	if done:
		return
	t_left -= delta
	if hold_kind != "":
		_process_hold(delta)
	else:
		_process_movement(delta)
	if suit.is_empty():
		end_walk("The suit ran out of energy. The crew had to stop.")
	elif t_left <= 0.0:
		end_walk("The EVA clock ran out.")
	elif Input.is_key_pressed(KEY_SPACE):
		end_walk("The crew returned to the lander early.")
	queue_redraw()

func _process_movement(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1
	# Pace: 1 easy, 2 normal, 3 hard, Shift burst. Stationary time always drains at easy.
	pace_wanted = "normal"
	if Input.is_key_pressed(KEY_1):
		pace_wanted = "easy"
	elif Input.is_key_pressed(KEY_3):
		pace_wanted = "hard"
	if Input.is_key_pressed(KEY_SHIFT):
		pace_wanted = "burst"
	var moving := dir.length() > 0.01
	var applied := suit.step(delta, pace_wanted, moving)
	var speed := SLOW_SPEED if in_crater(pl) else SPEED
	speed *= Stamina.speed_mult(applied)
	pl += dir.normalized() * speed * delta
	pl = _clamp_ground(pl)
	for it in items.duplicate():
		if pl.distance_to(it["pos"]) < PICKUP:
			items.erase(it)
			var mult := _doc_multiplier() if bool(it.get("documented", false)) else 1.0
			var gained := float(it["pts"]) * mult
			points += gained
			counts[it["type"]] += 1
			Sfx.play("pickup")
			info.text = "%s  +%.0f pts%s" % [String(res[it["type"]]["name"]), gained, "  (photographed x1.5)" if mult > 1.0 else ""]
	_check_hold_keys()
	var reserve: bool = suit.in_reserve()
	hud_label.text = "WALK %d/%d  Time %02d  Stamina %d%%  %s%s" % [
		walk_idx, walks_total, int(maxf(0.0, t_left)), int(suit.fraction() * 100.0), String(applied).to_upper(),
		"  RESERVE" if reserve else ""]
	hud_label.add_theme_color_override("font_color", Pix.BAD if reserve else Pix.WARN)
	count_label.text = _counts_text()

func _counts_text() -> String:
	var parts: Array = []
	for k in ["ice", "regolith", "ilmenite", "helium3"]:
		parts.append("%s %d" % [String(res[k]["name"]), int(counts.get(k, 0))])
	return "  |  ".join(PackedStringArray(parts))

func draw_extra() -> void:
	draw_rect(Rect2(0, GROUND_TOP, 1280, 720 - GROUND_TOP), Color("6e6e78"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 160:
		draw_rect(Rect2(rng.randi() % 1280, GROUND_TOP + rng.randi() % int(720 - GROUND_TOP), 4, 4), Color("5a5a64"))
	for o in outcrops:
		draw_rect(Rect2(o.x - 26, o.y - 18, 52, 36), Color("4a4a52"))
		draw_rect(Rect2(o.x - 18, o.y - 26, 30, 20), Color("55555e"))
	for c in craters:
		draw_circle(c["pos"], float(c["r"]), Color("2b2b36"))
		draw_circle(c["pos"], float(c["r"]) - 10.0, Color("1c1c26"))
	for it in items:
		var p: Vector2 = it["pos"]
		match String(it["type"]):
			"ice":
				draw_rect(Rect2(p.x - 7, p.y - 7, 14, 14), Color("7fe3ff"))
				draw_rect(Rect2(p.x - 3, p.y - 3, 6, 6), Color.WHITE)
			"regolith":
				draw_rect(Rect2(p.x - 6, p.y - 6, 12, 12), Color("ffd166"))
			"ilmenite":
				draw_rect(Rect2(p.x - 7, p.y - 7, 14, 14), Color("d98a3d"))
				draw_rect(Rect2(p.x - 3, p.y - 3, 6, 6), Color("f0c090"))
			"helium3":
				draw_rect(Rect2(p.x - 8, p.y - 8, 16, 16), Color("e8e05a"))
				draw_rect(Rect2(p.x - 4, p.y - 4, 8, 8), Color("fff8b0"))
	# lander
	draw_rect(Rect2(620, 370, 40, 8), Color("cfcfcf"))
	# astronaut
	draw_rect(Rect2(pl.x - 8, pl.y - 18, 16, 20), Color("f2f2f2"))
	draw_rect(Rect2(pl.x - 6, pl.y - 26, 12, 10), Color("ffe8b0"))
	draw_rect(Rect2(pl.x - 4, pl.y - 24, 8, 5), Color("1fb6ff"))
	# T18: deploy sites (posts) and drilled outcrops
	for i in deploy_sites.size():
		var s: Vector2 = deploy_sites[i]
		var used := i in deploy_used
		draw_rect(Rect2(s.x - 6, s.y - 14, 12, 12), Pix.GOOD if used else Pix.WARN)
		draw_rect(Rect2(s.x - 1, s.y - 14, 2, 20), Color("e8f1ff"))
	for oi in core_done:
		draw_circle(outcrops[oi], 9, Color("d98a3d"))
	# documented marker (small ring above the sample)
	for it in items:
		if bool(it.get("documented", false)):
			draw_circle(Vector2(it["pos"].x, it["pos"].y - 16), 5, Color("7fe3ff"))
	# suit stamina bar (top right, under the clock)
	if suit != null:
		var f := clampf(suit.fraction(), 0.0, 1.0)
		var col := Pix.GOOD if f > 0.35 else (Pix.WARN if f > 0.15 else Pix.BAD)
		draw_rect(Rect2(978, 46, 284, 18), Color("0b1026"))
		draw_rect(Rect2(978, 46, 284 * f, 18), col)
		draw_rect(Rect2(978, 46, 284, 1), Color("e8f1ff"))
		draw_rect(Rect2(978, 63, 284, 1), Color("e8f1ff"))
		draw_rect(Rect2(978, 46, 1, 18), Color("e8f1ff"))
		draw_rect(Rect2(1261, 46, 1, 18), Color("e8f1ff"))
