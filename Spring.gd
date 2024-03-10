extends RayCast2D

@onready var stiffness = get_parent().stiffness / get_parent().get_child_count()
@onready var damping = get_parent().damping / get_parent().get_child_count()
@onready var rest_distance = get_parent().rest_distance

var offset = 0
var prev_offset = 0
var velocity = 0


func _ready():
	target_position.y = rest_distance


func _physics_process(delta):
	if is_colliding():
		prev_offset = offset
		offset = (target_position - get_collision_point() * global_transform).length()
		velocity = (offset - prev_offset) / delta
		var spring_force = stiffness * offset
		var damping_force = damping * velocity
		var force_to_add = Vector2.UP * (spring_force + damping_force)
		get_parent().get_parent().apply_force(force_to_add * delta, get_parent().position)
