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
var last_used_formation = ""
var current_formation = "3-2-1"
var position_slots = {}
var draggable_players = []
var saved_lineup = {}

# Listas de posiciones compatibles por tipo
const POSITION_TYPES = {
	"Portero": ["Portero"],
	"Defensa": ["Defensa1", "Defensa2", "Defensa3", "Defensa"],
	"Mediocentro": ["Mediocentro1", "Mediocentro2", "Mediocentro3"],
	"Delantero": ["Delantero", "Delantero1", "Delantero2"]
}

# Formaciones del equipo disponibles
const FORMATION_LIST = ["3-2-1", "1-3-2", "2-2-2"]

# Posiciones en el campo horizontal (portero izquierda, delantero derecha)
var formations = {
	"3-2-1": {
		"Portero": {"pos": Vector2(100, 250), "color": Color.YELLOW},
		"Defensa1": {"pos": Vector2(300, 150), "color": Color.BLUE},
		"Defensa2": {"pos": Vector2(300, 250), "color": Color.BLUE},
		"Defensa3": {"pos": Vector2(300, 350), "color": Color.BLUE},
		"Mediocentro1": {"pos": Vector2(550, 200), "color": Color.GREEN},
		"Mediocentro2": {"pos": Vector2(550, 300), "color": Color.GREEN},
		"Delantero": {"pos": Vector2(780, 250), "color": Color.RED}
	},
	"1-3-2": {
		"Portero": {"pos": Vector2(100, 250), "color": Color.YELLOW},
		"Defensa": {"pos": Vector2(300, 250), "color": Color.BLUE},
		"Mediocentro1": {"pos": Vector2(500, 150), "color": Color.GREEN},
		"Mediocentro2": {"pos": Vector2(500, 250), "color": Color.GREEN},
		"Mediocentro3": {"pos": Vector2(500, 350), "color": Color.GREEN},
		"Delantero1": {"pos": Vector2(720, 190), "color": Color.RED},
		"Delantero2": {"pos": Vector2(720, 310), "color": Color.RED}
	},
	"2-2-2": {
		"Portero": {"pos": Vector2(100, 250), "color": Color.YELLOW},
		"Defensa1": {"pos": Vector2(300, 200), "color": Color.BLUE},
		"Defensa2": {"pos": Vector2(300, 300), "color": Color.BLUE},
		"Mediocentro1": {"pos": Vector2(550, 200), "color": Color.GREEN},
		"Mediocentro2": {"pos": Vector2(550, 300), "color": Color.GREEN},
		"Delantero1": {"pos": Vector2(780, 200), "color": Color.RED},
		"Delantero2": {"pos": Vector2(780, 300), "color": Color.RED}
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
	
	# Cargar alineación guardada si existe
	load_saved_lineup()
	
	print("LineupEditor: Editor listo para usar")

func load_player_data():
	# Cargar datos de jugadores desde PlayersManager (plantilla dinámica)
	if PlayersManager:
		player_data = PlayersManager.get_all_players()
		print("LineupEditor: Jugadores cargados desde PlayersManager: ", player_data.size())
	else:
		print("ERROR: PlayersManager no está disponible")
		# Fallback: cargar desde archivo estático
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
					print("Jugadores cargados desde archivo estático: ", player_data.size())
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
	
	# Ajustar el contenedor de jugadores a un diseño vertical
	if players_container:
		players_container.columns = 1  # Colocar un elemento por columna, ajustando a un diseño vertical
		players_container.custom_minimum_size = Vector2(280, 0)  # Expande verticalmente
	
	# Configurar selector de formación
	if formation_selector:
		formation_selector.add_item("3-2-1")
		formation_selector.add_item("1-3-2")
		formation_selector.add_item("2-2-2")
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
	
	# Agrupar jugadores por posición
	var players_by_position = {
		"Portero": [],
		"Defensa": [],
		"Mediocentro": [],
		"Delantero": []
	}
	
	for player in player_data:
		players_by_position[player["position"]].append(player)
	
	# Crear secciones por posición
	for position in ["Portero", "Defensa", "Mediocentro", "Delantero"]:
		if players_by_position[position].size() > 0:
			create_position_section(position, players_by_position[position])

func create_position_section(position_name, players):
	# Título de la sección
	var section_label = Label.new()
	section_label.text = position_name.to_upper()
	section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section_label.add_theme_font_size_override("font_size", 16)
	section_label.add_theme_color_override("font_color", Color.CYAN)
	section_label.custom_minimum_size = Vector2(280, 30)
	players_container.add_child(section_label)
	
	# Crear tarjetas de jugadores de esta posición
	for player in players:
		var player_card = create_player_card(player)
		players_container.add_child(player_card)
	
	# Separador
	var separator = HSeparator.new()
	separator.custom_minimum_size = Vector2(280, 10)
	players_container.add_child(separator)

func create_player_card(player_info):
	var card = Button.new()
	card.custom_minimum_size = Vector2(140, 180)
	card.flat = false
	
	# Estilo de la tarjeta mejorado
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.15, 0.18, 0.25, 1.0)
	card_style.border_width_left = 3
	card_style.border_width_right = 3
	card_style.border_width_top = 3
	card_style.border_width_bottom = 3
	card_style.border_color = Color(0.4, 0.6, 0.9, 1.0)
	card_style.corner_radius_top_left = 12
	card_style.corner_radius_top_right = 12
	card_style.corner_radius_bottom_left = 12
	card_style.corner_radius_bottom_right = 12
	# Sombra/gradiente
	card_style.shadow_color = Color(0, 0, 0, 0.3)
	card_style.shadow_size = 2
	card.add_theme_stylebox_override("normal", card_style)
	
	# Estilo cuando está presionado
	var card_style_pressed = StyleBoxFlat.new()
	card_style_pressed.bg_color = Color(0.25, 0.28, 0.35, 1.0)
	card_style_pressed.border_width_left = 3
	card_style_pressed.border_width_right = 3
	card_style_pressed.border_width_top = 3
	card_style_pressed.border_width_bottom = 3
	card_style_pressed.border_color = Color(0.6, 0.8, 1.0, 1.0)
	card_style_pressed.corner_radius_top_left = 12
	card_style_pressed.corner_radius_top_right = 12
	card_style_pressed.corner_radius_bottom_left = 12
	card_style_pressed.corner_radius_bottom_right = 12
	card.add_theme_stylebox_override("pressed", card_style_pressed)
	
	# Contenedor vertical para la tarjeta
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)
	
	# Espaciador superior
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 5)
	vbox.add_child(top_spacer)
	
	# Imagen del jugador
	var texture_rect = TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(80, 80)
	texture_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
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
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)
	
	# OVR destacado en esquina superior derecha
	var ovr_label = Label.new()
	ovr_label.text = str(player_info["overall"])
	ovr_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ovr_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	ovr_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	ovr_label.position = Vector2(95, 10)
	ovr_label.size = Vector2(40, 20)
	ovr_label.add_theme_font_size_override("font_size", 16)
	ovr_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0, 1.0))
	ovr_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	ovr_label.add_theme_constant_override("shadow_offset_x", 1)
	ovr_label.add_theme_constant_override("shadow_offset_y", 1)
	card.add_child(ovr_label)  # Añadirlo directamente al card, no al vbox
	
	# Stamina
	var stamina_label = Label.new()
	var stamina_value = PlayersManager.get_player_stamina(player_info["id"])
	stamina_label.text = "Stamina: " + str(stamina_value) + "/" + str(PlayersManager.MAX_STAMINA)
	stamina_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamina_label.add_theme_font_size_override("font_size", 10)
	# Color según el nivel de stamina
	if stamina_value == 0:
		stamina_label.add_theme_color_override("font_color", Color.RED)
	elif stamina_value == 1:
		stamina_label.add_theme_color_override("font_color", Color.ORANGE)
	else:
		stamina_label.add_theme_color_override("font_color", Color.GREEN)
	vbox.add_child(stamina_label)

	# Posición
	var pos_label = Label.new()
	pos_label.text = player_info["position"]
	pos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pos_label.add_theme_font_size_override("font_size", 11)
	pos_label.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0, 1.0))
	vbox.add_child(pos_label)
	
	# Espaciador inferior
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 5)
	vbox.add_child(bottom_spacer)
	
	# Configurar selección
	card.pressed.connect(_on_player_selected.bind(player_info, card))
	
	return card

func create_field():
	if not field_container:
		return
	
	# Limpiar TODAS las posiciones anteriores - buscar por tipo Button
	var children_to_remove = []
	for child in field_container.get_children():
		if child is Button:
			children_to_remove.append(child)
	
	for child in children_to_remove:
		child.queue_free()
	
	# Limpiar diccionarios
	field_positions.clear()
	position_slots.clear()
	
	# Crear posiciones según la formación actual
	var positions = formations[current_formation]
	
	for pos_name in positions:
		var position_slot = create_position_slot(pos_name, positions[pos_name])
		field_container.add_child(position_slot)

func create_position_slot(position_name, position_data):
	var button = Button.new()
	button.name = position_name
	button.position = position_data["pos"]
	button.custom_minimum_size = Vector2(120, 120)
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
	# Limpiar el botón de posición
	var position_button = position_slots[position_name]
	
	# Limpiar hijos anteriores
	for child in position_button.get_children():
		child.queue_free()
	
	# Crear mini tarjeta del jugador en la posición
	var mini_card = VBoxContainer.new()
	mini_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mini_card.add_theme_constant_override("separation", 2)
	position_button.add_child(mini_card)
	
	# Imagen pequeña del jugador (zoom en la cabeza)
	var mini_image = TextureRect.new()
	mini_image.custom_minimum_size = Vector2(60, 60)
	mini_image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mini_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	mini_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mini_image.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if player_info.has("image") and ResourceLoader.exists(player_info["image"]):
		mini_image.texture = load(player_info["image"])
	mini_card.add_child(mini_image)
	
	# Estilo de la mini tarjeta
	var mini_card_style = StyleBoxFlat.new()
	mini_card_style.bg_color = Color(0.15, 0.18, 0.4, 1.0)
	mini_card_style.border_color = Color(0.5, 0.7, 1.0, 1.0)
	mini_card_style.border_width_left = 2
	mini_card_style.border_width_right = 2
	mini_card_style.border_width_top = 2
	mini_card_style.border_width_bottom = 2
	mini_card_style.corner_radius_top_left = 8
	mini_card_style.corner_radius_top_right = 8
	mini_card_style.corner_radius_bottom_left = 8
	mini_card_style.corner_radius_bottom_right = 8
	position_button.add_theme_stylebox_override("normal", mini_card_style)
	
	# Nombre grande
	var mini_name = Label.new()
	mini_name.text = player_info["name"]
	mini_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mini_name.add_theme_font_size_override("font_size", 12)
	mini_name.add_theme_color_override("font_color", Color.WHITE)
	mini_card.add_child(mini_name)
	
	# OVR grande
	var mini_ovr = Label.new()
	mini_ovr.text = "OVR: " + str(player_info["overall"])
	mini_ovr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mini_ovr.add_theme_font_size_override("font_size", 14)
	mini_ovr.add_theme_color_override("font_color", Color.YELLOW)
	mini_card.add_child(mini_ovr)
	
	# Ocultar texto original del botón
	position_button.text = ""
	
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
	var formations_list = FORMATION_LIST
	current_formation = formations_list[index]
	print("Formación cambiada a: ", current_formation)
	
	# Limpiar posiciones actuales
	field_positions.clear()
	position_slots.clear()
	
	# Recrear campo con nueva formación
	create_field()
	
	# Nota: Al cambiar formación, el campo queda vacío
	# La alineación guardada solo se aplica si coincide con la formación guardada

func is_position_compatible(player_pos, field_pos):
	# Verificar compatibilidad de posiciones usando la constante
	if field_pos in POSITION_TYPES[player_pos]:
		return true
	return false

func _on_save_pressed():
	# Verificar que todas las posiciones estén ocupadas
	var required_positions = formations[current_formation].keys()
	var missing_positions = []
	
	for pos_name in required_positions:
		if not field_positions.has(pos_name):
			missing_positions.append(pos_name)
	
	if missing_positions.size() > 0:
		print("ERROR: Faltan jugadores en las siguientes posiciones: ", missing_positions)
		# Mostrar mensaje de error al usuario
		show_error_message("Debes completar todas las posiciones antes de guardar: " + str(missing_positions))
		return
	
	print("Guardando alineación...")
	
	# Guardar la alineación actual en LineupManager (no persistente)
	LineupManager.save_lineup(current_formation, field_positions)
	
	# Actualizar variables locales para compatibilidad
	saved_lineup = field_positions.duplicate(true)
	last_used_formation = current_formation
	
	# Mostrar confirmación
	show_success_message("Alineación guardada correctamente")
	
	for pos_name in field_positions:
		var player = field_positions[pos_name]
		print(pos_name, ": ", player["name"])

func save_lineup_to_file():
	var save_data = {
		"saved_lineup": saved_lineup,
		"last_used_formation": last_used_formation
	}
	
	var json_string = JSON.stringify(save_data)
	var file = FileAccess.open("user://saved_lineup.json", FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("Alineación guardada en archivo")
	else:
		print("ERROR: No se pudo guardar el archivo de alineación")

func load_lineup_from_file():
	var file = FileAccess.open("user://saved_lineup.json", FileAccess.READ)
	if not file:
		print("No hay archivo de alineación guardado")
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result == OK:
		var data = json.data
		if data.has("saved_lineup"):
			saved_lineup = data["saved_lineup"]
			print("Alineación cargada desde archivo")
		if data.has("last_used_formation"):
			last_used_formation = data["last_used_formation"]
			print("Última formación utilizada cargada: ", last_used_formation)
	else:
		print("ERROR: No se pudo parsear el archivo de alineación")

func load_saved_lineup():
	# Cargar alineación desde LineupManager (no persistente)
	var lineup_data = LineupManager.get_saved_lineup()
	
	if lineup_data != null:
		last_used_formation = lineup_data["formation"]
		saved_lineup = lineup_data["players"]
		
		# Si existe una alineación guardada y una formación guardada, usar la última formación
		if last_used_formation != "" and saved_lineup.size() > 0:
			current_formation = last_used_formation
			# Actualizar el selector de formación para reflejar la formación cargada
			var formation_index = FORMATION_LIST.find(current_formation)
			if formation_index != -1 and formation_selector:
				formation_selector.selected = formation_index
			# Recrear el campo con la formación correcta
			create_field()
		
			# Si existe una alineación guardada, cargarla
			print("Cargando alineación guardada")
			for pos_name in saved_lineup:
				var player_info = saved_lineup[pos_name]
				place_player_in_position(player_info, pos_name)
			print("Alineación restaurada exitosamente para formación: ", current_formation)
	else:
		print("No hay alineación guardada en memoria")

func show_error_message(message):
	# Crear un popup temporal para mostrar el error
	var popup = AcceptDialog.new()
	popup.dialog_text = message
	popup.title = "Error"
	get_tree().current_scene.add_child(popup)
	popup.popup_centered()
	
	# Auto-destruir después de 3 segundos
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(func(): 
		if popup and is_instance_valid(popup):
			popup.queue_free()
		if timer and is_instance_valid(timer):
			timer.queue_free()
	)
	get_tree().current_scene.add_child(timer)
	timer.start()

func show_success_message(message):
	# Crear un popup temporal para mostrar el éxito
	var popup = AcceptDialog.new()
	popup.dialog_text = message
	popup.title = "Éxito"
	get_tree().current_scene.add_child(popup)
	popup.popup_centered()
	
	# Auto-destruir después de 2 segundos
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(func(): 
		if popup and is_instance_valid(popup):
			popup.queue_free()
		if timer and is_instance_valid(timer):
			timer.queue_free()
	)
	get_tree().current_scene.add_child(timer)
	timer.start()

# Función para obtener la alineación actual (para usar en partidos)
func get_current_lineup():
	return {
		"formation": last_used_formation if last_used_formation != "" else current_formation,
		"players": saved_lineup.duplicate(true)
	}

# Función estática para obtener la alineación desde otros scripts
static func get_saved_lineup():
	# Usar LineupManager en lugar de archivo
	return LineupManager.get_saved_lineup()

func _on_back_pressed():
	print("LineupEditor: Volviendo al menú pre-partido...")
	get_tree().change_scene_to_file("res://scenes/PreMatchMenu.tscn")
