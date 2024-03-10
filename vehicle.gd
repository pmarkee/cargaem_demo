extends Node2D

const ACCELERATION_FORCE = 500
const BRAKING_FORCE = 700


func _physics_process(delta):
	print($Body.linear_velocity)
	if !$Body/GroundContactRayCast.is_colliding():
		# This ray cast is a stupid way of detecting ground contact but it will do
		# We should detect ground contact of each wheel: ground distance <= wheel radius + spring max len
		return

	var force = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		force.x += ACCELERATION_FORCE
	if Input.is_action_pressed("ui_select"):
		force.x -= sgn($Body.linear_velocity.x) * BRAKING_FORCE
	
	var torque = 0.0
	if force.x > 0:
		# Accelerating - apply counter clockwise torque, lifting the front
		torque -= 50000
	elif force.x < 0:
		# Braking - apply clockwise torque, lifting the rear
		torque += 70000

	$Body.apply_force(force)
	$Body.apply_torque(torque)


func sgn(n: float) -> int:
	if n < 0:
		return -1
	elif n == 0:
		return 0
	return 1
