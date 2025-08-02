extends Node

# Singleton del manager de la liga
signal match_completed(result: String)

var teams: Array = []
var schedule: Array = []
var current_match_day: int = 1
var match_results: Array = []  # [{match_day: 1, home_team: "...", away_team: "...", result: "win/draw/loss", points_home: 3, points_away: 0}]
var simulated_matches: Dictionary = {}  # Para evitar simular el mismo partido múltiples veces

func _ready():
	load_league_data()

func load_league_data():
	print("LeagueManager: Cargando datos de la liga...")
	
	var file = FileAccess.open("res://data/league_data.json", FileAccess.READ)
	if file == null:
		print("ERROR: No se pudo cargar league_data.json")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("ERROR: Error al parsear league_data.json")
		return
	
	var data = json.data
	teams = data.teams
	schedule = data.schedule
	
	print("LeagueManager: Liga cargada. ", teams.size(), " equipos, ", schedule.size(), " partidos")

func get_next_match():
	# Buscar el próximo partido que no se ha jugado aún
	for match in schedule:
		if match.match_day >= current_match_day:
			# Verificar si ya se jugó este partido
			var already_played = false
			for result in match_results:
				if result.match_day == match.match_day:
					already_played = true
					break
			
			if not already_played:
				return match
	
	# Si no hay más partidos, la liga ha terminado
	return null

func get_team_by_id(team_id: String):
	for team in teams:
		if team.id == team_id:
			return team
	return null

func complete_match(home_goals: int, away_goals: int):
	var next_match = get_next_match()
	if next_match == null:
		print("LeagueManager: No hay partidos pendientes")
		return
	
	var result = {
		"match_day": next_match.match_day,
		"home_team": next_match.home_team,
		"away_team": next_match.away_team,
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
	
	match_results.append(result)
	current_match_day = next_match.match_day + 1
	
	print("LeagueManager: Partido completado: ", result)
	match_completed.emit(result.result)
	
	# Otorgar experiencia a los jugadores
	var players_manager = get_node("/root/PlayersManager")
	if players_manager != null:
		players_manager.add_experience_after_match()

func get_league_table():
	# Calcular la tabla de posiciones
	var table = {}
	
	# Inicializar equipos
	for team in teams:
		table[team.id] = {
			"name": team.name,
			"points": 0,
			"matches_played": 0,
			"wins": 0,
			"draws": 0,
			"losses": 0,
			"goals_for": 0,
			"goals_against": 0
		}
	
	# Procesar resultados
	for result in match_results:
		var home_stats = table[result.home_team]
		var away_stats = table[result.away_team]
		
		home_stats.points += result.points_home
		away_stats.points += result.points_away
		
		home_stats.matches_played += 1
		away_stats.matches_played += 1
		
		home_stats.goals_for += result.home_goals
		home_stats.goals_against += result.away_goals
		away_stats.goals_for += result.away_goals
		away_stats.goals_against += result.home_goals
		
		if result.result == "home_win":
			home_stats.wins += 1
			away_stats.losses += 1
		elif result.result == "away_win":
			away_stats.wins += 1
			home_stats.losses += 1
		else:
			home_stats.draws += 1
			away_stats.draws += 1
	
	return table

func is_league_finished():
	return get_next_match() == null

func simulate_league_matches():
	"""Simula los otros 3 partidos de la jornada actual"""
	print("Simulando otros partidos de la jornada ", current_match_day - 1)
	
	# Buscar todos los partidos de la jornada anterior que no sean del FC Bufas
	var target_match_day = current_match_day - 1
	var other_matches = []
	
	for match in schedule:
		if match.match_day == target_match_day:
			# Verificar si es un partido que no involucra al FC Bufas
			if match.home_team != "fc_bufas" and match.away_team != "fc_bufas":
				# Verificar si ya fue simulado
				var already_simulated = false
				for result in match_results:
					if result.match_day == match.match_day and result.home_team == match.home_team and result.away_team == match.away_team:
						already_simulated = true
						break
				
				if not already_simulated:
					other_matches.append(match)
	
	# Simular cada partido
	for match in other_matches:
		var home_goals = randi() % 4  # 0-3 goles
		var away_goals = randi() % 4  # 0-3 goles
		
		var result = {
			"match_day": match.match_day,
			"home_team": match.home_team,
			"away_team": match.away_team,
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
		
		match_results.append(result)
		
		var home_team = get_team_by_id(match.home_team)
		var away_team = get_team_by_id(match.away_team)
		print("Simulado: ", home_team.name if home_team else match.home_team, " ", home_goals, "-", away_goals, " ", away_team.name if away_team else match.away_team)
	
	print("Jornada ", target_match_day, " completada.")

func get_standings():
	"""Obtiene la clasificación actual de la liga ordenada por puntos"""
	var table = get_league_table()
	var standings = []
	
	# Convertir el diccionario en array para poder ordenar
	for team_id in table.keys():
		var team_data = table[team_id]
		team_data.id = team_id
		team_data.goal_difference = team_data.goals_for - team_data.goals_against
		standings.append(team_data)
	
	# Ordenar por puntos (descendente), luego por diferencia de goles (descendente)
	standings.sort_custom(func(a, b): 
		if a.points != b.points:
			return a.points > b.points
		return a.goal_difference > b.goal_difference
	)
	
	return standings
