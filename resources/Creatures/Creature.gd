extends CharacterBody2D
class_name Creature

signal health_changed(hp: int)
signal damaged(from: Creature, damage: int)
signal attacked(target: Creature)
signal was_knockbacked(from: Creature)
signal knockbacked(target: Creature)
signal died
signal revived
signal animation_changed(state: int, flip_h: bool)


@export var max_hp: int = 3
var hp: int = max_hp
@export var speed: float = 200.0

# Invulnerability
@export var invul_duration: float = 2.0
var _invul_timer: float = 0.0

@export var knockback_resist: float = 0.2
@export var knockback_strength: float = 300
@export var damage: int = 1

@export var death_scene: PackedScene
@export var death_duration: float = 0.5
var _is_dead: bool = false

var _state: int = 0
var _flip_h: bool = false
@export var flippable: bool = false

@export var bouncy: bool = false
@export var bounce_coefficient: float = 1.0
var _collision: KinematicCollision2D

@onready var _saved_collision_layer: int = collision_layer
@onready var _saved_collision_mask: int = collision_mask

@export var gravity_scale: float = 1.0	

func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	
	if _invul_timer > 0:
		_invul_timer -= delta
	
	if flippable:
		_update_flip()
	_update_state()
	
	_logic_apply(delta)
	_physics_apply(delta)
	
	if _collision and bouncy:
		velocity = velocity.bounce(_collision.get_normal()) * bounce_coefficient
	
	if bouncy:
		_collision = move_and_collide(velocity * delta)
	else:
		move_and_slide()

# virtual - intended to be overridden by subclasses
func _physics_apply(_delta: float) -> void:
	pass

# virtual - intedned to ve overridden by subclasses 
func _logic_apply(_delta: float) -> void:
	pass

# virtual - intended to be overridden by subclasses
func _update_flip() -> void:
	pass

# virtual - intended to be overridden by subclasses
func _update_state() -> void:
	pass

func set_flip_h(new_flip_h) -> void:
	if not flippable:
		return
	if _flip_h != new_flip_h:
		_flip_h = new_flip_h
		# flip physic body
		scale.x *= -1
		# notify visuals
		animation_changed.emit(self, _state, _flip_h)

func get_flip_h() -> bool:
	return _flip_h

func set_state(new_state: int) -> void:
	if _state != new_state:
		_state = new_state
		animation_changed.emit(self, _state, _flip_h)

func get_state() -> int:
	return _state

func attack_and_knockback(creature: Creature) -> void:
	attack(creature)
	knockback(creature)

func attack(creature: Creature) -> void:
	creature.take_damage(self, damage)

	attacked.emit(creature)

func take_damage(from: Creature, dmg: int) -> void:
	if _is_dead:
		return
	if _invul_timer > 0:
		return

	hp = max(0, hp - dmg)
	_invul_timer = invul_duration
	damaged.emit(from, dmg)
	health_changed.emit(hp)

	if hp <= 0:
		die()

# virtual - intended to be overriden by subclasses
func _knockback_force(_target: Node2D) -> Vector2:
	return Vector2.ZERO

func knockback(target: Creature, force: Vector2 = Vector2.ZERO) -> void:
	if force == Vector2.ZERO:
		force = _knockback_force(target)
	target.get_knockback(self, force)

	knockbacked.emit(target)

func get_knockback(from: Creature, force: Vector2) -> void:
	if force.length() == 0:
		return

	velocity.x = force.x * (1 - knockback_resist)
	velocity.y = force.y * (1 - knockback_resist)

	was_knockbacked.emit(from)

func die() -> void:
	if _is_dead:
		return

	_is_dead = true
	died.emit()

	if death_scene:
		add_child(death_scene.instantiate())
	
	# stop movement & disable collisions & processing & change pos to parent's
	velocity = Vector2.ZERO
	#position = Vector2.ZERO
	set_collision_layer.call_deferred(0)
	set_collision_mask.call_deferred(0)
	set_process(false)
	set_physics_process(false)

func spawn(revive_hp: int = -1) -> void:

	_is_dead = false
	hp = (revive_hp if revive_hp > 0 else max_hp)
	revived.emit()
	health_changed.emit(hp)
	#emit_signal("damaged", self, hp) # why?

	# relatively to parent
	position = Vector2.ZERO
	# restore collision layers
	set_collision_layer.call_deferred(_saved_collision_layer)
	set_collision_mask.call_deferred(_saved_collision_mask)
	set_process(true)
	set_physics_process(true)
