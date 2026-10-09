extends Node3D

@onready var ball = $"RigidBody3D-ball"
@onready var plane = $"MeshInstance3D-plane"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Shoot"):
		launch_ball()
	pass
	
func get_random_point_on_plane(plane: MeshInstance3D) -> Vector3:
	var plane_mesh := plane.mesh as PlaneMesh
	var width = plane_mesh.size.x
	var depth = plane_mesh.size.y
	var local_point = Vector3(randf_range(-width * 0.5, width * 0.5),0,randf_range(-depth * 0.5, depth * 0.5))
	return plane.global_transform * local_point

func calculate_launch_velocity(
	start: Vector3,
	target: Vector3,
	apex_height: float
) -> Vector3:
	var g = ProjectSettings.get_setting("physics/3d/default_gravity")
	# Apex must be above the higher of the two points
	var apex_y = max(start.y, target.y) + apex_height
	# Time to reach apex
	var ascent_height = apex_y - start.y
	var t_up = sqrt(2.0 * ascent_height / g)
	# Initial vertical velocity
	var vy = g * t_up
	# Time to fall from apex to target
	var descent_height = apex_y - target.y
	var t_down = sqrt(2.0 * descent_height / g)
	var total_time = t_up + t_down
	# Horizontal velocity
	var horizontal = Vector3(target.x - start.x,0,target.z - start.z) * 1.2
	var vxz = horizontal / total_time
	return Vector3(vxz.x,vy,vxz.z)

func launch_ball():
	ball.linear_velocity = Vector3.ZERO 
	ball.angular_velocity = Vector3.ZERO
	var target = get_random_point_on_plane($"MeshInstance3D-plane")
	var start = $"RigidBody3D-ball".global_position
	var height = 2
	var distance = Vector2(target.x, target.y).distance_to(Vector2(start.x, start.y))
	if distance <= 3:
		height == 2.5
	var velocity = calculate_launch_velocity(start,target,height)
	$"RigidBody3D-ball".linear_velocity = velocity
