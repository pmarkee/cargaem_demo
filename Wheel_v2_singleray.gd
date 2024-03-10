extends Node2D


@export var stiffness: float = 1500
@export var damping: float = 5
@export var wheel_radius: float = 31

@onready var suspension_rest_dist: float = $Ray.position.y - $SuspensionMountPoint.position.y
@onready var car = get_parent()
@onready var prev_spring_length: float = suspension_rest_dist


func _ready():
	$Ray.target_position.y = wheel_radius


func _physics_process(delta):
	if $Ray.is_colliding():
		# We shoot the ray from the wheel hub
		var ray_origin = $Ray.global_position
		var ray_dst = $Ray.get_collision_point()
		var distance = ray_dst.distance_to(ray_origin)

		var spring_length = clamp(suspension_rest_dist - wheel_radius + distance, 0, suspension_rest_dist)
		var spring_force = stiffness * (suspension_rest_dist - spring_length)
		var spring_velocity = (prev_spring_length - spring_length) / delta
		prev_spring_length = spring_length
		var damping_force = damping * spring_velocity

		var wheelhub_point = Vector2(ray_dst.x, ray_dst.y - wheel_radius)
		var force_to_add = Vector2.UP * (spring_force + damping_force)
		car.apply_force(force_to_add, wheelhub_point - car.global_position)
