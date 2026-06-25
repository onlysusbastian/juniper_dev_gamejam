extends Node3D

@export var mission_number := 1
@export var enable_special := true
@export var enable_airtime := true
@export var enable_boost := true

@onready var player_stamina_bar = $CanvasLayer/Control/PlayerStamina
@onready var player_boost_bar = $CanvasLayer/Control/PlayerBoost
@onready var enemy_stamina_bar = $CanvasLayer/Control/EnemyStamina

@onready var conductor = $Conductor
@onready var camera = $Camera3D
@onready var marker = $MouseMarker
@onready var player = $Player

var tutorial_page := 1
var practice_mode := false
var game_over := false
var game_started := false
var target_fov := 37.9
var camera_base_offset := Vector3.ZERO
var camera_offset := Vector3.ZERO
var beat_punch := 0.0

var shake_strength := 0.0
var shake_fade := 10.0
var shake_offset := Vector3.ZERO

func trigger_shake(strength := 0.5):

	shake_strength = max(
		shake_strength,
		strength
	)

func _ready():
	
	$CanvasLayer/Control/AnimationPlayer.play("fade_in")
	#mechanic switching
	player.enable_boost = enable_boost
	player.enable_special = enable_special
	player.enable_airtime = enable_airtime
		
	GameManager.current_mission = mission_number
	
	target_fov = camera.fov

	camera_base_offset = (
		camera.global_position
		- player.global_position
	)

	conductor.note_judged.connect(
		_on_note_judged
	)

	player_stamina_bar.max_value = 60
	player_boost_bar.max_value = 100
	enemy_stamina_bar.max_value = 60
	show_tutorial(1)
	player.set_physics_process(false)
	game_started = false

func _process(delta):
	if !game_started:
		return
	camera.fov = lerp(
	camera.fov,
	target_fov,
	8.0 * delta
	)

	target_fov = lerp(
		target_fov,
		37.9,
		10.0 * delta
	)

	beat_punch = lerp(
		beat_punch,
		0.0,
		10.0 * delta
	)

	if shake_strength > 0:

		shake_strength = lerp(
			shake_strength,
			0.0,
			shake_fade * delta
		)

		shake_offset = Vector3(
			randf_range(
				-shake_strength,
				shake_strength
			),
			0,
			randf_range(
				-shake_strength,
				shake_strength
			)
		)

	else:

		shake_offset = Vector3.ZERO

	var mouse_pos = get_viewport().get_mouse_position()

	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)

	var plane = Plane(Vector3.UP, 0)

	var hit = plane.intersects_ray(
		ray_origin,
		ray_dir
	)

	if hit != null:

		var arena_radius := 12.0

		var hit_2d = Vector2(
			hit.x,
			hit.z
		)

		if hit_2d.length() > arena_radius:

			hit_2d = hit_2d.normalized() * arena_radius

			hit.x = hit_2d.x
			hit.z = hit_2d.y

		marker.global_position = hit

		player.target_position = hit

		var offset = hit - player.global_position

		camera_offset = camera_offset.lerp(
			Vector3(
				clamp(offset.x, -1.5, 1.5),
				0,
				0
			),
			1.0 * delta
		)

	player_stamina_bar.value = player.current_spin - 40
	player_boost_bar.value = player.current_boost

	var beat_offset = Vector3(
		randf_range(-0.2, 0.2) * beat_punch,
		randf_range(-0.1, 0.1) * beat_punch,
		beat_punch
	)

	camera.global_position = (
	player.global_position
	+ camera_base_offset
	+ camera_offset
	+ shake_offset
	+ beat_offset
)

func _on_note_judged(result):	
	
	player.show_judgement(result)
	match result:

		"miss":
			$note_audio/miss.play()
			beat_punch = randf_range(
				0.0,
				0.0
			)

		"good":
			$note_audio/good.play()
			player.current_boost += 4
			player.current_spin += 1
			beat_punch = randf_range(
				0.0,
				0.0
			)

		"great":
			$note_audio/great.play()
			player.current_boost += 7
			player.current_spin += 4

			beat_punch = randf_range(
				0.2,
				0.2
			)

		"perfect":
			$note_audio/perfect.play()
			player.current_boost += 10 
			player.current_spin += 8

			beat_punch = randf_range(
				0.5,
				0.5
			)

	player.current_boost = clamp(
		player.current_boost,
		0.0,
		100.0
	)

	player.current_spin = clamp(
		player.current_spin,
		0.0,
		100.0
	)

	print(result)
	
func camera_zoom(fov_value):

	target_fov = fov_value

func start_countdown():

	game_started = false

	$CanvasLayer/Control/Countdown.visible = true
	
	player.set_physics_process(false)

	$CanvasLayer/Control/Countdown.text = "[center]3[/center]"
	await get_tree().create_timer(1.0).timeout

	$CanvasLayer/Control/Countdown.text = "[center]2[/center]"
	await get_tree().create_timer(1.0).timeout

	$CanvasLayer/Control/Countdown.text = "[center]1[/center]"
	await get_tree().create_timer(1.0).timeout

	$CanvasLayer/Control/Countdown.text = "[center]GO![/center]"
	await get_tree().create_timer(0.6).timeout

	$CanvasLayer/Control/Countdown.visible = false
	player.set_physics_process(true)
	game_started = true

func show_tutorial(page):

	$CanvasLayer/Tutorial.visible = true

	$CanvasLayer/Tutorial/Screen1.hide()
	$CanvasLayer/Tutorial/Screen2.hide()
	$CanvasLayer/Tutorial/Screen3.hide()

	match page:

		1:
			$CanvasLayer/Tutorial/Screen1.show()

		2:
			$CanvasLayer/Tutorial/Screen2.show()

		3:
			$CanvasLayer/Tutorial/Screen3.show()

func _on_next_button_pressed():

	tutorial_page += 1

	if tutorial_page <= 3:

		show_tutorial(tutorial_page)

	else:
		$CanvasLayer/Tutorial/NextButton.disabled = true

		$CanvasLayer/Tutorial.hide()

		await start_countdown()

		practice_mode = true

		$CanvasLayer/TutorialT.visible = true

func _input(event):

	if !practice_mode:
		return

	if event.is_action_pressed("finish_tutorial"):

		print("F PRESSED")

		practice_mode = false

		var anim = $CanvasLayer/Control/AnimationPlayer

		print(anim)
		print(anim.has_animation("fade_out"))

		anim.play("fade_out")

		print(anim.current_animation)

		await anim.animation_finished

		print("Animation finished")

		get_tree().change_scene_to_file("res://Scenes/main_1.tscn")
