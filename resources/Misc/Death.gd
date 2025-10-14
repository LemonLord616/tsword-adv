extends Node2D

@onready var sprite = $Sprite2D

func _ready() -> void:
	await get_tree().create_timer(0.2).timeout
	sprite.rotation_degrees = -30
	await get_tree().create_timer(0.2).timeout
	sprite.rotation_degrees = 30
	await get_tree().create_timer(0.2).timeout
	sprite.rotation_degrees = 0
	await get_tree().create_timer(0.2).timeout
	queue_free()
