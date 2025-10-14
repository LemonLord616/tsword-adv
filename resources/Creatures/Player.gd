extends Creature
class_name Player
var slowness = 1
@export var player_id : int
#@export var it : Item
#@export var ti : Item
@onready var mazo = $UI/Health/TextureProgressBar
@onready var inventory_menu: InventoryMenu = $UI/InventoryMenu
@onready var inventory: Inventory = Inventory.new(self)

	#pickup_item(it)
	#pickup_item(ti)

@export var hitbox_scene: PackedScene

@export var start_hp: int = -1

# Move Settings
var _target_speed: float = 0.0 
@export var friction: float = 0.4

# Jump state variables
var coyote_timer: float = 0
var jump_buffer_timer: float = 0
var double_jump_armed: bool = false

# Jump parameters
@export_range(-1000, 1000, 10, "suffix:px/s") var jump_velocity = -300.0
@export_range(0, 100, 5, "suffix:%") var jump_cut_factor: float = 20
@export_range(0, 0.5, 1 / 60.0, "suffix:s") var coyote_time: float = 5.0 / 60.0
@export_range(0, 0.5, 1 / 60.0, "suffix:s") var jump_buffer: float = 5.0 / 60.0
@export var double_jump: bool = false

# State & input
enum States { IDLE, RUN, JUMP, FALL, MIDAIR, ATTACK }
var jump_hold_timer := 0.0
var horizontal_input := 0.0

# Buttons
@export var player_prefix: String = "p1"
@onready var accept_btn: String = "%s_accept" % player_prefix
@onready var inventory_btn: String = "inventory"
@onready var right_btn: String = "%s_right" % player_prefix
@onready var left_btn: String = "%s_left" % player_prefix
@onready var up_btn: String = "%s_up" % player_prefix
@onready var down_btn: String = "%s_down" % player_prefix
@onready var attack_btn: String = "%s_attack" % player_prefix

# Attack Settings
enum AttackDir { NONE, UP, FRONT }
@export var attack_cooldown: float = 0.5
var _attack_timer: float = 0.0

func _ready() -> void:
	if start_hp > 0:
		spawn(start_hp)
	else:
		spawn()

func _physics_apply(delta: float) -> void:
	if _attack_timer > 0:
		_attack_timer -= (delta * slowness)
	if is_on_floor():
		coyote_timer = (coyote_time + delta)
		double_jump_armed = false
	
	_handle_jump(delta)
	# Add the gravity.
	if coyote_timer <= 0:
		_apply_gravity(delta)
	# Update timers
	coyote_timer -= delta
	jump_buffer_timer -= delta
	_smooth_move_and_slide(delta)

func _logic_apply(delta: float) -> void:
	_handle_input(delta)

	if _attack_timer <= 0 and Input.is_action_just_pressed(attack_btn):
		_handle_attack(delta)

	if Input.is_action_just_pressed(inventory_btn):
		if inventory_menu.visible:
			inventory_menu.close()
		else:
			inventory_menu.open()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		if velocity.y < 0:
			# Ascent: slower near apex
			var ascent_factor = clamp(abs(velocity.y) / jump_velocity, 0.0, 1.0)
			velocity.y += get_gravity().y * delta * gravity_scale * (0.5 + 0.5 * ascent_factor)
		else:
			# Descent: faster fall
			velocity.y += get_gravity().y * delta * gravity_scale

func _smooth_move_and_slide(_delta: float):
	if _target_speed != 0:
		velocity.x = lerp(float(velocity.x), _target_speed, 1 - friction)
	else:
		velocity.x = lerp(float(velocity.x), 0.0, friction)

# Input handling
func _handle_input(_delta: float) -> void:
	horizontal_input = Input.get_action_strength(right_btn) \
		- Input.get_action_strength(left_btn)
	_target_speed = horizontal_input * speed
	if horizontal_input != 0:
		set_flip_h(horizontal_input < 0)

# Jump handling
func _handle_jump(delta: float) -> void:
	if Input.is_action_just_pressed(accept_btn):
		jump_buffer_timer = (jump_buffer + delta)

	if jump_buffer_timer > 0 and (double_jump_armed or coyote_timer > 0):
		_jump()

	# Reduce velocity if the player lets go of the jump key before the apex.
	# This allows controlling the height of the jump.
	if Input.is_action_just_released(accept_btn) and velocity.y < 0:
		velocity.y *= (1 - (jump_cut_factor / 100.00))
	
func _jump() -> void:
	velocity.y = jump_velocity
	coyote_timer = 0
	jump_buffer_timer = 0
	if double_jump_armed:
		double_jump_armed = false
		#_double_jump_particles.emitting = true
	elif double_jump:
		double_jump_armed = true

# State machine
func _update_state() -> void:
	if _attack_timer > 0:
		set_state(States.ATTACK)
		return
	if is_on_floor():
		if horizontal_input == 0:
			set_state(States.IDLE)
		else:
			set_state(States.RUN)
	else:
		if velocity.y < 0:
			set_state(States.JUMP)
		else:
			set_state(States.FALL)

# Handle directional attacks
func _handle_attack(_delta: float) -> void:
	var attack_direction: AttackDir = AttackDir.NONE

	# Determine direction
	if Input.is_action_pressed(up_btn):
		attack_direction = AttackDir.UP
	else:
		# Default to facing direction
		#attack_direction = AttackDir.RIGHT if get_flip_h() else AttackDir.LEFT
		attack_direction = AttackDir.FRONT
			
	_attack_timer = attack_cooldown
	_spawn_attack_hitbox(attack_direction)

func _knockback_force(target: Node2D) -> Vector2:
	var x_dir = 1 if target.global_position > global_position else -1
	return Vector2(x_dir, -1).normalized() * knockback_strength

func _spawn_attack_hitbox(dir: int) -> void:
	var hitbox: SwordAttack = hitbox_scene.instantiate()
	add_child(hitbox)
	hitbox.enemy_in_hitbox.connect(attack_and_knockback)

	match dir:
		AttackDir.UP:
			hitbox.position = Vector2(0, -16) # above player
			hitbox.rotation_degrees = -90
		AttackDir.FRONT:
			hitbox.position = Vector2(16, 0)
			hitbox.rotation_degrees = 0
		#AttackDir.RIGHT:
			#hitbox.position = Vector2(16, 0)
			#hitbox.rotation_degrees = 0
		#AttackDir.LEFT:
			#hitbox.position = Vector2(16, 0)
			#hitbox.rotation_degrees = 0



# ----------------------------
# Item System
# ----------------------------

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
		

func _on_texture_progress_bar_bar_empty_tick() -> void:
	take_damage(null, 1)
	print("Player took damage because the bar is empty!")
