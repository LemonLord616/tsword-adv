extends Node2D
class_name BeeBullet

signal player_in_hitbox(player: Player)

@export var lifetime: float = 3.0

@onready var hitbox: BeeBulletHitbox = $Hitbox

var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	hitbox.hit.connect(_on_hit)

func _physics_process(delta: float) -> void:
	global_position += velocity * delta

	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_hit(node: Node2D) -> void:
	if node is Player:
		player_in_hitbox.emit(node)
	queue_free()
