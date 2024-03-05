extends Node2D

@export var stiffness = 5000
@export var damping = 500
@export var rest_distance = 100

var offset = 0
var prev_offset = 0
var velocity = 0


func _ready():
	$RayCast2D.target_position.y = rest_distance


func _physics_process(delta):
	if $RayCast2D.is_colliding():
		prev_offset = offset
		offset = ($RayCast2D.target_position - $RayCast2D.get_collision_point() * global_transform).length()
		velocity = (offset - prev_offset) / delta
		var spring_force = stiffness * offset
		var damping_force = damping * velocity
		var force_to_add = Vector2.UP * (spring_force + damping_force)
		get_parent().apply_force(force_to_add * delta, position)
