extends Node

var enemy
var player

var state := "hunt"
var state_timer := 0.0

var attack_target := Vector3.ZERO

func _process(delta):

	if enemy == null or player == null:
		return

	state_timer -= delta

	var distance_to_player = enemy.global_position.distance_to(
		player.global_position
	)

	match state:

		"hunt":

			if distance_to_player < 7.0:
				change_state(
					"position",
					randf_range(0.5, 1.0)
				)

		"position":

			if state_timer <= 0:

				var predicted_pos = (
					player.global_position
					+ player.velocity * 0.5
				)

				var side_dir = Vector3(
					-player.velocity.z,
					0,
					player.velocity.x
				)

				if side_dir.length() < 0.1:
					side_dir = Vector3.RIGHT

				side_dir = side_dir.normalized()

				if randf() < 0.5:
					side_dir *= -1

				attack_target = (
					predicted_pos
					+ side_dir * 2.5
				)

				change_state(
					"commit",
					0.5
				)

		"commit":

			if state_timer <= 0:

				change_state(
					"attack",
					1.0
				)

		"attack":

			if state_timer <= 0:

				change_state(
					"recover",
					1.0
				)

		"recover":

			if state_timer <= 0:

				change_state(
					"hunt",
					randf_range(0.5, 1.5)
				)

func change_state(new_state, duration):

	state = new_state
	state_timer = duration

	#print("AI:", state)

func should_boost() -> bool:

	return state == "attack"

func get_move_direction() -> Vector3:

	if enemy == null or player == null:
		return Vector3.ZERO

	match state:

		"hunt":

			var dir = (
				player.global_position
				- enemy.global_position
			)

			dir.y = 0

			if dir.length() > 0:
				return dir.normalized()

		"position":

			var predicted_pos = (
				player.global_position
				+ player.velocity * 0.5
			)

			var side_dir = Vector3(
				-player.velocity.z,
				0,
				player.velocity.x
			)

			if side_dir.length() < 0.1:
				side_dir = Vector3.RIGHT

			side_dir = side_dir.normalized()

			var target = (
				predicted_pos
				+ side_dir * 2.5
			)

			var dir = target - enemy.global_position
			dir.y = 0

			if dir.length() > 0:
				return dir.normalized()

		"commit":

			var dir = (
				attack_target
				- enemy.global_position
			)

			dir.y = 0

			if dir.length() > 0:
				return dir.normalized()

		"attack":

			var dir = (
				attack_target
				- enemy.global_position
			)

			dir.y = 0

			if dir.length() > 0:
				return dir.normalized()

		"recover":

			var dir = (
				enemy.global_position
				- player.global_position
			)

			dir.y = 0

			if dir.length() > 0:
				return dir.normalized()

	return Vector3.ZERO
