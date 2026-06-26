extends CanvasLayer

@export var next_scene : String

var dialogues = []

var typing_sound_timer := 0.0
var current_index := 0
var current_label : RichTextLabel

var fading_out := false
var typing := false

var char_timer := 0.0
var char_delay := 0.08


func _ready():
	$"Fade/2".modulate.a = 0.0

	randomize()

	for child in get_children():

		if child.name.begins_with("Dialogue"):

			dialogues.append(child)
			child.hide()

	$Fade.color.a = 1.0

	play_cutscene()


func _process(delta):

	# Fade In
	if !fading_out and $Fade.color.a > 0.0:

		$Fade.color.a = max($Fade.color.a - delta, 0.0)

	# Fade Out
	if fading_out:

		$Fade.color.a += delta * 5.0
		$Fade.color.a = min($Fade.color.a, 1.0)

		$"Fade/2".modulate.a = $Fade.color.a

		if $Fade.color.a >= 1.0:

			#get_tree().change_scene_to_file(next_scene)
			return

	# Stop typing sound after 30ms
	if typing_sound_timer > 0.0:

		typing_sound_timer -= delta

		if typing_sound_timer <= 0.0:

			$TypingSound.stop()

	if !typing:
		return

	char_timer += delta

	if char_timer >= char_delay:

		char_timer = 0.0

		current_label.visible_characters += 1

		$TypingSound.pitch_scale = randf_range(0.1, 0.4)
		$TypingSound.play()
		typing_sound_timer = 0.03

		if current_label.visible_characters >= current_label.get_total_character_count():

			current_label.visible_characters = current_label.get_total_character_count()
			typing = false

func play_cutscene():

	for i in dialogues.size():

		current_index = i

		show_dialogue(i)

		# Wait until typing finishes
		while typing:
			await get_tree().process_frame

		# Keep the dialogue on screen
		await get_tree().create_timer(2.0).timeout

		# Hide it unless it's the last one
		if i < dialogues.size() - 1:
			dialogues[i].hide()

	fading_out = true

func show_dialogue(index):

	dialogues[index].show()

	for child in dialogues[index].get_children():

		if child is RichTextLabel:

			current_label = child

		elif child is AudioStreamPlayer:

			child.play()

	current_label.visible_characters = 0

	char_timer = 0.0

	typing = true
