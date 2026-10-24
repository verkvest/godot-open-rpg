## On-screen pad and confirm button for landscape phones.
##
## Grid steps come from the pad (hold to keep walking). Tap-to-move still works on the map.
## Dialogue advances on any tap. Battle commands are the large menu buttons; the pad and OK
## button are for choosing a target.
extends CanvasLayer

## Safe-area insets in viewport pixels: left, top, right, bottom.
var insets := Vector4.ZERO

const _PAD := 120
const _GAP := 14

var _dpad: Control
var _actions: Control
var _ok: Button
var _back: Button
var _dialogue: CanvasItem
var _win_rect: CanvasItem
var _layout_wait := 0.0


func _ready() -> void:
	layer = 30
	_build()
	get_viewport().size_changed.connect(_apply_layout)
	_apply_layout()


func _process(delta: float) -> void:
	_layout_wait += delta
	if _layout_wait > 0.4:
		_layout_wait = 0.0
		_layout_hud()
	_cache_nodes()
	var scene := get_tree().current_scene
	var hide_for_scene := scene != null and scene.is_in_group("hide_touch_controls")
	var ending := _win_rect != null and _win_rect.visible
	visible = not hide_for_scene and not ending
	if not visible:
		_release_all()
		return
	
	var talking := _dialogue != null and _dialogue.visible
	var choosing_action := _group_visible("touch_action_menu")
	var choosing_target := _group_visible("touch_targeting")
	_dpad.visible = not talking
	_actions.visible = not talking and not choosing_action
	if choosing_target:
		_ok.text = "OK"
	elif talking:
		_ok.text = "Next"
	else:
		_ok.text = "Talk"


func _build() -> void:
	_dpad = Control.new()
	_dpad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dpad)
	_hold_button(_dpad, "ui_up", Vector2(_PAD + _GAP, 0), "^")
	_hold_button(_dpad, "ui_down", Vector2(_PAD + _GAP, (_PAD + _GAP) * 2), "v")
	_hold_button(_dpad, "ui_left", Vector2(0, _PAD + _GAP), "<")
	_hold_button(_dpad, "ui_right", Vector2((_PAD + _GAP) * 2, _PAD + _GAP), ">")
	
	_actions = VBoxContainer.new()
	_actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_actions.add_theme_constant_override("separation", 16)
	_actions.alignment = BoxContainer.ALIGNMENT_END
	add_child(_actions)
	
	_ok = Button.new()
	_ok.text = "Talk"
	_ok.custom_minimum_size = Vector2(168, 168)
	MobileUI.style_round(_ok, 44)
	_ok.pressed.connect(_on_ok)
	_actions.add_child(_ok)
	
	_back = Button.new()
	_back.text = "Back"
	_back.custom_minimum_size = Vector2(168, 112)
	MobileUI.style_round(_back, 36)
	_back.pressed.connect(_on_back)
	_actions.add_child(_back)


func _hold_button(parent: Control, action: String, at: Vector2, label: String) -> void:
	var button := Button.new()
	button.text = label
	button.position = at
	button.custom_minimum_size = Vector2(_PAD, _PAD)
	button.size = Vector2(_PAD, _PAD)
	MobileUI.style_round(button, 52)
	button.button_down.connect(func() -> void: _set_action(action, true))
	button.button_up.connect(func() -> void: _set_action(action, false))
	parent.add_child(button)


func _set_action(action: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _tap(action: String) -> void:
	_set_action(action, true)
	await get_tree().process_frame
	_set_action(action, false)


func _on_ok() -> void:
	if _group_visible("touch_targeting"):
		await _tap("ui_accept")
	else:
		await _tap("interact")


func _on_back() -> void:
	await _tap("back")


func _release_all() -> void:
	for action in ["ui_up", "ui_down", "ui_left", "ui_right"]:
		if Input.is_action_pressed(action):
			_set_action(action, false)


func _cache_nodes() -> void:
	if _dialogue == null or not is_instance_valid(_dialogue):
		_dialogue = get_tree().root.find_child("DialogueLayout", true, false) as CanvasItem
	if _win_rect == null or not is_instance_valid(_win_rect):
		var win := get_tree().root.find_child("WinScreen", true, false)
		if win:
			_win_rect = win.get_node_or_null("ColorRect") as CanvasItem


func _group_visible(group_name: String) -> bool:
	for node in get_tree().get_nodes_in_group(group_name):
		if node is CanvasItem and (node as CanvasItem).visible:
			return true
	return false


func _apply_layout() -> void:
	_refresh_insets()
	var pad_span := (_PAD + _GAP) * 2 + _PAD
	_dpad.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_dpad.offset_left = insets.x + 20.0
	_dpad.offset_right = _dpad.offset_left + pad_span
	_dpad.offset_bottom = -insets.w - 20.0
	_dpad.offset_top = _dpad.offset_bottom - pad_span
	
	_actions.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_actions.offset_right = -insets.z - 20.0
	_actions.offset_left = _actions.offset_right - 180.0
	_actions.offset_bottom = -insets.w - 20.0
	_actions.offset_top = _actions.offset_bottom - 320.0
	_layout_hud()


func viewport_insets() -> Vector4:
	_refresh_insets()
	return insets


func _refresh_insets() -> void:
	var window := Vector2(DisplayServer.window_get_size())
	if window.x < 2.0 or window.y < 2.0:
		insets = Vector4.ZERO
		return
	var safe := DisplayServer.get_display_safe_area()
	var viewport := get_viewport().get_visible_rect().size
	var scale_x := viewport.x / window.x
	var scale_y := viewport.y / window.y
	insets = Vector4(
		maxf(safe.position.x, 0.0) * scale_x,
		maxf(safe.position.y, 0.0) * scale_y,
		maxf(window.x - safe.end.x, 0.0) * scale_x,
		maxf(window.y - safe.end.y, 0.0) * scale_y
	)


func _layout_hud() -> void:
	var dialogue := _dialogue
	if dialogue == null or not is_instance_valid(dialogue):
		dialogue = get_tree().root.find_child("DialogueLayout", true, false) as CanvasItem
		_dialogue = dialogue
	if dialogue:
		var box := dialogue.get_node_or_null("BoxMargins") as MarginContainer
		if box:
			box.add_theme_constant_override("margin_left", int(insets.x) + 48)
			box.add_theme_constant_override("margin_right", int(insets.z) + 48)
			box.add_theme_constant_override("margin_bottom", int(insets.w) + 16)
	
	var inventory := get_tree().root.find_child("Inventory", true, false) as Control
	if inventory:
		inventory.set_anchors_preset(Control.PRESET_TOP_LEFT)
		inventory.offset_left = insets.x + 28.0
		inventory.offset_top = insets.y + 20.0
		inventory.offset_right = inventory.offset_left + 420.0
		inventory.offset_bottom = inventory.offset_top + 56.0
	
	var battlers := get_tree().root.find_child("PlayerBattlerList", true, false) as Control
	if battlers:
		battlers.offset_right = -insets.z - 24.0
		battlers.offset_left = battlers.offset_right - 480.0
		battlers.offset_top = -220.0
		battlers.offset_bottom = 220.0
