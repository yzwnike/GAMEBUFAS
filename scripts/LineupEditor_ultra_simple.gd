extends Control

func _ready():
	print("LineupEditor_ultra_simple: ¡Funcionando!")
	
	# Solo buscar el botón de volver y conectarlo
	var back_btn = get_node_or_null("VBoxContainer/TopPanel/BackButton")
	if back_btn:
		back_btn.pressed.connect(go_back)
		print("LineupEditor_ultra_simple: Botón volver conectado")
	else:
		print("LineupEditor_ultra_simple: No se encontró el botón volver")

func go_back():
	print("LineupEditor_ultra_simple: Volviendo...")
	get_tree().change_scene_to_file("res://scenes/PreMatchMenu.tscn")
