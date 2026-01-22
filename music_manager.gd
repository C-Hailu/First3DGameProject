extends AudioStreamPlayer

@export var normal_music: AudioStream  # Calm/exploration music
@export var combat_music: AudioStream  # Fighting music
@export var fade_duration: float = 1.0  # Fade duration in seconds
@export var music_volume: float = -10.0  # Default volume in dB (-10 is fairly quiet)

var is_in_combat: bool = false
var is_transitioning: bool = false


func _ready():
	# Start with normal music
	volume_db = music_volume
	stream = normal_music
	play()


func start_combat():
	"""Called when enemy engages player"""
	if is_in_combat or is_transitioning:
		return
	
	is_in_combat = true
	is_transitioning = true
	
	# Fade out current music
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "volume_db", -80, fade_duration)
	await tween.finished
	
	# Change music and set volume low
	stream = combat_music
	volume_db = -80
	play()
	
	# Fade in combat music
	var tween2 = create_tween()
	tween2.set_trans(Tween.TRANS_LINEAR)
	tween2.tween_property(self, "volume_db", music_volume, fade_duration)
	await tween2.finished
	is_transitioning = false


func stop_combat():
	"""Called when enemy loses sight of player"""
	if not is_in_combat or is_transitioning:
		return
	
	is_in_combat = false
	is_transitioning = true
	
	# Fade out combat music
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "volume_db", -80, fade_duration)
	await tween.finished
	
	# Change music and set volume low
	stream = normal_music
	volume_db = -80
	play()
	
	# Fade in normal music
	var tween2 = create_tween()
	tween2.set_trans(Tween.TRANS_LINEAR)
	tween2.tween_property(self, "volume_db", music_volume, fade_duration)
	await tween2.finished
	is_transitioning = false
