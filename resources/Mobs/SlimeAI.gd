extends Node2D
class_name SlimeAI

const EPS_SPEED = 1.0
const NO_SCAN_DELAY: float = 0.5

var _scan_delay_timer: float = 0.0

@onready var slime: GroundEnemy = $GroundEnemy
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var scanner: SlimeScanner = $Scanner

var move_direction: Vector2 = Vector2.LEFT

var _scanner_stopped: bool = false
var _scanner_position: Vector2 = Vector2.ZERO
#var _scanner_inversed: bool = false
@export var time_between_jump: float = 1.0
var _jump_timer: float = 0.0

var _x_speed: float = 0.0

enum State { IDLE, JUMP, ASCENDING, DESCENDING }
var state: State = State.IDLE
enum Behavior { IDLE, WAIT, JUMP, IN_AIR }
var behavior: Behavior = Behavior.IDLE

func _ready() -> void:
	slime.animation_changed.connect(_on_animation_changed)
	slime.died.connect(_on_died)
	slime.revived.connect(_on_spawned)
	slime.no_floor_in_front.connect(_turn_around)
	slime.wall_in_front.connect(_turn_around)
	scanner.stop_signal.connect(_on_scanner_stop_signal)

func _on_died() -> void:
	set_process(false)
	set_physics_process(false)

func _on_spawned() -> void:
	set_process(true)
	set_physics_process(true)

func _on_scanner_stop_signal(pos: Vector2) -> void:
	_scanner_stopped = true
	_scanner_position = pos

func _physics_process(delta: float) -> void:
	#update_flip_h()
	update_state()
	match behavior:
		Behavior.IDLE:
			handle_idle(delta)
		Behavior.WAIT:
			handle_wait(delta)
		Behavior.JUMP:
			handle_jump()
		Behavior.IN_AIR:
			handle_air()

func handle_idle(delta: float) -> void:
	slime.set_target_speed(0)
	if _scan_delay_timer > 0:
		_scan_delay_timer -= delta
		return
	#print("Scan!")
	scanner.launch(slime, slime.get_flip_h(), time_between_jump)
	_jump_timer = time_between_jump
	behavior = Behavior.WAIT
	#print("Idle -> Wait")

func handle_wait(delta: float) -> void:
	if _jump_timer > 0:
		_jump_timer -= delta
		return
	if not _scanner_stopped:
		_scanner_position = scanner.global_position
	behavior = Behavior.JUMP
	#print("Wait -> Jump")

func handle_jump() -> void:
	var jump_time = abs(2 * slime.jump_velocity \
				/ (slime.get_gravity().y * slime.gravity_scale))
	_x_speed = min(slime.speed, \
				abs(slime.global_position - scanner.global_position).x / jump_time)
	##print(jump_time)
	##print(scanner.global_position)
	##print(abs(slime.global_position - scanner.global_position).x / jump_time)
	_x_speed *= move_direction.x
	
	slime._jump()
	behavior = Behavior.IN_AIR
	#print("Jump -> Air")

func handle_air() -> void:
	# bloat to make it update animation Ascending/Descending
	slime.animation_changed.emit(slime, slime.get_state(), slime.get_flip_h())
	if slime.is_on_floor():
		behavior = Behavior.IDLE
		_scanner_stopped = false
		_scan_delay_timer = NO_SCAN_DELAY
		#print("Air -> Idle")
	else:
		slime.set_target_speed(_x_speed)

#func update_flip_h() -> void:
	#if move_direction.x > 0:
		#slime.set_flip_h(true)
	#else:
		#slime.set_flip_h(false)

func update_state() -> void:
	if abs(slime.velocity.y) < EPS_SPEED:
		slime.set_state(State.IDLE)
	elif slime.velocity.y < 0:
		slime.set_state(State.ASCENDING)
	elif slime.velocity.y > 0:
		slime.set_state(State.DESCENDING)

func _on_animation_changed(_slime: Creature, _slime_state: int, slime_flip_h: bool) -> void:
	if _slime_state == State.IDLE:
		anim_sprite.play("Idle")
	elif _slime_state == State.ASCENDING:
		anim_sprite.play("Ascending")
	elif _slime_state == State.DESCENDING:
		anim_sprite.play("Descending")
	anim_sprite.flip_h = not slime_flip_h

func _turn_around() -> void:
	slime.set_flip_h(not slime.get_flip_h())
	move_direction.x = 1 if slime.get_flip_h() else -1
