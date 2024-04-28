extends Node2D

const MOMENT_OF_INERTIA = 0.1

@export_file var engine_file = "res://assets/engine/data.json"

@onready var rpm: float = 1000

var utils = load("res://utils.gd")
var torque_curve: Dictionary
var rpm_limit: int

var final_drive_ratio = 4.25

var current_gear: int = 0
const gear_ratios = [3.25, 1.909, 1.25, 0.909, 0.75]


func _ready():
	torque_curve = utils.read_torque_curve(engine_file)
	rpm_limit = torque_curve["rpm_values"][-1]


'''
throttle: throttle position between 0 and 1
external_load: resistance torque in Nm
delta: time elapsed since last physics update in seconds
Returns amount of effective work done by the engine in delta time and updates engine speed.
'''
func get_work(throttle: float, external_load: float, delta: float) -> float:
	var tq = _calculate_torque(torque_curve, rpm, throttle) # Torque in Nm.
	var net_tq = (tq - external_load) * gear_ratios[current_gear] * final_drive_ratio
	var power = _calculate_power(net_tq, rpm) # Power in Watts
	var work = power * delta # Work in Joules
	print("old rpm: ", rpm)
	rpm = _calculate_new_rpm(rpm, net_tq, delta)
	print("tq: ", tq)
	print("new rpm: ", rpm)
	print("power: ", power / 1000)
	print("-----------------")
	return max(work, 0)


func upshift():
	var new_gear = clamp(current_gear + 1, 0, gear_ratios.size() - 1)
	var new_rpm = rpm * gear_ratios[new_gear] / gear_ratios[current_gear]
	current_gear = new_gear
	rpm = new_rpm
	print("UPSHIFT ", current_gear + 1)
	


func downshift():
	var new_gear = clamp(current_gear - 1, 0, gear_ratios.size() - 1)
	var new_rpm = rpm * gear_ratios[new_gear] / gear_ratios[current_gear]
	current_gear = new_gear
	rpm = new_rpm
	print("DOWNSHIFT ", current_gear + 1)

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
		rpm_idx = _find_last_smaller(torque_curve["rpm_values"], rpm)
		var lower_rpm = torque_curve["rpm_values"][rpm_idx]
		var upper_rpm = torque_curve["rpm_values"][rpm_idx + 1]
		var tq_low_rpm = torque_curve["%.1f" % throttle][rpm_idx]
		var tq_high_rpm = torque_curve["%.1f" % throttle][rpm_idx + 1]
		var final_tq = tq_low_rpm + (tq_high_rpm - tq_low_rpm) * (rpm - lower_rpm) / (upper_rpm - lower_rpm)
		return final_tq

	elif rpm_idx != -1:
		# Don't need to interpolate between rpm values, only throttle
		throttle_idx = _find_last_smaller(torque_curve["throttle_values"], throttle)
		var lower_throttle = torque_curve["throttle_values"][throttle_idx]
		var upper_throttle = torque_curve["throttle_values"][throttle_idx + 1]
		var tq_low_throttle = torque_curve["%.1f" % lower_throttle][rpm_idx]
		var tq_high_throttle = torque_curve["%.1f" % upper_throttle][rpm_idx]
		var final_tq = tq_low_throttle + (tq_high_throttle - tq_low_throttle) * throttle
		return final_tq

	else:
		# 1. find nearest rpm and throttle values
		throttle_idx = _find_last_smaller(torque_curve["throttle_values"], throttle)
		var lower_throttle = torque_curve["throttle_values"][throttle_idx]
		var upper_throttle = torque_curve["throttle_values"][throttle_idx + 1]

		rpm_idx = _find_last_smaller(torque_curve["rpm_values"], rpm)
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
Takes torque in Nm and engine speed in RPM.
Returns power in kW.
'''
func _calculate_power(tq: float, rpm: float) -> float:
	# Convert engine speed to rad/s.
	var omega = 2 * PI * rpm / 60
	return tq * omega


'''
rpm: engine speed in rpm
tq: net torque of the engine (assuming external load is already subtracted)
delta: time elapsed since last physics update in seconds
Returns the new RPM of the engine.
'''
func _calculate_new_rpm(rpm: float, tq: float, delta: float) -> float:
	var omega = 2 * PI * rpm / 60 # Engine speed in rad/s.
	var angular_acceleration = tq / MOMENT_OF_INERTIA
	var new_omega = omega + angular_acceleration * delta
	var new_rpm = new_omega * 60 / (2 * PI) # New engine speed in rpm.
	#print("rpm: ", rpm)
	#print("omega: ", omega)
	#print("angular_acceleration: ", angular_acceleration)
	#print("new_omega: ", new_omega)
	#print("new_rpm: ", new_rpm)
	return clamp(new_rpm, 0, rpm_limit)

'''
Find the last element in an array that is smaller than the specified value.
The array is assumed to be ordered.
Returns the index of the element.
'''
func _find_last_smaller(values: Array, target: float) -> int:
	var closest_index = null
	var closest_diff = -1

	for i in range(values.size()):
		if values[i] >= target:
			return i - 1

	return -1
