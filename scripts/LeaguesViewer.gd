extends Control

# Referencias a los nodos de la interfaz
@onready var title_label = $MainContainer/Header/Title
@onready var close_button = $MainContainer/Header/CloseButton
@onready var division_tabs = $MainContainer/DivisionTabs

# Referencias a las tablas de clasificación
@onready var standings_table_1 = $"MainContainer/DivisionTabs/Primera División/FirstDivisionContent/StandingsPanel/StandingsContainer/StandingsTable"
@onready var standings_table_2 = $"MainContainer/DivisionTabs/Segunda División/SecondDivisionContent/StandingsPanel2/StandingsContainer2/StandingsTable2"
@onready var standings_table_3 = $"MainContainer/DivisionTabs/Tercera División/ThirdDivisionContent/StandingsPanel3/StandingsContainer3/StandingsTable3"

# Referencias a las listas de resultados
@onready var results_list_1 = $"MainContainer/DivisionTabs/Primera División/FirstDivisionContent/RecentResults/ResultsContainer/ResultsList"
@onready var results_list_2 = $"MainContainer/DivisionTabs/Segunda División/SecondDivisionContent/RecentResults2/ResultsContainer2/ResultsList2"
@onready var results_list_3 = $"MainContainer/DivisionTabs/Tercera División/ThirdDivisionContent/RecentResults3/ResultsContainer3/ResultsList3"

var leagues_manager: Node

func _ready():
	# Obtener referencia al LeaguesManager
	leagues_manager = get_node("/root/LeaguesManager") if get_node_or_null("/root/LeaguesManager") else null
	
	if not leagues_manager:
		print("❌ LeaguesViewer: No se pudo encontrar LeaguesManager")
		return
	
	# Conectar a las señales del LeaguesManager
	if leagues_manager.has_signal("league_standings_updated"):
		leagues_manager.league_standings_updated.connect(_on_standings_updated)
	
	# Cargar datos iniciales
	update_all_data()

func update_all_data():
	"""Actualiza todos los datos de la interfaz"""
	if not leagues_manager:
		return
	
	var league_summary = leagues_manager.get_league_summary()
	
	# Actualizar título con temporada actual
	title_label.text = "🏆 OTRAS LIGAS - TEMPORADA " + str(league_summary.season)
	
	# Actualizar cada división
	update_division_data(1, standings_table_1, results_list_1)
	update_division_data(2, standings_table_2, results_list_2)
	update_division_data(3, standings_table_3, results_list_3)

func update_division_data(division: int, standings_table: VBoxContainer, results_list: VBoxContainer):
	"""Actualiza los datos de una división específica"""
	if not leagues_manager:
		return
	
	# Limpiar contenido anterior
	clear_container(standings_table)
	clear_container(results_list)
	
	# Crear encabezado de la tabla
	create_standings_header(standings_table)
	
	# Obtener y mostrar clasificación
	var standings = leagues_manager.get_league_standings(division)
	for team in standings:
		create_team_row(standings_table, team, division)
	
	# Obtener y mostrar resultados recientes
	var recent_results = leagues_manager.get_recent_results(division, 8)
	for result in recent_results:
		create_result_row(results_list, result)

func create_standings_header(container: VBoxContainer):
	"""Crea el encabezado de la tabla de clasificación"""
	var header = HBoxContainer.new()
	
	# Configurar columnas
	var columns = [
		{"text": "POS", "min_width": 50},
		{"text": "EQUIPO", "min_width": 200},
		{"text": "PJ", "min_width": 40},
		{"text": "G", "min_width": 30},
		{"text": "E", "min_width": 30},
		{"text": "P", "min_width": 30},
		{"text": "GF", "min_width": 40},
		{"text": "GC", "min_width": 40},
		{"text": "DG", "min_width": 40},
		{"text": "PTS", "min_width": 50},
		{"text": "FORMA", "min_width": 80}
	]
	
	for column in columns:
		var label = Label.new()
		label.text = column.text
		label.custom_minimum_size.x = column.min_width
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color.YELLOW)
		header.add_child(label)
	
	container.add_child(header)
	
	# Añadir separador
	var separator = HSeparator.new()
	container.add_child(separator)

func create_team_row(container: VBoxContainer, team: Dictionary, division: int):
	"""Crea una fila con los datos de un equipo"""
	var row = HBoxContainer.new()
	
	# Datos a mostrar
	var data = [
		str(team.position),
		team.name,
		str(team.matches_played),
		str(team.wins),
		str(team.draws),
		str(team.losses),
		str(team.goals_for),
		str(team.goals_against),
		str(team.goal_difference),
		str(team.points),
		leagues_manager.get_team_form_string(team) if leagues_manager else ""
	]
	
	# Anchos mínimos correspondientes
	var widths = [50, 200, 40, 30, 30, 30, 40, 40, 40, 50, 80]
	
	for i in range(data.size()):
		var label = Label.new()
		label.text = data[i]
		label.custom_minimum_size.x = widths[i]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		# Colorear según posición
		var color = get_position_color(team.position, division)
		label.add_theme_color_override("font_color", color)
		
		# Destacar equipo del jugador
		if team.has("is_player") and team.is_player:
			label.add_theme_color_override("font_color", Color.CYAN)
		
		row.add_child(label)
	
	container.add_child(row)

func create_result_row(container: VBoxContainer, result: Dictionary):
	"""Crea una fila con un resultado"""
	var row = HBoxContainer.new()
	
	# Formatear resultado
	var result_text = "%s %d - %d %s" % [
		result.home_team,
		result.home_goals,
		result.away_goals,
		result.away_team
	]
	
	var label = Label.new()
	label.text = result_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Color según resultado
	if result.home_goals > result.away_goals:
		label.add_theme_color_override("font_color", Color.GREEN)
	elif result.home_goals < result.away_goals:
		label.add_theme_color_override("font_color", Color.RED)
	else:
		label.add_theme_color_override("font_color", Color.YELLOW)
	
	row.add_child(label)
	container.add_child(row)

func get_position_color(position: int, division: int) -> Color:
	"""Devuelve el color según la posición del equipo"""
	match division:
		1:  # Primera División
			if position == 1:
				return Color.GOLD  # Campeón
			elif position >= 8:  # Los últimos 3 descienden (posiciones 8, 9, 10)
				return Color.RED   # Descenso
			else:
				return Color.WHITE
		
		2:  # Segunda División
			if position <= 3:  # Los primeros 3 ascienden
				return Color.GREEN  # Ascenso
			elif position >= 6:  # Los últimos 3 descienden (posiciones 6, 7, 8)
				return Color.RED    # Descenso
			else:
				return Color.WHITE
		
		3:  # Tercera División
			if position <= 3:  # Los primeros 3 ascienden
				return Color.GREEN  # Ascenso
			else:
				return Color.WHITE
		
		_:
			return Color.WHITE

func clear_container(container: VBoxContainer):
	"""Limpia todos los hijos de un contenedor"""
	for child in container.get_children():
		child.queue_free()

func _on_standings_updated(division: int):
	"""Se ejecuta cuando se actualizan las clasificaciones"""
	print("📊 Actualizando clasificación de división ", division)
	
	# Actualizar solo la división específica
	match division:
		1:
			update_division_data(1, standings_table_1, results_list_1)
		2:
			update_division_data(2, standings_table_2, results_list_2)
		3:
			update_division_data(3, standings_table_3, results_list_3)

func _on_close_button_pressed():
	"""Cierra la ventana del visor de ligas"""
	print("🚪 Cerrando visor de ligas...")
	hide()
	
	# Buscar el controlador de la oficina y mostrar la UI
	var office_menu = get_parent()
	print("🔍 Buscando oficina: ", office_menu.name if office_menu else "No encontrado")
	
	if office_menu and office_menu.has_method("show_office_ui"):
		print("✅ Encontrada oficina, mostrando UI...")
		office_menu.show_office_ui()
	else:
		print("⚠️ No se pudo encontrar el controlador de la oficina")
		print("🔄 Intentando reactivar manualmente...")
		# Fallback: intentar mostrar todos los nodos padre
		if office_menu:
			for child in office_menu.get_children():
				if child != self:
					child.show()

func show_leagues():
	"""Muestra la ventana de ligas y actualiza los datos"""
	show()
	update_all_data()
	
	# Enfocar en la división del jugador
	if leagues_manager:
		var player_division = leagues_manager.get_player_division()
		division_tabs.current_tab = player_division - 1  # Los tabs empiezan en 0

func _input(event):
	"""Maneja entrada de teclado"""
	if visible and event.is_action_pressed("ui_cancel"):
		_on_close_button_pressed()
