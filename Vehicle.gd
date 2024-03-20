extends Node2D

const ACCELERATION_FORCE = 500
const BRAKING_FORCE = 700

# Engine parameters
@export var MOMENT_OF_INERTIA = 1.0
@export var DRAG_COEFFICIENT = 0.5
@export var ROLLING_RESISTANCE = 10
@export var RPM_LIMIT = 6000

var rpm = 1000
var throttle = 0.0

const torque_curve = {
	1000: 650,
	1500: 830,
	2000: 980,
	2500: 1110,
	3000: 1220,
	3500: 1290,
	4000: 1340,
	4500: 1380,
	5000: 1360,
	5500: 1300,
	6000: 1220,
	6500: 1150,
}

enum SuspensionVariant {
	V1_SINGLERAY,
	V1_MULTIRAY_ANGLE,
	V1_MULTIRAY_PARALLEL,
	V2_SINGLERAY
}

@export var variant = SuspensionVariant.V1_SINGLERAY
@export var wheelbase = 70
@export var wheel_radius = 31 # TODO make sure it's consistent here and in suspension


func _ready():
	var scene_to_load = ""
	if variant == SuspensionVariant.V1_SINGLERAY:
		scene_to_load = "res://Wheel_v1_singleray.tscn"
	elif variant == SuspensionVariant.V1_MULTIRAY_PARALLEL:
		scene_to_load = "res://Wheel_v1_multiray_parallel.tscn"
	elif variant == SuspensionVariant.V1_MULTIRAY_ANGLE:
		scene_to_load = "res://Wheel_v1_multiray_angle.tscn"
	elif variant == SuspensionVariant.V2_SINGLERAY:
		scene_to_load = "res://Wheel_v2_singleray.tscn"
	
	var wheel_scene = load(scene_to_load)
	var FrontWheel = wheel_scene.instantiate()
	FrontWheel.position.x = wheelbase
	var RearWheel = wheel_scene.instantiate()
	RearWheel.position.x = -wheelbase
	$Body.add_child(FrontWheel)
	$Body.add_child(RearWheel)


func _physics_process(delta):
	find_closest_key(torque_curve, 1800)
	if !$Body/GroundContactRayCast.is_colliding():
		# This ray cast is a stupid way of detecting ground contact but it will do
		# We should detect ground contact of each wheel: ground distance <= wheel radius + spring max len
		return

	if Input.is_action_pressed("ui_right"):
		throttle = 1
	else:
		throttle = 0
	
	var engine_torque = calculate_engine_torque(delta)
	var force = Vector2(engine_torque / wheel_radius, 0)

	# TODO braking
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


func calculate_engine_torque(delta: float) -> float:
	var closest_rpm = find_closest_key(torque_curve, rpm)
	var engine_torque = torque_curve[closest_rpm] * throttle
	var resistance = DRAG_COEFFICIENT * $Body.linear_velocity.x + ROLLING_RESISTANCE
	var net_torque = engine_torque - resistance
	var angular_acceleration = net_torque / MOMENT_OF_INERTIA
	rpm += angular_acceleration * delta
	rpm = clamp(rpm, 0, RPM_LIMIT)
	print(net_torque)
	print(rpm)
	return net_torque


func find_closest_key(dict: Dictionary, target: int) -> int:
	var closest_key = null
	var closest_diff = -1
	
	var keys = dict.keys()
	keys.sort()
	for key in keys:
		var diff = abs(key - target)
		if closest_key == null || diff < closest_diff:
			closest_key = key
			closest_diff = diff

	return closest_key


func sgn(n: float) -> int:
	if n < 0:
		return -1
	elif n == 0:
		return 0
	return 1
