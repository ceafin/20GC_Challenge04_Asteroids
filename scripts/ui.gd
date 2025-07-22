extends Control
class_name GameUI

var is_transmission_active : bool = false

@onready var transmission_panel: TextureRect = $TransmissionPanel
@onready var transmission_text: Label = $TransmissionPanel/TransmissionText
@onready var button: Button = $Button
@onready var transmission_blinker: Timer = $TransmissionBlinker

func _ready() -> void:
	transmission_panel.visible = false


func _on_transmission_blinker_timeout() -> void:
	print("Blink")
	transmission_text.visible = not transmission_text.visible

func _on_button_toggled( toggled_on: bool ) -> void:
	is_transmission_active = toggled_on
	if is_transmission_active:
		transmission_panel.visible = true
		transmission_blinker.start()
		print("Start")
	else:
		transmission_panel.visible = false
		transmission_blinker.stop()
		print("Stop")
	
