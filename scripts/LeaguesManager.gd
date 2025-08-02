extends Node

# 🏆 LeaguesManager - Sistema completo de ligas jerárquicas
# Gestiona 3 divisiones con ascensos, descensos y simulación automática

signal league_standings_updated(division: int)
signal season_ended(division: int, final_standings: Array)
signal team_promoted(team_name: String, from_division: int, to_division: int)
signal team_relegated(team_name: String, from_division: int, to_division: int)

# Estructura de las ligas
var leagues: Dictionary = {}
var current_season: int = 1
var matches_per_season: int = 14  # Cada equipo juega contra todos los demás una vez

# Configuración de dificultad por división
var division_difficulty = {
	1: -25,  # Primera División: éxito = substat - 25
	2: -20,  # Segunda División: éxito = substat - 20
	3: -15   # Tercera División: éxito = substat - 15
}

func _ready():
	print("🏆 LeaguesManager: Inicializando sistema de ligas...")
	
	# Inicializar las 3 divisiones
	initialize_leagues()
	
	# Conectar a señales del GameManager para simular partidos automáticamente
	if GameManager and GameManager.has_signal("match_completed"):
		GameManager.match_completed.connect(_on_player_match_completed)
	
	print("🏆 LeaguesManager: Sistema listo - 3 divisiones creadas")

func initialize_leagues():
	"""Inicializa las 3 divisiones con sus equipos"""
	
	# Primera División (10 equipos)
	leagues[1] = {
		"name": "Primera División",
		"teams": [
			create_team("Porcinos FC", 1),
			create_team("Ultimate Móstoles", 1),
			create_team("Saiyans FC", 1),
			create_team("Jijantes FC", 1),
			create_team("Aniquiladores FC", 1),
			create_team("El Barrio", 1),
			create_team("Kunisports", 1),
			create_team("1K FC", 1),
			create_team("PIO FC", 1),
			create_team("XBuyer Team", 1)
		],
		"promotion_spots": 0,  # No hay ascenso desde Primera
		"relegation_spots": 3,  # Los últimos 3 descienden
		"matches_played": 0
	}
	
	# Segunda División (8 equipos)
	leagues[2] = {
		"name": "Segunda División",
		"teams": [
			create_team("Rayo de Barcelona (Kings)", 2),
			create_team("Gijón Five (Kings)", 2),
			create_team("Nike FC", 2),
			create_team("Adidas United", 2),
			create_team("Puma Atlético", 2),
			create_team("Reebok United", 2),
			create_team("Umbro City", 2),
			create_team("New Balance CF", 2)
		],
		"promotion_spots": 3,  # Los primeros 3 ascienden
		"relegation_spots": 3,  # Los últimos 3 descienden
		"matches_played": 0
	}
	
	# Tercera División (8 equipos)
	leagues[3] = {
		"name": "Tercera División",
		"teams": [
			create_team("FC Bufas", 3, true),  # Equipo del jugador
			create_team("Chocolateros FC", 3),
			create_team("Picacachorras FC", 3),
			create_team("Inter de Panzones", 3),
			create_team("Patrulla Canina", 3),
			create_team("Fantasy FC", 3),
			create_team("Deportivo Magadios", 3),
			create_team("Reyes de Jalisco", 3)
		],
		"promotion_spots": 3,  # Los primeros 3 ascienden
		"relegation_spots": 0,  # No hay descenso desde Tercera
		"matches_played": 0
	}
	
	print("🏆 Primera División: ", leagues[1].teams.size(), " equipos")
	print("🥈 Segunda División: ", leagues[2].teams.size(), " equipos")
	print("🥉 Tercera División: ", leagues[3].teams.size(), " equipos")

func create_team(name: String, division: int, is_player: bool = false) -> Dictionary:
	"""Crea un equipo con estadísticas base"""
	var team = {
		"name": name,
		"division": division,
		"is_player": is_player,
		"points": 0,
		"matches_played": 0,
		"wins": 0,
		"draws": 0,
		"losses": 0,
		"goals_for": 0,
		"goals_against": 0,
		"goal_difference": 0,
		"form": [],  # Últimos 5 resultados
		"strength": generate_team_strength(division),
		"recent_matches": []
	}
	
	return team

func generate_team_strength(division: int) -> int:
	"""Genera la fuerza del equipo según la división"""
	var base_strength = 0
	
	match division:
		1:  # Primera División - equipos más fuertes
			base_strength = randi_range(75, 90)
		2:  # Segunda División - equipos medios
			base_strength = randi_range(60, 75)
		3:  # Tercera División - equipos más débiles
			base_strength = randi_range(45, 65)
	
	return base_strength

func get_player_division() -> int:
	"""Devuelve la división actual del jugador"""
	for division in leagues:
		for team in leagues[division].teams:
			if team.is_player:
				return division
	return 3  # Por defecto en Tercera

func get_league_standings(division: int) -> Array:
	"""Devuelve la clasificación ordenada de una división"""
	if not leagues.has(division):
		return []
	
	var teams = leagues[division].teams.duplicate()
	
	# Ordenar por: puntos, diferencia de goles, goles a favor
	teams.sort_custom(func(a, b):
		if a.points != b.points:
			return a.points > b.points
		if a.goal_difference != b.goal_difference:
			return a.goal_difference > b.goal_difference
		return a.goals_for > b.goals_for
	)
	
	# Añadir posición
	for i in range(teams.size()):
		teams[i]["position"] = i + 1
	
	return teams

func get_player_team() -> Dictionary:
	"""Devuelve los datos del equipo del jugador"""
	for division in leagues:
		for team in leagues[division].teams:
			if team.is_player:
				return team
	return {}

func get_player_position() -> int:
	"""Devuelve la posición actual del jugador en su división"""
	var player_division = get_player_division()
	var standings = get_league_standings(player_division)
	
	for i in range(standings.size()):
		if standings[i].is_player:
			return i + 1
	
	return -1

func simulate_all_matches():
	"""Simula partidos de todas las divisiones (excepto el jugador)"""
	print("⚽ Simulando partidos de todas las divisiones...")
	
	for division in leagues:
		simulate_division_matches(division)
	
	# Actualizar clasificaciones
	for division in leagues:
		league_standings_updated.emit(division)

func simulate_division_matches(division: int):
	"""Simula los partidos de una división específica"""
	var league = leagues[division]
	var teams = league.teams
	
	# Generar partidos para esta jornada
	var matches = generate_round_matches(teams, league.matches_played)
	
	for match in matches:
		if not match.home_team.is_player and not match.away_team.is_player:
			# Solo simular si ninguno de los equipos es el jugador
			simulate_match(match.home_team, match.away_team, division)

func generate_round_matches(teams: Array, round: int) -> Array:
	"""Genera los partidos de una jornada específica"""
	var matches = []
	var team_count = teams.size()
	
	# Sistema round-robin simple
	for i in range(team_count):
		for j in range(i + 1, team_count):
			if (i + j + round) % 2 == 0:  # Alternar local/visitante
				matches.append({
					"home_team": teams[i],
					"away_team": teams[j]
				})
			else:
				matches.append({
					"home_team": teams[j],
					"away_team": teams[i]
				})
	
	return matches

func simulate_match(home_team: Dictionary, away_team: Dictionary, division: int):
	"""Simula un partido entre dos equipos de IA"""
	var home_strength = home_team.strength + 5  # Ventaja de local
	var away_strength = away_team.strength
	
	# Calcular probabilidades basadas en fuerza
	var strength_diff = home_strength - away_strength
	var home_win_prob = 0.33 + (strength_diff * 0.01)
	var draw_prob = 0.34
	var away_win_prob = 0.33 - (strength_diff * 0.01)
	
	# Normalizar probabilidades
	var total_prob = home_win_prob + draw_prob + away_win_prob
	home_win_prob /= total_prob
	draw_prob /= total_prob
	away_win_prob /= total_prob
	
	var random = randf()
	var home_goals = 0
	var away_goals = 0
	
	if random < home_win_prob:
		# Victoria local
		home_goals = randi_range(1, 4)
		away_goals = randi_range(0, home_goals - 1)
	elif random < home_win_prob + draw_prob:
		# Empate
		var goals = randi_range(0, 3)
		home_goals = goals
		away_goals = goals
	else:
		# Victoria visitante
		away_goals = randi_range(1, 4)
		home_goals = randi_range(0, away_goals - 1)
	
	# Actualizar estadísticas
	update_team_stats(home_team, away_team, home_goals, away_goals)
	
	# Registrar resultado
	var match_result = {
		"home_team": home_team.name,
		"away_team": away_team.name,
		"home_goals": home_goals,
		"away_goals": away_goals,
		"date": DayManager.get_current_day() if DayManager else 1
	}
	
	home_team.recent_matches.append(match_result)
	away_team.recent_matches.append(match_result)
	
	# Mantener solo los últimos 5 partidos
	if home_team.recent_matches.size() > 5:
		home_team.recent_matches.pop_front()
	if away_team.recent_matches.size() > 5:
		away_team.recent_matches.pop_front()

func update_team_stats(home_team: Dictionary, away_team: Dictionary, home_goals: int, away_goals: int):
	"""Actualiza las estadísticas de ambos equipos tras un partido"""
	# Actualizar partidos jugados
	home_team.matches_played += 1
	away_team.matches_played += 1
	
	# Actualizar goles
	home_team.goals_for += home_goals
	home_team.goals_against += away_goals
	away_team.goals_for += away_goals
	away_team.goals_against += home_goals
	
	# Actualizar diferencia de goles
	home_team.goal_difference = home_team.goals_for - home_team.goals_against
	away_team.goal_difference = away_team.goals_for - away_team.goals_against
	
	# Actualizar resultados y puntos
	if home_goals > away_goals:
		# Victoria local
		home_team.wins += 1
		home_team.points += 3
		away_team.losses += 1
		home_team.form.append("W")
		away_team.form.append("L")
	elif home_goals < away_goals:
		# Victoria visitante
		away_team.wins += 1
		away_team.points += 3
		home_team.losses += 1
		home_team.form.append("L")
		away_team.form.append("W")
	else:
		# Empate
		home_team.draws += 1
		home_team.points += 1
		away_team.draws += 1
		away_team.points += 1
		home_team.form.append("D")
		away_team.form.append("D")
	
	# Mantener solo los últimos 5 resultados en forma
	if home_team.form.size() > 5:
		home_team.form.pop_front()
	if away_team.form.size() > 5:
		away_team.form.pop_front()

func _on_player_match_completed(match_result: Dictionary):
	"""Se ejecuta cuando el jugador completa un partido"""
	print("🏆 Simulando partidos de otras ligas después del partido del jugador...")
	
	# Incrementar partidos jugados en todas las divisiones
	for division in leagues:
		leagues[division].matches_played += 1
	
	# Simular todos los demás partidos
	simulate_all_matches()
	
	# Verificar fin de temporada
	check_season_end()

func check_season_end():
	"""Verifica si la temporada ha terminado y maneja ascensos/descensos"""
	var season_complete = true
	
	for division in leagues:
		if leagues[division].matches_played < matches_per_season:
			season_complete = false
			break
	
	if season_complete:
		print("🏆 ¡FIN DE TEMPORADA ", current_season, "!")
		handle_season_end()

func handle_season_end():
	"""Maneja el final de temporada con ascensos y descensos"""
	var promotions = []
	var relegations = []
	
	# Procesar cada división
	for division in [3, 2, 1]:  # De abajo hacia arriba
		var standings = get_league_standings(division)
		var league = leagues[division]
		
		# Emitir señal de final de temporada
		season_ended.emit(division, standings)
		
		# Manejar ascensos
		if league.promotion_spots > 0 and division < 3:
			for i in range(league.promotion_spots):
				if i < standings.size():
					var team = standings[i]
					promotions.append({
						"team": team,
						"from": division,
						"to": division - 1
					})
		
		# Manejar descensos
		if league.relegation_spots > 0 and division > 1:
			var start_pos = standings.size() - league.relegation_spots
			for i in range(start_pos, standings.size()):
				if i >= 0 and i < standings.size():
					var team = standings[i]
					relegations.append({
						"team": team,
						"from": division,
						"to": division + 1
					})
	
	# Aplicar ascensos y descensos
	apply_division_changes(promotions, relegations)
	
	# Iniciar nueva temporada
	start_new_season()

func apply_division_changes(promotions: Array, relegations: Array):
	"""Aplica los cambios de división"""
	# Procesar ascensos
	for promotion in promotions:
		var team = promotion.team
		var from_div = promotion.from
		var to_div = promotion.to
		
		# Remover del división actual
		leagues[from_div].teams.erase(team)
		
		# Añadir a la nueva división
		team.division = to_div
		team.strength += 5  # Bonus por ascender
		leagues[to_div].teams.append(team)
		
		team_promoted.emit(team.name, from_div, to_div)
		print("📈 ", team.name, " asciende de ", leagues[from_div].name, " a ", leagues[to_div].name)
	
	# Procesar descensos
	for relegation in relegations:
		var team = relegation.team
		var from_div = relegation.from
		var to_div = relegation.to
		
		# Remover de la división actual
		leagues[from_div].teams.erase(team)
		
		# Añadir a la nueva división
		team.division = to_div
		team.strength -= 3  # Penalización por descender
		leagues[to_div].teams.append(team)
		
		team_relegated.emit(team.name, from_div, to_div)
		print("📉 ", team.name, " desciende de ", leagues[from_div].name, " a ", leagues[to_div].name)

func start_new_season():
	"""Inicia una nueva temporada"""
	current_season += 1
	print("🆕 Iniciando temporada ", current_season)
	
	# Resetear estadísticas de todos los equipos
	for division in leagues:
		leagues[division].matches_played = 0
		
		for team in leagues[division].teams:
			team.points = 0
			team.matches_played = 0
			team.wins = 0
			team.draws = 0
			team.losses = 0
			team.goals_for = 0
			team.goals_against = 0
			team.goal_difference = 0
			team.form = []
			team.recent_matches = []

func get_league_summary() -> Dictionary:
	"""Devuelve un resumen de todas las ligas"""
	var summary = {
		"season": current_season,
		"player_division": get_player_division(),
		"player_position": get_player_position(),
		"divisions": {}
	}
	
	for division in leagues:
		var standings = get_league_standings(division)
		summary.divisions[division] = {
			"name": leagues[division].name,
			"standings": standings,
			"matches_played": leagues[division].matches_played,
			"matches_remaining": matches_per_season - leagues[division].matches_played
		}
	
	return summary

func get_recent_results(division: int, limit: int = 10) -> Array:
	"""Devuelve los resultados recientes de una división"""
	var results = []
	
	if not leagues.has(division):
		return results
	
	for team in leagues[division].teams:
		for match in team.recent_matches:
			if not results.has(match):
				results.append(match)
	
	# Ordenar por fecha (más reciente primero)
	results.sort_custom(func(a, b): return a.date > b.date)
	
	# Limitar cantidad
	if results.size() > limit:
		results = results.slice(0, limit)
	
	return results

func get_division_difficulty_modifier(division: int) -> int:
	"""Devuelve el modificador de dificultad para una división"""
	return division_difficulty.get(division, -15)

func get_team_form_string(team: Dictionary) -> String:
	"""Convierte la forma del equipo en string legible"""
	var form_icons = {
		"W": "🟢",  # Victoria
		"D": "🟡",  # Empate
		"L": "🔴"   # Derrota
	}
	
	var form_string = ""
	for result in team.form:
		form_string += form_icons.get(result, "⚪")
	
	return form_string
