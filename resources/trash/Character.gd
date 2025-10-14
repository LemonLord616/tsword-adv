extends Node2D

@onready var player: Player = $Player
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	player.animation_changed.connect(_on_player_animation_changed)
	player.died.connect(_on_player_died)
	player.revived.connect(_on_player_revived)

func _process(_delta: float) -> void:
	anim_sprite.global_position = player.global_position

func _on_player_died() -> void:
	anim_sprite.visible = false

func _on_player_revived() -> void:
	anim_sprite.visible = true

func _on_player_animation_changed(state: int, flip_h: bool, _attack_dir: int) -> void:
	match state:
		Player.States.IDLE:
			anim_sprite.play("Idle")
		Player.States.RUN:
			anim_sprite.play("Run")
		Player.States.JUMP:
			anim_sprite.play("Jump")
		Player.States.FALL:
			anim_sprite.play("Fall")
		Player.States.MIDAIR:
			anim_sprite.play("Midair")
		Player.States.ATTACK:
			anim_sprite.play("Attack")

	# Override if attacking
	#match attack_dir:
		#Player.AttackDir.UP:
			#anim_sprite.play("Attack_Up")
		#Player.AttackDir.LEFT:
			#anim_sprite.play("Attack_Left")
		#Player.AttackDir.RIGHT:
			#anim_sprite.play("Attack_Right")

	anim_sprite.flip_h = flip_h
