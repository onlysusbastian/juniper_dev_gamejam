extends CanvasLayer

@export var next_scene : String

var dialogues = []

var typing_sound_timer := 0.0
var current_index := 0
var current_label : RichTextLabel

var fading_out := false
var typing := false

var char_timer := 0.0
var char_delay := 0.03


func _ready():

	randomize()

	for child in get_children():

		if child.name.begins_with("Dialogue"):

			dialogues.append(child)
			child.hide()

	$Fade.color.a = 1.0

	show_dialogue(0)


func _process(delta):

	# Fade In
	if !fading_out and $Fade.color.a > 0.0:

		$Fade.color.a = max($Fade.color.a - delta, 0.0)

	# Fade Out
	if fading_out:

		$Fade.color.a = min($Fade.color.a + delta, 1.0)

		if $Fade.color.a >= 1.0:

			get_tree().change_scene_to_file(next_scene)
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

		$TypingSound.pitch_scale = randf_range(0.3, 1.1)
		$TypingSound.play()
		typing_sound_timer = 0.03

		if current_label.visible_characters >= current_label.get_total_character_count():

			current_label.visible_characters = current_label.get_total_character_count()
			typing = false


func _input(event):

	if !event.is_action_pressed("ui_accept"):
		return

	# Ignore input while fading out
	if fading_out:
		return

	# Finish current text instantly
	if typing:

		current_label.visible_characters = current_label.get_total_character_count()

		typing = false

		$TypingSound.stop()

		return

	# Safety check
	if current_index >= dialogues.size():
		return

	# Stop current dialogue audio
	for child in dialogues[current_index].get_children():

		if child is AudioStreamPlayer:
			child.stop()

	current_index += 1
 
	# If this was the last dialogue,
	# keep it visible while fading.
	if current_index >= dialogues.size():

		fading_out = true
		return

	# Otherwise hide the previous dialogue
	dialogues[current_index - 1].hide()

	show_dialogue(current_index)


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
