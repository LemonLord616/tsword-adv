extends CharacterBody2D
class_name OldCreature

signal damaged(creature: Creature, hp: int)
signal died(creature: Creature)
signal revived(creature: Creature)
signal attacked(creature: Creature, target: Creature)
signal animation_changed(creature: Creature, state: int, flip_h: bool)

@export var speed: float = 200

@export var max_hp: int = 3
var hp: int = max_hp

@export var damage: int = 1
@export var knockback_strength: float = 200

@export var attack_cooldown: float = 0.45
var attack_timer: float = 0.0

# higher = less knockback, 0.4 = 40% (apply 60% of force)
@export var knockback_resist: float = 0.4
@export var stun_duration: float = 0.45
@export var invul_duration: float = 0.2
var stun_timer: float = 0.0
var invul_timer: float = 0.0

@export var death_scene: PackedScene
@export var death_duration: float = 0.5
var _is_dead: bool = false

var _state: int = 0
var _flip_h: bool = false
@export var flippable: bool = false
var EPS_SPEED: float = 1.0

# remember original collision layers so revive() can restore them
@onready var _saved_collision_layer: int = collision_layer
@onready var _saved_collision_mask: int = collision_mask


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	if attack_timer > 0:
		attack_timer -= delta
	if stun_timer > 0:
		stun_timer -= delta
	if invul_timer > 0:
		invul_timer -= delta
		if invul_timer <= 0:
			set_collision_layer_value.call_deferred(2, true)
			set_collision_mask_value.call_deferred(2, true)

	if flippable:
		_update_flip()
	_update_state()
	if stun_timer <= 0:
		_logic_apply(delta)
	_physics_apply(delta)
	
	move_and_slide()
# virtual - intended to be overridden by subclasses
func _physics_apply(_delta: float) -> void:
	pass

# virtual - intedned to ve overridden by subclasses 
func _logic_apply(_delta: float) -> void:
	pass

# (not) virtual - intended to be overriden by subclasses
# func _update_flip() -> void:
# 	if not flippable:
# 		return
# 	
# 	if abs(velocity.x) > EPS_SPEED:
# 		set_flip_h(velocity.x < 0.0)

# virtual - intended to be overridden by subclasses
func _update_flip() -> void:
	pass

# virtual - intended to be overridden by subclasses
func _update_state() -> void:
	pass

# physical body turn around
func turn_around() -> void:
	scale.x *= -1

func set_flip_h(new_flip_h) -> void:
	if not flippable:
		return
	if _flip_h != new_flip_h:
		_flip_h = new_flip_h
		animation_changed.emit(self, _state, _flip_h)

func get_flip_h() -> bool:
	return _flip_h

func set_state(new_state: int) -> void:
	if _state != new_state:
		_state = new_state
		animation_changed.emit(self, _state, _flip_h)

func get_state() -> int:
	return _state

func can_attack() -> bool:
	return attack_timer <= 0

func is_attacking() -> bool:
	return attack_timer > 0

func is_dead() -> bool:
	return _is_dead

func is_stunned() -> bool:
	return stun_timer > 0

func is_invul() -> bool:
	return invul_timer > 0

# or may override this
func attack(body: Creature) -> void:
	if attack_timer > 0:
		return
	attacked.emit(self, body)
	body.take_damage(damage)
	var knockback_force = knockback_force_for(body)
	body.knockback(knockback_force)
	attack_timer = attack_cooldown

# (not) virtual - intended to be overriden by subclasses
func knockback_force_for(target: Node2D) -> Vector2:
	var x_dir = 1 if target.global_position > global_position else -1
	return Vector2(x_dir, -1).normalized() * knockback_strength

# Knockback (receiving side)
# Apply knockback in a direction (direction is a vector pointing from attacker -> this creature or any normalized dir),
# 'strength' can be provided; if strength == Vector2.ZERO, default exports are used.
func knockback(force: Vector2 = Vector2.ZERO) -> void:
	print(self.name, " knockbacked!")
	if force.length() == 0:
		return

	velocity.x = force.x * (1 - knockback_resist)
	velocity.y = force.y * (1 - knockback_resist)

	stun_timer = stun_duration

# Damage / death / revive / spawn
func take_damage(dmg: int) -> void:
	if _is_dead:
		return
	if invul_timer > 0:
		return

	hp = max(0, hp - dmg)
	damaged.emit(self, hp)

	invul_timer = invul_duration
	set_collision_layer_value.call_deferred(2, false)
	set_collision_mask_value.call_deferred(2, false)

	if hp <= 0:
		die()

func die() -> void:
	if _is_dead:
		return

	_is_dead = true
	died.emit(self)

	if death_scene:
		add_child(death_scene.instantiate())
	
	# reset timers
	stun_timer = 0
	invul_timer = 0

	# stop movement & disable collisions & processing
	velocity = Vector2.ZERO
	set_collision_layer(0)
	set_collision_mask(0)
	set_process(false)
	set_physics_process(false)

func revive(_revive_hp: int = -1) -> void:
	if not _is_dead:
		return

	_is_dead = false
	hp = (_revive_hp if _revive_hp > 0 else max_hp)
	revived.emit(self)
	#emit_signal("damaged", self, hp) # why?

	# restore collision layers
	collision_layer = _saved_collision_layer
	collision_mask = _saved_collision_mask

	# relatively to parent
	position = Vector2.ZERO

	set_process(true)
	set_physics_process(true)
