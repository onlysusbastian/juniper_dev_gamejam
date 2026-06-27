extends CanvasLayer

@onready var fade = $Fade

func _ready():

	fade.color.a = 0.0


func change_scene(scene_path:String):

	await fade_out()

	get_tree().change_scene_to_file(scene_path)

	await get_tree().process_frame

	await fade_in()


func fade_out():

	var tween = create_tween()

	tween.tween_property(
		fade,
		"color:a",
		1.0,
		0.5
	)

	await tween.finished


func fade_in():

	var tween = create_tween()

	tween.tween_property(
		fade,
		"color:a",
		0.0,
		0.5
	)

	await tween.finished
