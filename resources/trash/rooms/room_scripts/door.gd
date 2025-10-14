extends Area2D

@export var target_room: Node2D
@export var target_door: Node2D       # Destination door node

var is_locked := true
@export var mobs_in_room: Array[Creature] = []

@onready var col_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	if not mobs_in_room:
		is_locked = false
		return
	for mob in mobs_in_room:
		mob.died.connect(_on_mob_died)
	print(mobs_in_room)
	if mobs_in_room.is_empty():
		is_locked = false

func _on_mob_died(mob):
	mobs_in_room.erase(mob)
	if mobs_in_room.is_empty():
		is_locked = false

func _on_body_entered(body: Node) -> void:
	if body is Player and not is_locked:
		is_locked = true
		col_shape.disabled = true  # disable trigger

		# Teleport player immediately
		var i = 0
		for p in get_tree().get_nodes_in_group("player"):
			p.global_position = target_door.global_position + Vector2(10, 0) * i
			i += 1

		# Switch to the target room's camera
		switch_to_target_room_camera()

func switch_to_target_room_camera():
	# Get the target room's camera bounds
	var target_camera_bounds = target_room.get_node("CameraBounds")
	if target_camera_bounds:
		# Trigger the camera bounds to switch cameras
		target_camera_bounds.emit_signal("body_entered", get_tree().get_first_node_in_group("player"))
