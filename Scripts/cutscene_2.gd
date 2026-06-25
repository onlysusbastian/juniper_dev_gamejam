extends CanvasLayer

@export var next_scene : String

var dialogues = []
var typing_sound_timer := 0.0
var current_index := 0
var current_label : RichTextLabel

var typing := false
var char_timer := 0.0
var char_delay := 0.03


func _ready():

	randomize()

	for child in get_children():

		if child.name.begins_with("Dialogue"):

			dialogues.append(child)
			child.hide()

	show_dialogue(0)


func _process(delta):

	if !typing:
		return

	char_timer += delta

	if char_timer >= char_delay:

		char_timer = 0.0

		current_label.visible_characters += 1

		# Play typing sound for every character
		$TypingSound.pitch_scale = randf_range(0.3,1.3)
		#if !$TypingSound.playing:
		$TypingSound.play()
		typing_sound_timer = 0.03

		if current_label.visible_characters >= current_label.get_total_character_count():

			typing = false


func _input(event):

	if !event.is_action_pressed("ui_accept"):
		return

	if typing:

		current_label.visible_characters = current_label.get_total_character_count()

		typing = false

		$TypingSound.stop()

	else:

		# Stop current dialogue voice
		for child in dialogues[current_index].get_children():

			if child is AudioStreamPlayer:
				child.stop()

		dialogues[current_index].hide()

		current_index += 1

		if current_index >= dialogues.size():

			get_tree().change_scene_to_file(next_scene)

		else:

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
