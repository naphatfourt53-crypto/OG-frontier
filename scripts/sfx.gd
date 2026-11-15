extends Node
# Small sound-effect player (autoload "Sfx").
# Sound files are CC0 retro SFX (see assets/CREDITS.md). Eight pooled players let
# short sounds overlap without cutting each other off, and every call no-ops when
# the player has muted sound in Settings or when a file is missing.

const PATHS := {
	"click": "res://assets/sfx/click.wav",
	"launch": "res://assets/sfx/launch.wav",
	"pickup": "res://assets/sfx/pickup.wav",
	"build": "res://assets/sfx/build.wav",
	"damage": "res://assets/sfx/damage.wav",
	"success": "res://assets/sfx/success.wav",
	"fail": "res://assets/sfx/fail.wav",
}

const VOLUME_DB := {
	"click": -14.0,
	"launch": -4.0,
	"pickup": -8.0,
	"build": -7.0,
	"damage": -6.0,
	"success": -3.0,
	"fail": -5.0,
}

const POOL := 8

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _enabled: bool = true

func _ready() -> void:
	# Headless CI has a dummy audio driver; skip loading streams so test runs exit
	# without dangling AudioStreamPlayback objects.
	_enabled = DisplayServer.get_name() != "headless"
	if not _enabled:
		return
	for key in PATHS:
		var path: String = PATHS[key]
		if ResourceLoader.exists(path):
			_streams[key] = load(path)
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

func play(key: String) -> void:
	if not _enabled or not GameState.sound_on:
		return
	var stream: AudioStream = _streams.get(key)
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.volume_db = float(VOLUME_DB.get(key, -6.0))
	p.play()

func has(key: String) -> bool:
	return _streams.has(key)

func _exit_tree() -> void:
	# Release the pooled players and cached streams so headless test runs exit cleanly.
	for p in _players:
		p.stop()
		p.stream = null
	_streams.clear()
	_players.clear()
