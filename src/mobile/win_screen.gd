## Clear ending overlay. The lunge animation fades this layer in; the button returns to the title.
extends CanvasLayer


func _ready() -> void:
	var box := $ColorRect/VBoxContainer/VBoxContainer as VBoxContainer
	box.add_theme_constant_override("separation", 28)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var title := box.get_node("Label") as Label
	title.text = "THE FEN IS QUIET"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if title.label_settings:
		title.label_settings = title.label_settings.duplicate()
		title.label_settings.font = MobileUI.FONT
		title.label_settings.font_size = 92
		title.label_settings.font_color = Color(0.98, 0.9, 0.62)
	
	var body := box.get_node("Label2") as Label
	body.text = "You reached the one who was waiting.\nThank you for playing Quillfen."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.custom_minimum_size = Vector2(1200, 0)
	body.add_theme_font_override("font", MobileUI.FONT)
	body.add_theme_font_size_override("font_size", 42)
	body.add_theme_color_override("font_color", Color(0.9, 0.93, 0.9))
	
	var button := Button.new()
	button.text = "Back to title"
	button.custom_minimum_size = Vector2(520, 120)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	MobileUI.style_button(button, 48)
	button.pressed.connect(_on_title)
	box.add_child(button)
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()


func _apply_safe_area() -> void:
	var frame := $ColorRect/VBoxContainer as Control
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	var safe := Vector4.ZERO
	if is_instance_valid(TouchControls):
		safe = TouchControls.viewport_insets()
	frame.offset_left = safe.x + 24.0
	frame.offset_top = safe.y + 24.0
	frame.offset_right = -safe.z - 24.0
	frame.offset_bottom = -safe.w - 24.0


func _on_title() -> void:
	if is_instance_valid(Player.gamepiece):
		Player.gamepiece = null
	get_tree().change_scene_to_file("res://src/mobile/title_screen.tscn")
