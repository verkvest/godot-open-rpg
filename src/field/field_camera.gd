## Specialized camera that is constrained to the [Gameboard]'s boundaries.
##
## The camera's limits are set dynamically according to the viewport's dimensions. Normally, the
## camera is limited to the [member Gameboard.boundaries].
## [br][br]In some cases the gameboard is smaller than the viewport, in which case it will be
## snapped to the gameboard centre along the constrained axis/axes.
class_name FieldCamera
extends Camera2D

func _init() -> void:
	# Autoload cameras enter the tree before the main scene. An enabled Camera2D
	# calls make_current() on enter, and the default anchor is drag-center.
	# At (0, 0) that places the canvas origin at the middle of the window, so
	# the title only covers the bottom-right quadrant and the rest stays the
	# grey clear color. Stay off until the field asks for a camera.
	enabled = false


@export var gameboard_properties: GameboardProperties:
	set(value):
		gameboard_properties = value
		_on_viewport_resized()


@export var gamepiece: Gamepiece:
	set(value):
		if gamepiece:
			gamepiece.animation_transform.remote_path = ""
		
		gamepiece = value
		if gamepiece and gamepiece.is_inside_tree():
			gamepiece.animation_transform.remote_path \
				= gamepiece.animation_transform.get_path_to(self)
		_on_viewport_resized()


func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()


func reset_position() -> void:
	if gamepiece:
		position = gamepiece.position * scale
		
	reset_smoothing()


func _on_viewport_resized() -> void:
	if not gameboard_properties or not is_inside_tree():
		return
	
	var cell := Vector2(gameboard_properties.cell_size)
	var extents := gameboard_properties.extents
	var local := Rect2(Vector2(extents.position) * cell, Vector2(extents.size) * cell)
	var limit_rect := local
	var focus_rect := local
	var board := _board_node()
	if board:
		limit_rect = board.get_global_transform() * local
		var everywhere := _painted_global_rect(board, false)
		if everywhere.size.x > 1.0 and everywhere.size.y > 1.0:
			limit_rect = everywhere
		var nearby := _painted_global_rect(board, true)
		if nearby.size.x > 1.0 and nearby.size.y > 1.0:
			focus_rect = nearby
	
	var view := get_viewport_rect().size
	var cover := 1.0
	if focus_rect.size.x > 1.0 and focus_rect.size.y > 1.0 and view.x > 1.0 and view.y > 1.0:
		cover = maxf(view.x / focus_rect.size.x, view.y / focus_rect.size.y)
	# Zoom 1 is the design framing. Zoom in only when this window would
	# otherwise show past the tiles around the player and leave the clear color.
	zoom = Vector2.ONE * maxf(cover, 1.0)
	
	var visible := view / zoom
	_fit_limit(limit_rect, visible)


func _painted_global_rect(board: Node2D, nearby_only: bool) -> Rect2:
	var focus := global_position
	if gamepiece and gamepiece.is_inside_tree():
		focus = gamepiece.global_position
	# Nearby tiles decide zoom. Every map still contributes to the limits, or
	# the player could not walk out of the starting area.
	var neighborhood := Rect2(focus - Vector2(480, 480), Vector2(960, 960))
	var union := Rect2()
	var found := false
	for node in board.find_children("*", "TileMapLayer", true, false):
		var layer := node as TileMapLayer
		if layer == null or not layer.visible or _is_debug(layer):
			continue
		var used := layer.get_used_rect()
		if used.size.x <= 0 or used.size.y <= 0:
			continue
		var tile_size := Vector2(16, 16)
		if layer.tile_set:
			tile_size = Vector2(layer.tile_set.tile_size)
		var local := Rect2(Vector2(used.position) * tile_size, Vector2(used.size) * tile_size)
		var global := layer.get_global_transform() * local
		if nearby_only and not global.intersects(neighborhood):
			continue
		union = global if not found else union.merge(global)
		found = true
	return union


func _is_debug(node: Node) -> bool:
	var current := node
	while current:
		var node_name := String(current.name)
		if node_name.contains("Debug") or node_name == "Overlay":
			return true
		current = current.get_parent()
	return false


func _board_node() -> Node2D:
	if gamepiece and gamepiece.is_inside_tree():
		var parent := gamepiece.get_parent()
		if parent is Node2D:
			return parent
	return null


## Limits are the edges of the visible rect in global canvas pixels. A view larger
## than the map on one axis is locked to that axis so the engine centers the map.
func _fit_limit(global_rect: Rect2, visible: Vector2) -> void:
	if global_rect.size.x <= visible.x:
		var mid_x := global_rect.get_center().x
		limit_left = int(mid_x - visible.x * 0.5)
		limit_right = int(mid_x + visible.x * 0.5)
	else:
		limit_left = int(floor(global_rect.position.x))
		limit_right = int(ceil(global_rect.end.x))
	
	if global_rect.size.y <= visible.y:
		var mid_y := global_rect.get_center().y
		limit_top = int(mid_y - visible.y * 0.5)
		limit_bottom = int(mid_y + visible.y * 0.5)
	else:
		limit_top = int(floor(global_rect.position.y))
		limit_bottom = int(ceil(global_rect.end.y))
