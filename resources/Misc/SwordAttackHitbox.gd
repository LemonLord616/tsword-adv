extends Area2D
class_name SwordAttackHitbox

signal enemy_in_hitbox(enemy: Creature)

# TODO: consider optimizations
func _physics_process(_delta: float) -> void:
	for body: Node2D in get_overlapping_bodies():
		if body is GroundEnemy or body is AirEnemy:
			enemy_in_hitbox.emit(body)
