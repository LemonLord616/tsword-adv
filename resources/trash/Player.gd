extends OldGroundCreature
class_name OldCreaturePlayer
var slowness = 1
@export var player_id : int
#@export var it : Item
#@export var ti : Item
@onready var mazo = $UI/Health/TextureProgressBar
func _ready() -> void:
	pass
	#pickup_item(it)
	#pickup_item(ti)

@export var hitbox_scene: PackedScene

# Jump Settings
@export var jump_height := 800.0
@export var time_to_jump_apex := 0.4
@export var max_jump_hold := 0.2
@export var jump_cut_multiplier := 3.0

# Derived physics values
@onready var gravity := (2 * jump_height) / (time_to_jump_apex*2)
@onready var jump_velocity := gravity * time_to_jump_apex

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
enum AttackDir { NONE, UP, LEFT, RIGHT }
var attack_direction := AttackDir.NONE

# Due to some complications (attack slowness), I leave it here
func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	if stun_timer > 0:
		stun_timer -= delta
	if invul_timer > 0:
		invul_timer -= delta
		if invul_timer <= 0:
			set_collision_layer_value.call_deferred(2, true)
			set_collision_mask_value.call_deferred(2, true)
		
	if stun_timer <= 0:
		_logic_apply(delta)

	_physics_apply(delta)
	move_and_slide()

# Physics process
func _logic_apply(delta: float) -> void:
	handle_input(delta)
	handle_jump(delta)
	handle_attack(delta)
	handle_state()

	if Input.is_action_just_pressed(inventory_btn):
		if inventory_menu.visible:
			inventory_menu.close()
		else:
			inventory_menu.open()

# Input handling
func handle_input(_delta: float) -> void:
	horizontal_input = Input.get_action_strength(right_btn) \
		- Input.get_action_strength(left_btn)
	set_target_speed(horizontal_input * speed)
	if horizontal_input != 0:
		set_flip_h(horizontal_input < 0)

# Jump handling
func handle_jump(delta: float) -> void:
	if is_on_floor():
		jump_hold_timer = 0.0
		if Input.is_action_just_pressed(accept_btn):
			velocity.y = -jump_velocity
			jump_hold_timer = max_jump_hold
	else:
		# Variable jump height
		if Input.is_action_pressed(accept_btn) and jump_hold_timer > 0:
			jump_hold_timer -= delta
		elif Input.is_action_just_released(accept_btn) and velocity.y < 0:
			velocity.y /= jump_cut_multiplier

# State machine
func handle_state() -> void:
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
func handle_attack(delta: float) -> void:
	if attack_timer > 0:
		attack_timer -= (delta * slowness)
		return

	if attack_direction != AttackDir.NONE :
		attack_direction = AttackDir.NONE

	if attack_timer <= 0 and Input.is_action_just_pressed(attack_btn):
		# Determine direction
		if Input.is_action_pressed(up_btn):
			attack_direction = AttackDir.UP
		else:
			# Default to facing direction
			attack_direction = AttackDir.LEFT if get_flip_h() else AttackDir.RIGHT

		perform_attack(attack_direction)

func perform_attack(dir: int) -> void:
	attack_timer = attack_cooldown
	spawn_attack_hitbox(dir)

	# Play animation (if you want to add later)
	# match dir:
	# 	AttackDir.UP:
	# 		anim_player.play("Attack_Up")
	# 	AttackDir.LEFT:
	# 		anim_player.play("Attack_Left")
	# 	AttackDir.RIGHT:
	# 		anim_player.play("Attack_Right")


func spawn_attack_hitbox(dir: int) -> void:
	var hitbox = hitbox_scene.instantiate()
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


func _on_texture_progress_bar_bar_empty_tick() -> void:
	take_damage(1)
	print("Player took damage because the bar is empty!")
