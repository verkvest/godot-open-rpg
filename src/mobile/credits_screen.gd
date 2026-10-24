## In-game credits. The same notices live in THIRD_PARTY_LICENSES.md.
extends Control


var _margin: MarginContainer


func _ready() -> void:
	add_to_group("hide_touch_controls")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_offsets_preset(Control.PRESET_FULL_RECT)
	get_viewport().size_changed.connect(_apply_safe_margins)
	
	var background := ColorRect.new()
	background.color = Color(0.05, 0.1, 0.12)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	
	_margin = MarginContainer.new()
	_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_margin)
	_apply_safe_margins()
	
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	_margin.add_child(column)
	
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 24)
	column.add_child(header)
	
	var title := Label.new()
	title.text = "Credits & licenses"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_override("font", MobileUI.FONT)
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.98, 0.9, 0.62))
	header.add_child(title)
	
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(220, 100)
	MobileUI.style_button(back, 44)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://src/mobile/title_screen.tscn"))
	header.add_child(back)
	
	var body := RichTextLabel.new()
	body.bbcode_enabled = false
	body.scroll_active = true
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_override("normal_font", MobileUI.FONT)
	body.add_theme_font_size_override("normal_font_size", 28)
	body.add_theme_color_override("default_color", Color(0.9, 0.93, 0.9))
	body.text = _license_text()
	column.add_child(body)


func _apply_safe_margins() -> void:
	if _margin == null:
		return
	var safe := Vector4.ZERO
	if is_instance_valid(TouchControls):
		safe = TouchControls.viewport_insets()
	_margin.add_theme_constant_override("margin_left", int(safe.x) + 64)
	_margin.add_theme_constant_override("margin_top", int(safe.y) + 36)
	_margin.add_theme_constant_override("margin_right", int(safe.z) + 64)
	_margin.add_theme_constant_override("margin_bottom", int(safe.w) + 36)


func _license_text() -> String:
	var path := "res://THIRD_PARTY_LICENSES.md"
	if FileAccess.file_exists(path):
		var text := FileAccess.get_file_as_string(path)
		if not text.is_empty():
			return text
	return "Quillfen\nSee THIRD_PARTY_LICENSES.md in the project for full notices."
