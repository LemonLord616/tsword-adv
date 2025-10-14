extends Creature
class_name GroundEnemy

signal no_floor_in_front
signal wall_in_front
signal looks_at(node: Node2D)

@onready var hitbox: EnemyHitbox = $EnemyHitbox
@onready var floor_ray_cast: RayCast2D = $FloorRayCast
@onready var wall_ray_cast: RayCast2D = $WallRayCast
@onready var vision_ray_cast: RayCast2D = $VisionRayCast

@export var stun_duration: float = 1.0
var _stun_timer: float = 0.0

# more friction -> slower acceleration and faster decceleration
@export var friction: float = 0.5
@export var air_drag_coef: float = 0.1
@export var jump_velocity = -300.0
var _target_speed: float = 0.0

@export var sensor_signal_cooldown: float = 1.0
var _sensor_signal_timer: float = 0.0

func _ready() -> void:
	hitbox.player_in_hitbox.connect(_on_player_in_hitbox)
	was_knockbacked.connect(_on_knockback_stun)
	friction = clamp(friction, 0, 1)
	air_drag_coef = clamp(air_drag_coef, 0, 1)

func _on_player_in_hitbox(player: Player) -> void:
	if _stun_timer > 0:
		return
	attack_and_knockback(player)

func _on_knockback_stun(_from: Creature) -> void:
	_stun_timer = stun_duration

func _logic_apply(_delta: float) -> void:
	if _stun_timer > 0:
		return
	if is_on_floor() and _no_floor_in_front():
		no_floor_in_front.emit()
		_sensor_signal_timer = sensor_signal_cooldown
	elif is_on_floor() and _wall_in_front():
		wall_in_front.emit()
		_sensor_signal_timer = sensor_signal_cooldown
	if vision_ray_cast.is_colliding():
		looks_at.emit(vision_ray_cast.get_collider())

func _wall_in_front() -> bool:
	if _sensor_signal_timer > 0:
		return false
	return wall_ray_cast.is_colliding()

func _no_floor_in_front() -> bool:
	if _sensor_signal_timer > 0:
		return false
	return not floor_ray_cast.is_colliding()

func _physics_apply(delta: float) -> void:
	if _stun_timer > 0:
		_stun_timer -= delta
	if _sensor_signal_timer > 0:
		_sensor_signal_timer -= delta
	_apply_gravity(delta)
	_handle_target_speed(delta)

func _knockback_force(target: Node2D) -> Vector2:
	var x_dir = 1 if target.global_position > global_position else -1
	return Vector2(x_dir, -1).normalized() * knockback_strength

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	velocity.y += get_gravity().y * delta * gravity_scale

func _handle_target_speed(delta):
	#if is_on_floor():
		#_smooth_move_and_slide(delta)
	#else:
		#velocity.x = lerp(float(velocity.x), 0.0, air_drag_coef)
	_smooth_move_and_slide(delta)

func _jump(jump_speed: float = 0) -> void:
	if jump_speed == 0:
		velocity.y = jump_velocity
	else:
		velocity.y = jump_speed

func _smooth_move_and_slide(_delta: float):
	if _target_speed != 0:
		velocity.x = lerp(float(velocity.x), _target_speed, 1 - friction)
	else:
		velocity.x = lerp(float(velocity.x), 0.0, friction)

func set_target_speed(v: float) -> void:
	_target_speed = v

func get_target_speed() -> float:
	return _target_speed

func set_target_velocity(v: Vector2) -> void:
	_target_speed = v.x

func get_target_velocity() -> Vector2:
	return Vector2(_target_speed, 0)
