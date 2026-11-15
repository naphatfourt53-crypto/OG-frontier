extends SceneTree
# Checks that every sound file imports, has a non-zero length and starts playing.
# Needs a real audio device, so do NOT pass --headless:
#   Godot_v4.7.2-stable_win64.exe --path . -s tools/audio_check.gd
# Prints AUDIO OK, or AUDIO FAIL <n> and exits non-zero. Never writes the save.

const KEYS := ["click", "launch", "pickup", "build", "damage", "success", "fail"]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var gs := root.get_node_or_null("GameState")
	var sfx := root.get_node_or_null("Sfx")
	if gs == null or sfx == null:
		print("AUDIO FAIL: autoload missing")
		quit(1)
		return
	gs.skip_save = true
	gs.sound_on = true
	var fails := 0
	for k in KEYS:
		if not sfx.has(k):
			print("  %-8s MISSING" % k)
			fails += 1
			continue
		sfx.play(k)
		var playing := false
		var length := 0.0
		for p in sfx.get_children():
			if p is AudioStreamPlayer and p.playing:
				playing = true
				length = p.stream.get_length()
		print("  %-8s %s  %.2f s" % [k, "ok" if playing else "SILENT", length])
		if not playing or length <= 0.0:
			fails += 1
		await create_timer(0.05).timeout
	if fails == 0:
		print("AUDIO OK (%d sounds)" % KEYS.size())
	else:
		print("AUDIO FAIL (%d)" % fails)
	quit(1 if fails > 0 else 0)
