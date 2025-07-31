extends Control

func _ready():
	print("PreMatchMenu: Inicializando...")
	
	# Conectar botones directamente por ruta
	var back_btn = get_node("MarginContainer/VBoxContainer/BackButton")
	var lineup_btn = get_node("MarginContainer/VBoxContainer/ActionButtons/LineupButton")
	var play_btn = get_node("MarginContainer/VBoxContainer/ActionButtons/PlayButton")
	
	back_btn.pressed.connect(_on_back_pressed)
	lineup_btn.pressed.connect(_on_lineup_pressed)
	play_btn.pressed.connect(_on_play_pressed)
	
	# Cargar info del partido
	load_match_info()
	
	print("PreMatchMenu: Botones conectados")

func _on_back_pressed():
	print("VOLVER AL TORNEO")
	get_tree().change_scene_to_file("res://scenes/TournamentMenu.tscn")

func _on_lineup_pressed():
	print("COMPROBAR ALINEACIÓN")
	get_tree().change_scene_to_file("res://scenes/LineupEditor.tscn")

func _on_play_pressed():
	print("IR AL CAMPO - SIMULANDO PARTIDO")
	simulate_match()

func simulate_match():
	print("Simulando partido...")
	
	# Generar resultado aleatorio
	var home_goals = randi() % 4
	var away_goals = randi() % 4
	
	print("Resultado: ", home_goals, "-", away_goals)
	
	# Completar partido y avanzar día
	LeagueManager.complete_match(home_goals, away_goals)
	DayManager.advance_day()
	
	print("Día avanzado")
	
	# Volver al torneo
	get_tree().change_scene_to_file("res://scenes/TournamentMenu.tscn")

func load_match_info():
	var match = LeagueManager.get_next_match()
	if match:
		# Determinar quién es el rival de FC Bufas
		var opponent_id = ""
		if match.home_team == "fc_bufas":
			opponent_id = match.away_team
		else:
			opponent_id = match.home_team
		
		var opponent_team = LeagueManager.get_team_by_id(opponent_id)
		if opponent_team:
			get_node("MarginContainer/VBoxContainer/MatchInfoContainer/VSContainer/AwayTeamLabel").text = opponent_team.name
		
		get_node("MarginContainer/VBoxContainer/MatchInfoContainer/MatchDayLabel").text = "Jornada " + str(match.match_day)

func create_lineup_editor():
	print("Creando editor de alineación...")
	
	# Limpiar contenido actual
	for child in get_children():
		child.queue_free()
	
	# Crear contenedor principal
	var main_container = VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(main_container)
	
	# Título
	var title = Label.new()
	title.text = "EDITOR DE ALINEACIÓN - FÚTBOL 7"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	main_container.add_child(title)
	
	# Contenedor horizontal (campo + jugadores)
	var h_container = HBoxContainer.new()
	main_container.add_child(h_container)
	
	# Campo de fútbol (izquierda)
	var field_container = create_football_field()
	h_container.add_child(field_container)
	
	# Lista de jugadores (derecha)
	var players_container = create_players_list()
	h_container.add_child(players_container)
	
	# Botones de acción
	var buttons_container = HBoxContainer.new()
	buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	main_container.add_child(buttons_container)
	
	# Botón guardar
	var save_btn = Button.new()
	save_btn.text = "GUARDAR ALINEACIÓN"
	save_btn.custom_minimum_size = Vector2(200, 50)
	save_btn.pressed.connect(_on_save_lineup_pressed)
	buttons_container.add_child(save_btn)
	
	# Botón volver
	var back_btn = Button.new()
	back_btn.text = "VOLVER"
	back_btn.custom_minimum_size = Vector2(150, 50)
	back_btn.pressed.connect(_on_back_from_lineup_pressed)
	buttons_container.add_child(back_btn)

func create_football_field():
	var field = VBoxContainer.new()
	field.custom_minimum_size = Vector2(500, 400)
	
	# Fondo verde para el campo
	var bg = ColorRect.new()
	bg.color = Color(0.2, 0.8, 0.2, 1.0)  # Verde césped
	bg.custom_minimum_size = Vector2(500, 400)
	field.add_child(bg)
	
	# Selector de formación
	var formation_label = Label.new()
	formation_label.text = "FORMACIÓN:"
	formation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	field.add_child(formation_label)
	
	var formations = OptionButton.new()
	formations.add_item("3-2-1 (Defensa sólida)")
	formations.add_item("1-3-2 (Control medio)")
	formations.selected = 0
	formations.item_selected.connect(_on_formation_changed)
	field.add_child(formations)
	
	# Posiciones del campo
	create_field_positions(field)
	
	return field

func create_field_positions(field):
	# Portero
	var gk_container = HBoxContainer.new()
	gk_container.alignment = BoxContainer.ALIGNMENT_CENTER
	var gk_slot = create_position_slot("Portero", "GK")
	gk_container.add_child(gk_slot)
	field.add_child(gk_container)
	
	# Línea defensiva (3 jugadores por defecto)
	var def_container = HBoxContainer.new()
	def_container.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in range(3):
		var def_slot = create_position_slot("Defensa", "DEF" + str(i+1))
		def_container.add_child(def_slot)
	field.add_child(def_container)
	
	# Línea media (2 jugadores por defecto)
	var mid_container = HBoxContainer.new()
	mid_container.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in range(2):
		var mid_slot = create_position_slot("Medio", "MID" + str(i+1))
		mid_container.add_child(mid_slot)
	field.add_child(mid_container)
	
	# Línea delantera (1 jugador por defecto)
	var att_container = HBoxContainer.new()
	att_container.alignment = BoxContainer.ALIGNMENT_CENTER
	var att_slot = create_position_slot("Delantero", "ATT1")
	att_container.add_child(att_slot)
	field.add_child(att_container)

func create_position_slot(position_name: String, slot_id: String):
	var slot = Button.new()
	slot.text = position_name
	slot.custom_minimum_size = Vector2(80, 60)
	slot.add_theme_color_override("font_color", Color.WHITE)
	slot.add_theme_color_override("font_color_hover", Color.YELLOW)
	slot.modulate = Color(0.3, 0.7, 0.3, 1.0)  # Verde oscuro
	slot.pressed.connect(_on_position_slot_pressed.bind(slot_id, slot))
	return slot

func create_players_list():
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(300, 400)
	
	var title = Label.new()
	title.text = "JUGADORES DISPONIBLES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(title)
	
	# Scroll para la lista de jugadores
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(280, 350)
	container.add_child(scroll)
	
	var players_list = VBoxContainer.new()
	scroll.add_child(players_list)
	
	# Jugadores de ejemplo (deberían venir del PlayersManager)
	var sample_players = [
		{"name": "Portero A", "position": "GK", "grl": 85},
		{"name": "Defensa B", "position": "DEF", "grl": 78},
		{"name": "Defensa C", "position": "DEF", "grl": 80},
		{"name": "Defensa D", "position": "DEF", "grl": 76},
		{"name": "Medio E", "position": "MID", "grl": 82},
		{"name": "Medio F", "position": "MID", "grl": 79},
		{"name": "Medio G", "position": "MID", "grl": 77},
		{"name": "Delantero H", "position": "ATT", "grl": 83},
		{"name": "Delantero I", "position": "ATT", "grl": 81}
	]
	
	for player in sample_players:
		var player_btn = Button.new()
		player_btn.text = player.name + " (" + str(player.grl) + ")"
		player_btn.custom_minimum_size = Vector2(260, 35)
		player_btn.pressed.connect(_on_player_selected.bind(player))
		players_list.add_child(player_btn)
	
	return container

func _on_formation_changed(index):
	print("Formación cambiada a: ", index)
	# TODO: Reorganizar posiciones según formación

func _on_position_slot_pressed(slot_id: String, slot_button: Button):
	print("Posición seleccionada: ", slot_id)
	# TODO: Lógica para asignar jugador a posición

func _on_player_selected(player):
	print("Jugador seleccionado: ", player.name)
	# TODO: Lógica para arrastrar/asignar jugador

func _on_save_lineup_pressed():
	print("Guardando alineación...")
	# TODO: Guardar alineación actual

func _on_back_from_lineup_pressed():
	print("Volviendo del editor de alineación...")
	get_tree().change_scene_to_file("res://scenes/PreMatchMenu.tscn")
