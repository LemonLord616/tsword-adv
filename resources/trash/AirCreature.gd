extends OldCreature
class_name OldAirCreature

var is_flying: bool = true
var _target_velocity: Vector2 = Vector2.ZERO

@export var smooth_factor: float = 0.5

func _physics_apply(delta: float) -> void:
	_smooth_move_and_slide(delta)

func _smooth_move_and_slide(_delta: float):
	velocity = velocity.lerp(_target_velocity, smooth_factor)

func set_target_velocity(v: Vector2) -> void:
	_target_velocity = v

func get_target_velocity() -> Vector2:
	return _target_velocity
