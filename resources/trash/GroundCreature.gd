extends OldCreature
class_name OldGroundCreature

@export var acceleration: float = 12.0
@export var friction: float = 0.08

var peak_velocity: float = 0.0
@export var gravity_scale: float = 1.0

var _target_speed: float = 0.0 

# enum States { IDLE, RUN, JUMP, FALL }
# var state: States = States.IDLE

# Parent Creature class virtual method override
func _physics_apply(delta: float) -> void:
	_smooth_move_and_slide(delta)
	_apply_gravity(delta)

# TODO: consider axis independent gravity
func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	print(name, " gravity: ", get_gravity(), " ", peak_velocity, " ", velocity.y)
	velocity.y += get_gravity().y * delta * gravity_scale
	#if is_on_floor():
	#	peak_velocity = 0.0
	#	return

	#if velocity.y < 0:
	#	peak_velocity = max(peak_velocity, abs(velocity.y))
	#if velocity.y < 0:
	#	# Ascent: slower near apex using dynamic peak velocity
	#	var ascent_factor = clamp(abs(velocity.y) / max(peak_velocity, 50.0), 0.0, 1.0)
	#	velocity.y += get_gravity().y * delta * gravity_scale * (0.5 + 0.5 * ascent_factor)
	#else:
	#	# Descent: faster fall, reset peak velocity when starting to fall
	#	if abs(velocity.y) == 0.5:  # Near apex
	#		peak_velocity = 0.0  # Reset for next ascent
	#	velocity.y += get_gravity().y * delta * gravity_scale

func _smooth_move_and_slide(delta: float):
	if _target_speed != 0:
		velocity.x = lerp(float(velocity.x), _target_speed, acceleration * delta)
	else:
		velocity.x = lerp(float(velocity.x), 0.0, friction)
		# velocity.x = lerp(float(velocity.x), 0.0, friction * delta)

func set_target_speed(v: float) -> void:
	_target_speed = v

func get_target_speed() -> float:
	return _target_speed

func set_target_velocity(v: Vector2) -> void:
	_target_speed = v.x

func get_target_velocity() -> Vector2:
	return Vector2(_target_speed, 0)

# func _update_state() -> void:
# 	last_state = state
# 	if is_on_floor():
# 		state = States.JUMP if velocity.y < 0 else States.FALL
# 	elif abs(velocity.x) > EPS_SPEED:
# 		state = States.RUN
# 	else:
# 		state = States.IDLE

# func _emit_animation_if_changed() -> void:
# 	# flip logic based on velocity.x
# 	if abs(velocity.x) > EPS_SPEED:
# 		flip_h = velocity.x < 0.0
# 	if state != last_state or flip_h != last_flip_h:
# 		last_flip_h = flip_h
# 		last_state = state
# 		# emit a compact animation signal so UI/AnimationPlayer can respond
# 		emit_signal("animation_changed", state, flip_h)


# extends CharacterBody2D
# 
# # Gravity properties
# var gravity_direction := Vector2.DOWN  # Default gravity direction
# var gravity_strength := 980.0
# var gravity_scale := 1.0
# var peak_velocity := 0.0
# 
# func get_gravity_vector() -> Vector2:
# 	return gravity_direction * gravity_strength
# 
# func apply_gravity(delta: float) -> void:
# 	var gravity_vec = get_gravity_vector()
# 	
# 	# Set up_direction to be opposite of gravity for proper floor detection
# 	up_direction = -gravity_direction
# 	
# 	if not is_on_floor():
# 		# Get velocity component in gravity direction
# 		var velocity_in_gravity_dir = velocity.dot(gravity_direction)
# 		
# 		if velocity_in_gravity_dir < 0:
# 			# Moving against gravity - ascending
# 			peak_velocity = max(peak_velocity, abs(velocity_in_gravity_dir))
# 			
# 			var ascent_factor = clamp(abs(velocity_in_gravity_dir) / max(peak_velocity, 50.0), 0.0, 1.0)
# 			var gravity_effect = gravity_strength * delta * gravity_scale * (0.5 + 0.5 * ascent_factor)
# 			velocity += gravity_direction * gravity_effect
# 		else:
# 			# Moving with gravity - descending
# 			if abs(velocity_in_gravity_dir) < 1.0:  # Near apex
# 				peak_velocity = 0.0
# 			
# 			var gravity_effect = gravity_strength * delta * gravity_scale * 1.5
# 			velocity += gravity_direction * gravity_effect
# 	else:
# 		# Reset when on floor
# 		peak_velocity = 0.0
# 
# func set_gravity_direction(new_direction: Vector2):
# 	gravity_direction = new_direction.normalized()
# 
# func set_gravity_angle(angle_degrees: float):
# 	var angle_radians = deg_to_rad(angle_degrees)
# 	gravity_direction = Vector2(sin(angle_radians), cos(angle_radians)).normalized()
# 
# func _physics_process(delta):
# 	apply_gravity(delta)
# 	move_and_slide()
