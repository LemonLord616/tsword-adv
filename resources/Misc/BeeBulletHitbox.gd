extends Area2D
class_name BeeBulletHitbox

signal hit(node: Node2D)

# TODO: consider optimizations
func _physics_process(_delta: float) -> void:
	for body: Node2D in get_overlapping_bodies():
		hit.emit(body)
