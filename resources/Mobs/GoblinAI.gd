extends Node2D
class_name GoblinAI

const EPS_SPEED: float = 1.0

@onready var goblin: GroundEnemy = $GroundEnemy
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var wander_speed: float = 150.0
@export var chase_speed: float = 300.0

@export var attack_frames_duration: float = 1.0
var _attack_timer: float = 0.0

enum Behavior { WANDER, CHASE }
var behavior: Behavior = Behavior.WANDER
var target: Player = null

enum State { IDLE, MOVE, ATTACK }
var state: State = State.IDLE

var move_direction: Vector2 = Vector2.LEFT

func _ready() -> void:
	goblin.speed = wander_speed
	goblin.attacked.connect(_on_attacked)
	goblin.died.connect(_on_died)
	goblin.revived.connect(_on_spawned)
	goblin.animation_changed.connect(_on_animation_changed)
	goblin.no_floor_in_front.connect(_turn_around)
	goblin.wall_in_front.connect(_turn_around)
	goblin.looks_at.connect(handle_behavior)

func _on_died() -> void:
	set_process(false)
	set_physics_process(false)

func _on_spawned() -> void:
	set_process(true)
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	handle_state()
	handle_flip()
	if _attack_timer > 0:
		_attack_timer -= delta
	if behavior == Behavior.CHASE:
		move_direction = (target.global_position - goblin.global_position).normalized()
		#vision_ray_cast.target_position = target.global_position
	if goblin.is_on_floor():
		goblin.set_target_speed(move_direction.x * goblin.speed)
	else:
		goblin.set_target_speed(0)

func handle_state() -> void:
	if _attack_timer > 0:
		goblin.set_state(State.ATTACK)
	elif goblin.get_target_speed() < EPS_SPEED:
		goblin.set_state(State.IDLE)
	else:
		goblin.set_state(State.MOVE)

func handle_flip() -> void:
	if goblin.get_target_speed() > 0:
		goblin.set_flip_h(true)
	elif goblin.get_target_speed() < 0:
		goblin.set_flip_h(false)

		
func handle_behavior(body: Node2D) -> void:
	if body is Player:
		if behavior != Behavior.CHASE:
			target = body
			behavior = Behavior.CHASE
			goblin.speed = chase_speed
	else:
		if behavior != Behavior.WANDER:
			target = null
			behavior = Behavior.WANDER
			goblin.speed = wander_speed

func _on_attacked(_target: Creature) -> void:
	_attack_timer = attack_frames_duration

func _on_animation_changed(_goblin: Creature, goblin_state: int, goblin_flip_h: bool) -> void:
	match goblin_state:
		State.IDLE:
			anim_sprite.play("Idle")
		State.MOVE:
			anim_sprite.play("Move")
		State.ATTACK:
			anim_sprite.play("Attack")
	anim_sprite.flip_h = goblin_flip_h

func _turn_around() -> void:
	if behavior == Behavior.CHASE:
		return
	move_direction = -move_direction
