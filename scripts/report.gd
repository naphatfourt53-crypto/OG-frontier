extends Screen
# Screen 7 - Mission report: explains WHY it worked or failed. Lets the player modify and rerun.

func build() -> void:
	star_seed = 71
	var r: Dictionary = GameState.last_report
	if r.is_empty():
		go("station")
		return
	var ok: bool = r["success"]
	var a: Dictionary = r["a"]
	Sfx.play("success" if ok else "fail")
	Pix.lbl(self, "MISSION REPORT", Vector2(20, 12), Vector2(500, 34), 26, Pix.EDGE)
	Pix.lbl(self, "MISSION COMPLETE" if ok else "GAME OVER: " + String(r["reason"]).to_upper(), Vector2(20, 52), Vector2(900, 50), 38, Pix.GOOD if ok else Pix.BAD)
	var why := ""
	if ok:
		why = "The crew landed, collected ore for the Helios smelter, and returned home. Every system stayed inside its limits."
	else:
		var info: Dictionary = GameState.REASONS[r["reason"]]
		why = "WHY: %s\nDETAIL: %s\nHOW TO FIX: %s" % [info["why"], r["detail"], info["fix"]]
	Pix.lbl(self, why, Vector2(20, 108), Vector2(800, 110), 16)
	# six resources (official challenge criteria)
	Pix.panel(self, Vector2(20, 230), Vector2(600, 270))
	Pix.lbl(self, "RESOURCES", Vector2(34, 236), Vector2(300, 24), 18, Pix.WARN)
	var rows := [
		"Mass:   %.1f t launched (limit %.0f t)" % [a["total_kg"] / 1000.0, a["mass_cap_kg"] / 1000.0],
		"Power:  worst margin %+.1f kW (%.1f made, %.1f used)" % [r["min_net"], a["gen_solar"] + a["gen_other"], a["use"]],
		"Budget: %.0f spent of %.0f" % [a["cost"], a["budget"]],
		"Data:   +%d science (comm quality %d%%)" % [int(r["data_gain"]), int(a["comm_q"] * 100.0)],
		"Comms:  %d%% link quality" % int(a["comm_q"] * 100.0),
		"Time:   %.0f days (plan %.0f)" % [r["day"], GameState.mission_days(GameState.mission(r["mission"]))],
		"Hull:   %d%%" % int(maxf(0.0, r["hull"]))
	]
	var y := 268.0
	for t in rows:
		Pix.lbl(self, t, Vector2(34, y), Vector2(580, 24), 16)
		y += 30.0
	# burns
	Pix.panel(self, Vector2(640, 230), Vector2(620, 290))
	Pix.lbl(self, "BURNS (rocket equation)", Vector2(654, 236), Vector2(400, 24), 18, Pix.WARN)
	y = 268.0
	for l in r["legs"]:
		var good: bool = l["ok"]
		Pix.lbl(self, "%s %s: need %.1f t, had %.1f t" % ["OK " if good else "FAIL", l["name"], l["need_t"], l["have_t"]], Vector2(654, y), Vector2(590, 24), 15, Pix.GOOD if good else Pix.BAD)
		y += 28.0
	Pix.lbl(self, "Delta-v: %.2f km/s available, %.2f needed.\nm_prop = m_f (e^(dv / (Isp*g0)) - 1)" % [a["dv"], a["dv_need"]], Vector2(654, y + 8), Vector2(590, 60), 14, Pix.DIM)
	# station support and EVA cost: shows that prep and the ISS farm changed this run
	Pix.lbl(self, "SUPPORT", Vector2(654, 418), Vector2(200, 18), 14, Pix.WARN)
	var scout_txt := "scout READY" if bool(r.get("scout", false)) else "no scout"
	var rad_txt := "rad kit READY" if float(r.get("rad_mult", 1.0)) < 0.99 else "no rad kit"
	var suit_used := float(r.get("stamina_btu", 0.0))
	var kcal := float(r.get("eva_food_kcal", 0.0))
	var sup := [
		"ISS food offset: %.1f kg   |   %s, %s" % [float(r.get("food_store_used", 0.0)), scout_txt, rad_txt],
		"EVA suit: %d Btu used (%d kcal extra food)" % [int(suit_used), int(kcal)] if suit_used > 0.0 else "EVA suit: not used on this run",
		"Helios smelter: %d / %d pts (%.0f%%)" % [GameState.smelter_points(),
			int(GameState.C.get("smelter_target", 165)), GameState.smelter_pct() * 100.0]
	]
	var sy := 438.0
	for t in sup:
		Pix.lbl(self, t, Vector2(654, sy), Vector2(590, 18), 12, Pix.DIM)
		sy += 18.0
	# T18: samples returned, instrument deploys, points per walk
	var walks: Array = r.get("walks_log", [])
	if not walks.is_empty():
		var wtxt := "Points by walk: "
		for i in walks.size():
			wtxt += str(int(walks[i])) + ("  |  " if i < walks.size() - 1 else "")
		Pix.lbl(self, wtxt, Vector2(654, sy), Vector2(590, 18), 12, Pix.DIM)
		sy += 18.0
	Pix.lbl(self, "Samples returned: %.0f kg (%d pieces)  |  Instruments deployed: %d" % [
		float(r.get("sample_kg", 0.0)), _piece_count(r), int(r.get("deploys", 0))],
		Vector2(654, sy), Vector2(590, 18), 12, Pix.DIM)
	sy += 18.0
	# moon samples collected during the EVA
	Pix.lbl(self, _samples_text(r), Vector2(20, 506), Vector2(1240, 44), 15, Pix.TEXT)
	# decisions + score
	var dec := "Decisions: " + ("none" if r["decisions"].is_empty() else "; ".join(PackedStringArray(r["decisions"])))
	Pix.lbl(self, dec, Vector2(20, 550), Vector2(1240, 40), 13, Pix.DIM)
	var prev := ""
	if GameState.history.size() >= 2:
		var p: Dictionary = GameState.history[GameState.history.size() - 2]
		prev = "   |   Previous run: %d" % int(p["score"])
	Pix.lbl(self, "SCORE %d   |   Best %d%s   |   Seed %d" % [int(r["score"]), GameState.best_score, prev, GameState.seed_value], Vector2(20, 586), Vector2(1240, 30), 20, Pix.WARN)
	if ok:
		Pix.lbl(self, "DEMO COMPLETE - Mars unlocked! Use your new Data to grow the station.", Vector2(20, 616), Vector2(1240, 30), 18, Pix.GOOD)
	Pix.btn(self, "Modify ship & rerun (same seed)", Vector2(20, 650), Vector2(360, 48), func(): go("hangar"))
	Pix.btn(self, "New seed, change ship", Vector2(390, 650), Vector2(280, 48), func():
		GameState.new_seed()
		go("hangar"))
	Pix.btn(self, "Back to station", Vector2(990, 650), Vector2(270, 48), func(): go("station"))
	var ok_photo: bool = bool(GameState.last_report["success"])
	Pix.lbl(self, "Apollo 11 on the Moon - NASA (public domain)" if ok_photo else "Apollo 11 EVA - NASA (public domain)",
		Vector2(1000, 166), Vector2(262, 18), 11, Color(0.55, 0.62, 0.78))

func draw_extra() -> void:
	if GameState.last_report.is_empty():
		return
	var path := Pix.NASA_LANDER if bool(GameState.last_report["success"]) else Pix.NASA_ASTRONAUT
	Pix.photo_frame(self, path, Rect2(1000, 8, 260, 150), 0.15)

func back_scene() -> String:
	return "station"

func _samples_text(r: Dictionary) -> String:
	var counts: Dictionary = r.get("explore_counts", {})
	var res: Dictionary = GameState.data["moon_resources"]
	var parts: Array = []
	var total := 0
	for k in ["ice", "regolith", "ilmenite", "helium3"]:
		var n := int(counts.get(k, 0))
		var pts := n * int(res[k]["pts"])
		total += pts
		parts.append("%s x%d = %d" % [res[k]["name"], n, pts])
	return "MOON SAMPLES (%d s EVA):  %s  |  total %d pts" % [int(float(r.get("eva_time", GameState.eva_seconds))), "  |  ".join(PackedStringArray(parts)), total]

func _piece_count(r: Dictionary) -> int:
	var counts: Dictionary = r.get("explore_counts", {})
	var total := 0
	for k in counts:
		total += int(counts[k])
	return total
