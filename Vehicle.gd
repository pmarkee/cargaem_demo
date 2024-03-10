extends Node2D

const ACCELERATION_FORCE = 500
const BRAKING_FORCE = 700

enum SuspensionVariant {V1_SINGLERAY, V1_MULTIRAY_ANGLE, V1_MULTIRAY_PARALLEL}

@export var variant = SuspensionVariant.V1_SINGLERAY
@export var wheelbase = 70


func _ready():
	var scene_to_load = ""
	if variant == SuspensionVariant.V1_SINGLERAY:
		scene_to_load = "res://Wheel_v1_singleray.tscn"
	elif variant == SuspensionVariant.V1_MULTIRAY_PARALLEL:
		scene_to_load = "res://Wheel_v1_multiray_parallel.tscn"
	elif variant == SuspensionVariant.V1_MULTIRAY_ANGLE:
		scene_to_load = "res://Wheel_v1_multiray_angle.tscn"
	
	var wheel_scene = load(scene_to_load)
	var FrontWheel = wheel_scene.instantiate()
	FrontWheel.position.x = wheelbase
	var RearWheel = wheel_scene.instantiate()
	RearWheel.position.x = -wheelbase
	$Body.add_child(FrontWheel)
	$Body.add_child(RearWheel)


func _physics_process(delta):
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
