extends OldAirCreature
class_name OldAirEnemy

@onready var hitbox: EnemyHitbox = $Hitbox

enum States { FLOAT, ATTACK }

func _ready() -> void:
	hitbox.player_in_hitbox.connect(_on_player_in_hitbox)

func _logic_apply(_delta: float) -> void:
	handle_state()

func _on_player_in_hitbox(player: Player) -> void:
	if is_stunned():
		return
	attack(player)
	set_state(States.ATTACK)

func move_to(target: Node2D) -> void:
	var direction: Vector2

	direction = (target.global_position - global_position).normalized()

	set_target_velocity(direction * speed)

func handle_state() -> void:
	if is_attacking():
		return
	set_state(States.FLOAT)
