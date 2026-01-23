extends AudioStreamPlayer

@export var normal_music: AudioStream  # Calm/exploration music
@export var combat_music: AudioStream  # Fighting music
@export var house_interior_music: AudioStream  # Music for inside the house
@export var fade_duration: float = 1.0  # Fade duration in seconds
@export var music_volume: float = -10.0  # Default volume in dB (-10 is fairly quiet)

var is_in_combat: bool = false
var is_transitioning: bool = false
var active_enemies: Array = []  # Track all enemies in combat
var current_scene_music: AudioStream = null  # Track what music should play for current scene
var combat_cooldown: float = 0.0  # Prevent rapid combat state changes

func _ready():
	# Start with normal music
	current_scene_music = normal_music
	volume_db = music_volume
	stream = normal_music
	play()


func _process(delta):
	# Reduce combat cooldown timer
	if combat_cooldown > 0:
		combat_cooldown -= delta

func start_combat(enemy = null):
	"""Called when enemy engages player"""
	# Add enemy to active list if provided
	if enemy and not active_enemies.has(enemy):
		active_enemies.append(enemy)
	
	# Only transition if not already in combat
	if is_in_combat or is_transitioning:
		return
	
	is_in_combat = true
	is_transitioning = true
	
	# Fade out current music
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "volume_db", -80, fade_duration)
	await tween.finished
	
	# Stop the current stream before changing
	stop()
	
	# Small delay to ensure stop completes
	await get_tree().create_timer(0.1).timeout
	
	# Change music and set volume low
	stream = combat_music
	if not combat_music:
		print("ERROR: Combat music is null!")
		is_transitioning = false
		is_in_combat = false
		return
	
	volume_db = -80
	play()
	
	# Fade in combat music
	var tween2 = create_tween()
	tween2.set_trans(Tween.TRANS_LINEAR)
	tween2.tween_property(self, "volume_db", music_volume, fade_duration)
	await tween2.finished
	is_transitioning = false

func stop_combat(enemy = null):
	"""Called when enemy loses sight of player or dies"""
	# Remove enemy from active list if provided
	if enemy and active_enemies.has(enemy):
		active_enemies.erase(enemy)
	
	# Only stop combat music if no enemies remain
	if active_enemies.size() > 0:
		return
	
	# Prevent rapid toggling
	if combat_cooldown > 0:
		return
	
	if not is_in_combat or is_transitioning:
		return
	
	is_in_combat = false
	is_transitioning = true
	combat_cooldown = 2.0  # 2 second cooldown before combat can start again
	
	# Fade out combat music
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "volume_db", -80, fade_duration * 8)
	await tween.finished
	
	# Stop the current stream before changing
	stop()
	
	# Return to scene-appropriate music (not always normal_music)
	stream = current_scene_music if current_scene_music else normal_music
	volume_db = -80
	play()
	
	# Fade in scene music
	var tween2 = create_tween()
	tween2.set_trans(Tween.TRANS_LINEAR)
	tween2.tween_property(self, "volume_db", music_volume, fade_duration)
	await tween2.finished
	is_transitioning = false

func enemy_died(enemy):
	"""Called when an enemy dies - removes from combat tracking"""
	stop_combat(enemy)


func _on_scene_changed(node):
	# Only react when the root of a new scene is added
	if node == get_tree().current_scene:
		change_music_for_scene()


func change_music_for_scene():
	"""Change music based on current scene"""
	if is_in_combat or is_transitioning:
		return  # Don't change music during combat
	
	var scene_path = get_tree().current_scene.scene_file_path
	var scene_name = get_tree().current_scene.name
	var new_music: AudioStream = null
	
	print("Checking music for scene: ", scene_name, " at path: ", scene_path)
	
	# Determine which music to play based on scene path or name
	if "interior" in scene_path.to_lower() or "house" in scene_path.to_lower() or \
	   "interior" in scene_name.to_lower() or "house" in scene_name.to_lower():
		new_music = house_interior_music
		print("Playing house interior music")
	else:
		new_music = normal_music
		print("Playing normal music")
	
	# Only change if it's different music
	if new_music and new_music != stream:
		current_scene_music = new_music
		transition_to_music(new_music)


func set_scene_music(music_type: String):
	"""Manually set music type - called by door/transition scripts"""
	var new_music: AudioStream = null
	
	match music_type.to_lower():
		"house", "interior":
			new_music = house_interior_music
		"normal", "outdoor":
			new_music = normal_music
		_:
			print("Unknown music type: ", music_type)
			return
	
	if new_music and new_music != stream and not is_in_combat:
		current_scene_music = new_music
		transition_to_music(new_music)


func transition_to_music(new_music: AudioStream):
	"""Smoothly transition to new music"""
	if is_transitioning:
		return
	
	is_transitioning = true
	
	# Fade out current music
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "volume_db", -80, fade_duration)
	await tween.finished
	
	# Stop the current stream before changing
	stop()
	
	# Change to new music
	stream = new_music
	volume_db = -80
	play()
	
	# Fade in new music
	var tween2 = create_tween()
	tween2.set_trans(Tween.TRANS_LINEAR)
	tween2.tween_property(self, "volume_db", music_volume, fade_duration)
	await tween2.finished
	
	is_transitioning = false
