extends Node2D

## The cutscene that will play on starting a new game.
@export var opening_cutscene: Cutscene

## A PlayerController that will be dynamically assigned to whichever Gamepiece the player currently
## controls.
@export var player_controller: PackedScene

## The first gamepiece that the player will control. This may be null and assigned via an
## introductory cutscene instead.
@export var player_default_gamepiece: Gamepiece


func _ready() -> void:
	randomize()
	_add_backdrop()
	
	if OS.get_environment("QUILLFEN_SKIP_INTRO") == "1":
		opening_cutscene = null
	
	# Returning from the ending leaves this static lock set. Clear it before the new game.
	if Cutscene._is_cutscene_in_progress:
		Cutscene._is_cutscene_in_progress = false
	
	# Assign proper controllers to player gamepieces whenever they change.
	Player.gamepiece_changed.connect(
		func _on_player_gp_changed() -> void:
			var new_gp: = Player.gamepiece
			Camera.gamepiece = new_gp
	
			# Free up any lingering controller(s).
			for controller in get_tree().get_nodes_in_group(PlayerController.GROUP):
				controller.queue_free()
			
			if new_gp:
				var new_controller = player_controller.instantiate()
				assert(new_controller is PlayerController, "The Field game state requires a valid
					 PlayerController set in the editor!")
				
				new_gp.add_child(new_controller)
				new_controller.is_active = true
	)
	
	Player.gamepiece = player_default_gamepiece
	
	# The field state must pause/unpause with combat accordingly.
	# Note that pausing/unpausing input is already wrapped up in triggers, which are what will
	# initiate combat.
	CombatEvents.combat_initiated.connect(func(): hide())
	CombatEvents.combat_finished.connect(func(_is_victory): show())
	
	Camera.scale = scale
	Camera.enabled = true
	Camera.make_current()
	Camera.reset_position()
	
	if opening_cutscene:
		opening_cutscene.run.call_deferred()


func _add_backdrop() -> void:
	# Empty cells inside the board are transparent. Without this they show the
	# engine clear color, which is the grey band around a tall phone viewport.
	var layer := CanvasLayer.new()
	layer.layer = -100
	var fill := ColorRect.new()
	fill.color = Color(0.278, 0.624, 0.290)
	fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fill)
	add_child(layer)
	var fit := func() -> void:
		fill.size = get_viewport_rect().size
	get_viewport().size_changed.connect(fit)
	fit.call_deferred()


func _exit_tree() -> void:
	# The autoload outlives this scene. Leaving it current keeps drag-center
	# applied to the title and credits, which are drawn on the root canvas.
	if is_instance_valid(Camera):
		Camera.enabled = false
