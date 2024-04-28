extends Node2D

const BRAKING_FORCE = 700
const PX_PER_M = 50

var throttle = 0.0

enum SuspensionVariant {
	V1_SINGLERAY,
	V1_MULTIRAY_ANGLE,
	V1_MULTIRAY_PARALLEL,
	V2_SINGLERAY
}

@export var variant = SuspensionVariant.V1_SINGLERAY
@export var wheelbase = 70
@export var wheel_radius = 0.4 * PX_PER_M # TODO make sure it's consistent here and in suspension


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

	if Input.is_action_just_pressed("ui_up"):
		$Engine.upshift()
	elif Input.is_action_just_pressed("ui_down"):
		$Engine.downshift()

	var external_load = 50 # TODO calculate resistances properly
	$Engine.update_engine_state(throttle, external_load, delta)

	var new_velocity = $Engine.wheel_omega() * wheel_radius
	var acceleration = (new_velocity - $Body.linear_velocity.x) / delta
	var force = Vector2($Body.mass * acceleration, 0)

	# TODO braking
	if Input.is_action_pressed("ui_select"):
		force.x -= sgn($Body.linear_velocity.x) * BRAKING_FORCE

	$Body.apply_force(force)
	
	var engine_work = $Engine.power() * delta
	var velocity_mps = $Body.linear_velocity.x / PX_PER_M

	var kinetic_e = $Body.mass / 2 * pow(velocity_mps, 2)
	var new_kinetic_e = $Body.mass / 2 * pow(new_velocity / PX_PER_M, 2)

	#print("wheel omega: ", $Engine.wheel_omega())
	#print("new_velocity kph: ", new_velocity / PX_PER_M * 3.6)
	#print("force: ", force / PX_PER_M)
	#print("v kph = ", velocity_mps * 3.6)
	print("current E: ", kinetic_e)
	print("engine work (J): ", engine_work)
	print("predicted E based on target velocity: ", new_kinetic_e)
	print("predicted E based on engine work: ", kinetic_e + engine_work)
	print("-----------")


func sgn(n: float) -> int:
	if n < 0:
		return -1
	elif n == 0:
		return 0
	return 1
