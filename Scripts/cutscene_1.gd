extends Node2D

func _on_continue_pressed():
	get_tree().change_scene_to_file(
		"res://Scenes/main_2.tscn"
	)
