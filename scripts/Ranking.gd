extends Control

@onready var grid_container = $MarginContainer/VBoxContainer/GridContainer
@onready var back_button = $MarginContainer/VBoxContainer/BackButton
@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel

var league_manager: Node

func _ready():
	print("Ranking: Inicializando pantalla de clasificación...")
	
	# Obtener referencia al LeagueManager
	league_manager = get_node("/root/LeagueManager")
	if league_manager == null:
		print("ERROR: No se pudo encontrar LeagueManager")
		return
	
	# Configurar estilos
	setup_styles()
	
	# Conectar botón de volver
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Mostrar la tabla de clasificación
	display_league_table()
	
	print("Ranking: Pantalla de clasificación lista")

func setup_styles():
	# Estilo del título
	var title_settings = LabelSettings.new()
	title_settings.font_size = 48
	title_settings.font_color = Color.WHITE
	title_settings.outline_size = 3
	title_settings.outline_color = Color.BLACK
	title_label.label_settings = title_settings
	
	# Estilo del botón volver
	back_button.add_theme_font_size_override("font_size", 20)

func display_league_table():
	print("Ranking: Generando tabla de clasificación...")
	
	# Limpiar la grilla (mantener solo los headers)
	clear_table_data()
	
	# Obtener los datos de la tabla desde LeagueManager
	var table_data = league_manager.get_league_table()
	
	# Simular resultados de partidos que no involucran al FC Bufas
	simulate_other_matches()
	
	# Volver a obtener los datos actualizados
	table_data = league_manager.get_league_table()
	
	# Convertir el diccionario a array y ordenar por puntos
	var teams_array = []
	for team_id in table_data.keys():
		var team_data = table_data[team_id]
		team_data["id"] = team_id
		teams_array.append(team_data)
	
	# Ordenar por puntos (descendente), luego por diferencia de goles, luego por goles a favor
	teams_array.sort_custom(func(a, b):
		if a.points != b.points:
			return a.points > b.points
		var goal_diff_a = a.goals_for - a.goals_against
		var goal_diff_b = b.goals_for - b.goals_against
		if goal_diff_a != goal_diff_b:
			return goal_diff_a > goal_diff_b
		return a.goals_for > b.goals_for
	)
	
	# Mostrar cada equipo en la tabla
	for i in range(teams_array.size()):
		var team = teams_array[i]
		var position = i + 1
		
		# Crear labels para cada columna
		create_table_row(position, team)
	
	print("Ranking: Tabla de clasificación mostrada con ", teams_array.size(), " equipos")

func clear_table_data():
	# Eliminar todos los nodos que no sean headers (los primeros 9)
	var children = grid_container.get_children()
	for i in range(9, children.size()):
		children[i].queue_free()

func create_table_row(position: int, team: Dictionary):
	# Posición
	var pos_label = Label.new()
	pos_label.text = str(position)
	pos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pos_label.add_theme_font_size_override("font_size", 18)
	
	# Destacar al FC Bufas
	if team.id == "fc_bufas":
		pos_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		pos_label.add_theme_color_override("font_color", Color.WHITE)
	
	grid_container.add_child(pos_label)
	
	# Nombre del equipo
	var team_label = Label.new()
	team_label.text = team.name
	team_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	team_label.add_theme_font_size_override("font_size", 18)
	
	if team.id == "fc_bufas":
		team_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		team_label.add_theme_color_override("font_color", Color.WHITE)
	
	grid_container.add_child(team_label)
	
	# Puntos
	var points_label = Label.new()
	points_label.text = str(team.points)
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	points_label.add_theme_font_size_override("font_size", 18)
	
	if team.id == "fc_bufas":
		points_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		points_label.add_theme_color_override("font_color", Color.WHITE)
	
	grid_container.add_child(points_label)
	
	# Partidos jugados
	var played_label = Label.new()
	played_label.text = str(team.matches_played)
	played_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	played_label.add_theme_font_size_override("font_size", 18)
	
	if team.id == "fc_bufas":
		played_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		played_label.add_theme_color_override("font_color", Color.WHITE)
	
	grid_container.add_child(played_label)
	
	# Victorias
	var wins_label = Label.new()
	wins_label.text = str(team.wins)
	wins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wins_label.add_theme_font_size_override("font_size", 18)
	
	if team.id == "fc_bufas":
		wins_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		wins_label.add_theme_color_override("font_color", Color.WHITE)
	
	grid_container.add_child(wins_label)
	
	# Empates
	var draws_label = Label.new()
	draws_label.text = str(team.draws)
	draws_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	draws_label.add_theme_font_size_override("font_size", 18)
	
	if team.id == "fc_bufas":
		draws_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		draws_label.add_theme_color_override("font_color", Color.WHITE)
	
	grid_container.add_child(draws_label)
	
	# Derrotas
	var losses_label = Label.new()
	losses_label.text = str(team.losses)
	losses_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	losses_label.add_theme_font_size_override("font_size", 18)
	
	if team.id == "fc_bufas":
		losses_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		losses_label.add_theme_color_override("font_color", Color.WHITE)
	
	grid_container.add_child(losses_label)
	
	# Goles a favor
	var gf_label = Label.new()
	gf_label.text = str(team.goals_for)
	gf_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gf_label.add_theme_font_size_override("font_size", 18)
	
	if team.id == "fc_bufas":
		gf_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		gf_label.add_theme_color_override("font_color", Color.WHITE)
	
	grid_container.add_child(gf_label)
	
	# Goles en contra
	var ga_label = Label.new()
	ga_label.text = str(team.goals_against)
	ga_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ga_label.add_theme_font_size_override("font_size", 18)
	
	if team.id == "fc_bufas":
		ga_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		ga_label.add_theme_color_override("font_color", Color.WHITE)
	
	grid_container.add_child(ga_label)

func simulate_other_matches():
	"""
	Simula los partidos entre equipos que no involucran al FC Bufas
	para completar la jornada actual y mostrar una tabla realista
	"""
	print("Ranking: Simulando partidos entre otros equipos...")
	
	var all_teams = []
	for team in league_manager.teams:
		if team.id != "fc_bufas":
			all_teams.append(team.id)
	
	# Simular algunos partidos aleatorios entre los otros equipos
	# Solo simulamos partidos de jornadas anteriores a la actual
	var current_match_day = league_manager.current_match_day
	
	# Para cada jornada hasta la actual, simular partidos que no estén ya jugados
	for match_day in range(1, current_match_day):
		# Buscar si ya hay un resultado para el FC Bufas en esta jornada
		var bufas_played_this_matchday = false
		for result in league_manager.match_results:
			if result.match_day == match_day and (result.home_team == "fc_bufas" or result.away_team == "fc_bufas"):
				bufas_played_this_matchday = true
				break
		
		# Si FC Bufas ya jugó esta jornada, simular 1-2 partidos más entre otros equipos
		if bufas_played_this_matchday:
			simulate_random_matches_for_matchday(match_day, 2)

func simulate_random_matches_for_matchday(match_day: int, num_matches: int):
	"""
	Simula partidos aleatorios para una jornada específica
	"""
	var other_teams = []
	for team in league_manager.teams:
		if team.id != "fc_bufas":
			other_teams.append(team.id)
	
	# Barajar la lista de equipos
	other_teams.shuffle()
	
	# Crear partidos aleatorios
	for i in range(min(num_matches, other_teams.size() / 2)):
		if i * 2 + 1 < other_teams.size():
			var home_team = other_teams[i * 2]
			var away_team = other_teams[i * 2 + 1]
			
			# Verificar que este partido no exista ya
			var match_exists = false
			for result in league_manager.match_results:
				if result.match_day == match_day and result.home_team == home_team and result.away_team == away_team:
					match_exists = true
					break
			
			if not match_exists:
				# Generar resultado aleatorio
				var home_goals = randi() % 4  # 0-3 goles
				var away_goals = randi() % 4  # 0-3 goles
				
				# Crear el resultado manualmente
				var result = {
					"match_day": match_day,
					"home_team": home_team,
					"away_team": away_team,
					"home_goals": home_goals,
					"away_goals": away_goals
				}
				
				# Determinar puntos
				if home_goals > away_goals:
					result.points_home = 3
					result.points_away = 0
					result.result = "home_win"
				elif home_goals < away_goals:
					result.points_home = 0
					result.points_away = 3
					result.result = "away_win"
				else:
					result.points_home = 1
					result.points_away = 1
					result.result = "draw"
				
				# Añadir al array de resultados
				league_manager.match_results.append(result)
				print("Simulado: ", home_team, " ", home_goals, "-", away_goals, " ", away_team)

func _on_back_button_pressed():
	print("Ranking: Volviendo al menú del torneo...")
	get_tree().change_scene_to_file("res://scenes/TournamentMenu.tscn")

# Función para manejar la tecla ESC (volver atrás)
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
