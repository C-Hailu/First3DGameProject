extends Control

@onready var pause_panel = $PanelContainer
@onready var settings_panel = $SettingsPanel
@onready var resume_button = $PanelContainer/MarginContainer/VBoxContainer/ResumeButton
@onready var settings_button = $PanelContainer/MarginContainer/VBoxContainer/SettingsButton
@onready var main_menu_button = $PanelContainer/MarginContainer/VBoxContainer/MainMenuButton
@onready var volume_slider = $SettingsPanel/MarginContainer/VBoxContainer/VolumeContainer/VolumeSlider
@onready var back_button = $SettingsPanel/MarginContainer/VBoxContainer/VolumeContainer/BackButton

func _ready():
	hide()
	# Connect pause menu buttons
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	
	# Connect settings panel buttons
	back_button.pressed.connect(_on_back_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)
	
	# Initialize settings panel
	settings_panel.hide()
	
	# Set initial volume slider value (0 to 100)
	var current_volume = db_to_linear(AudioServer.get_bus_volume_db(0)) * 100
	volume_slider.value = current_volume

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key by default
		if settings_panel.visible:
			# If settings is open, close it
			_on_back_pressed()
		else:
			# Otherwise toggle pause
			toggle_pause()

func toggle_pause():
	if get_tree().paused:
		resume_game()
	else:
		pause_game()

func pause_game():
	get_tree().paused = true
	show()
	pause_panel.show()
	settings_panel.hide()
	# Capture mouse for menu
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func resume_game():
	get_tree().paused = false
	hide()
	pause_panel.hide()
	settings_panel.hide()
	# Return mouse to game state (adjust based on your game's needs)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume_pressed():
	resume_game()

func _on_settings_pressed():
	pause_panel.hide()
	settings_panel.show()

func _on_back_pressed():
	settings_panel.hide()
	pause_panel.show()

func _on_volume_changed(value: float):
	# Convert slider value (0-100) to decibels
	var volume_db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(0, volume_db)
	
	# Optional: Mute if slider is at 0
	if value == 0:
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, false)

func _on_main_menu_pressed():
	resume_game()  # Unpause before changing scenes
	get_tree().change_scene_to_file("res://main_menu.tscn")  # Change to your main menu path
