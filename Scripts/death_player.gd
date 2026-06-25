extends Node3D

func _on_next_pressed():
		match GameManager.current_mission:

			1:
				get_tree().change_scene_to_file(
					"res://Scenes/main_1.tscn"
				)

			2:
				get_tree().change_scene_to_file(
					"res://Scenes/main_2.tscn"
				)

			3:
				get_tree().change_scene_to_file(
					"res://Scenes/main.tscn"
				)
