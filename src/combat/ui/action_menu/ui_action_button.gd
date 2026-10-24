## A button representing a single [BattlerAction], shown in the player's [UIActionMenu].
class_name UIActionButton extends TextureButton

## Setup the button's icon and label to match a given [BattlerAction].
var action: BattlerAction:
	set(value):
		action = value
		
		if not is_inside_tree():
			await ready
		
		_icon.texture = action.icon
		_name_label.text = action.name
		
		await get_tree().process_frame
		var content: Vector2 = $MarginContainer.size
		custom_minimum_size = Vector2(maxf(content.x, 560.0), maxf(content.y, 156.0))

@onready var _icon: = $MarginContainer/Items/Icon
@onready var _name_label: = $MarginContainer/Items/Name


func _ready() -> void:
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_SCALE
	_icon.custom_minimum_size = Vector2(80, 80)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pressed.connect(release_focus)
