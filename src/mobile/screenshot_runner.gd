## Captures a phone-aspect title shot and a field shot, then quits.
## Launch with: godot --path . res://src/mobile/screenshot_runner.tscn
extends Node


func _ready() -> void:
	# Defer so we are not inside the scene tree's add-child pass.
	_detach_and_run.call_deferred()


func _detach_and_run() -> void:
	# Leave the scene that change_scene_to_file will free, or this coroutine dies with it.
	var tree := get_tree()
	var root := tree.root
	if get_parent():
		get_parent().remove_child(self)
	tree.current_scene = null
	root.add_child(self)
	_run()


func _run() -> void:
	var directory := OS.get_environment("SCREENSHOT_DIR")
	if directory.is_empty():
		directory = ProjectSettings.globalize_path("res://build/screenshots")
	DirAccess.make_dir_recursive_absolute(directory)
	
	await _frames(2)
	_phone_window()
	
	get_tree().change_scene_to_file("res://src/mobile/title_screen.tscn")
	await _frames(8)
	_phone_window()
	await _frames(4)
	_save(directory + "/title.png")
	
	OS.set_environment("QUILLFEN_SKIP_INTRO", "1")
	get_tree().change_scene_to_file("res://src/main.tscn")
	await _frames(16)
	_phone_window()
	await _frames(8)
	_save(directory + "/gameplay.png")
	get_tree().quit(0)


func _phone_window() -> void:
	# Wider than 16:9 so the shot matches a landscape phone, not the editor window.
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(2400, 1080))
	var window := get_window()
	if window:
		window.size = Vector2i(2400, 1080)


func _frames(count: int) -> void:
	for _i in count:
		await RenderingServer.frame_post_draw


func _save(path: String) -> void:
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	print("screenshot ", path, " ", image.get_width(), "x", image.get_height(), " err=", error)
