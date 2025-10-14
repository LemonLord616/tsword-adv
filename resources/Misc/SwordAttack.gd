extends Node2D
class_name SwordAttack

@export var lifetime := 0.2 # seconds

@onready var hitbox: SwordAttackHitbox = $SwordAttackHitbox

signal enemy_in_hitbox(enemy: Creature)

func _ready():
	hitbox.enemy_in_hitbox.connect(_on_enemy_in_hitbox)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_enemy_in_hitbox(enemy: Creature):
	enemy_in_hitbox.emit(enemy)
