extends Node2D
class_name SlimeScanner

signal stop_signal(position: Vector2)

const NO_COLLIDE_DELAY: float = 0.2
var _delay_timer: float = 0.0

@onready var floor_ray_cast: RayCast2D = $FloorRayCast
@onready var wall_ray_cast: RayCast2D = $WallRayCast

@export var speed: float = 200
var _launched: bool = false
var _timeout: float = 0.0
var _x_dir: int = 1

func _physics_process(delta: float) -> void:
	if not _launched:
		return
	global_position.x += _x_dir * speed * delta

	if _timeout > 0:
		_timeout -= delta
	if _delay_timer > 0:
		_delay_timer -= delta
		return
	
	if _timeout <= 0:
		_stop()
	if not floor_ray_cast.is_colliding():
		_stop()
	elif wall_ray_cast.is_colliding():
		_stop()

func _stop() -> void:
	stop_signal.emit(global_position)
	_launched = false


func launch(from: Creature, inversed: bool = false, timeout: float = 5.0) -> void:
	# right if inversed, left if not
	wall_ray_cast.target_position = Vector2(20, 0) if inversed else Vector2(-20, 0)
	floor_ray_cast.position = Vector2(20, 0) if inversed else Vector2(-20, 0)
	_x_dir = 1 if inversed else -1
	global_position = from.global_position
	_launched = true
	_timeout = timeout
	_delay_timer = NO_COLLIDE_DELAY
	
