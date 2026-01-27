# GameOverUI.gd
extends Control

@onready var retry_button = $PanelContainer/VBoxContainer/RetryButton

var is_game_over = false

func _ready():
	hide()
	
	# Check if retry button exists
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)
	else:
		print("ERROR: RetryButton not found! Check your scene structure.")
	
	# Set process mode to always so it works when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_game_over():
	"""Called when player dies"""
	if is_game_over:
		return
	
	is_game_over = true
	show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_retry_pressed():
	"""Restart the game"""
	is_game_over = false
	get_tree().paused = false
	hide()
	
	# Reset player stats
	GameManager.player_hp = GameManager.player_max_hp
	GameManager.player_gold = 15
	GameManager.last_area = ""
	
	# Restart the current scene or go to starting area
	get_tree().change_scene_to_file(GameManager.scene_paths["outdoor"])
	
	# Return mouse to captured mode
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
