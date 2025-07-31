extends Control

# Referencias a nodos del UI básicas
var formation_selector
var field_container
var players_scroll
var players_container
var back_button
var save_button

func _ready():
	print("LineupEditor_clean: Inicializando editor limpio...")
	
	# Solo configurar UI básica
	if not setup_ui():
		print("ERROR: No se pudo configurar la UI del LineupEditor_clean")
		return
	
	# Conectar solo el botón de volver
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
		print("LineupEditor_clean: Botón volver conectado")
	
	print("LineupEditor_clean: Editor limpio listo")

func setup_ui():
	print("LineupEditor_clean: Configurando UI...")
	
	# Obtener nodos básicos con los paths correctos de la escena
	formation_selector = get_node_or_null("VBoxContainer/TopPanel/FormationSelector")
	field_container = get_node_or_null("VBoxContainer/MainContainer/FieldContainer/Field")
	players_scroll = get_node_or_null("VBoxContainer/MainContainer/PlayersPanel/ScrollContainer")
	players_container = get_node_or_null("VBoxContainer/MainContainer/PlayersPanel/ScrollContainer/PlayersContainer")
	back_button = get_node_or_null("VBoxContainer/TopPanel/BackButton")
	save_button = get_node_or_null("VBoxContainer/TopPanel/SaveButton")
	
	# Debug: Verificar que los nodos fueron encontrados
	print("LineupEditor_clean: formation_selector: ", formation_selector)
	print("LineupEditor_clean: field_container: ", field_container)
	print("LineupEditor_clean: players_container: ", players_container)
	print("LineupEditor_clean: back_button: ", back_button)
	print("LineupEditor_clean: save_button: ", save_button)
	
	# Si encontramos los nodos básicos, todo está bien
	if back_button and field_container:
		print("LineupEditor_clean: UI configurada correctamente")
		return true
	else:
		print("LineupEditor_clean: Faltan nodos básicos")
		return false

func _on_back_pressed():
	print("LineupEditor_clean: Volviendo al menú pre-partido...")
	get_tree().change_scene_to_file("res://scenes/PreMatchMenu.tscn")
