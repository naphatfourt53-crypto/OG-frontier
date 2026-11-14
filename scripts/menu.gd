extends Screen
# Screen 1 - Main menu

func build() -> void:
	star_seed = 11
	Pix.lbl(self, "LAST LAUNCH", Vector2(80, 90), Vector2(700, 80), 64, Pix.EDGE)
	Pix.lbl(self, "OG-Frontier  |  Space Mission Design Game (prototype)", Vector2(84, 175), Vector2(700, 30), 18, Pix.DIM)
	Pix.lbl(self, "Earth is nearly uninhabitable. Your station is humanity's last home. Design a ship, pick a mission, survive the trip, and bring back the data that lets the station grow.",
		Vector2(84, 225), Vector2(560, 100), 18, Pix.TEXT)
	Pix.btn(self, "START", Vector2(84, 360), Vector2(260, 56), func(): go("station"))
	Pix.btn(self, "RESET SAVE", Vector2(84, 430), Vector2(260, 44), func():
		GameState.wipe_save()
		go("menu"))
	Pix.btn(self, "QUIT", Vector2(84, 490), Vector2(260, 44), func(): get_tree().quit())
	var hist := "Best score: %d\nData in station: %d\n\nRecent runs:\n" % [GameState.best_score, GameState.station_data]
	if GameState.history.is_empty():
		hist += "  (none yet)"
	for h in GameState.history:
		var tag := "OK  " if h["success"] else "FAIL"
		hist += "  %s  score %d  seed %d  %s\n" % [tag, int(h["score"]), int(h["seed"]), String(h["reason"])]
	Pix.lbl(self, hist, Vector2(84, 560), Vector2(560, 150), 14, Pix.DIM)
	Pix.lbl(self, "Controls: mouse for menus, WASD / arrow keys during the Moon walk.", Vector2(700, 680), Vector2(560, 30), 14, Pix.DIM)

func draw_extra() -> void:
	# big pixel ship
	var d := {"cockpit": 2, "engine": 2, "tank": 2, "life": 2, "power": 1, "storage": 1, "comms": 2}
	Pix.draw_ship(self, Vector2(960, 110), d, 9.0, true)
	# Earth horizon
	draw_circle(Vector2(640, 1100), 560, Color("1d4e9e"))
	draw_circle(Vector2(640, 1100), 540, Color("2a7bd4"))
	draw_rect(Rect2(500, 560, 80, 16), Color("3fae5a"))
	draw_rect(Rect2(720, 575, 100, 14), Color("3fae5a"))
