extends Creature
class_name AirEnemy

@onready var hitbox: EnemyHitbox = $EnemyHitbox
@export var stun_duration: float = 1.0
var _stun_timer: float = 0.0

# more friction -> slower acceleration and faster decceleration
@export var air_drag_coef: float = 0.3
var _target_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	hitbox.player_in_hitbox.connect(_on_player_in_hitbox)
	was_knockbacked.connect(_on_knockback_stun)
	air_drag_coef = clamp(air_drag_coef, 0, 1)

func _on_player_in_hitbox(player: Player) -> void:
	if _stun_timer > 0:
		return
	attack_and_knockback(player)

func _on_knockback_stun(_from: Creature) -> void:
	_stun_timer = stun_duration

func _logic_apply(delta: float) -> void:
	if _stun_timer > 0:
		return
	_handle_target_speed(delta)

func _physics_apply(delta: float) -> void:
	if _stun_timer > 0:
		_stun_timer -= delta

func _knockback_force(target: Node2D) -> Vector2:
	var dir = target.global_position - global_position
	return dir.normalized() * knockback_strength

func _handle_target_speed(_delta):
	if _target_velocity.length() != 0:
		velocity = velocity.lerp(_target_velocity, 1 - air_drag_coef)
	else:
		velocity = velocity.lerp(_target_velocity, air_drag_coef)

func set_target_velocity(v: Vector2) -> void:
	_target_velocity = v

func get_target_velocity() -> Vector2:
	return _target_velocity	
