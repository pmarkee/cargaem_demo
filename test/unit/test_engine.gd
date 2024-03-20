extends GutTest

class TestCalculateTorque:
	extends GutTest
	var engine_script = load("res://Engine.gd")
	var utils = load("res://utils.gd")
	var engine
	var torque_curve: Dictionary

	func before_all():
		torque_curve = utils.read_torque_curve("res://assets/engine/data.json")

	func before_each():
		engine = engine_script.new()

	func test_invalid_throttle():
		var tq = engine._calculate_torque(torque_curve, 3000, -1)
		assert_eq(tq, 0.0, "Should return 0 on invalid torque")
		var tq2 = engine._calculate_torque(torque_curve, 3000, 2)
		assert_eq(tq2, 0.0, "Should return 0 on invalid torque")
