extends OldGroundCreature
class_name OldGroundEnemy

signal no_floor_in_front
signal wall_in_front
signal looks_at(node: Node2D)

@onready var hitbox: EnemyHitbox = $EnemyHitbox
@onready var floor_ray_cast: RayCast2D = $FloorRayCast
@onready var wall_ray_cast: RayCast2D = $WallRayCast
@onready var vision_ray_cast: RayCast2D = $VisionRayCast

enum States { IDLE, MOVE, ATTACK }

func _ready() -> void:
	hitbox.player_in_hitbox.connect(_on_player_in_hitbox)

func _logic_apply(_delta: float) -> void:
	handle_state()
	if flippable:
		handle_flip()
	if not is_on_floor():
		set_target_speed(0)
		return
	if is_on_floor() and not floor_ray_cast.is_colliding():
		no_floor_in_front.emit()
	elif is_on_floor() and wall_ray_cast.is_colliding():
		wall_in_front.emit()
	if vision_ray_cast.is_colliding():
		looks_at.emit(vision_ray_cast.get_collider())

func _on_player_in_hitbox(player: Player) -> void:
	if is_stunned():
		return
	attack(player)
	set_state(States.ATTACK)

func move_to(target: Node2D) -> void:
	if not is_on_floor():
		return
	var direction: Vector2
	direction = (target.global_position - global_position).normalized()
	
	set_target_velocity(direction * speed)

func move_in_dir(direction: Vector2) -> void:
	if not is_on_floor():
		return
	direction = direction.normalized()
	set_target_velocity(direction * speed)

func handle_state() -> void:
	if is_attacking():
		return
	var target_speed = get_target_speed()
	if target_speed == 0:
		set_state(States.IDLE)
	else:
		set_state(States.MOVE)

func handle_flip() -> void:
	if _target_speed > 0:
		set_flip_h(true)
	else:
		set_flip_h(false)
