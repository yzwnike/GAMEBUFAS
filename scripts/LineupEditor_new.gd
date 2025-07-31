extends Control

# Referencias a nodos del UI
var field_container
var players_container
var back_button
var save_button
var formation_selector
var player_data = []

# Variables para drag & drop
var dragging_player = null
var field_positions = {}
var current_formation = "3-2-1"

# Posiciones en el campo para fútbol 7
var formations = {
	"3-2-1": {
		"Portero": Vector2(400, 550),
		"Defensa1": Vector2(300, 450),
		"Defensa2": Vector2(400, 450), 
		"Defensa3": Vector2(500, 450),
		"Mediocentro1": Vector2(350, 350),
		"Mediocentro2": Vector2(450, 350),
		"Delantero": Vector2(400, 250)
	},
	"1-3-2": {
		"Portero": Vector2(400, 550),
		"Defensa": Vector2(400, 450),
		"Mediocentro1": Vector2(300, 350),
		"Mediocentro2": Vector2(400, 350),
		"Mediocentro3": Vector2(500, 350),
		"Delantero1": Vector2(350, 250),
		"Delantero2": Vector2(450, 250)
	}
}

func _ready():
	print("LineupEditor: Inicializando editor de alineación...")
	
	# Cargar datos de jugadores
	load_player_data()
	
	# Configurar UI
	if not setup_ui():
		print("ERROR: No se pudo configurar la UI del LineupEditor")
		return
	
	# Configurar interacciones
	setup_interactions()
	
	# Crear campo de fútbol
	create_field()
	
	print("LineupEditor: Editor listo para usar")

func load_player_data():
	# Cargar datos de jugadores desde el archivo JSON
	var json_file = FileAccess.open("res://data/players_data.json", FileAccess.READ)
	if json_file:
		var json_text = json_file.get_as_text()
		json_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		
		if parse_result == OK:
			var data = json.data
			if typeof(data) == TYPE_DICTIONARY and data.has("players"):
				player_data = data["players"]
				print("Jugadores cargados: ", player_data.size())
		else:
			print("Error al parsear JSON: ", parse_result)

func setup_ui():
	print("LineupEditor: Configurando UI...")
	
	# Obtener nodos básicos
	field_container = get_node_or_null("VBoxContainer/HBoxContainer/FieldContainer")
	players_container = get_node_or_null("VBoxContainer/HBoxContainer/PlayersContainer/ScrollContainer/PlayerList")
	back_button = get_node_or_null("VBoxContainer/ButtonsContainer/BackButton")
	save_button = get_node_or_null("VBoxContainer/ButtonsContainer/SaveButton")
	formation_selector = get_node_or_null("VBoxContainer/FormationContainer/FormationSelector")
	
	# Verificar nodos críticos
	if back_button and field_container and players_container:
		print("LineupEditor: UI configurada correctamente")
		return true
	else:
		print("LineupEditor: Faltan nodos básicos")
		return false

func setup_interactions():
	# Conectar botones
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
	
	# Crear elementos de jugadores con drag & drop
	create_player_list()

func create_player_list():
	if not players_container:
		return
	
	# Limpiar contenedor
	for child in players_container.get_children():
		child.queue_free()
	
	# Crear elementos de jugadores
	for player in player_data:
		var player_card = create_player_card(player)
		players_container.add_child(player_card)

func create_player_card(player_info):
	var card = Control.new()
	card.custom_minimum_size = Vector2(250, 60)
	
	# Panel de fondo
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(panel)
	
	# Contenedor horizontal
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(hbox)
	
	# Imagen del jugador (placeholder)
	var texture_rect = TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(50, 50)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	hbox.add_child(texture_rect)
	
	# Información del jugador
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	
	var name_label = Label.new()
	name_label.text = player_info["name"]
	name_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_label)
	
	var info_label = Label.new()
	info_label.text = player_info["position"] + " - OVR: " + str(player_info["overall"])
	info_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(info_label)
	
	# Configurar drag & drop
	card.gui_input.connect(_on_player_card_input.bind(player_info, card))
	
	return card

func create_field():
	if not field_container:
		return
	
	# Limpiar campo
	for child in field_container.get_children():
		if child.name != "FieldBackground":
			child.queue_free()
	
	# Crear posiciones según la formación actual
	var positions = formations[current_formation]
	
	for pos_name in positions:
		var position_slot = create_position_slot(pos_name, positions[pos_name])
		field_container.add_child(position_slot)

func create_position_slot(position_name, position):
	var slot = Control.new()
	slot.name = position_name
	slot.position = position
	slot.custom_minimum_size = Vector2(80, 80)
	
	# Panel de fondo
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot.add_child(panel)
	
	# Label con el nombre de la posición
	var label = Label.new()
	label.text = position_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 10)
	panel.add_child(label)
	
	# Configurar drop zone
	slot.gui_input.connect(_on_position_slot_input.bind(position_name, slot))
	
	return slot

func _on_player_card_input(event, player_info, card):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Iniciar drag
				dragging_player = {"info": player_info, "card": card}
				print("Iniciando drag de: ", player_info["name"])
			else:
				# Finalizar drag
				dragging_player = null

func _on_position_slot_input(event, position_name, slot):
	if event is InputEventMouseButton and event.pressed and dragging_player:
		# Colocar jugador en la posición
		place_player_in_position(dragging_player["info"], position_name, slot)
		dragging_player = null

func place_player_in_position(player_info, position_name, slot):
	# Verificar si la posición es compatible
	var player_position = player_info["position"]
	if is_position_compatible(player_position, position_name):
		# Actualizar el slot con la información del jugador
		var label = slot.get_child(0).get_child(0)
		label.text = player_info["name"] + "\n" + str(player_info["overall"])
		
		# Guardar la asignación
		field_positions[position_name] = player_info
		
		print("Jugador ", player_info["name"], " colocado en ", position_name)
	else:
		print("Posición incompatible para ", player_info["name"])

func is_position_compatible(player_pos, field_pos):
	# Verificar compatibilidad de posiciones
	if player_pos == "Portero" and "Portero" in field_pos:
		return true
	elif player_pos == "Defensa" and ("Defensa" in field_pos):
		return true
	elif player_pos == "Mediocentro" and ("Mediocentro" in field_pos):
		return true
	elif player_pos == "Delantero" and ("Delantero" in field_pos):
		return true
	
	return false

func _on_save_pressed():
	print("Guardando alineación...")
	# Aquí puedes implementar la lógica para guardar la alineación
	for pos_name in field_positions:
		var player = field_positions[pos_name]
		print(pos_name, ": ", player["name"])

func _on_back_pressed():
	print("LineupEditor: Volviendo al menú pre-partido...")
	get_tree().change_scene_to_file("res://scenes/PreMatchMenu.tscn")
