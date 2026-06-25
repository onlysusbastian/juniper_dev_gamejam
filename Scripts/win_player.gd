extends Node3D

func _on_next_button_pressed():
		match GameManager.current_mission:

			1:
				get_tree().change_scene_to_file(
					"res://Scenes/Cutscene2.tscn"
				)

			2:
				get_tree().change_scene_to_file(
					"res://Scenes/Cutscene3.tscn"
				)

			3:
				get_tree().change_scene_to_file(
					"res://Scenes/Ending.tscn"
				)
