extends Control

# Referencias a nodos del UI
var field_container
var players_container
var back_button
var save_button
var formation_selector
var player_data = []

# Variables para selección de jugadores
var selected_player = null
var field_positions = {}
var current_formation = "3-2-1"
var position_slots = {}

# Posiciones en el campo horizontal (portero izquierda, delantero derecha)
var formations = {
	"3-2-1": {
		"Portero": {"pos": Vector2(80, 200), "color": Color.YELLOW},
		"Defensa1": {"pos": Vector2(220, 120), "color": Color.BLUE},
		"Defensa2": {"pos": Vector2(220, 200), "color": Color.BLUE},
		"Defensa3": {"pos": Vector2(220, 280), "color": Color.BLUE},
		"Mediocentro1": {"pos": Vector2(400, 150), "color": Color.GREEN},
		"Mediocentro2": {"pos": Vector2(400, 250), "color": Color.GREEN},
		"Delantero": {"pos": Vector2(580, 200), "color": Color.RED}
	},
	"1-3-2": {
		"Portero": {"pos": Vector2(80, 200), "color": Color.YELLOW},
		"Defensa": {"pos": Vector2(220, 200), "color": Color.BLUE},
		"Mediocentro1": {"pos": Vector2(360, 120), "color": Color.GREEN},
		"Mediocentro2": {"pos": Vector2(360, 200), "color": Color.GREEN},
		"Mediocentro3": {"pos": Vector2(360, 280), "color": Color.GREEN},
		"Delantero1": {"pos": Vector2(520, 150), "color": Color.RED},
		"Delantero2": {"pos": Vector2(520, 250), "color": Color.RED}
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
	field_container = get_node_or_null("VBoxContainer/MainHBox/FieldContainer")
	players_container = get_node_or_null("VBoxContainer/MainHBox/PlayersContainer/ScrollContainer/PlayerGrid")
	back_button = get_node_or_null("VBoxContainer/ButtonsContainer/BackButton")
	save_button = get_node_or_null("VBoxContainer/ButtonsContainer/SaveButton")
	formation_selector = get_node_or_null("VBoxContainer/FormationContainer/FormationSelector")
	
	# Configurar selector de formación
	if formation_selector:
		formation_selector.add_item("3-2-1")
		formation_selector.add_item("1-3-2")
		formation_selector.selected = 0
	
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
	
	if formation_selector:
		formation_selector.item_selected.connect(_on_formation_changed)
	
	# Crear elementos de jugadores
	create_player_cards()

func create_player_cards():
	if not players_container:
		return
	
	# Limpiar contenedor
	for child in players_container.get_children():
		child.queue_free()
	
	# Crear tarjetas de jugadores
	for player in player_data:
		var player_card = create_player_card(player)
		players_container.add_child(player_card)

func create_player_card(player_info):
	var card = Button.new()
	card.custom_minimum_size = Vector2(130, 90)
	card.flat = true
	
	# Contenedor vertical para la tarjeta
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)
	
	# Imagen del jugador
	var texture_rect = TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(60, 60)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Cargar imagen si existe
	if player_info.has("image") and ResourceLoader.exists(player_info["image"]):
		texture_rect.texture = load(player_info["image"])
	vbox.add_child(texture_rect)
	
	# Nombre del jugador
	var name_label = Label.new()
	name_label.text = player_info["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(name_label)
	
	# OVR y posición
	var info_label = Label.new()
	info_label.text = "OVR: " + str(player_info["overall"]) + " | " + player_info["position"]
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 10)
	info_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	vbox.add_child(info_label)
	
	# Configurar selección
	card.pressed.connect(_on_player_selected.bind(player_info, card))
	
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

func create_position_slot(position_name, position_data):
	var button = Button.new()
	button.name = position_name
	button.position = position_data["pos"]
	button.custom_minimum_size = Vector2(80, 80)
	button.flat = false
	
	# Color según la posición
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = position_data["color"]
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color.WHITE
	button.add_theme_stylebox_override("normal", style_box)
	
	# Label con el nombre de la posición
	button.text = position_name.replace("1", "").replace("2", "").replace("3", "")
	button.add_theme_font_size_override("font_size", 10)
	button.add_theme_color_override("font_color", Color.WHITE)
	
	# Conectar clic en posición
	button.pressed.connect(_on_position_clicked.bind(position_name))
	
	# Guardar referencia
	position_slots[position_name] = button
	
	return button

func _on_player_selected(player_info, card):
	# Deseleccionar jugador anterior
	if selected_player and selected_player.has("card"):
		selected_player["card"].modulate = Color.WHITE
	
	# Seleccionar nuevo jugador
	selected_player = {"info": player_info, "card": card}
	card.modulate = Color.CYAN
	
	# Mostrar posiciones compatibles
	highlight_compatible_positions(player_info["position"])
	
	print("Jugador seleccionado: ", player_info["name"])

func _on_position_clicked(position_name):
	if not selected_player:
		print("No hay jugador seleccionado")
		return
	
	# Verificar compatibilidad
	var player_position = selected_player["info"]["position"]
	if is_position_compatible(player_position, position_name):
		# Colocar jugador en la posición
		place_player_in_position(selected_player["info"], position_name)
		
		# Deseleccionar jugador
		selected_player["card"].modulate = Color.WHITE
		selected_player = null
		
		# Limpiar resaltado
		clear_position_highlights()
	else:
		print("Posición incompatible para ", selected_player["info"]["name"])

func place_player_in_position(player_info, position_name):
	# Actualizar el botón de posición
	var position_button = position_slots[position_name]
	position_button.text = player_info["name"] + "\n" + str(player_info["overall"])
	position_button.add_theme_font_size_override("font_size", 9)
	
	# Guardar la asignación
	field_positions[position_name] = player_info
	
	print("Jugador ", player_info["name"], " colocado en ", position_name)

func highlight_compatible_positions(player_position):
	# Limpiar resaltado anterior
	clear_position_highlights()
	
	# Resaltar posiciones compatibles
	for pos_name in position_slots:
		if is_position_compatible(player_position, pos_name):
			position_slots[pos_name].modulate = Color.LIGHT_GREEN

func clear_position_highlights():
	for pos_name in position_slots:
		position_slots[pos_name].modulate = Color.WHITE

func _on_formation_changed(index):
	var formations_list = ["3-2-1", "1-3-2"]
	current_formation = formations_list[index]
	print("Formación cambiada a: ", current_formation)
	
	# Limpiar posiciones actuales
	field_positions.clear()
	position_slots.clear()
	
	# Recrear campo con nueva formación
	create_field()

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
