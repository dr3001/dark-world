extends Control

# Dark World — Login Screen

@onready var status_label = $StatusLabel

func _ready():
	# This script is attached to the Login Control node
	# Buttons are handled by Main.gd
	pass

func set_status(text: String):
	if status_label:
		status_label.text = text
