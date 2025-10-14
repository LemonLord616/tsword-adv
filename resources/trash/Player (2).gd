extends CharacterBody2D
class_name PlayerOld
var slowness = 1
@export var player_id : int
signal damaged(player, hp)
@export var it : Item
@export var ti : Item
@onready var mazo = $UI/Health/TextureProgressBar
func _ready() -> void:
	pickup_item(it)
	pickup_item(ti)

@export var player_prefix: String = "p1"

# ----------------------------
# Combat Settings
# ----------------------------
@export var max_hp := 3
@export var hp := 3
@export var knockback_resist := 1.0
@export var attack_knockback := 200
@export var knockback_duration := 0.5

var knockback_timer := 0.0

# ----------------------------
# Movement Settings
# ----------------------------
@export var move_speed := 100.0
@export var acceleration := 15.0
@export var friction := 0.2

# ----------------------------
# Jump Settings
# ----------------------------
@export var jump_height := 400.0
@export var time_to_jump_apex := 0.4
@export var max_jump_hold := 0.2
@export var jump_cut_multiplier := 3.0
@export var gravity_scale := 1.0

# ----------------------------
# Derived physics values
# ----------------------------
@onready var gravity := (2 * jump_height) / (time_to_jump_apex*2)
@onready var jump_velocity := gravity * time_to_jump_apex

# ----------------------------
# State & input
# ----------------------------
enum States { IDLE, RUN, JUMP, FALL, MIDAIR, ATTACK, DEAD }
var state := States.IDLE
var last_state := States.IDLE
var flip_h := false
var last_flip_h := false
var jump_hold_timer := 0.0
var horizontal_input := 0.0


# ----------------------------
# Physics process
# ----------------------------
func _physics_process(delta: float) -> void:
	if knockback_timer > 0:
		knockback_timer -= delta
	handle_input(delta)
	handle_jump(delta)
	handle_attack(delta)
	
	handle_horizontal(delta)
	apply_gravity(delta)
	move_and_slide()
	
	update_state()
	apply_animation()

# ----------------------------
# Input handling
# ----------------------------
func handle_input(_delta: float) -> void:
	horizontal_input = Input.get_action_strength("%s_right" % player_prefix) \
		- Input.get_action_strength("%s_left" % player_prefix)

# ----------------------------
# Horizontal movement with friction
# ----------------------------
func handle_horizontal(delta: float) -> void:
	var target_speed := float(horizontal_input) * move_speed

	if horizontal_input != 0:
		velocity.x = lerp(float(velocity.x), target_speed, acceleration * delta)
	else:
		velocity.x = lerp(float(velocity.x), 0.0, friction)

	if horizontal_input != 0:
		flip_h = horizontal_input < 0

# ----------------------------
# Jump handling
# ----------------------------
func handle_jump(delta: float) -> void:
	var accept = "%s_accept" % player_prefix
	if is_on_floor():
		jump_hold_timer = 0.0
		if Input.is_action_just_pressed(accept):
			velocity.y = -jump_velocity
			jump_hold_timer = max_jump_hold
	else:
		# Variable jump height
		if Input.is_action_pressed(accept) and jump_hold_timer > 0:
			jump_hold_timer -= delta
		elif Input.is_action_just_released(accept) and velocity.y < 0:
			velocity.y /= jump_cut_multiplier

# ----------------------------
# Gravity with smooth apex
# ----------------------------
func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		if velocity.y < 0:
			# Ascent: slower near apex
			var ascent_factor = clamp(abs(velocity.y) / jump_velocity, 0.0, 1.0)
			velocity.y += gravity * delta * gravity_scale * (0.5 + 0.5 * ascent_factor)
		else:
			# Descent: faster fall
			velocity.y += gravity * delta * gravity_scale * 1.5

# ----------------------------
# State machine
# ----------------------------
func update_state() -> void:
	last_state = state
	if attack_direction != AttackDir.NONE:
		state = States.ATTACK
	elif is_on_floor():
		if horizontal_input == 0:
			state = States.IDLE
		else:
			state = States.RUN
	else:
		if velocity.y < 0:
			state = States.JUMP
		else:
			state = States.FALL

# ----------------------------
# Attack Settings
# ----------------------------
enum AttackDir { NONE, UP, LEFT, RIGHT }
var attack_direction := AttackDir.NONE
var attack_timer := 0.0
@export var attack_cooldown := 0.3

# ----------------------------
# Handle directional attacks
# ----------------------------
func handle_attack(delta: float) -> void:
	if attack_timer > 0:
		attack_timer -= (delta * slowness)
		return

	if attack_direction != AttackDir.NONE :
		attack_direction = AttackDir.NONE

	if attack_timer <= 0 and Input.is_action_just_pressed("%s_attack" % player_prefix):
		# Determine direction
		if Input.is_action_pressed("%s_up" % player_prefix):
			attack_direction = AttackDir.UP
		else:
			# Default to facing direction
			attack_direction = AttackDir.LEFT if flip_h else AttackDir.RIGHT

		perform_attack(attack_direction)

func perform_attack(dir: int) -> void:
	attack_timer = attack_cooldown

	# Play animation (if you want to add later)
	# match dir:
	# 	AttackDir.UP:
	# 		anim_player.play("Attack_Up")
	# 	AttackDir.LEFT:
	# 		anim_player.play("Attack_Left")
	# 	AttackDir.RIGHT:
	# 		anim_player.play("Attack_Right")

	# Spawn hitbox
	spawn_attack_hitbox(dir)

func spawn_attack_hitbox(dir: int) -> void:
	var hitbox := preload("res://resources/old_misc/AttackHitbox.tscn").instantiate()
	add_child(hitbox)
	
	match dir:
		AttackDir.UP:
			hitbox.position = Vector2(0, -16) # above player
			hitbox.rotation_degrees = -90
			hitbox.set_direction(Vector2.UP)
		AttackDir.LEFT:
			hitbox.position = Vector2(-16, 0)
			hitbox.rotation_degrees = 180
			hitbox.set_direction(Vector2.LEFT)
		AttackDir.RIGHT:
			hitbox.position = Vector2(16, 0)
			hitbox.rotation_degrees = 0
			hitbox.set_direction(Vector2.RIGHT)

	
	# Play attack animation
	#match dir:
		#AttackDir.UP:
			#anim_player.play("Attack_Up")
		#AttackDir.DOWN:
			#anim_player.play("Attack_Down")
		#AttackDir.LEFT:
			#anim_player.play("Attack_Left")
		#AttackDir.RIGHT:
			#anim_player.play("Attack_Right")

signal animation_changed(state: int, flip_h: bool, attack_dir: int)

func apply_animation() -> void:
	# Instead of playing animations here, just notify others
	if state != last_state or flip_h != last_flip_h:
		last_flip_h = flip_h
		emit_signal("animation_changed", state, flip_h, attack_direction)

	#if state != last_state:
		#match state:
			#States.IDLE:
				#anim_player.play("Idle")
			#States.RUN:
				#anim_player.play("Run")
			#States.JUMP:
				#anim_player.play("Jump")
			#States.FALL:
				#anim_player.play("Fall")

# ----------------------------
# Item System
# ----------------------------

@onready var inventory: Inventory = Inventory.new(self)

func pickup_item(item: Item) -> void:
	inventory.add_item(item)
	
	if self.inventory.has_item(load("res://resources/Items/Individual Dummies/ODE.tres")) and self.inventory.has_item(load("res://resources/Items/Individual Dummies/Nails.tres")):
		inventory.add_item(load("res://resources/Items/Combos/combo_items/ODE_NAIL.tres"))
		
	if self.inventory.has_item(load("res://resources/Items/Individual Dummies/ODE.tres")) and self.inventory.has_item(load("res://resources/Items/Individual Dummies/Vampire.tres")):
		inventory.add_item(load("res://resources/Items/Combos/combo_items/Yrav_ZAN.tres"))
		
	if self.inventory.has_item(load("res://resources/Items/Individual Dummies/UFO.tres")) and self.inventory.has_item(load("res://resources/Items/Individual Dummies/Nails.tres")):
		inventory.add_item(load("res://resources/Items/Combos/combo_items/Nail_NLO.tres"))
		
	if self.inventory.has_item(load("res://resources/Items/Individual Dummies/UFO.tres")) and self.inventory.has_item(load("res://resources/Items/Individual Dummies/Vampire.tres")):
		inventory.add_item(load("res://resources/Items/Combos/combo_items/ZAN_NLO.tres"))
		
	if self.inventory.has_item(load("res://resources/Items/Individual Dummies/Jug.tres")) and self.inventory.has_item(load("res://resources/Items/Individual Dummies/Eye.tres")):
		inventory.add_item(load("res://resources/Items/Combos/combo_items/WaterEye.tres"))
		
	if self.inventory.has_item(load("res://resources/Items/Individual Dummies/Jug.tres")) and self.inventory.has_item(load("res://resources/Items/Individual Dummies/Heart.tres")):
		inventory.add_item(load("res://resources/Items/Combos/combo_items/WaterHeart.tres"))
		
	if self.inventory.has_item(load("res://resources/Items/Individual Dummies/Elfor.tres")) and self.inventory.has_item(load("res://resources/Items/Individual Dummies/Eye.tres")):
		inventory.add_item(load("res://resources/Items/Combos/combo_items/Elec_Eye.tres"))
		
	if self.inventory.has_item(load("res://resources/Items/Individual Dummies/Elfor.tres")) and self.inventory.has_item(load("res://resources/Items/Individual Dummies/Heart.tres")):
		inventory.add_item(load("res://resources/Items/Combos/combo_items/El_heart.tres"))

func drop_item(item: Item) -> void:
	inventory.remove_item(item)

var active_effects: Array[ItemEffect] = []

func add_item_effect(effect: ItemEffect):
	if effect not in active_effects:
		active_effects.append(effect)
		effect.apply(self)

func remove_item_effect(effect: ItemEffect):
	if effect in active_effects:
		active_effects.erase(effect)
		effect.remove(self)
		
@onready var inventory_menu: InventoryMenu = $UI/InventoryMenu

func _process(_delta):
	if Input.is_action_just_pressed("inventory"):
		if inventory_menu.visible:
			inventory_menu.close()
		else:
			inventory_menu.open()

# ----------------------------
# Combat System
# ----------------------------

func knockback_from(from: Vector2, strength_x: float = 0.0, strength_y: float = 0.0):
	if knockback_timer > 0:
		return
	strength_x = abs(strength_x)
	strength_y = abs(strength_y)
	var vec = global_position - from
	var direction = Vector2(vec.x, 0).normalized()
	velocity.x = direction.x * strength_x / knockback_resist
	velocity.y = -strength_y / knockback_resist
	
	knockback_timer = knockback_duration
	
		
func take_damage(dmg: int):
	if knockback_timer > 0:
		return
	hp = max(0, hp - dmg)
	mazo.refill()
	emit_signal("damaged", self, hp)
	if hp <= 0:
		die()


func _on_texture_progress_bar_bar_empty_tick() -> void:
	take_damage(1)
	print("Player took damage because the bar is empty!")

var is_dead = false
@onready var death_icon = $Death

signal revived

func revive(at_position: Vector2, _revive_hp: int = 3):
	is_dead = false
	hp = max_hp
	revived.emit()
	emit_signal("damaged", self, max_hp)
	global_position = at_position
	set_collision_layer(1) # restore
	set_collision_mask(1)
	set_process(true)
	set_physics_process(true)
	print("Player revived!")


signal died

func die():
	var death := preload("res://resources/old_misc/death.tscn").instantiate()
	add_child(death)
	died.emit()
	is_dead = true
	velocity = Vector2.ZERO
	state = States.DEAD
	print("Player died!")

	# disable collision so they don't interfere with gameplay
	set_collision_layer(0)
	set_collision_mask(0)

	# optionally disable input
	set_process(false)
	set_physics_process(false)
	
