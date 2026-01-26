extends CanvasLayer

@onready var color_rect = $ColorRect

func _ready():
	# Start transparent
	color_rect.color = Color(0, 0, 0, 0)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func fade_to_scene(scene_path: String):
	"""Fade to black, change scene, then fade in"""
	print("Starting transition to: ", scene_path)
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Fade to black
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, 0.5)
	await tween.finished
	
	print("Fade out complete, changing scene...")
	
	# Free the old scene explicitly before loading new one
	var old_scene = get_tree().current_scene
	
	# Change scene
	var result = get_tree().change_scene_to_file(scene_path)
	if result != OK:
		print("ERROR: Failed to load scene: ", scene_path)
		print("Error code: ", result)
		# Fade back in to show the error
		var tween_error = create_tween()
		tween_error.tween_property(color_rect, "color:a", 0.0, 0.5)
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	
	# Explicitly free old scene
	if is_instance_valid(old_scene):
		old_scene.queue_free()
	
	await get_tree().process_frame  # Wait for scene to load
	print("Scene loaded, fading in...")
	
	# Fade in from black
	var tween2 = create_tween()
	tween2.tween_property(color_rect, "color:a", 0.0, 0.5)
	await tween2.finished
	
	print("Transition complete!")
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func fade_out():
	"""Just fade to black"""
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, 0.5)
	await tween.finished

func fade_in():
	"""Just fade in from black"""
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, 0.5)
	await tween.finished
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
