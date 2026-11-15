extends Screen
# Screen 1 - Main menu, plus the settings overlay (EVA length, tutorial replay).

var settings_box: Control

func build() -> void:
	star_seed = 11
	Pix.lbl(self, "LAST LAUNCH", Vector2(80, 90), Vector2(700, 80), 64, Pix.EDGE)
	Pix.lbl(self, "OG-Frontier  |  Space Mission Design Game (prototype)", Vector2(84, 175), Vector2(700, 30), 18, Pix.DIM)
	Pix.lbl(self, "2031. Heat domes and failed harvests have made Earth nearly uninhabitable. The ISS is humanity's last home. Design a ship, pick a mission, survive the trip, and bring back the ore that finishes the Helios smelter.",
		Vector2(84, 225), Vector2(560, 100), 18, Pix.TEXT)
	Pix.btn(self, "START", Vector2(84, 338), Vector2(260, 50), start_game)
	Pix.btn(self, "HOW TO PLAY", Vector2(84, 394), Vector2(125, 40), func(): go("tutorial"))
	Pix.btn(self, "STORY", Vector2(219, 394), Vector2(125, 40), func(): go("story"))
	Pix.btn(self, "SETTINGS", Vector2(84, 440), Vector2(260, 40), open_settings)
	Pix.btn(self, "RESET SAVE", Vector2(84, 486), Vector2(260, 40), func():
		GameState.wipe_save()
		go("menu"))
	Pix.btn(self, "QUIT", Vector2(84, 532), Vector2(260, 40), func(): get_tree().quit())
	var hist := "Best %d   |   Data %d   |   Runs %d\n" % [GameState.best_score, GameState.station_data, GameState.history.size()]
	if GameState.history.is_empty():
		hist += "No runs yet."
	else:
		var first: int = maxi(0, GameState.history.size() - 4)
		for i in range(first, GameState.history.size()):
			var h: Dictionary = GameState.history[i]
			var tag := "OK  " if h["success"] else "FAIL"
			hist += "%s  score %d  seed %d  %s\n" % [tag, int(h["score"]), int(h["seed"]), String(h["reason"])]
	Pix.lbl(self, hist, Vector2(84, 578), Vector2(560, 130), 12, Pix.DIM)
	Pix.lbl(self, "Mouse for menus  |  WASD / arrows on the Moon  |  Enter = continue  |  Esc = back", Vector2(620, 692), Vector2(640, 20), 13, Pix.DIM)
	Pix.lbl(self, "Earthrise, Apollo 8 - NASA (public domain)  |  see assets/CREDITS.md", Vector2(620, 670), Vector2(640, 18), 11, Color(0.55, 0.62, 0.78))

func start_game() -> void:
	# First launch gets the three-slide briefing; afterwards START goes straight to the ISS.
	if GameState.story_seen:
		go("station")
	else:
		go("story")

# ---------- settings ----------

func open_settings() -> void:
	if settings_box != null:
		return
	settings_box = Control.new()
	settings_box.size = Vector2(1280, 720)
	add_child(settings_box)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.85)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_box.add_child(dim)
	Pix.panel(settings_box, Vector2(320, 150), Vector2(640, 420))
	Pix.lbl(settings_box, "SETTINGS", Vector2(350, 172), Vector2(500, 36), 26, Pix.EDGE)

	Pix.lbl(settings_box, "Moon walk time (EVA)", Vector2(350, 232), Vector2(300, 24), 18, Pix.WARN)
	var value_lbl := Pix.lbl(settings_box, "%d s" % int(GameState.eva_seconds), Vector2(760, 232), Vector2(160, 24), 18, Pix.TEXT)
	var slider := HSlider.new()
	slider.position = Vector2(350, 264)
	slider.size = Vector2(570, 24)
	slider.min_value = 30.0
	slider.max_value = 300.0
	slider.step = 15.0
	slider.value = GameState.eva_seconds
	slider.value_changed.connect(func(v: float):
		GameState.eva_seconds = v
		value_lbl.text = "%d s" % int(v))
	settings_box.add_child(slider)
	Pix.lbl(settings_box, "60 s matches the demo script. A longer walk gives more time to sample the surface. In reality an Apollo EVA lasted 4-8 hours outside.",
		Vector2(350, 296), Vector2(580, 60), 14, Pix.DIM)

	Pix.btn(settings_box, "Replay tutorial", Vector2(350, 380), Vector2(240, 44), func():
		close_settings()
		go("tutorial"))
	Pix.btn(settings_box, "CLOSE", Vector2(610, 380), Vector2(240, 44), close_settings)
	var sound_btn := Pix.btn(settings_box, _sound_label(), Vector2(350, 434), Vector2(240, 40), func(): pass)
	sound_btn.tooltip_text = "Toggle all sound effects (the setting is saved)"
	sound_btn.pressed.connect(func(): toggle_sound(sound_btn))
	Pix.lbl(settings_box, "Save data: user://ogfrontier_save.json (save_version %d)" % GameState.SAVE_VERSION,
		Vector2(350, 500), Vector2(580, 24), 13, Pix.DIM)

func _sound_label() -> String:
	return "Sound: ON" if GameState.sound_on else "Sound: OFF"

func toggle_sound(b: Button) -> void:
	GameState.sound_on = not GameState.sound_on
	b.text = _sound_label()
	if GameState.sound_on:
		Sfx.play("click")  # confirm the sound is back
	GameState.save_game()

func close_settings() -> void:
	GameState.save_game()
	if settings_box != null:
		settings_box.queue_free()
		settings_box = null

func draw_extra() -> void:
	# Full-bleed archival photo; if the asset is missing we keep the code-drawn horizon
	# so the menu never depends on files being present.
	if not Pix.photo(self, Pix.NASA_MENU, Rect2(0, 0, 1280, 720), 0.38):
		draw_circle(Vector2(640, 1100), 560, Color("1d4e9e"))
		draw_circle(Vector2(640, 1100), 540, Color("2a7bd4"))
		draw_rect(Rect2(500, 560, 80, 16), Color("3fae5a"))
		draw_rect(Rect2(720, 575, 100, 14), Color("3fae5a"))
	# big pixel ship on top of the photo
	var d := {"cockpit": 2, "engine": 2, "tank": 2, "life": 2, "power": 1, "storage": 1, "comms": 2}
	Pix.draw_ship(self, Vector2(1040, 110), d, 9.0, true)
