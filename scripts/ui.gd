extends Control
class_name GameUI

var is_transmission_active : bool = false

@onready var score_number: Label = $HBoxScore/ScoreNumber
@onready var lives_number: Label = $HBoxScore/LivesNumber
@onready var transmission_panel: TextureRect = $TransmissionPanel
@onready var transmission_text: Label = $TransmissionPanel/TransmissionText
@onready var button: Button = $Button
@onready var transmission_blinker: Timer = $TransmissionBlinker

func _ready() -> void:
	transmission_panel.visible = false


func _on_transmission_blinker_timeout() -> void:
	transmission_text.visible = not transmission_text.visible

func _transmission_toggle( toggled_on: bool ) -> void:
	is_transmission_active = toggled_on
	if is_transmission_active:
		transmission_panel.visible = true
		transmission_blinker.start()
	else:
		transmission_panel.visible = false
		transmission_blinker.stop()
	
func display_message( message: String, how_long: float ) -> void:
	transmission_text.text = message
	_transmission_toggle( true )
	await get_tree().create_timer( how_long ).timeout
	_transmission_toggle( false )


func update_score( score: int ) -> void:
	score_number.text = str(score)

func update_lives( lives: int ) -> void:
	lives_number.text = str(lives)
