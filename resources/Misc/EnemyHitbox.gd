extends Area2D
class_name EnemyHitbox

signal player_in_hitbox(player: Player)

# TODO: consider optimizations
func _physics_process(_delta: float) -> void:
	for body: Node2D in get_overlapping_bodies():
		if body is Player:
			player_in_hitbox.emit(body)
