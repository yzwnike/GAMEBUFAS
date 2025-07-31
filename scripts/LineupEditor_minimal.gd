extends Control

func _ready():
	print("LineupEditor_minimal: ¡Funcionando!")
	
	# Solo mostrar un mensaje básico
	var label = Label.new()
	label.text = "LINEUP EDITOR FUNCIONA"
	label.position = Vector2(100, 100)
	add_child(label)
	
	# Botón para volver
	var button = Button.new()
	button.text = "VOLVER"
	button.position = Vector2(100, 200)
	button.pressed.connect(_go_back)
	add_child(button)

func _go_back():
	print("Volviendo...")
	get_tree().change_scene_to_file("res://scenes/PreMatchMenu.tscn")
