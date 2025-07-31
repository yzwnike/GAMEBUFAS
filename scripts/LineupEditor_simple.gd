extends Control

func _ready():
	print("LineupEditor_simple: Cargando correctamente")
	
	# Verificar que los nodos básicos existen
	var formation_selector = get_node_or_null("VBoxContainer/TopPanel/FormationSelector")
	var back_button = get_node_or_null("VBoxContainer/TopPanel/BackButton")
	var field_container = get_node_or_null("VBoxContainer/MainContainer/FieldContainer/Field")
	
	print("formation_selector: ", formation_selector)
	print("back_button: ", back_button)
	print("field_container: ", field_container)
	
	# Conectar botón de volver
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
		print("Botón volver conectado")

func _on_back_pressed():
	print("Volviendo al PreMatchMenu...")
	get_tree().change_scene_to_file("res://scenes/PreMatchMenu.tscn")
