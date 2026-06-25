extends CharacterBody3D

var enable_boost := true
var enable_special := true
var enable_airtime := true

@export var wobble_strength := 0.08
@export var tilt_strength := 0.03
@export var tilt_spring := 20.0
@export var tilt_damping := 8.0
@onready var attack_effect = $attackeffect
@onready var sparkle = $Visual/Sparkle
@onready var visual = $Visual/MeshInstance3D
@onready var blade1 = $Visual/MeshInstance3D/blade1
@onready var hit_effect = $hit_effect
@onready var judgement_text = $Visual/JudgementText

@export var attack_effect_duration := 1.0

const BIG_HIT_THRESHOLD := 2.0

var judgement_timer := 0.0
var judgement_duration := 1.0
var play_hit_animation = 0.0
var hit_animation_timer := 0.0
var airtime_progress := 0.0
var trail
var pending_hit_stop := 0.0
var hit_stop := 0.0
var airtime_start_y := 0.0
var attack_effect_timer := 0.0

var sparkle_hide_timer := 0.0
var hit_wobble_timer := 0.0
var hit_wobble_strength := 0.0

var flash_material : StandardMaterial3D
var original_material : Material
var hit_flash_timer := 0.0

@export var current_spin := 100.0
var current_boost := 200.0

@export var spin_damage_multiplier := 2.0
var spin_resistance := 1.0

var weight := 1.0
var move_speed := 15.0
var acceleration := 1.0

# Boost
var boost_multiplier := 1.8
var current_boost_multiplier := 1.0
var boost_acceleration := 4.0
var boost_drain := 25.0
var boost_regen := 8.0

# SPECIAL ATTACK

var charging_special := false
var special_charge_timer := 0.0

@export var special_charge_time := 1
@export var special_speed := 40
@export var special_duration := 0.3

# AIRTIME ATTACK

var airtime_active := false
var airtime_phase := 0
var airtime_timer := 0.0

@export var airtime_charge_time := 1.0
@export var airtime_height := 12.0
@export var airtime_dive_speed := 100

var airtime_target := Vector3.ZERO


var special_timer := 0.0
var special_direction := Vector3.ZERO

var hit_stun := 0.0
var knockback_velocity := Vector3.ZERO

var tilt := Vector2.ZERO
var tilt_velocity := Vector2.ZERO

var target_position := Vector3.ZERO

func _ready():
	hit_effect.visible = false

	hit_effect.animation_finished.connect(
		_on_hit_effect_finished
	)

	original_material = visual.get_active_material(0)

	flash_material = StandardMaterial3D.new()
	flash_material.albedo_color = Color.WHITE
	flash_material.emission_enabled = true
	flash_material.emission = Color.WHITE

func _physics_process(delta):
	
	if judgement_timer > 0:

		judgement_timer -= delta

		var progress = 1.0 - (
			judgement_timer / judgement_duration
		)

		# Move upward
		judgement_text.position.y = lerp(
			5.0,
			8.0,
			progress
		)

		# Fade in
		if progress < 0.2:

			judgement_text.modulate.a = (
				progress / 0.2
			)

		# Stay visible
		elif progress < 0.8:

			judgement_text.modulate.a = 1.0

		# Fade out
		else:

			judgement_text.modulate.a = (
				1.0 - (
					(progress - 0.8) / 0.2
				)
			)

	else:

		judgement_text.visible = false
	
	if hit_animation_timer > 0:

		hit_animation_timer -= delta

		if hit_animation_timer <= 0:

			hit_effect.visible = true
			hit_effect.stop()
			hit_effect.play()
		
	if attack_effect_timer > 0:

		attack_effect_timer -= delta
		attack_effect.visible = true

	else:

		attack_effect.visible = false
	
	if sparkle_hide_timer > 0:

		sparkle_hide_timer -= delta
		sparkle.visible = false

	else:

		sparkle.visible = true

	hit_wobble_timer -= delta

	if pending_hit_stop > 0:

		pending_hit_stop -= delta

		if pending_hit_stop <= 0:
			hit_stop = 0.001

	if hit_stop > 0:
		hit_stop -= delta
		return
		
	# START SPECIAL CHARGE

	if enable_special \
	and Input.is_action_just_pressed("special_attack1") \
	and current_boost >= 20 \
	and current_boost >= 20 \
	and !charging_special \
	and special_timer <= 0 \
	and !hit_effect.visible:
		attack_effect_timer = attack_effect_duration
		charging_special = true
		special_charge_timer = special_charge_time
		current_boost = current_boost - 20
		get_parent().trigger_shake(0.4)

	if enable_airtime \
	and Input.is_action_just_pressed("airtime_attack") \
	and current_boost >= 49 \
	and current_boost >= 49 \
	and !airtime_active \
	and !charging_special \
	and special_timer <= 0 \
	and !hit_effect.visible:
			attack_effect_timer = attack_effect_duration
			airtime_active = true
			#get_parent().camera_zoom(30.0)
			airtime_phase = 0
			airtime_timer = airtime_charge_time
			airtime_progress = 0.0
			get_parent().trigger_shake(0.4)

			airtime_start_y = global_position.y
			current_boost = current_boost - 49
	# CHARGING SPECIAL

	if charging_special:
		
		get_parent().camera_zoom(28.0)

		special_charge_timer -= delta

		velocity = Vector3.ZERO

		special_direction = (
			target_position - global_position
		)

		special_direction.y = 0

		if special_direction.length() > 0:
			special_direction = special_direction.normalized()

		current_spin += 50 * delta

		if special_charge_timer <= 0:
			
			#get_parent().camera_zoom(34.0)
			get_parent().trigger_shake(1.4)
			charging_special = false
			special_timer = special_duration

		return
	
	hit_flash_timer -= delta

	if hit_flash_timer > 0:
		visual.material_override = flash_material
	else:
		visual.material_override = original_material

	if current_spin <= 40:
		print("GAME OVER")
		return

	hit_stun -= delta
	if play_hit_animation and hit_stun <= 0:

		play_hit_animation = false

		hit_effect.visible = true
		hit_effect.stop()
		hit_effect.play()
	
	 # SPECIAL DASH

	if special_timer > 0:

		special_timer -= delta

		velocity = (
			special_direction
			* special_speed
		)

		move_and_slide()
		clamp_to_arena()
		
		var arena_radius := 14.0

		var flat_pos = Vector2(
			global_position.x,
			global_position.z
		)

		if flat_pos.length() > arena_radius:

			flat_pos = flat_pos.normalized() * arena_radius

			global_position.x = flat_pos.x
			global_position.z = flat_pos.y

			return
	
	# AIRTIME ATTACK

	if airtime_active:
		
		get_parent().camera_zoom(30.0)
		
		if airtime_phase == 0:

			airtime_timer -= delta

			velocity = Vector3.ZERO

			visual.visible = true

			airtime_progress += delta / airtime_charge_time

			var t = clamp(airtime_progress, 0.0, 1.0)

			var eased = 1.0 - pow(1.0 - t, 10.0)

			global_position.y = lerp(
				airtime_start_y,
				airtime_height,
				eased
			)

			if airtime_timer <= 0:

				airtime_target = target_position

				airtime_target.x = clamp(
					airtime_target.x,
					-14.0,
					14.0
				)

				airtime_target.z = clamp(
					airtime_target.z,
					-14.0,
					14.0
				)

				airtime_phase = 1
				airtime_progress = 0.0

				

		elif airtime_phase == 1:

			var dive_dir = (
				airtime_target - global_position
			).normalized()

			airtime_progress += delta

			var speed_multiplier = min(
				airtime_progress * 4.0,
				1.0
			)

			velocity = dive_dir * (
				airtime_dive_speed * speed_multiplier
			)
			move_and_slide()
			clamp_to_arena()

			if global_position.distance_to(
				airtime_target
			) < 3.0:
				$hard_hit.play()

				#visual.visible = true

				airtime_active = false
				get_parent().trigger_shake(3)
				airtime_phase = 0

				velocity = Vector3.ZERO
				global_position.y = 0.0

		return
	
	# BOOST

	if enable_boost \
	and Input.is_action_pressed("boost") \
	and current_boost >= 0:
		
		get_parent().camera_zoom(26.0)
		current_boost_multiplier = lerp(
			current_boost_multiplier,
			boost_multiplier,
			boost_acceleration * delta
		)
		$boost_tag.show()
		$hit_effect.hide()
		
		current_boost -= boost_drain * delta

	else:

		current_boost_multiplier = lerp(
			current_boost_multiplier,
			1.0,
			boost_acceleration * delta
		)
		$boost_tag.hide()
		#current_boost += boost_regen * delta

	current_boost = clamp(
		current_boost,
		0.0,
		100.0
	)

	# TILT

	var tilt_amount = 0.15
	var local_vel = velocity.normalized()

	rotation.x = lerp(
		rotation.x,
		local_vel.z * tilt_amount,
		5.0 * delta
	)

	rotation.z = lerp(
		rotation.z,
		-local_vel.x * tilt_amount,
		5.0 * delta
	)

	# MOVEMENT

	var direction = target_position - global_position
	direction.y = 0

	if hit_stun <= 0:

		if direction.length() > 1.0:

			var desired_velocity = (
				direction.normalized()
				* move_speed
				* current_boost_multiplier
			)

			velocity = velocity.lerp(
				desired_velocity,
				acceleration * delta
			)

		else:

			velocity = velocity.lerp(
				Vector3.ZERO,
				2.0 * delta
			)

	velocity += knockback_velocity

	move_and_slide()
	clamp_to_arena()
	
	global_position.y = 0.0
	velocity.y = 0.0
	knockback_velocity.y = 0.0

	knockback_velocity = knockback_velocity.lerp(
		Vector3.ZERO,
		5.0 * delta
	)

	# SPIN DECAY

	current_spin -= 0.5 * delta
	current_spin = max(current_spin, 0.0)

	# VISUAL SPIN

	visual.rotate_y(
		current_spin * 0.15 * delta
	)

	# VISUAL TILT

	var horizontal_velocity = Vector2(
		velocity.x,
		velocity.z
	)

	var target_tilt = Vector2(
		-horizontal_velocity.y,
		horizontal_velocity.x
	) * tilt_strength

	if hit_wobble_timer > 0:

		target_tilt += Vector2(
			sin(Time.get_ticks_msec() * 0.03),
			cos(Time.get_ticks_msec() * 0.035)
		) * hit_wobble_strength * (
			hit_wobble_timer / 0.25
		)

	var force = (
		target_tilt - tilt
	) * tilt_spring

	tilt_velocity += force * delta

	tilt_velocity *= exp(
		-tilt_damping * delta
	)

	tilt += tilt_velocity * delta

	visual.rotation.x = tilt.x
	visual.rotation.z = tilt.y

func clamp_to_arena():

	var arena_radius := 12.0

	var flat_pos = Vector2(
		global_position.x,
		global_position.z
	)

	if flat_pos.length() > arena_radius:

		var arena_normal = flat_pos.normalized()

		flat_pos = arena_normal * arena_radius

		global_position.x = flat_pos.x
		global_position.z = flat_pos.y

		var vel2d = Vector2(
			velocity.x,
			velocity.z
		)

		vel2d = vel2d.bounce(arena_normal) * 0.7

		velocity.x = vel2d.x
		velocity.z = vel2d.y

func got_hit():

	if attack_effect_timer > 0:
		return

	play_hit_animation = true

func _on_hit_effect_finished():

	hit_effect.visible = false

func show_judgement(text_value):

	judgement_text.text = text_value

	judgement_text.visible = true

	judgement_timer = judgement_duration

	judgement_text.position.y = 5

	judgement_text.modulate.a = 0.0
	
	judgement_text.scale = Vector3.ONE * 5.0
