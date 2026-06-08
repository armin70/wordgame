extends Control


func _on_multi_player_pressed() -> void:
	PuzzleManager.is_multiplayer = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_single_player_pressed() -> void:
	PuzzleManager.is_multiplayer = false
	get_tree().change_scene_to_file("res://scenes/rps.tscn")
