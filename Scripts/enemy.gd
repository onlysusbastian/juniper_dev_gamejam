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

				var impact_force = max(
					enemy_force,
					player_force
				)
				var spark = HIT_SPARK.instantiate()

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

	var move_velocity = Vector3.ZERO

	if stun_time <= 0:

		var move_dir = ai.get_move_direction()

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

	global_position.y = 0.0
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
