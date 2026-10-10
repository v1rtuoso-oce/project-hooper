extends Node3D

@onready var ball = $"RigidBody3D-ball"
@onready var plane = $"MeshInstance3D-plane"

var power_set = [[1,1],[1,1]]
var power_min = power_set[0][0]
var power_max = power_set[1][0]
var jump = 1.5
var shot_time = 0.8
var elapsed = 0
var shot_valid = 1
var possession = true
var tween = create_tween()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ball.contact_monitor = true
	ball.max_contacts_reported = 1
	ball.body_entered.connect(_on_ball_body_entered)

func _on_ball_body_entered(_body: Node) -> void:
	if not possession and tween.is_running():
		tween.kill()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Label.text = str(power_min) + " and " + str(power_max)
	if possession and Input.is_action_just_pressed("Shoot"):
		elapsed = 0
		shot_valid = 1
		power_min = power_set[0][0]
		power_max = power_set[1][0]
		ready_shot()
	if possession and Input.is_action_pressed("Shoot") and elapsed < shot_time:
		elapsed = elapsed + delta * shot_valid
	if possession and (Input.is_action_just_released("Shoot") or elapsed > shot_time):
		tween.kill()
		possession = false
		shot_valid = 0
		elapsed = 0
		launch_ball()
	if Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()
	pass
	
func get_random_point_on_plane(plane: MeshInstance3D) -> Vector3:
	var plane_mesh := plane.mesh as PlaneMesh
	var width = plane_mesh.size.x
	var depth = plane_mesh.size.y
	var local_point = Vector3(randf_range(-width * 0.5, width * 0.5),0,randf_range(-depth * 0.5, depth * 0.5))
	return plane.global_transform * local_point

func _update_ball_trajectory(progress: float, start: Vector3, target: Vector3, apex_y: float) -> void:
	var apex_time = 1.0 / (1.0 + sqrt((apex_y - target.y) / (apex_y - start.y)))
	var vertical_offset = apex_y - start.y
	var position = start.lerp(target, progress)
	if progress <= apex_time:
		var ascent_progress = progress / apex_time
		var ascent_curve = ascent_progress * (2.0 - ascent_progress) + 0.3 * ascent_progress * pow(1.0 - ascent_progress, 3.0)
		position.y = start.y + vertical_offset * ascent_curve
	else:
		var descent_progress = (progress - apex_time) / (1.0 - apex_time)
		var descent_curve: float
		if descent_progress <= 0.75:
			descent_curve = pow(descent_progress, 2.0)
		else:
			var tail_progress = (descent_progress - 0.75) / 0.25
			var tail_start = pow(0.75, 2.0)
			var tail_start_tangent = 2.0 * 0.75 * 0.25
			var tail_end_tangent = 0.75
			var tail_progress_squared = pow(tail_progress, 2.0)
			var tail_progress_cubed = pow(tail_progress, 3.0)
			descent_curve = (2.0 * tail_progress_cubed - 3.0 * tail_progress_squared + 1.0) * tail_start
			descent_curve += (tail_progress_cubed - 2.0 * tail_progress_squared + tail_progress) * tail_start_tangent
			descent_curve += -2.0 * tail_progress_cubed + 3.0 * tail_progress_squared
			descent_curve += (tail_progress_cubed - tail_progress_squared) * tail_end_tangent
		position.y = apex_y - (apex_y - target.y) * descent_curve
	ball.global_position = position

func launch_ball():
	ball.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	ball.freeze = true
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	var target = get_random_point_on_plane(plane)
	var start = ball.global_position
	var apex_y = max(start.y, target.y) + 4.0
	var distance = Vector2(target.x - start.x, target.z - start.z).length()
	var shot_power = max(randf_range(power_min, power_max), 0.01)
	var duration = distance / (8.0 * shot_power)
	tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_method(
		_update_ball_trajectory.bind(start, target, apex_y),
		0.0, 1.0, duration
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	await tween.finished
	ball.freeze = false
	var apex_t = 1.0 / (1.0 + sqrt((apex_y - target.y) / (apex_y - start.y)))
	var vy = -3.  * (apex_y - target.y) / ((1.0 - apex_t) * duration)
	var v = Vector3((target.x - start.x) / duration, vy, (target.z - start.z) / duration)
	ball.linear_velocity = (v * 0.6).limit_length(8.0)
	ball.angular_velocity = Vector3.ZERO

func ready_shot():
	tween = create_tween()
	# First pair (runs at the same time)
	tween.tween_property(self, "power_min", power_set[0][1], shot_time / 2).from(power_set[0][0])
	tween.parallel().tween_property(self, "power_max", power_set[1][1], shot_time / 2).from(power_set[1][0])
	tween.parallel().tween_property(ball, "position:y", ball.position.y + jump, shot_time / 2).from(ball.position.y)
	
	# Second pair (runs at the same time, after the first pair finishes)
	tween.tween_property(self, "power_min", power_set[0][0], shot_time / 2).from(power_set[0][1])
	tween.parallel().tween_property(self, "power_max", power_set[1][0], shot_time / 2).from(power_set[1][1])
	tween.parallel().tween_property(ball, "position:y", ball.position.y, shot_time / 2).from(ball.position.y + jump)


func _on_rigid_body_3_dball_body_entered(body: Node) -> void:
	tween.kill()
	print(ball.linear_velocity, ball.angular_velocity)
	pass # Replace with function body.
