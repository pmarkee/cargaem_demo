extends Node2D

const STIFFNESS = 5000
const DAMPING = 500
const GROUND_DISTANCE = 300

var offset = 0
var prev_offset = 0
var velocity = 0


func _ready():
	$RayCast2D.target_position.y = GROUND_DISTANCE


func _physics_process(delta):
	if $RayCast2D.is_colliding():
		prev_offset = offset
		offset = ($RayCast2D.target_position - $RayCast2D.get_collision_point() * global_transform).length()
		velocity = (offset - prev_offset) / delta
		var spring_force = STIFFNESS * offset
		var damping_force = DAMPING * velocity
		var force_to_add = Vector2.UP * (spring_force + damping_force)
		get_parent().apply_central_force(force_to_add * delta)
