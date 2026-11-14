class_name Screen
extends Control
# Base class for every screen. Subclasses override build() and optionally draw_extra().

var star_seed: int = 7

func _ready() -> void:
	theme = Pix.make_theme()
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	build()
	queue_redraw()

func build() -> void:
	pass

func draw_extra() -> void:
	pass

func _draw() -> void:
	Pix.stars(self, star_seed)
	draw_extra()

func go(scene_name: String) -> void:
	get_tree().change_scene_to_file("res://scenes/%s.tscn" % scene_name)
