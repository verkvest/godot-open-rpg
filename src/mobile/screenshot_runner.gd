## Captures title and field shots at the phone sizes used to check scaling, then quits.
## Launch with: godot --path . res://src/mobile/screenshot_runner.tscn
extends Node

const _SIZES: Array[Vector2i] = [
	Vector2i(1170, 2532),
	Vector2i(2532, 1170),
	Vector2i(1179, 2556),
	Vector2i(750, 1334),
	Vector2i(2400, 1080),
]


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
	var failed := false
	for size in _SIZES:
		var tag := "%dx%d" % [size.x, size.y]
		_set_window(size)
		get_tree().change_scene_to_file("res://src/mobile/title_screen.tscn")
		await _frames(8)
		_set_window(size)
		await _frames(4)
		var title_path := directory + "/title-" + tag + ".png"
		if not _save(title_path, size, true):
			failed = true
		
		OS.set_environment("QUILLFEN_SKIP_INTRO", "1")
		get_tree().change_scene_to_file("res://src/main.tscn")
		await _frames(16)
		_set_window(size)
		await _frames(8)
		var gameplay_path := directory + "/gameplay-" + tag + ".png"
		if not _save(gameplay_path, size, false):
			failed = true
	
	get_tree().quit(1 if failed else 0)


func _set_window(size: Vector2i) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_size(size)
	var window := get_window()
	if window:
		window.size = size


func _frames(count: int) -> void:
	for _i in count:
		await RenderingServer.frame_post_draw


func _save(path: String, expected: Vector2i, title: bool) -> bool:
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	var camera := get_viewport().get_camera_2d()
	print(
		"screenshot ", path, " ", image.get_width(), "x", image.get_height(),
		" err=", error,
		" camera=", camera,
		" window=", DisplayServer.window_get_size()
	)
	if image.get_width() != expected.x or image.get_height() != expected.y:
		push_error("screenshot size mismatch for " + path)
		return false
	if _clear_color_fraction(image) > (0.02 if title else 0.08):
		push_error("clear color still visible in " + path)
		return false
	return error == OK


## Share of pixels that are still the engine clear color (0.3, 0.3, 0.3).
func _clear_color_fraction(image: Image) -> float:
	var hits := 0
	var step := 8
	var samples := 0
	var width := image.get_width()
	var height := image.get_height()
	for y in range(0, height, step):
		for x in range(0, width, step):
			samples += 1
			var pixel := image.get_pixel(x, y)
			if absf(pixel.r - 0.3) < 0.04 and absf(pixel.g - 0.3) < 0.04 and absf(pixel.b - 0.3) < 0.04:
				hits += 1
	if samples == 0:
		return 1.0
	var fraction := float(hits) / float(samples)
	print("clear_color_fraction ", fraction)
	return fraction
