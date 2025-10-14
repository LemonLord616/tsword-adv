extends AnimatedSprite2D
class_name CreatureAnimatedSprite

@export var creature: Creature = null

func _ready() -> void:
	creature.died.connect(_on_creature_died)
	creature.revived.connect(_on_creature_spawned)
	
func _process(_delta: float) -> void:
	global_position = creature.global_position

func _on_creature_died(_creature: Creature):
	visible = false

func _on_creature_spawned(_creature: Creature):
	visible = true
