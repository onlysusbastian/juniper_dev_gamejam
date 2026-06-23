extends CharacterBody3D

@export var wobble_strength := 0.08
@export var tilt_strength := 0.03
@export var tilt_spring := 20.0
@export var tilt_damping := 8.0

@onready var sparkle = $Visual/Sparkle
@onready var visual = $Visual/MeshInstance3D
@onready var blade1 = $Visual/MeshInstance3D/blade1
const BIG_HIT_THRESHOLD := 2.0

var trail
var pending_hit_stop := 0.0
var hit_stop := 0.0

var sparkle_hide_timer := 0.0
var hit_wobble_timer := 0.0
var hit_wobble_strength := 0.0

var flash_material : StandardMaterial3D
var original_material : Material
var hit_flash_timer := 0.0

var current_spin := 100.0
var current_boost := 100.0

var spin_damage_multiplier := 2.0
var spin_resistance := 1.0

var weight := 1.0
var move_speed := 8.0
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

@export var special_charge_time := 1.0
@export var special_speed := 40
@export var special_duration := 0.3

var special_timer := 0.0
var special_direction := Vector3.ZERO

var hit_stun := 0.0
var knockback_velocity := Vector3.ZERO

var tilt := Vector2.ZERO
var tilt_velocity := Vector2.ZERO

var target_position := Vector3.ZERO

func _ready():

	original_material = visual.get_active_material(0)

	flash_material = StandardMaterial3D.new()
	flash_material.albedo_color = Color.WHITE
	flash_material.emission_enabled = true
	flash_material.emission = Color.WHITE

func _physics_process(delta):
	
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

	if Input.is_action_just_pressed("special_attack1") \
	and !charging_special \
	and special_timer <= 0:

		charging_special = true
		special_charge_timer = special_charge_time
	
	# CHARGING SPECIAL

	if charging_special:

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
	
	 # SPECIAL DASH

	if special_timer > 0:

		special_timer -= delta

		velocity = (
			special_direction
			* special_speed
		)

		move_and_slide()

		return

	# BOOST

	if Input.is_action_pressed("boost") and current_boost > 0:

		current_boost_multiplier = lerp(
			current_boost_multiplier,
			boost_multiplier,
			boost_acceleration * delta
		)
		current_boost -= boost_drain * delta

	else:

		current_boost_multiplier = lerp(
			current_boost_multiplier,
			1.0,
			boost_acceleration * delta
		)
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
