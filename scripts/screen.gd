class_name Screen
extends Control
# Base class for every screen. Subclasses override build() and optionally draw_extra().
# Also owns the 0.25 s scene fade and the shared Esc/Enter keyboard handling.

var star_seed: int = 7
var _leaving: bool = false

const FADE_OUT := 0.12
const FADE_IN := 0.13
const FADE_COLOR := Color(0.02, 0.03, 0.08)

func _ready() -> void:
	theme = Pix.make_theme()
	# The scene root already uses full-rect anchors; forcing a size here fights the
	# layout pass (Godot 4.7 warns about it). Let the anchors do the work instead.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build()
	queue_redraw()
	if GameState.pending_fade:
		GameState.pending_fade = false
		_fade_in()

func build() -> void:
	pass

func draw_extra() -> void:
	pass

func _draw() -> void:
	Pix.stars(self, star_seed)
	draw_extra()

# Override on screens that have a "back" destination. Empty string = Esc does nothing.
func back_scene() -> String:
	return ""

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var back := back_scene()
		if back != "":
			get_viewport().set_input_as_handled()
			go(back)

func go(scene_name: String) -> void:
	if _leaving:
		return
	_leaving = true
	var layer := CanvasLayer.new()
	layer.layer = 128
	add_child(layer)
	var rect := ColorRect.new()
	rect.color = Color(FADE_COLOR.r, FADE_COLOR.g, FADE_COLOR.b, 0.0)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(rect)
	var tw := create_tween()
	tw.tween_property(rect, "color:a", 1.0, FADE_OUT)
	await tw.finished
	GameState.pending_fade = true
	get_tree().change_scene_to_file("res://scenes/%s.tscn" % scene_name)

func _fade_in() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 128
	add_child(layer)
	var rect := ColorRect.new()
	rect.color = Color(FADE_COLOR.r, FADE_COLOR.g, FADE_COLOR.b, 1.0)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	var tw := create_tween()
	tw.tween_property(rect, "color:a", 0.0, FADE_IN)
	tw.tween_callback(func(): layer.queue_free())
