extends Node2D
class_name BeeAI

@export var projectile_scene: PackedScene
@export var projectile_speed: float = 150.0
@export var aim_ray_length: float = 2000.0
@export var fire_rate: float = 0.5	# shots per second
var _cooldown: float = 0.0

@export var player1: Player
@export var player2: Player
@onready var players: Array[Player] = []

@onready var bee = $AirEnemy
@onready var anim_sprite = $AnimatedSprite2D
@onready var aim_ray_cast: RayCast2D = $AimRayCast
@onready var navigation_agent: NavigationAgent2D = $AirEnemy/NavigationAgent2D

@export var attack_frames_duration: float = 1.0
var _attack_timer: float = 0.0

@export var targets: Array[Marker2D] = []

enum State { FLOAT, ATTACK }

func _ready():
	bee.animation_changed.connect(_on_animation_changed)
	bee.died.connect(_on_died)
	bee.revived.connect(_on_spawned)
	if player1:
		players.append(player1)
	if player2:
		players.append(player2)

	navigation_agent.navigation_finished.connect(_on_navigation_finished)
	if targets.size() > 0:
		navigation_agent.target_position = targets[0].global_position

func _on_navigation_finished():
	# Cycle to next target
	targets.push_back(targets.pop_front())
	navigation_agent.target_position = targets[0].global_position

func _on_died() -> void:
	set_process(false)
	set_physics_process(false)

func _on_spawned() -> void:
	set_process(true)
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if _attack_timer > 0:
		_attack_timer -= delta
	_handle_state()
	_handle_flip_h()
	_handle_movement()
	if _cooldown > 0:
		_cooldown -= delta
	else:
		_handle_shoot()

func _handle_state() -> void:
	if _attack_timer > 0:
		bee.set_state(State.ATTACK)
	else:
		bee.set_state(State.FLOAT)

func _handle_flip_h() -> void:
	if _attack_timer > 0:
		return
	if bee.get_target_velocity().x > 0:
		bee.set_flip_h(true)
	else:
		bee.set_flip_h(false)

func _handle_movement() -> void:
	var next_path_position = navigation_agent.get_next_path_position()
	var direction = bee.global_position.direction_to(next_path_position)
	bee.set_target_velocity(direction * bee.speed)

func _handle_shoot() -> void:
	# Check which players are visible
	var visible_players: Array[Node2D] = []
	for player in players:
		if _can_aim_at(player):
			visible_players.append(player)
	
	# Pick one of the visible players at random
	var player: Player
	if visible_players.size() > 0:
		player = visible_players.pick_random()
	else:
		player = null
		
	if player:
		_fire(player)
		_cooldown = 1.0 / fire_rate

func _can_aim_at(player: Player) -> bool:
	aim_ray_cast.global_position = bee.global_position
	var direction: Vector2 = player.global_position - bee.global_position
	direction = direction.normalized()
	aim_ray_cast.target_position = direction * aim_ray_length
	return aim_ray_cast.get_collider() is Player

func _fire(player: Player = null) -> void:
	if projectile_scene == null:
		return
	
	var proj: BeeBullet = projectile_scene.instantiate()
	get_tree().get_root().add_child(proj)
	proj.player_in_hitbox.connect(bee.attack_and_knockback)

	var dir: Vector2
	if player:
		dir = (player.global_position - bee.global_position).normalized()
	else:
		dir = Vector2.RIGHT if bee.get_flip_h() else Vector2.LEFT

	proj.global_position = bee.global_position
	proj.velocity = dir * projectile_speed
	proj.rotation = (-dir).angle()
	
	if dir.x > 0:
		bee.set_flip_h(true)
	else:
		bee.set_flip_h(false)
	_attack_timer = attack_frames_duration

func _on_animation_changed(_bee: Creature, bee_state: int, bee_flip_h: bool):
	match bee_state:
		State.FLOAT:
			anim_sprite.play("Float")
		State.ATTACK:
			anim_sprite.play("Attack")
	anim_sprite.flip_h = bee_flip_h
