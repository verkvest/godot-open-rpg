## Landscape title. Play starts a fresh demo; Credits lists third-party notices.
extends Control

const GAME_SCENE := "res://src/main.tscn"
const CREDITS_SCENE := "res://src/mobile/credits_screen.tscn"


func _ready() -> void:
	add_to_group("hide_touch_controls")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var background := ColorRect.new()
	background.color = Color(0.04, 0.12, 0.14)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	
	var wash := ColorRect.new()
	wash.color = Color(0.09, 0.28, 0.24, 0.55)
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	wash.anchor_top = 0.62
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)
	
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 72)
	margin.add_theme_constant_override("margin_right", 72)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 36)
	add_child(margin)
	
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 48)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(row)
	
	var mark := TextureRect.new()
	mark.texture = load("res://assets/gui/icons/quillfen_1024.png")
	mark.custom_minimum_size = Vector2(280, 280)
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(mark)
	
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(column)
	
	var title := Label.new()
	title.text = "QUILLFEN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_override("font", MobileUI.FONT)
	title.add_theme_font_size_override("font_size", 120)
	title.add_theme_color_override("font_color", Color(0.98, 0.9, 0.62))
	title.add_theme_constant_override("outline_size", 18)
	title.add_theme_color_override("font_outline_color", Color(0.05, 0.1, 0.12))
	column.add_child(title)
	
	var subtitle := Label.new()
	subtitle.text = "A short turn-based tale"
	subtitle.add_theme_font_override("font", MobileUI.FONT)
	subtitle.add_theme_font_size_override("font_size", 42)
	subtitle.add_theme_color_override("font_color", Color(0.86, 0.92, 0.88))
	column.add_child(subtitle)
	
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 24)
	column.add_child(buttons)
	
	var play := Button.new()
	play.text = "Play"
	play.custom_minimum_size = Vector2(280, 120)
	MobileUI.style_button(play, 56)
	play.pressed.connect(_on_play)
	buttons.add_child(play)
	
	var credits := Button.new()
	credits.text = "Credits"
	credits.custom_minimum_size = Vector2(280, 120)
	MobileUI.style_button(credits, 56)
	credits.pressed.connect(func() -> void: get_tree().change_scene_to_file(CREDITS_SCENE))
	buttons.add_child(credits)
	
	var hint := Label.new()
	hint.text = "Tap the ground to walk, or use the pad.\nTap a person to talk. In battle, tap a command."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hint.add_theme_font_override("font", MobileUI.FONT)
	hint.add_theme_font_size_override("font_size", 32)
	hint.add_theme_color_override("font_color", Color(0.78, 0.86, 0.82))
	column.add_child(hint)
	
	if is_instance_valid(Music):
		Music.play(load("res://assets/music/the_fun_run.mp3"), 0.6)


func _on_play() -> void:
	if Cutscene._is_cutscene_in_progress:
		Cutscene._is_cutscene_in_progress = false
	if is_instance_valid(Player.gamepiece):
		Player.gamepiece = null
	Dialogic.VAR.reset()
	var inventory_path := ProjectSettings.globalize_path("user://inventory.tres")
	if FileAccess.file_exists(inventory_path):
		DirAccess.remove_absolute(inventory_path)
	get_tree().change_scene_to_file(GAME_SCENE)
