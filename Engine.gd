extends Node2D

const MOMENT_OF_INERTIA = 0.1

@export_file var engine_file = "res://assets/engine/data.json"

@onready var rpm: float = 1000

var utils = load("res://utils.gd")
var torque_curve: Dictionary
var rpm_limit: int


func _ready():
	torque_curve = utils.read_torque_curve(engine_file)
	rpm_limit = torque_curve["rpm_values"][-1]


func get_torque(throttle: float) -> float:
	return _calculate_torque(torque_curve, rpm, throttle)


'''
Based on current torque and load, update rpm.
'''
func apply_load(torque: float, load: float, delta: float):
	var net_torque = torque - load
	var angular_acceleration = net_torque / MOMENT_OF_INERTIA
	rpm += angular_acceleration * delta
	rpm = clamp(rpm, 0, rpm_limit) # TODO how to implement a realistic rpm limiter?
	print(rpm)


'''
Based on provided throttle position and load, calculate overall torque.
The torque curve values are assumed to be measured at the wheels, i.e. any
loss from the drivetrain (gearbox etc) is assumed to be accounted for in the curve
and doesn't need to be deducted.
External load (rolling resistance, air resistance etc) must be subtracted on the calling side.
'''
func _calculate_torque(torque_curve: Dictionary, rpm: int, throttle: float) -> float:
	if throttle > 1 || throttle < 0:
		# TODO how to properly handle errors?
		print("Throttle must be between 0 and 1")
		return 0.0

	var throttle_idx = torque_curve["throttle_values"].find(throttle)
	var rpm_idx = torque_curve["rpm_values"].find(rpm)
	if throttle_idx != -1 && rpm_idx != -1:
		# Value can be read directly without calculation
		return torque_curve["%.1f" % throttle][rpm_idx]

	elif throttle_idx != -1:
		# Don't need to interpolate between throttle values, only rpm
		rpm_idx = find_last_smaller(torque_curve["rpm_values"], rpm)
		var lower_rpm = torque_curve["rpm_values"][rpm_idx]
		var upper_rpm = torque_curve["rpm_values"][rpm_idx + 1]
		var tq_low_rpm = torque_curve["%.1f" % throttle][rpm_idx]
		var tq_high_rpm = torque_curve["%.1f" % throttle][rpm_idx + 1]
		var final_tq = tq_low_rpm + (tq_high_rpm - tq_low_rpm) * (rpm - lower_rpm) / (upper_rpm - lower_rpm)
		return final_tq

	elif rpm_idx != -1:
		# Don't need to interpolate between rpm values, only throttle
		throttle_idx = find_last_smaller(torque_curve["throttle_values"], throttle)
		var lower_throttle = torque_curve["throttle_values"][throttle_idx]
		var upper_throttle = torque_curve["throttle_values"][throttle_idx + 1]
		var tq_low_throttle = torque_curve["%.1f" % lower_throttle][rpm_idx]
		var tq_high_throttle = torque_curve["%.1f" % upper_throttle][rpm_idx]
		var final_tq = tq_low_throttle + (tq_high_throttle - tq_low_throttle) * throttle
		return final_tq

	else:
		# 1. find nearest rpm and throttle values
		throttle_idx = find_last_smaller(torque_curve["throttle_values"], throttle)
		var lower_throttle = torque_curve["throttle_values"][throttle_idx]
		var upper_throttle = torque_curve["throttle_values"][throttle_idx + 1]

		rpm_idx = find_last_smaller(torque_curve["rpm_values"], rpm)
		var lower_rpm = torque_curve["rpm_values"][rpm_idx]
		var upper_rpm = torque_curve["rpm_values"][rpm_idx + 1]

		# 2. find torque values at each rpm and throttle combination
		var lower_tq_1 = torque_curve["%.1f" % lower_throttle][rpm_idx]
		var lower_tq_2 = torque_curve["%.1f" % upper_throttle][rpm_idx]
		var upper_tq_1 = torque_curve["%.1f" % lower_throttle][rpm_idx + 1]
		var upper_tq_2 = torque_curve["%.1f" % upper_throttle][rpm_idx + 1]

		# 3. find intermediate torque values at both rpm values based on throttle
		var tq_low_rpm = lower_tq_1 + (lower_tq_2 - lower_tq_1) * throttle
		var tq_high_rpm = upper_tq_1 + (upper_tq_2 - upper_tq_1) * throttle

		# 4. find final torque between intermediate torque values based on rpm
		# NOTE: lower_tq could actually be higher than upper_tq, but the equation will still work
		var final_tq = tq_low_rpm + (tq_high_rpm - tq_low_rpm) * (rpm - lower_rpm) / (upper_rpm - lower_rpm)
		return final_tq


'''
Find the last element in an array that is smaller than the specified value.
The array is assumed to be ordered.
Returns the index of the element.
'''
func find_last_smaller(values: Array, target: float) -> int:
	var closest_index = null
	var closest_diff = -1

	for i in range(values.size()):
		if values[i] >= target:
			return i - 1

	return -1
