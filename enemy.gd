extends CharacterBody3D

enum States {attack, idle, chase, die, spell}

var state = States.idle
var hp = 20
var accel = 10
var damage = 10
var gravity = 9.8
var target = null
var value = 15
var can_spell = true
var is_casting = false
var can_attack = true  # Add attack cooldown flag


# Patrol variables
var patrol_timer = 0.0
@export var patrol_duration: float = 3.0  # How long to walk before stopping
@export var walk_speed: float = 2.0  # Slower walking speed
@export var speed: float = 4.0  # Chase/run speed
@export var spell_cooldown: float = 5.0  # Cooldown between spells
var is_patrolling = false
var patrol_target = Vector3.ZERO

@export var navAgent : NavigationAgent3D
@export var animationPlayer: AnimationPlayer
@export var fireball_scene: PackedScene  # Assign your fireball scene here
@export var fireball_spawn_point: Node3D  # Assign the Marker3D node here
@export var punch_sound: AudioStream  # Sound for punch attack
@export var spell_hit_sound: AudioStream  # Sound for spell hit
@export var punch_volume: float = 0.0  # Volume in dB (0 = normal, -10 = quieter, 10 = louder)
@export var spell_volume: float = 0.0  # Volume in dB (0 = normal, -10 = quieter, 10 = louder)

@onready var audio_player = AudioStreamPlayer3D.new()  # 3D positional audio



func enemy(): pass


func _ready():
	# Setup audio player
	add_child(audio_player)
	audio_player.max_distance = 50.0  # How far sound can be heard
	audio_player.unit_size = 10.0  # Size of sound source


func _process(delta):
	if hp <= 0:
		state = States.die


func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity
	
	# Handle death music transition (only once when entering die state)
	if state == States.die and hp <= 0:
		var music_manager = get_tree().root.find_child("MusicManager", true, false)
		if music_manager and not music_manager.active_enemies.has(self):
			pass  # Already removed
		elif music_manager:
			music_manager.enemy_died(self)
	
	if state == States.idle:
		if is_patrolling:
			# Continue patrolling
			patrol_timer -= delta
			look_at(Vector3(patrol_target.x, global_position.y, patrol_target.z), Vector3.UP, true)
			navAgent.target_position = patrol_target
			var direction = navAgent.get_next_path_position() - global_position
			direction = direction.normalized()
			velocity = velocity.lerp(direction * walk_speed, accel * delta)
			animationPlayer.play("walk")
			
			# Stop patrolling after duration
			if patrol_timer <= 0:
				is_patrolling = false
		else:
			# Idle/looking - standing still
			velocity = Vector3(0, velocity.y, 0)
			animationPlayer.play("look")
			
			# Start new patrol after a delay
			patrol_timer = randf_range(2.0, 4.0)  # Wait 2-4 seconds before next patrol
			if randf() > 0.3:  # 70% chance to patrol
				start_patrol()
	elif state == States.chase:
		look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP, true)
		navAgent.target_position = target.global_position
		var direction = navAgent.get_next_path_position() - global_position
		direction = direction.normalized()
		velocity = velocity.lerp(direction * speed, accel * delta)
		animationPlayer.play("run")
	elif state == States.attack:
		look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP, true)
		velocity = Vector3.ZERO
		if can_attack:
			animationPlayer.play("punch")
			attack()
	elif state == States.spell:
		look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP, true)
		velocity = Vector3.ZERO
		# Only play animation if we can actually cast
		if can_spell:
			animationPlayer.play("spell1")
		else:
			# If on cooldown, return to chase state
			state = States.chase
	elif state == States.die:
		velocity = Vector3.ZERO
		animationPlayer.play("die1")
		# Notify music manager that this enemy died
		var music_manager = get_tree().root.find_child("MusicManager", true, false)
		if music_manager:
			music_manager.enemy_died(self)
	
	move_and_slide()


func attack():
	if target and can_attack:
		can_attack = false
		target.hp -= damage
		# Sound is now played by animation at exact frame
		# Wait for attack animation to finish before attacking again
		await get_tree().create_timer(1.0).timeout  # Adjust time based on your animation length
		can_attack = true


func play_punch_sound():
	"""Called by AnimationPlayer at exact punch frame via CallMethod track"""
	if punch_sound:
		audio_player.stream = punch_sound
		audio_player.volume_db = punch_volume
		audio_player.play()


func start_patrol():
	"""Generate a random patrol point and start walking"""
	is_patrolling = true
	patrol_timer = patrol_duration
	
	# Generate random position within reasonable distance
	var random_offset = Vector3(randf_range(-15, 15), 0, randf_range(-15, 15))
	patrol_target = global_position + random_offset
	
	# Clamp to prevent going too far
	patrol_target.y = global_position.y


func cast_spell():
	"""Called by AnimationPlayer at exact frame via CallMethod track"""
	if not target or not can_spell or not fireball_scene:
		return
	
	is_casting = true
	can_spell = false
	
	# Instance the fireball scene
	var fireball = fireball_scene.instantiate()
	
	# Add to scene first
	get_parent().add_child(fireball)
	
	# Set position AFTER adding to scene
	if fireball_spawn_point:
		fireball.global_position = fireball_spawn_point.global_position
	else:
		fireball.global_position = global_position + Vector3(0, 0.5, 0)
	
	# Get the Area3D root node for collision detection
	var hit_area = fireball if fireball is Area3D else fireball.get_child(0)
	
	# Calculate direction toward target's aim point if available, otherwise aim at chest
	var target_aim_position = target.aim_point.global_position if target.has_meta("aim_point") or target.aim_point else target.global_position + Vector3(0, 1, 0)
	var direction = (target_aim_position - fireball.global_position).normalized()
	
	# Connect hit detection
	hit_area.body_entered.connect(func(body): _on_fireball_hit(body, fireball))
	
	# Create a tween for smooth fireball movement
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(fireball, "position", fireball.position + direction * 50, 2.5)
	await tween.finished
	
	# Destroy fireball after tween completes
	if is_instance_valid(fireball):
		fireball.queue_free()
	
	# Start cooldown before allowing next spell
	await get_tree().create_timer(spell_cooldown).timeout
	can_spell = true
	is_casting = false


func _on_fireball_hit(body: Node3D, fireball: Node3D):
	if body.has_method("player") and is_instance_valid(fireball):
		print("Fireball hit player!")
		# Play spell hit sound
		if spell_hit_sound:
			audio_player.stream = spell_hit_sound
			audio_player.volume_db = spell_volume
			audio_player.play()
		# Call the player's take_damage method which handles VFX
		if body.has_method("take_damage_with_vfx"):
			print("Calling take_damage_with_vfx with damage: ", damage)
			body.take_damage_with_vfx(damage, fireball.global_position)
		else:
			print("Player doesn't have take_damage_with_vfx, using direct HP")
			body.hp -= damage
		print("Fireball hit player! Damage: ", damage)
		fireball.queue_free()


func give_loot():
	if target:
		target.gold += value


func _on_chase_area_body_entered(body: Node3D) -> void:
	if body.has_method("player") and state != States.die:
		target = body
		state = States.chase
		# Trigger combat music - search entire tree
		var music_manager = get_tree().root.find_child("MusicManager", true, false)
		if music_manager:
			print("Starting combat music...")
			music_manager.start_combat(self)  # Pass this enemy
		else:
			print("ERROR: MusicManager not found in scene!")


func _on_chase_area_body_exited(body: Node3D) -> void:
	if body.has_method("player") and state != States.die:
		target = null
		state = States.idle
		# Stop combat music - search entire tree
		var music_manager = get_tree().root.find_child("MusicManager", true, false)
		if music_manager:
			music_manager.stop_combat(self)  # Pass this enemy


func _on_attack_area_body_entered(body: Node3D) -> void:
	if body.has_method("player") and state != States.die:
		state = States.attack


func _on_attack_area_body_exited(body: Node3D) -> void:
	if body.has_method("player") and state != States.die:
		state = States.chase


func _on_spell_area_body_entered(body: Node3D) -> void:
	# Only enter spell state if spell is off cooldown
	if body.has_method("player") and state != States.die and can_spell:
		state = States.spell


func _on_spell_area_body_exited(body: Node3D) -> void:
	if body.has_method("player") and state != States.die:
		state = States.chase  # Changed from idle to chase so enemy keeps pursuing
