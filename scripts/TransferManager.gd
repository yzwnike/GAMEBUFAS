extends Node

# Singleton del manager de fichajes
signal player_obtained(player_data: Dictionary)

var all_players: Array = []
var available_players: Array = []
var gacha_cost = 1  # Precio único del gachapón en Tickets Bufas

func _ready():
	load_all_players()
	calculate_available_players()

func load_all_players():
	print("TransferManager: Cargando todos los jugadores...")
	
	var file = FileAccess.open("res://data/encyclopedia_data.json", FileAccess.READ)
	if file == null:
		print("ERROR: No se pudo cargar encyclopedia_data.json")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("ERROR: Error al parsear encyclopedia_data.json")
		return
	
	var data = json.data
	all_players = data.all_players
	
	print("TransferManager: Cargados ", all_players.size(), " jugadores disponibles para fichajes")

func calculate_available_players():
	# Obtener jugadores actuales del equipo
	var current_team_ids = []
	for player in PlayersManager.get_all_players():
		current_team_ids.append(player.id)
	
	# Filtrar jugadores disponibles (no están en nuestro equipo)
	available_players.clear()
	for player in all_players:
		if not current_team_ids.has(player.id):
			available_players.append(player)
	
	print("TransferManager: ", available_players.size(), " jugadores disponibles para fichar")

func get_random_player() -> Dictionary:
	if available_players.is_empty():
		print("TransferManager: No hay jugadores disponibles para fichar")
		return {}
	
	# Sistema de rareza basado en overall
	var player = select_player_by_rarity()
	return player

func select_player_by_rarity() -> Dictionary:
	# Categorizar jugadores por overall
	var common_players = []      # 70-79
	var rare_players = []        # 80-84  
	var epic_players = []        # 85-89
	var legendary_players = []   # 90+
	
	for player in available_players:
		var overall = player.overall
		if overall >= 90:
			legendary_players.append(player)
		elif overall >= 85:
			epic_players.append(player)
		elif overall >= 80:
			rare_players.append(player)
		else:
			common_players.append(player)
	
	# Probabilidades: 50% común, 30% raro, 15% épico, 5% legendario
	var rand_value = randf()
	var selected_array = []
	
	if rand_value < 0.5 and not common_players.is_empty():
		selected_array = common_players
		print("TransferManager: Seleccionando jugador COMÚN")
	elif rand_value < 0.8 and not rare_players.is_empty():
		selected_array = rare_players
		print("TransferManager: Seleccionando jugador RARO")
	elif rand_value < 0.95 and not epic_players.is_empty():
		selected_array = epic_players
		print("TransferManager: Seleccionando jugador ÉPICO")
	elif not legendary_players.is_empty():
		selected_array = legendary_players
		print("TransferManager: ¡Seleccionando jugador LEGENDARIO!")
	else:
		# Si no hay jugadores de la rareza seleccionada, usar cualquiera disponible
		selected_array = available_players
		print("TransferManager: Seleccionando jugador disponible")
	
	if selected_array.is_empty():
		return {}
	
	var random_index = randi() % selected_array.size()
	return selected_array[random_index]

func perform_gacha_pull() -> Dictionary:
	print("TransferManager: Realizando gachapón")
	
	# Verificar si el jugador tiene suficientes Tickets Bufas
	if not GameManager.can_afford_tickets(gacha_cost):
		print("TransferManager: No tienes suficientes Tickets Bufas para el gachapón")
		return {}
	
	# Descontar Tickets Bufas
	GameManager.spend_tickets_bufas(gacha_cost)
	
	# Obtener jugador aleatorio
	var obtained_player = get_random_player()
	if obtained_player.is_empty():
		print("TransferManager: No se pudo obtener ningún jugador")
		return {}
	
	# Añadir el jugador al equipo
	add_player_to_team(obtained_player)
	
	print("TransferManager: ¡Obtienes a ", obtained_player.name, "! (Overall: ", obtained_player.overall, ")")
	player_obtained.emit(obtained_player)
	
	return obtained_player

func add_player_to_team(player_data: Dictionary):
	# Preparar datos del jugador para añadir al equipo
	var new_player = {
		"id": player_data.id,
		"name": player_data.name,
		"position": player_data.position,
		"overall": player_data.overall,
		"attack": player_data.attack,
		"defense": player_data.defense,
		"speed": player_data.speed,
		"stamina": player_data.stamina,
		"skill": player_data.skill,
		"experience": 0,  # Los jugadores nuevos empiezan sin experiencia
		"image": player_data.image,
		"description": player_data.description
	}
	
	# Añadir al PlayersManager
	PlayersManager.add_new_player(new_player)
	
	# Actualizar la enciclopedia para que el jugador ahora pertenezca a FC Bufas
	update_player_team_in_encyclopedia(player_data.id, "FC Bufas")
	
	# Recalcular jugadores disponibles
	calculate_available_players()
	
	print("TransferManager: ", player_data.name, " ahora pertenece a FC Bufas y está disponible en la plantilla")

func get_gacha_cost() -> int:
	return gacha_cost

func can_perform_gacha() -> bool:
	return GameManager.can_afford_tickets(gacha_cost) and not available_players.is_empty()

func update_player_team_in_encyclopedia(player_id: String, new_team: String):
	# Actualizar el equipo del jugador en la lista de todos los jugadores
	for player in all_players:
		if player.id == player_id:
			player.team = new_team
			print("TransferManager: ", player.name, " ahora pertenece al equipo ", new_team)
			break
	
	# TODO: Opcional - Guardar cambios en el archivo de enciclopedia
	# save_encyclopedia_data()
