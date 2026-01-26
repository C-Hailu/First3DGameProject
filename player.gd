extends CharacterBody3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var anim_tree: AnimationTree = $AnimationTree
var last_lean := 0.0

## Determines how fast the player moves
@export var speed := 5.0
const JUMP_VELOCITY = 4.5 # constants never change
@onready var camera: Node3D = $CameraRig/Camera3D
@onready var hpBar = $HUD/HPBar
@onready var goldLabel = $HUD/GoldLabel
@onready var cooldown = $AttackCooldown
@export var aim_point: Node3D
@export var hit_vfx: PackedScene
@export var hit_vfx_point: Node3D  # Marker3D for where hit VFX spawns on body
@export var hit_vfx_duration: float = 0.25  # How long the hit VFX displays


var gold = 15
var hp = 50
var maxHP = 50
var damage = 10
var target = []
var onCooldown = false




func _ready():
	hpBar.max_value = maxHP
	hpBar.min_value = 0
	hpBar.value = hp
	
	
	
func update_HUD():
	
	hpBar.value = hp
	goldLabel.text = str(gold)


func player():
	pass
	
func attack():
	if Input.is_action_just_pressed("attack") and onCooldown == false:
		anim_player.play("punch")
		onCooldown = true
		cooldown.start()
		
func deal_damage():
	for enemies in target:
		enemies.hp -= damage


func _physics_process(delta: float) -> void:
	update_HUD()
	attack()
	

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (camera.global_basis * Vector3(input_dir.x, 0, input_dir.y))
	direction = Vector3(direction.x, 0, direction.z).normalized() * input_dir.length()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
	turn_to(direction)

	var current_speed := velocity.length()
	const RUN_SPEED := 3.5
	const BLEND_SPEED := 0.2

	if not is_on_floor():
		anim_tree.set("parameters/movement/transition_request", "fall")

	elif current_speed > RUN_SPEED:
		anim_tree.set("parameters/movement/transition_request", "run")
		var lean := direction.dot(global_basis.x)
		last_lean = lerpf(last_lean, lean, 0.3)
		anim_tree.set("parameters/run_lean/add_amount", last_lean)
	elif current_speed > 0.0:
		anim_tree.set("parameters/movement/transition_request", "walk")
		var walk_speed := lerpf(0.5, 1.75, current_speed / RUN_SPEED)
		anim_tree.set("parameters/walk_speed/scale", walk_speed)
	else:
		anim_tree.set("parameters/movement/transition_request", "idle")

func turn_to(direction: Vector3) -> void:
	if direction.length() > 0:
		var yaw := atan2(-direction.x, -direction.z)
		yaw = lerp_angle(rotation.y, yaw, .25)
		rotation.y = yaw


func _on_attack_zone_body_entered(body: Node3D) -> void:
	if body.has_method("enemy"):
		target.append(body)


func _on_attack_zone_body_exited(body: Node3D) -> void:
	if body.has_method("enemy"):
		target.erase(body)


func _on_attack_cooldown_timeout() -> void:
	onCooldown = false


func take_damage_with_vfx(damage: int, impact_position: Vector3) -> void:
	print("Player taking damage: ", damage, " | HP before: ", hp)
	hp -= damage
	print("HP after: ", hp)
	
	# Spawn hit VFX at designated point on body, or at impact location if not set
	if hit_vfx:
		var vfx = hit_vfx.instantiate()
		if hit_vfx_point:
			vfx.global_position = hit_vfx_point.global_position
		else:
			vfx.global_position = impact_position
		get_parent().add_child(vfx)
		
		# Auto-destroy VFX after duration
		await get_tree().create_timer(hit_vfx_duration).timeout
		if is_instance_valid(vfx):
			vfx.queue_free()
