extends CharacterBody3D

@onready var ai = $Visual
@onready var visual = $Visual/MeshInstance3D
@onready var blade2 = $Visual/MeshInstance3D/blade2
const BIG_HIT_THRESHOLD := 2.0
const HIT_SPARK = preload(
	"res://Scenes/HitSpark.tscn"
)
var pending_hit_stop := 0.0
var hit_stop := 0.0
var boost_timer := 0.0
var boosting := false
var charging_special := false
var special_charge_timer := 0.0

var special_timer := 0.0
var special_direction := Vector3.ZERO
var airtime_active := false
var airtime_phase := 0
var airtime_timer := 0.0
var airtime_progress := 0.0
var airtime_target := Vector3.ZERO
var airtime_start_y := 0.0
var airtime_cooldown := 8.0

@export var airtime_charge_time := 1.0
@export var airtime_height := 12.0
@export var airtime_dive_speed := 100.0


@export var special_charge_time := 1.0
@export var special_speed := 40.0
@export var special_duration := 0.3

var hit_wobble_timer := 0.0
var hit_wobble_strength := 0.0

var tilt := Vector2.ZERO
var tilt_velocity := Vector2.ZERO

var tilt_strength := 0.03
var tilt_spring := 20.0
var tilt_damping := 8.0

var flash_material : StandardMaterial3D
var original_material : Material
var hit_flash_timer := 0.0
var regen_rate := 2

var current_spin := 100.0
var current_boost := 100.0

var boost_multiplier := 1.8
var current_boost_multiplier := 1.0

var boost_acceleration := 4.0
var boost_drain := 25.0
var boost_regen := 8.0

var weight := 1.5
var move_speed := 10.0
var acceleration := 2.0

var spin_damage_multiplier := 1.0
var spin_resistance := 1.0

var stun_time := 0.0
var hit_cooldown := 0.8

var player : CharacterBody3D
var knockback_velocity := Vector3.ZERO


func _ready():

	original_material = visual.get_active_material(0)

	flash_material = StandardMaterial3D.new()
	flash_material.albedo_color = Color.WHITE
	flash_material.emission_enabled = true
	flash_material.emission = Color.WHITE

	ai.enemy = self


func _physics_process(delta):
	
	
	if player \
	and !charging_special \
	and special_timer <= 0 \
	and !airtime_active:

		if randf() < 0.002:

			charging_special = true
			special_charge_timer = special_charge_time
			$Visual/effect.show()
			
	if player \
	and !airtime_active \
	and !charging_special \
	and special_timer <= 0 \
	and airtime_cooldown <= 0:

		if randf() < 0.002:
			$Visual/effect.show()
			airtime_active = true
			airtime_phase = 0
			airtime_timer = airtime_charge_time
			airtime_progress = 0.0
			airtime_start_y = global_position.y

			airtime_cooldown = randf_range(6.0, 12.0)
	
	boost_timer -= delta
	airtime_cooldown -= delta

	if boost_timer <= 0:

		boosting = !boosting

		if boosting:
			boost_timer = randf_range(1.0, 2.0)
		else:
			boost_timer = randf_range(2.0, 4.0)

	hit_wobble_timer -= delta

	if pending_hit_stop > 0:

		pending_hit_stop -= delta

		if pending_hit_stop <= 0:
			hit_stop = 0.05

	if hit_stop > 0:

		hit_stop -= delta
		return

	hit_flash_timer -= delta

	if hit_flash_timer > 0:
		visual.material_override = flash_material
	else:
		visual.material_override = original_material

	if current_spin <= 40:
		queue_free()
		return

	current_spin -= 1.0 * delta
	current_spin += regen_rate * delta

	current_spin = clamp(
		current_spin,
		0.0,
		100.0
	)

	stun_time -= delta
	hit_cooldown -= delta

	if player:

		if global_position.distance_to(player.global_position) < 4 and hit_cooldown <= 0:
			$Visual/effect.hide()
			var push_dir = global_position - player.global_position
			push_dir.y = 0

			if push_dir.length() > 0:

				push_dir = push_dir.normalized()

				var enemy_force = (
					velocity.length()
					* (0.2 * current_spin / 100.0)
					/ weight
				)

				var player_force = (
					player.velocity.length()
					* (0.2 * player.current_spin / 100.0)
					/ player.weight
				)

				knockback_velocity += (
					push_dir
					* player_force
					* 0.15
				)

				player.knockback_velocity -= (
					push_dir
					* enemy_force
					* 0.3
				)
				player.knockback_velocity.y = 0.0

				var impact_force = max(
					enemy_force,
					player_force
				)
				var spark = HIT_SPARK.instantiate()
				$hit.pitch_scale = randf_range(0.8,1.03) 
				$hit.play()

				get_parent().add_child(
					spark
				)

				var hit_pos = (
					global_position +
					player.global_position
				) * 0.5

				hit_pos.y += 6

				hit_pos += push_dir * 0.2

				spark.global_position = hit_pos
				spark.scale = Vector3.ONE * 8
				player.sparkle_hide_timer = 0.15
				if impact_force > BIG_HIT_THRESHOLD:

					hit_flash_timer = 0.06
					player.hit_flash_timer = 0.06

				get_parent().trigger_shake(
					clamp(
						impact_force * 5,
						0.02,
						0.25
					)
				)

				player.hit_stun = 0.05

				if enemy_force > player_force:
					player.got_hit()

				hit_wobble_timer = 0.25
				player.hit_wobble_timer = 0.25

				hit_wobble_strength = impact_force * 0.3
				player.hit_wobble_strength = impact_force * 0.1

				var impact_speed = (
					velocity - player.velocity
				).length()

				var base_spin_damage = impact_speed * 0.7

				if enemy_force > player_force:

					current_spin -= (
						base_spin_damage
						* 0.1
						/ weight
						/ spin_resistance
					)

					player.current_spin -= (
						base_spin_damage
						* spin_damage_multiplier
						/ player.weight
						/ player.spin_resistance
					)

				else:

					current_spin -= (
						base_spin_damage
						* player.spin_damage_multiplier
						/ weight
						/ spin_resistance
					)

					player.current_spin -= (
						base_spin_damage
						* 0.5
						/ player.weight
						/ player.spin_resistance
					)

				current_spin = max(current_spin, 0.0)
				player.current_spin = max(player.current_spin, 0.0)

				hit_cooldown = 0.2
				stun_time = 0.1
	
	if charging_special:

		special_charge_timer -= delta

		velocity = Vector3.ZERO

		special_direction = (
			player.global_position
			- global_position
		)

		special_direction.y = 0

		if special_direction.length() > 0:
			special_direction = special_direction.normalized()

		if special_charge_timer <= 0:
			$Visual/effect.hide()
			charging_special = false
			special_timer = special_duration

		return
		
	if special_timer > 0:

		special_timer -= delta

		velocity = (
			special_direction
			* special_speed
		)

		move_and_slide()

		return
		
	if airtime_active:

		if airtime_phase == 0:

			airtime_timer -= delta

			velocity = Vector3.ZERO

			airtime_progress += delta / airtime_charge_time

			var t = clamp(
				airtime_progress,
				0.0,
				1.0
			)

			var eased = 1.0 - pow(
				1.0 - t,
				10.0
			)

			global_position.y = lerp(
				airtime_start_y,
				airtime_height,
				eased
			)

			if airtime_timer <= 0:

				airtime_target = player.global_position
				airtime_target.y = 0

				airtime_phase = 1
				airtime_progress = 0.0

		elif airtime_phase == 1:

			var dive_dir = (
				airtime_target - global_position
			)

			if dive_dir.length() > 0:
				dive_dir = dive_dir.normalized()

			airtime_progress += delta

			var speed_multiplier = min(
				airtime_progress * 4.0,
				1.0
			)

			velocity = dive_dir * (
				airtime_dive_speed
				* speed_multiplier
			)

			move_and_slide()

			if global_position.distance_to(
				airtime_target
			) < 3.0:
				$hard_hit.play()

				airtime_active = false
				airtime_phase = 0

				velocity = Vector3.ZERO
				if !airtime_active:

					global_position.y = 0.0
					velocity.y = 0.0
					knockback_velocity.y = 0.0

		return
	
	var move_velocity = Vector3.ZERO

	if stun_time <= 0:

		var move_dir = ai.get_move_direction()

		current_boost_multiplier = (
			boost_multiplier
			if boosting
			else 1.0
		)

		move_velocity = (
			move_dir
			* move_speed
			* current_boost_multiplier
		)

	velocity = velocity.lerp(
		move_velocity,
		acceleration * delta
	)

	velocity += knockback_velocity

	move_and_slide()
	
	velocity.y = 0.0
	knockback_velocity.y = 0.0

	knockback_velocity = knockback_velocity.lerp(
		Vector3.ZERO,
		2.0 * delta
	)

	blade2.rotate_y(
	current_spin * 0.15 * delta
	)

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

	blade2.rotation.x = tilt.x
	blade2.rotation.z = tilt.y
