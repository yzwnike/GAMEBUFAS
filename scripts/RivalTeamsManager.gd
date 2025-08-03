extends Node

# Singleton para gestionar la configuración de equipos rivales
signal rival_updated(team_id: String)

var teams_config: Dictionary = {}
var minigames_config: Dictionary = {}
var current_rival_id: String = ""
var current_rival_data: Dictionary = {}

func _ready():
	print("RivalTeamsManager: Inicializando...")
	load_teams_config()

func load_teams_config():
	print("RivalTeamsManager: Cargando configuración de equipos rivales...")
	
	var file = FileAccess.open("res://data/rival_teams_config.json", FileAccess.READ)
	if not file:
		print("ERROR: No se pudo cargar rival_teams_config.json")
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("ERROR: Error al parsear rival_teams_config.json")
		return
	
	var data = json.data
	teams_config = data.get("teams", {})
	minigames_config = data.get("training_minigames", {})
	
	print("RivalTeamsManager: Configuración cargada - ", teams_config.size(), " equipos, ", minigames_config.size(), " minijuegos")

func set_current_rival(team_id: String):
	"""Establece el rival actual basado en el ID del equipo"""
	if teams_config.has(team_id):
		current_rival_id = team_id
		current_rival_data = teams_config[team_id]
		print("RivalTeamsManager: Rival actual establecido: ", current_rival_data.name)
		
		# Actualizar TrainingManager con el nuevo rival
		if TrainingManager:
			var match_day = LeagueManager.current_match_day if LeagueManager else 1
			TrainingManager.set_current_opponent(current_rival_data.name, match_day)
		
		rival_updated.emit(team_id)
	else:
		print("ERROR: Equipo no encontrado en configuración: ", team_id)

func get_current_rival() -> Dictionary:
	"""Devuelve los datos del rival actual"""
	return current_rival_data

func get_current_rival_id() -> String:
	"""Devuelve el ID del rival actual"""
	return current_rival_id

func get_team_data(team_id: String) -> Dictionary:
	"""Obtiene los datos de un equipo específico"""
	return teams_config.get(team_id, {})

func get_pre_training_dialogue_path() -> String:
	"""Devuelve la ruta del diálogo de pre-entrenamiento para el rival actual"""
	return current_rival_data.get("pre_training_dialogue", "")

func get_training_dialogue_path() -> String:
	"""Devuelve la ruta del diálogo de entrenamiento para el rival actual"""
	return current_rival_data.get("training_dialogue", "")

func get_match_dialogue_path() -> String:
	"""Devuelve la ruta del diálogo de partido para el rival actual"""
	return current_rival_data.get("match_dialogue", "")

func get_post_match_dialogue_path() -> String:
	"""Devuelve la ruta del diálogo post-partido para el rival actual"""
	return current_rival_data.get("post_match_dialogue", "")

func get_post_training_dialogue_path() -> String:
	"""Devuelve la ruta del diálogo post-entrenamiento para el rival actual"""
	return current_rival_data.get("post_training_dialogue", "")

func get_training_minigame_info() -> Dictionary:
	"""Devuelve información del minijuego de entrenamiento para el rival actual"""
	var minigame_id = current_rival_data.get("training_minigame", "")
	if minigame_id and minigames_config.has(minigame_id):
		var minigame_data = minigames_config[minigame_id].duplicate()
		# Aplicar modificador de dificultad
		var difficulty = current_rival_data.get("difficulty", "medium")
		var modifier = minigame_data.get("difficulty_modifiers", {}).get(difficulty, 1.0)
		minigame_data["difficulty_modifier"] = modifier
		minigame_data["minigame_id"] = minigame_id
		return minigame_data
	return {}

func get_training_description() -> String:
	"""Devuelve la descripción del entrenamiento para el rival actual"""
	return current_rival_data.get("training_description", "Entrenamiento general")

func get_team_description() -> String:
	"""Devuelve la descripción del equipo rival actual"""
	return current_rival_data.get("team_description", "Equipo rival")

func get_tactics_info() -> String:
	"""Devuelve información táctica sobre el rival actual"""
	return current_rival_data.get("tactics", "Táctica general")

func get_difficulty() -> String:
	"""Devuelve la dificultad del rival actual"""
	return current_rival_data.get("difficulty", "medium")

func update_rival_from_next_match():
	"""Actualiza el rival basado en el próximo partido de la liga"""
	if not LeagueManager:
		print("ERROR: LeagueManager no disponible")
		return
	
	var next_match = LeagueManager.get_next_match()
	if not next_match:
		print("RivalTeamsManager: No hay próximo partido")
		return
	
	# Determinar el ID del equipo rival
	var rival_team_id = ""
	if next_match.home_team == "fc_bufas":
		rival_team_id = next_match.away_team
	else:
		rival_team_id = next_match.home_team
	
	print("RivalTeamsManager: Próximo rival detectado: ", rival_team_id)
	set_current_rival(rival_team_id)

func get_all_teams() -> Dictionary:
	"""Devuelve todos los equipos configurados"""
	return teams_config

func has_team(team_id: String) -> bool:
	"""Verifica si existe configuración para un equipo"""
	return teams_config.has(team_id)

func find_team_by_name(team_name: String) -> String:
	"""Busca el ID de un equipo por su nombre"""
	for team_id in teams_config.keys():
		if teams_config[team_id].get("name", "") == team_name:
			return team_id
	return ""

func set_current_rival_by_name(team_name: String):
	"""Establece el rival actual basado en el nombre del equipo"""
	var team_id = find_team_by_name(team_name)
	if team_id != "":
		set_current_rival(team_id)
		print("RivalTeamsManager: Rival establecido por nombre - ", team_name, " (ID: ", team_id, ")")
	else:
		print("ERROR: No se encontró equipo con nombre: ", team_name)
