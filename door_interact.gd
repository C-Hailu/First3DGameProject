extends Area3D

@export var current_area: String = "outdoor"  # Where this door is located
@export var target_area: String = "house_interior"  # Where it leads to
@export var prompt_text: String = "Press X to enter"

var player_nearby: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	add_to_group("door")
	
	# Check if player should spawn here (if coming from target area)
	if GameManager.last_area == target_area:
		_set_player_position()

func _set_player_position():
	"""Position player at spawn point if they came from the target area"""
	await get_tree().process_frame
	
	var player = get_tree().get_first_node_in_group("player")
	var spawn_marker = get_node_or_null("SpawnMarker")
	
	if player and spawn_marker:
		player.global_position = spawn_marker.global_position
		player.rotation.y = spawn_marker.rotation.y
		print("Positioned player at door spawn point")
		
		# Restore player stats
		GameManager.restore_player_stats(player)
	elif player:
		# No spawn marker, just restore stats at current position
		GameManager.restore_player_stats(player)

func _process(_delta):
	if player_nearby and Input.is_action_just_pressed("interact"):
		use_door()

func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		player_nearby = true
		print(prompt_text)

func _on_body_exited(body: Node3D):
	if body.is_in_group("player"):
		player_nearby = false

func use_door():
	player_nearby = false
	
	# Save player stats before transition
	var player = get_tree().get_first_node_in_group("player")
	if player:
		GameManager.save_player_stats(player)
	
	print("Door: Going from ", current_area, " to ", target_area)
	
	# Get the target scene path
	var target_scene_path = GameManager.scene_paths.get(target_area, "")
	if target_scene_path == "":
		print("ERROR: No scene path found for area: ", target_area)
		return
	
	print("Target scene path: ", target_scene_path)
	
	# Set last_area BEFORE changing scene
	GameManager.last_area = current_area
	
	# Change music BEFORE transition
	var music_manager = get_node_or_null("/root/MusicManager")
	if music_manager:
		print("Setting music for area: ", target_area)
		if target_area == "house_interior":
			music_manager.set_scene_music("interior")
		else:
			music_manager.set_scene_music("normal")
	
	# Use SceneTransition if available
	var transition = get_node_or_null("/root/SceneTransition")
	if transition:
		transition.fade_to_scene(target_scene_path)
	else:
		# No transition, just change scene directly
		get_tree().change_scene_to_file(target_scene_path)
