extends CharacterBody3D

enum States {attack, idle, chase, die, spell}

var state = States.idle
var hp = 20
var speed = 4
var accel = 10
var damage = 10
var gravity = 9.8
var target = null
var value = 15
var can_spell = true
var is_casting = false

@export var navAgent : NavigationAgent3D
@export var animationPlayer: AnimationPlayer
@export var fireball_scene: PackedScene  # Assign your fireball scene here
@export var fireball_spawn_point: Node3D  # Assign the Marker3D node here



func enemy(): pass


func _process(delta):
	if hp <= 0:
		state = States.die


func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity
	
	if state == States.idle:
		velocity = Vector3(0, velocity.y, 0)
		animationPlayer.play("look")
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
		animationPlayer.play("punch")
		attack()
	elif state == States.spell:
		look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP, true)
		velocity = Vector3.ZERO
		animationPlayer.play("spell1")
	elif state == States.die:
		velocity = Vector3.ZERO
		animationPlayer.play("die1")
	
	move_and_slide()


func attack():
	if target:
		target.hp -= damage


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
	

	can_spell = true
	is_casting = false


func _on_fireball_hit(body: Node3D, fireball: Node3D):
	if body.has_method("player") and is_instance_valid(fireball):
		# Call the player's take_damage method which handles VFX
		if body.has_method("take_damage_with_vfx"):
			body.take_damage_with_vfx(damage, fireball.global_position)
		else:
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


func _on_chase_area_body_exited(body: Node3D) -> void:
	if body.has_method("player") and state != States.die:
		target = null
		state = States.idle


func _on_attack_area_body_entered(body: Node3D) -> void:
	if body.has_method("player") and state != States.die:
		state = States.attack


func _on_attack_area_body_exited(body: Node3D) -> void:
	if body.has_method("player") and state != States.die:
		state = States.chase





func _on_spell_area_body_entered(body: Node3D) -> void:
	if body.has_method("player") and state != States.die:
		state = States.spell


func _on_spell_area_body_exited(body: Node3D) -> void:
	if body.has_method("player") and state != States.die:
		state = States.idle
	
