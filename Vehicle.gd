extends Node2D

const BRAKING_FORCE = 700
const PX_PER_M = 50

# Engine parameters
@export var MOMENT_OF_INERTIA = 1.0
@export var DRAG_COEFFICIENT = 0.5
@export var ROLLING_RESISTANCE = 10
@export var RPM_LIMIT = 6000

var throttle = 0.0

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
	if !$Body/GroundContactRayCast.is_colliding():
		# This ray cast is a stupid way of detecting ground contact but it will do
		# We should detect ground contact of each wheel: ground distance <= wheel radius + spring max len
		return

	if Input.is_action_pressed("ui_right"):
		throttle = 1.0
	else:
		throttle = 0.0

	var engine_torque = $Engine.get_torque(throttle)
	$Engine.apply_load(engine_torque, 10 + $Body.linear_velocity.x * 0.1, delta) # TODO calculate load instead of constant
	var force = Vector2(engine_torque * PX_PER_M / wheel_radius, 0)

	# TODO braking
	if Input.is_action_pressed("ui_select"):
		force.x -= sgn($Body.linear_velocity.x) * BRAKING_FORCE

	$Body.apply_force(force)


func sgn(n: float) -> int:
	if n < 0:
		return -1
	elif n == 0:
		return 0
	return 1
