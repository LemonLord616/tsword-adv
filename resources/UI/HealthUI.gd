extends Control
class_name HealthUI

@export var player1: Player
@export var player2: Player
@export var heart_full: Texture2D
@export var heart_empty: Texture2D
@export var heart_size: int = 100

@onready var left_bar: HBoxContainer = $HealthBarLeft
@onready var right_bar: HBoxContainer = $HealthBarRight

func _ready():
	print(left_bar, right_bar)
	_build(left_bar, player1.max_hp)
	_build(right_bar, player2.max_hp)
	
	player1.health_changed.connect(_on_health_left)
	player2.health_changed.connect(_on_health_right)

func _build(bar: HBoxContainer, max_hp: int) -> void:
	for c in bar.get_children(): c.queue_free()
	for i in range(max(0, max_hp)):
		var heart: TextureRect = TextureRect.new()
		heart.texture = heart_empty
		heart.custom_minimum_size = Vector2(heart_size, heart_size)  # clamp to desired size
		heart.expand = true
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.size_flags_horizontal = Control.SIZE_FILL
		heart.size_flags_vertical = Control.SIZE_FILL
		bar.add_child(heart)

func _update(bar: HBoxContainer, hp: int) -> void:
	var n = bar.get_child_count()
	hp = clamp(hp, 0, n)
	for i in range(n):
		var heart: TextureRect = bar.get_child(i)
		heart.texture = heart_full if i < hp else heart_empty

func _on_health_left(new_hp: int) -> void:
	_update(left_bar, new_hp)
func _on_health_right(new_hp: int) -> void:
	_update(right_bar, new_hp)
