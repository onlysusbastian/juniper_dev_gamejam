extends AudioStreamPlayer

@export var bpm := 100
@export var measures := 4

# Tracking the beat and song position
var last_judged_beat := -999
var song_position = 0.0
var song_position_in_beats = 1
var sec_per_beat = 60.0 / bpm
var last_reported_beat = 0
var beats_before_start = 0
var current_measure = 1

# Determining how close to the beat an event is
var closest = 0
var time_off_beat = 0.0

var perfect_window := 0.04
var great_window := 0.8
var good_window := 0.18

signal beat(position)
signal measure(position)
signal note_judged(result)


func _ready():
	sec_per_beat = 60.0 / bpm


func _physics_process(_delta):
	if playing:
		song_position = get_playback_position() + AudioServer.get_time_since_last_mix()
		song_position -= AudioServer.get_output_latency()
		song_position_in_beats = int(floor(song_position / sec_per_beat)) + beats_before_start
		_report_beat()


func _report_beat():
	if last_reported_beat < song_position_in_beats:
		if current_measure > measures:
			current_measure = 1
		emit_signal("beat", song_position_in_beats)
		emit_signal("measure", current_measure)
		last_reported_beat = song_position_in_beats
		current_measure += 1


func play_with_beat_offset(num):
	beats_before_start = num
	$StartTimer.wait_time = sec_per_beat
	$StartTimer.start()


func closest_beat(nth):
	closest = int(round((song_position / sec_per_beat) / nth) * nth) 
	time_off_beat = abs(closest * sec_per_beat - song_position)
	return Vector2(closest, time_off_beat)


func play_from_beat(beat_number, offset):
	play()
	seek(beat_number * sec_per_beat)
	beats_before_start = offset
	current_measure = beat_number % measures


func _on_StartTimer_timeout():
	song_position_in_beats += 1
	if song_position_in_beats < beats_before_start - 1:
		$StartTimer.start()
	elif song_position_in_beats == beats_before_start - 1:
		$StartTimer.wait_time = $StartTimer.wait_time - (AudioServer.get_time_to_next_mix() +
														AudioServer.get_output_latency())
		$StartTimer.start()
	else:
		play()
		$StartTimer.stop()
	_report_beat()

func _input(event):

	if event.is_action_pressed("rhythm_hit"):

		var beat_info = closest_beat(1)

		var beat_number = int(beat_info.x)

		if beat_number == last_judged_beat:
			return

		last_judged_beat = beat_number

		var error = beat_info.y

		if error <= perfect_window:

			note_judged.emit("perfect")

		elif error <= great_window:

			note_judged.emit("great")

		elif error <= good_window:

			note_judged.emit("good")

		else:

			note_judged.emit("miss")
