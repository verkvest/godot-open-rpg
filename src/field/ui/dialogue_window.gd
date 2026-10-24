extends DialogicNode_StyleLayer


func _ready():
	super._ready()
	
	Dialogic.timeline_started.connect(func(): show())
	Dialogic.timeline_ended.connect(func(): hide())
	hide()
	
	var choices := get_node_or_null("BoxMargins/Choices")
	if choices:
		choices.add_theme_constant_override("separation", 12)
		for child in choices.get_children():
			if child is Button:
				child.custom_minimum_size = Vector2(560, 108)
				MobileUI.style_button(child, 48)
