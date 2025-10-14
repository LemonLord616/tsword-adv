extends Node2D

@onready var choice_ui: Node = $Choice
@onready var trigger: Area2D = $ChoiceTrigger
@export var player1: Player = null
@export var player2: Player = null

func _ready():
	# Show the choice UI
	choice_ui.player1 = player1
	choice_ui.player2 = player2
	# Connect to choice logic to resume game after selection
	choice_ui.items_chosen.connect(_on_items_chosen)

func show_choice_ui():
	choice_ui.visible = true

	# Optionally disable player movement while choosing
	player1.set_process(false)
	player2.set_process(false)
	
func _on_items_chosen():
	# Hide the UI
	choice_ui.visible = false
	
	# Re-enable player movement
	player1.set_process(true)
	player2.set_process(true)


func _on_choice_trigger_body_entered(body: Node2D) -> void:
	if body is not Player:
		return
	
	trigger.monitoring = false
	show_choice_ui()
		
		
