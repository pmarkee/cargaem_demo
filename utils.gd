extends Node


static func read_torque_curve(path) -> Dictionary:
	# NOTE might need to use ResourceLoader in exported project!
	var file = FileAccess.open(path, FileAccess.READ)
	if !file:
		print(FileAccess.get_open_error())
	var json_string = file.get_as_text()
	file.close()

	var data = JSON.parse_string(json_string)
	if !data:
		print("error parsing json")
		return {}

	#for i in range(data["rpm_values"].size()):
		# All numbers are read as float for whatever reason
		#data["rpm_values"][i] = int(data["rpm_values"][i])

	return data


static func rpm_to_rad_per_sec(rpm: float) -> float:
	return rpm * 2 * PI / 60


static func rad_per_sec_to_rpm(omega: float) -> float:
	return omega * 60 / (2 * PI)
