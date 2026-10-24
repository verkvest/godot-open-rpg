## Shared phone-sized button styling for menus and the touch HUD.
class_name MobileUI
extends RefCounted

const FONT := preload("res://assets/gui/font/Kenney Pixel.ttf")


static func style_button(button: Button, font_size: int = 48) -> void:
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(0.97, 0.94, 0.86))
	button.add_theme_color_override("font_hover_color", Color(1, 0.96, 0.75))
	button.add_theme_color_override("font_pressed_color", Color(0.9, 0.78, 0.48))
	button.add_theme_color_override("font_focus_color", Color(1, 0.96, 0.75))
	button.add_theme_stylebox_override("normal", _box(Color(0.11, 0.24, 0.27, 0.94), Color(0.93, 0.78, 0.42)))
	button.add_theme_stylebox_override("hover", _box(Color(0.16, 0.34, 0.36, 0.96), Color(1.0, 0.88, 0.55)))
	button.add_theme_stylebox_override("pressed", _box(Color(0.07, 0.14, 0.16, 0.96), Color(0.95, 0.68, 0.28)))
	button.add_theme_stylebox_override("focus", _box(Color(0.16, 0.34, 0.36, 0.96), Color(1.0, 0.88, 0.55)))
	button.add_theme_stylebox_override("disabled", _box(Color(0.12, 0.14, 0.16, 0.7), Color(0.4, 0.4, 0.4)))
	button.focus_mode = Control.FOCUS_NONE


static func style_round(button: Button, font_size: int = 40) -> void:
	style_button(button, font_size)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := button.get_theme_stylebox(state) as StyleBoxFlat
		if box:
			box = box.duplicate() as StyleBoxFlat
			box.set_corner_radius_all(48)
			button.add_theme_stylebox_override(state, box)


static func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(4)
	style.set_corner_radius_all(22)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
