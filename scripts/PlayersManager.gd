extends Node

# Singleton del manager de jugadores
signal player_upgraded(player_id: String)
signal experience_gained(player_id: String, amount: int)

var players: Array = []

func _ready():
	load_players_data()

func load_players_data():
	print("PlayersManager: Cargando datos de jugadores...")
	
	var file = FileAccess.open("res://data/players_data.json", FileAccess.READ)
	if file == null:
		print("ERROR: No se pudo cargar players_data.json")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("ERROR: Error al parsear players_data.json")
		return
	
	var data = json.data
	players = data.players
	
	print("PlayersManager: Jugadores cargados. ", players.size(), " jugadores en la plantilla")

func get_all_players():
	return players

func get_player_by_id(player_id: String):
	for player in players:
		if player.id == player_id:
			return player
	return null

func upgrade_player(player_id: String, stat: String, amount: int = 1):
	var player = get_player_by_id(player_id)
	if player == null:
		print("ERROR: Jugador no encontrado: ", player_id)
		return false
	
	# Límite máximo de estadísticas
	var max_stat = 99
	
	match stat:
		"attack":
			player.attack = min(player.attack + amount, max_stat)
		"defense":
			player.defense = min(player.defense + amount, max_stat)
		"speed":
			player.speed = min(player.speed + amount, max_stat)
		"stamina":
			player.stamina = min(player.stamina + amount, max_stat)
		"skill":
			player.skill = min(player.skill + amount, max_stat)
	
	# Recalcular overall
	update_player_overall(player)
	
	print("PlayersManager: Jugador mejorado - ", player.name, " (", stat, " +", amount, ")")
	player_upgraded.emit(player_id)
	return true

func upgrade_player_with_experience(player_id: String, stat: String, experience_cost: int = 1) -> bool:
	var player = get_player_by_id(player_id)
	if player == null:
		print("ERROR: Jugador no encontrado: ", player_id)
		return false
	
	# Verificar si tiene suficiente experiencia
	if player.experience < experience_cost:
		print("ERROR: Experiencia insuficiente. Necesita: ", experience_cost, ", Tiene: ", player.experience)
		return false
	
	# Límite máximo de estadísticas
	var max_stat = 99
	var current_stat = 0
	
	match stat:
		"attack":
			current_stat = player.attack
			if current_stat >= max_stat:
				print("ERROR: Estadística ya está al máximo")
				return false
			player.attack = min(player.attack + 1, max_stat)
		"defense":
			current_stat = player.defense
			if current_stat >= max_stat:
				print("ERROR: Estadística ya está al máximo")
				return false
			player.defense = min(player.defense + 1, max_stat)
		"speed":
			current_stat = player.speed
			if current_stat >= max_stat:
				print("ERROR: Estadística ya está al máximo")
				return false
			player.speed = min(player.speed + 1, max_stat)
		"stamina":
			current_stat = player.stamina
			if current_stat >= max_stat:
				print("ERROR: Estadística ya está al máximo")
				return false
			player.stamina = min(player.stamina + 1, max_stat)
		"skill":
			current_stat = player.skill
			if current_stat >= max_stat:
				print("ERROR: Estadística ya está al máximo")
				return false
			player.skill = min(player.skill + 1, max_stat)
		_:
			print("ERROR: Estadística no válida: ", stat)
			return false
	
	# Descontar experiencia
	player.experience -= experience_cost
	
	# Recalcular overall
	update_player_overall(player)
	
	print("PlayersManager: Jugador mejorado con experiencia - ", player.name, " (", stat, " +1) - Experiencia restante: ", player.experience)
	player_upgraded.emit(player_id)
	return true

func update_player_overall(player: Dictionary):
	# Calcular overall basado en todas las estadísticas
	var total = player.attack + player.defense + player.speed + player.stamina + player.skill
	player.overall = int(total / 5.0)

func get_upgrade_cost(player_id: String, stat: String) -> int:
	var player = get_player_by_id(player_id)
	if player == null:
		return -1
	
	# El costo aumenta según el nivel actual de la estadística
	var current_stat = 0
	match stat:
		"attack":
			current_stat = player.attack
		"defense":
			current_stat = player.defense
		"speed":
			current_stat = player.speed
		"stamina":
			current_stat = player.stamina
		"skill":
			current_stat = player.skill
	
	# Fórmula de costo: base + (stat_level / 10) * 50
	var base_cost = 100
	var cost = base_cost + int(current_stat / 10.0) * 50
	return cost

func can_afford_upgrade(cost: int) -> bool:
	# TODO: Integrar con sistema de dinero/puntos
	# Por ahora siempre devuelve true
	return true

# Funciones de experiencia
func add_experience_to_player(player_id: String, amount: int):
	var player = get_player_by_id(player_id)
	if player == null:
		print("ERROR: Jugador no encontrado: ", player_id)
		return
	
	player.experience += amount
	print("PlayersManager: ", player.name, " ganó ", amount, " puntos de experiencia. Total: ", player.experience)
	experience_gained.emit(player_id, amount)

func add_experience_to_all_players(amount: int):
	for player in players:
		player.experience += amount
		print("PlayersManager: ", player.name, " ganó ", amount, " puntos de experiencia. Total: ", player.experience)
		experience_gained.emit(player.id, amount)

func add_experience_after_match():
	# Dar 2 puntos de experiencia a todos los jugadores después de un partido
	print("PlayersManager: Otorgando experiencia post-partido...")
	add_experience_to_all_players(2)

func add_experience_after_training():
	# Dar 2 puntos de experiencia a todos los jugadores después de entrenar
	print("PlayersManager: Otorgando experiencia post-entrenamiento...")
	add_experience_to_all_players(2)

func add_new_player(player_data: Dictionary):
	# Añadir un nuevo jugador a la plantilla
	players.append(player_data)
	print("PlayersManager: Nuevo jugador añadido - ", player_data.name, " (", player_data.position, ", Overall: ", player_data.overall, ")")
	
	# TODO: Guardar cambios en archivo (persistencia)
	# save_players_data()

# Sistema de valor de mercado dinámico
func calculate_market_value(player_id: String) -> int:
	"""Calcula el valor de mercado de un jugador basado en su OVR actual con variación aleatoria"""
	var player = get_player_by_id(player_id)
	if player == null:
		print("ERROR: Jugador no encontrado para calcular valor de mercado: ", player_id)
		return 0
	
	# Valor base según OVR (en miles de euros)
	var base_value = calculate_base_market_value(player.overall)
	
	# Aplicar variación aleatoria de ±5%
	var variation = randf_range(-0.05, 0.05)
	var final_value = int(base_value * (1.0 + variation))
	
	# Asegurar que el valor mínimo sea 1000€
	if final_value < 1000:
		final_value = 1000
	
	return final_value

func calculate_base_market_value(overall: int) -> int:
	"""Calcula el valor base de mercado según el OVR del jugador - Valores específicos por OVR"""
	# Tabla de valores base por OVR con los valores especificados
	var base_values = {
		99: 300000,  # 300k
		98: 280000,  # 280k
		97: 260000,  # 260k
		96: 240000,  # 240k
		95: 220000,  # 220k
		94: 200000,  # 200k
		93: 190000,  # 190k
		92: 180000,  # 180k
		91: 170000,  # 170k
		90: 160000,  # 160k
		89: 145000,  # 145k
		88: 135000,  # 135k
		87: 125000,  # 125k
		86: 115000,  # 115k
		85: 105000,  # 105k
		84: 95000,   # 95k (referencia)
		83: 85000,   # 85k
		82: 75000,   # 75k
		81: 64000,   # 64k
		80: 54000,   # 54k
		79: 43000,   # 43k
		78: 35000,   # 35k
		77: 28000,   # 28k
		76: 23000,   # 23k
		75: 18000,   # 18k
		74: 14000,   # 14k
		73: 11000,   # 11k
		72: 8000,    # 8k
		71: 6000,    # 6k
		70: 4000,    # 4k
		69: 3000,    # 3k
	}
	
	# Si el OVR está en la tabla, usar ese valor
	if base_values.has(overall):
		return base_values[overall]
	
	# Para OVR menores a 69, usar valores bajos
	if overall < 69:
		# De 68 hacia abajo: valores progresivamente menores
		var value = max(500, 3000 - (69 - overall) * 300)
		return value
	
	# Fallback para valores fuera de rango
	return 500

func get_player_market_value_formatted(player_id: String) -> String:
	"""Devuelve el valor de mercado formateado como texto legible"""
	var value = calculate_market_value(player_id)
	
	if value >= 1000000:
		return str(value / 1000000.0).pad_decimals(1) + "M €"
	elif value >= 1000:
		return str(value / 1000) + "K €"
	else:
		return str(value) + " €"

func get_all_players_with_market_value() -> Array:
	"""Devuelve todos los jugadores con su valor de mercado calculado"""
	var players_with_value = []
	for player in players:
		var player_copy = player.duplicate()
		player_copy.market_value = calculate_market_value(player.id)
		player_copy.market_value_formatted = get_player_market_value_formatted(player.id)
		players_with_value.append(player_copy)
	return players_with_value
