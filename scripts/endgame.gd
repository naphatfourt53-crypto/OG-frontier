extends Screen
# Screen - campaign result. WIN: all eight missions done and the 180-day epilogue has passed.
# LOSE: the Earth deadline arrived first. Shows what was done and when, from the save.

func build() -> void:
	star_seed = 91
	var ui := Control.new()
	ui.size = Vector2(1280, 720)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	var won: bool = bool(GameState.campaign.get("won", false))
	var done: Dictionary = GameState.campaign["done"]
	Pix.panel(ui, Vector2(28, 22), Vector2(1224, 676))
	Pix.lbl(ui, "CAMPAIGN RESULT", Vector2(56, 36), Vector2(600, 30), 20, Pix.EDGE)
	if won:
		Pix.lbl(ui, "EARTH IS STABLE", Vector2(56, 70), Vector2(1100, 64), 52, Pix.GOOD)
		Pix.lbl(ui, "All eight missions are complete. The epilogue ran its full 180 days: the Helios smelter and the outer-planet data give Earth a stable future.",
			Vector2(56, 142), Vector2(1100, 50), 16, Pix.TEXT)
	else:
		Pix.lbl(ui, "THE EARTH DEADLINE HAS PASSED", Vector2(56, 70), Vector2(1100, 64), 46, Pix.BAD)
		Pix.lbl(ui, "%d of %d missions were done before the deadline (day %d). Try a different order: the windows and transit times decide how many probes fit." % [
			done.size(), GameState.TOTAL_MISSIONS, int(Campaign.deadline_days())], Vector2(56, 142), Vector2(1100, 50), 16, Pix.TEXT)
	# Mission list with the day each one was finished.
	Pix.panel(ui, Vector2(56, 210), Vector2(560, 440))
	Pix.lbl(ui, "MISSIONS", Vector2(76, 222), Vector2(520, 24), 18, Pix.WARN)
	var y := 258.0
	for mid in Campaign.cfg()["campaign"]["order"]:
		var mid_s := String(mid)
		var name_s := "Moon - crewed Lunar Ice Survey" if mid_s == "moon" else String(Campaign.probe(mid_s)["name"])
		if done.has(mid_s):
			Pix.lbl(ui, "[x]  %s   day %d" % [name_s, int(done[mid_s])], Vector2(76, y), Vector2(520, 22), 16, Pix.GOOD)
		else:
			Pix.lbl(ui, "[ ]  %s   not done" % name_s, Vector2(76, y), Vector2(520, 22), 16, Pix.DIM)
		y += 40.0
	# Totals and the last log lines.
	Pix.panel(ui, Vector2(640, 210), Vector2(600, 440))
	Pix.lbl(ui, "RECORD", Vector2(660, 222), Vector2(560, 24), 18, Pix.WARN)
	Pix.lbl(ui, "Final day: %d   (deadline %d)" % [GameState.day, int(Campaign.deadline_days())], Vector2(660, 258), Vector2(560, 22), 15, Pix.TEXT)
	Pix.lbl(ui, "Data: %d   |   Gas to the smelter: %d   |   Best score: %d" % [
		GameState.station_data, int(GameState.campaign.get("gas", 0)), GameState.best_score], Vector2(660, 284), Vector2(560, 22), 15, Pix.TEXT)
	if int(GameState.campaign.get("end_day", 0)) > 0:
		var last := 0
		for k in done:
			last = maxi(last, int(done[k]))
		Pix.lbl(ui, "Last mission done on day %d. Epilogue ends on day %d." % [last, int(GameState.campaign["end_day"])],
			Vector2(660, 310), Vector2(560, 22), 15, Pix.DIM)
	Pix.lbl(ui, "LOG", Vector2(660, 344), Vector2(560, 20), 14, Pix.WARN)
	var entries: Array = GameState.campaign["log"]
	var ly := 370.0
	for i in range(maxi(0, entries.size() - 12), entries.size()):
		Pix.lbl(ui, String(entries[i]), Vector2(660, ly), Vector2(560, 30), 12, Pix.TEXT)
		ly += 28.0
	Pix.btn_ghost(ui, "Back to station", Vector2(56, 660), Vector2(240, 44), func(): go("station"))
	Pix.btn_primary(ui, "NEW CAMPAIGN", Vector2(1000, 660), Vector2(240, 44), _new_campaign)

func _new_campaign() -> void:
	GameState.wipe_save()
	go("station")

func back_scene() -> String:
	return "station"
