# GameManager.gd - Make this an Autoload
extends Node

# Player stats that persist across scenes
var player_hp: int = 50
var player_max_hp: int = 50
var player_gold: int = 15

# Track which area we came from
var last_area: String = ""

# Scene paths
var scene_paths = {
	"outdoor": "res://start.tscn",  # UPDATE THIS to your outdoor scene path
	"house_interior": "res://house_interior.tscn"  # UPDATE THIS to your interior scene path
}

func save_player_stats(player):
	"""Call this before changing scenes to save player data"""
	if player:
		player_hp = player.hp
		player_gold = player.gold
		player_max_hp = player.maxHP
		print("Saved player stats - HP: ", player_hp, " Gold: ", player_gold)

func restore_player_stats(player):
	"""Call this after scene loads to restore player data"""
	if player:
		player.hp = player_hp
		player.gold = player_gold
		player.maxHP = player_max_hp
		print("Restored player stats - HP: ", player_hp, " Gold: ", player_gold)

func change_area(from_area: String, to_area: String):
	"""Change to a different area/scene"""
	last_area = from_area
	print("Changing from ", from_area, " to ", to_area)
	
	# Save player stats before transition
	var player = get_tree().get_first_node_in_group("player")
	if player:
		save_player_stats(player)
	
	# Change scene
	if scene_paths.has(to_area):
		get_tree().change_scene_to_file(scene_paths[to_area])
	else:
		print("ERROR: Unknown area: ", to_area)
