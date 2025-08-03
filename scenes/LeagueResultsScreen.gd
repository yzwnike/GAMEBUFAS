extends Control

# LeagueResultsScreen - Muestra los resultados de la liga después de cada partido del FC Bufas

@onready var results_container = $MarginContainer/VBoxContainer/ResultsContainer
@onready var continue_button = $MarginContainer/VBoxContainer/ContinueButton
@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel

func _ready():
	print("LeagueResultsScreen: Inicializando...")
	
	# Configurar UI inicial
	setup_ui()
	
	# Simular otros partidos de la jornada
	simulate_other_matches()
	
	# Mostrar resultados
	display_results()
	
	# Conectar botón
	continue_button.pressed.connect(_on_continue_pressed)

func setup_ui():
	# Configurar título
	if title_label:
		title_label.text = "RESULTADOS DE LA JORNADA"
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Configurar botón
	if continue_button:
		continue_button.text = "CONTINUAR AL SIGUIENTE DÍA"

func simulate_other_matches():
	print("Simulando otros partidos de la liga...")
	# El LeaguesManager ya simula automáticamente cuando se completa un partido del jugador
	# No necesitamos hacer nada adicional aquí

func display_results():
	# Usar el nuevo LeaguesManager para obtener las clasificaciones de Tercera División
	var leagues_manager = get_node("/root/LeaguesManager") if get_node_or_null("/root/LeaguesManager") else null
	var league_standings = []
	
	if leagues_manager:
		# Obtener clasificación de la Tercera División (división del jugador)
		var player_division = leagues_manager.get_player_division()
		league_standings = leagues_manager.get_league_standings(player_division)
	else:
		print("❌ No se pudo encontrar LeaguesManager")
		return
	
	print("=== CLASIFICACIÓN DE LA LIGA ===")
	
	# Crear interfaz visual para los resultados
	if results_container:
		# Limpiar contenedor
		for child in results_container.get_children():
			child.queue_free()
		
		# Crear encabezado de tabla
		var header = create_team_row("POS", "EQUIPO", "PJ", "PTS", "DG", true)
		results_container.add_child(header)
		
		# Crear fila para cada equipo
		for i in range(league_standings.size()):
			var team = league_standings[i]
			var position = str(i + 1)
			var team_name = team.name
			var matches_played = str(team.matches_played)
			var points = str(team.points)
			var goal_diff = "+" + str(team.goal_difference) if team.goal_difference >= 0 else str(team.goal_difference)
			
			var row = create_team_row(position, team_name, matches_played, points, goal_diff, false)
			
			# Resaltar FC Bufas
			if team.has("is_player") and team.is_player:
				row.modulate = Color.YELLOW
			
			results_container.add_child(row)
			
			print(position, ". ", team_name, " - ", points, " pts (PJ: ", matches_played, ", DG: ", goal_diff, ")")

func create_team_row(pos: String, name: String, played: String, points: String, diff: String, is_header: bool) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(600, 30)
	
	# Crear labels
	var pos_label = Label.new()
	pos_label.text = pos
	pos_label.custom_minimum_size = Vector2(50, 30)
	pos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var name_label = Label.new()
	name_label.text = name
	name_label.custom_minimum_size = Vector2(250, 30)
	
	var played_label = Label.new()
	played_label.text = played
	played_label.custom_minimum_size = Vector2(50, 30)
	played_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var points_label = Label.new()
	points_label.text = points
	points_label.custom_minimum_size = Vector2(50, 30)
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var diff_label = Label.new()
	diff_label.text = diff
	diff_label.custom_minimum_size = Vector2(60, 30)
	diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Estilo especial para encabezado
	if is_header:
		for label in [pos_label, name_label, played_label, points_label, diff_label]:
			label.add_theme_font_size_override("font_size", 16)
			label.modulate = Color.CYAN
	
	row.add_child(pos_label)
	row.add_child(name_label)
	row.add_child(played_label)
	row.add_child(points_label)
	row.add_child(diff_label)
	
	return row

func _on_continue_pressed():
	print("Avanzando al próximo día de entrenamiento...")
	
	# Resetear entrenamiento para el nuevo día
	TrainingManager.reset_training_after_match()
	
	# Avanzar día
	DayManager.advance_day_with_origin("match")
	
	# Volver al menú interactivo
	get_tree().change_scene_to_file("res://scenes/InteractiveMenu.tscn")

