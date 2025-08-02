extends Node

# Singleton para manejar el mercado de traspasos
signal market_updated
signal negotiation_response_received(player_id: String, response: Dictionary)

# Estado del mercado
var available_players: Array = []
var market_last_update: float = 0.0
var market_update_interval: float = 300.0  # 5 minutos en segundos

# Estado de negociaciones activas
var active_negotiations: Dictionary = {}  # {player_id: negotiation_data}

# Variables del sistema de días (usa DayManager ahora)
var pending_negotiations: Array = []  # Negociaciones que se resuelven al día siguiente

# Estados posibles de negociación:
# "pending_initial_response" - Esperando respuesta a oferta inicial
# "response_received" - Respuesta recibida, esperando acción del jugador
# "pending_counter_response" - Esperando respuesta a contraoferta del jugador
# "completed" - Negociación terminada (aceptada/rechazada)

func _ready():
	print("TransferMarketManager: Inicializando manager del mercado de traspasos...")
	update_market_if_needed()

func _process(delta):
	# Verificar si es hora de actualizar el mercado
	if Time.get_ticks_msec() / 1000.0 - market_last_update > market_update_interval:
		update_market_if_needed()

func update_market_if_needed():
	print("TransferMarketManager: Actualizando mercado de traspasos...")
	
	# Limpiar jugadores anteriores
	available_players.clear()
	
	# Cargar todos los jugadores disponibles
	var all_players = load_all_players()
	if all_players.is_empty():
		print("TransferMarketManager: No se pudieron cargar jugadores")
		return
	
	# Filtrar jugadores (no repetidos, no en FC Bufas)
	var filtered_players = filter_available_players(all_players)
	
	# Seleccionar 5 jugadores aleatorios
	available_players = select_random_players(filtered_players, 5)
	
	# Calcular precios de mercado
	calculate_market_values()
	
	market_last_update = Time.get_ticks_msec() / 1000.0
	market_updated.emit()
	
	print("TransferMarketManager: Mercado actualizado con ", available_players.size(), " jugadores")

func load_all_players() -> Array:
	var file = FileAccess.open("res://data/encyclopedia_data.json", FileAccess.READ)
	if file == null:
		print("ERROR: No se pudo cargar encyclopedia_data.json")
		return []
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("ERROR: Error al parsear encyclopedia_data.json")
		return []
	
	var data = json.data
	return data.all_players if data.has("all_players") else []

func filter_available_players(all_players: Array) -> Array:
	var filtered = []
	
	# Obtener IDs de jugadores en FC Bufas
	var fc_bufas_ids = []
	for player in PlayersManager.get_all_players():
		fc_bufas_ids.append(player.id)
	
	# Filtrar jugadores
	for player in all_players:
		if not fc_bufas_ids.has(player.id):
			filtered.append(player)
	
	return filtered

func select_random_players(players: Array, count: int) -> Array:
	if players.size() <= count:
		return players
	
	var selected = []
	var available = players.duplicate()
	
	for i in range(count):
		if available.is_empty():
			break
		var random_index = randi() % available.size()
		selected.append(available[random_index])
		available.remove_at(random_index)
	
	return selected

func calculate_market_values():
	for player in available_players:
		# Calcular OVR dinámica basada en substats antes de calcular el precio
		var dynamic_overall = calculate_player_dynamic_overall(player)
		
		# Usar el sistema dinámico del PlayersManager para calcular valores consistentes
		player.market_value = calculate_player_market_value(dynamic_overall)
		
		print("TransferMarketManager: ", player.name, " (OVR estática: ", player.overall, ", OVR dinámica: ", dynamic_overall, ") - Valor: €", player.market_value)

func calculate_player_dynamic_overall(player: Dictionary) -> int:
	"""Calcula la OVR dinámica basada en substats y posición - Idéntico al PlayersManager"""
	var total = 0.0
	match player.position:
		"Delantero":
			total += player.get("shooting", 70) * 0.2
			total += player.get("heading", 70) * 0.2
			total += player.get("dribbling", 70) * 0.2
			total += player.get("speed", 70) * 0.2
			total += player.get("positioning", 70) * 0.2
		"Mediocentro":
			total += player.get("short_pass", 70) * 0.2
			total += player.get("long_pass", 70) * 0.2
			total += player.get("dribbling", 70) * 0.2
			total += player.get("concentration", 70) * 0.2
			total += player.get("speed", 70) * 0.2
		"Defensa":
			total += player.get("marking", 70) * 0.2
			total += player.get("tackling", 70) * 0.2
			total += player.get("positioning", 70) * 0.2
			total += player.get("speed", 70) * 0.2
			total += player.get("heading", 70) * 0.2
		"Portero":
			total += player.get("reflexes", 70) * 0.2
			total += player.get("positioning", 70) * 0.2
			total += player.get("concentration", 70) * 0.2
			total += player.get("short_pass", 70) * 0.2
			total += player.get("speed", 70) * 0.2
		_:
			# Fallback para posiciones desconocidas - promedio de todas las stats
			total += player.get("shooting", 70) + player.get("heading", 70) + player.get("short_pass", 70) + player.get("long_pass", 70) + player.get("dribbling", 70)
			total += player.get("speed", 70) + player.get("marking", 70) + player.get("tackling", 70) + player.get("reflexes", 70) + player.get("positioning", 70)
			total += player.get("stamina", 70) + player.get("concentration", 70)
			total /= 12.0
	
	return int(total)

func calculate_player_market_value(overall: int) -> int:
	"""Calcula el valor de mercado usando la misma lógica que PlayersManager"""
	# Valor base según OVR (en euros)
	var base_value = calculate_base_market_value(overall)
	
	# Aplicar variación aleatoria de ±5%
	var variation = randf_range(-0.05, 0.05)
	var final_value = int(base_value * (1.0 + variation))
	
	# Asegurar que el valor mínimo sea 1000€
	if final_value < 1000:
		final_value = 1000
	
	return final_value

func calculate_base_market_value(overall: int) -> int:
	"""Calcula el valor base de mercado según el OVR del jugador - Idéntico al PlayersManager"""
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

func get_available_players() -> Array:
	return available_players

func start_negotiation(player_id: String, initial_offer: int) -> Dictionary:
	print("TransferMarketManager: Iniciando negociación para jugador ", player_id, " con oferta de €", initial_offer)
	
	# Buscar el jugador
	var player_data = null
	for player in available_players:
		if player.id == player_id:
			player_data = player
			break
	
	if player_data == null:
		return {"success": false, "message": "Jugador no encontrado"}
	
	# Calcular respuesta del representante
	var market_value = player_data.market_value
	var offer_percentage = float(initial_offer) / float(market_value)
	
	var response = generate_agent_response(offer_percentage, market_value, initial_offer)
	
	# Guardar negociación activa
	active_negotiations[player_id] = {
		"player_data": player_data,
		"initial_offer": initial_offer,
		"current_offer": initial_offer,
		"agent_counter": response.get("counter_offer", 0),
		"rounds": 1,
		"status": "pending_initial_response",
		"last_action_day": DayManager.get_current_day()
	}
	
	# Si no es rechazo inmediato, programar respuesta para el día siguiente
	if response.status != "rejected":
		pending_negotiations.append({
			"player_id": player_id,
			"response": response,
			"day": DayManager.get_current_day() + 1
		})
		
		return {"success": true, "message": "Oferta enviada. Recibirás respuesta mañana.", "immediate_response": false}
	else:
		# Rechazo inmediato - marcar como completada
		active_negotiations[player_id]["status"] = "completed"
		return {"success": true, "message": response.message, "immediate_response": true, "response": response}

func generate_agent_response(offer_percentage: float, market_value: int, offer: int) -> Dictionary:
	var response = {}
	
	if offer_percentage < 0.75:  # Menos del 75% (equivale a -25%)
		# Rechazo inmediato
		response.status = "rejected"
		response.message = "¡Ni de coña! Esa oferta es un insulto. No queremos seguir negociando."
	elif offer_percentage >= 0.75 and offer_percentage < 1.0:  # Entre 75% y 100%
		# Contraoferta
		var counter_percentage = randf_range(1.05, 1.15)  # Entre 105% y 115%
		var counter_offer = int(market_value * counter_percentage)
		
		response.status = "counter_offer"
		response.counter_offer = counter_offer
		response.message = "Tu oferta es interesante pero insuficiente. Contraoferta: €%s" % counter_offer
	else:  # 100% o más
		# Aceptación o negociación favorable
		if offer_percentage >= 1.1:  # 110% o más
			response.status = "accepted"
			response.message = "¡Perfecto! Aceptamos tu oferta."
		else:
			# Contraoferta menor
			var counter_percentage = randf_range(1.02, 1.08)  # Entre 102% y 108%
			var counter_offer = int(market_value * counter_percentage)
			
			response.status = "counter_offer"
			response.counter_offer = counter_offer
			response.message = "Casi perfecto. ¿Qué tal €%s?" % counter_offer
	
	return response

func make_counter_offer(player_id: String, new_offer: int) -> Dictionary:
	if not active_negotiations.has(player_id):
		return {"success": false, "message": "No hay negociación activa para este jugador"}
	
	var negotiation = active_negotiations[player_id]
	var market_value = negotiation.player_data.market_value
	var offer_percentage = float(new_offer) / float(market_value)
	
	# Generar nueva respuesta del agente (más flexible en rondas posteriores)
	var response = generate_agent_response_continued(offer_percentage, market_value, new_offer, negotiation.rounds)
	
	negotiation.current_offer = new_offer
	negotiation.rounds += 1
	negotiation.status = "pending_counter_response"
	negotiation.last_action_day = DayManager.get_current_day()
	
	# Limpiar respuesta anterior del agente ya que estamos haciendo nueva contraoferta
	if negotiation.has("latest_response"):
		negotiation.erase("latest_response")
	if negotiation.has("agent_counter"):
		negotiation.agent_counter = 0
	
	# Programar respuesta para el día siguiente
	pending_negotiations.append({
		"player_id": player_id,
		"response": response,
		"day": DayManager.get_current_day() + 1
	})
	
	return {"success": true, "message": "Contraoferta enviada. Recibirás respuesta mañana."}

func generate_agent_response_continued(offer_percentage: float, market_value: int, offer: int, round: int) -> Dictionary:
	var response = {}
	
	# Verificar si el agente debe retirarse por negociaciones prolongadas o falta de flexibilidad
	if should_agent_withdraw(offer_percentage, round):
		response.status = "rejected"
		response.message = get_withdrawal_message(round)
		return response
	
	# El agente se vuelve más flexible en rondas posteriores
	var flexibility_bonus = round * 0.02  # 2% más flexible por ronda
	
	if offer_percentage < (0.75 - flexibility_bonus):
		response.status = "rejected"
		response.message = "Seguimos muy lejos. No podemos aceptar esa cantidad."
	elif offer_percentage >= (0.9 - flexibility_bonus):  # Más flexible para aceptar
		response.status = "accepted"
		response.message = "De acuerdo, aceptamos tu oferta final."
	else:
		# Contraoferta más conservadora
		var counter_percentage = randf_range(1.02, 1.08) - flexibility_bonus
		var counter_offer = max(offer + 1000, int(market_value * counter_percentage))
		
		response.status = "counter_offer"
		response.counter_offer = counter_offer
		response.message = "Estamos cerca. Última oferta: €%s" % counter_offer
	
	return response

# Función para determinar si el agente debe retirarse de la negociación
func should_agent_withdraw(offer_percentage: float, round: int) -> bool:
	# El agente se retira si:
	# 1. Han pasado 5+ rondas Y la oferta es menos del 70% del valor de mercado
	# 2. Han pasado 7+ rondas Y la oferta es menos del 75% del valor de mercado  
	# 3. Han pasado 10+ rondas (sin importar la oferta)
	
	if round >= 10:
		return true  # Límite absoluto de rondas
	
	if round >= 7 and offer_percentage < 0.75:
		return true  # Falta de progreso después de muchas rondas
	
	if round >= 5 and offer_percentage < 0.70:
		return true  # Ofertas muy bajas después de varias rondas
	
	return false

# Función para generar mensaje de retirada según la razón
func get_withdrawal_message(round: int) -> String:
	if round >= 10:
		return "Esto se está alargando demasiado. No queremos seguir perdiendo el tiempo. La negociación ha terminado."
	elif round >= 7:
		return "Hemos sido muy pacientes pero no vemos progreso real en tus ofertas. Nos retiramos de esta negociación."
	else:
		return "Después de varias rondas, no creemos que podamos llegar a un acuerdo. Terminamos aquí."

func advance_day():
	var current_day = DayManager.get_current_day()
	print("TransferMarketManager: Procesando negociaciones para el día ", current_day)
	print("TransferMarketManager: Negociaciones pendientes: ", pending_negotiations.size())
	print("TransferMarketManager: Negociaciones activas: ", active_negotiations.size())
	
	# Procesar negociaciones pendientes
	var responses_to_send = []
	for i in range(pending_negotiations.size() - 1, -1, -1):
		var negotiation = pending_negotiations[i]
		print("TransferMarketManager: Checkeando negociación para día ", negotiation.day, " (actual: ", current_day, ") - jugador: ", negotiation.player_id)
		if negotiation.day <= current_day:
			print("TransferMarketManager: Procesando respuesta para jugador ", negotiation.player_id)
			responses_to_send.append(negotiation)
			pending_negotiations.remove_at(i)
	
	print("TransferMarketManager: Respuestas a enviar: ", responses_to_send.size())
	
	# Enviar respuestas y actualizar estados
	for response_data in responses_to_send:
		var player_id = response_data.player_id
		var response = response_data.response
		
		print("TransferMarketManager: Procesando respuesta para ", player_id, " - estado: ", response.status)
		
		# Actualizar estado de la negociación
		if active_negotiations.has(player_id):
			print("TransferMarketManager: Negociación encontrada para ", player_id)
			# Todas las respuestas van a response_received para que el jugador las confirme
			active_negotiations[player_id].status = "response_received"
			active_negotiations[player_id].agent_counter = response.get("counter_offer", 0)
			active_negotiations[player_id].latest_response = response
			print("TransferMarketManager: Negociación actualizada a response_received (estado: ", response.status, ")")
		else:
			print("ERROR: No se encontró negociación activa para ", player_id)
		
		negotiation_response_received.emit(player_id, response)
	
	print("TransferMarketManager: Procesamiento de día completado")

func accept_deal(player_id: String) -> Dictionary:
	if not active_negotiations.has(player_id):
		return {"success": false, "message": "No hay negociación activa"}
	
	var negotiation = active_negotiations[player_id]
	var player_data = negotiation.player_data
	
	# Debug: mostrar datos de la negociación
	print("TransferMarketManager: DEBUG accept_deal - Negociación: ", negotiation)
	
	# Determinar el precio final correcto
	var final_price = 0
	
	# Si hay una respuesta aceptada, usar la oferta actual del jugador
	if negotiation.has("latest_response") and negotiation.latest_response != null and negotiation.latest_response.status == "accepted":
		final_price = negotiation.current_offer
		print("TransferMarketManager: DEBUG accept_deal - Precio de oferta aceptada: €", final_price)
	# Si hay agent_counter, usarlo
	elif negotiation.has("agent_counter") and negotiation.agent_counter > 0:
		final_price = negotiation.agent_counter
		print("TransferMarketManager: DEBUG accept_deal - Precio de agent_counter: €", final_price)
	# Fallback a current_offer
	else:
		final_price = negotiation.current_offer
		print("TransferMarketManager: DEBUG accept_deal - Precio fallback current_offer: €", final_price)
	
	print("TransferMarketManager: DEBUG accept_deal - Precio final determinado: €", final_price)
	
	# Verificar si el jugador tiene suficiente dinero
	print("TransferMarketManager: DEBUG accept_deal - Dinero actual: €", GameManager.get_money())
	print("TransferMarketManager: DEBUG accept_deal - ¿Puede permitírselo? ", GameManager.can_afford(final_price))
	
	if not GameManager.can_afford(final_price):
		return {"success": false, "message": "No tienes suficiente dinero para completar la transferencia"}
	
	# Realizar la transferencia
	print("TransferMarketManager: DEBUG accept_deal - Dinero antes de gastar: €", GameManager.get_money())
	var money_spent_result = GameManager.spend_money(final_price)
	print("TransferMarketManager: DEBUG accept_deal - ¿Se gastó el dinero correctamente? ", money_spent_result)
	print("TransferMarketManager: DEBUG accept_deal - Dinero después de gastar: €", GameManager.get_money())
	
	# Añadir jugador al equipo
	var new_player = {
		"id": player_data.id,
		"name": player_data.name,
		"position": player_data.position,
		"overall": player_data.overall,
		"shooting": player_data.get("shooting", 70),
		"heading": player_data.get("heading", 70),
		"short_pass": player_data.get("short_pass", 70),
		"long_pass": player_data.get("long_pass", 70),
		"dribbling": player_data.get("dribbling", 70),
		"speed": player_data.get("speed", 70),
		"marking": player_data.get("marking", 70),
		"tackling": player_data.get("tackling", 70),
		"reflexes": player_data.get("reflexes", 70),
		"positioning": player_data.get("positioning", 70),
		"stamina": player_data.get("stamina", 70),
		"concentration": player_data.get("concentration", 70),
		"experience": 0,
		"image": player_data.image,
		"description": player_data.description
	}
	
	PlayersManager.add_new_player(new_player)
	
	# Actualizar enciclopedia
	update_player_team_in_encyclopedia(player_data.id, "FC Bufas")
	
	# Limpiar negociación
	active_negotiations.erase(player_id)
	
	# Quitar jugador del mercado
	for i in range(available_players.size()):
		if available_players[i].id == player_id:
			available_players.remove_at(i)
			break
	
	print("TransferMarketManager: ¡Transferencia completada! ", player_data.name, " se une a FC Bufas por €", final_price)
	
	return {"success": true, "message": "¡Transferencia completada! %s se une a FC Bufas por €%s" % [player_data.name, final_price]}

func update_player_team_in_encyclopedia(player_id: String, new_team: String):
	# Actualizar el equipo del jugador en TransferManager también
	if TransferManager.has_method("update_player_team_in_encyclopedia"):
		TransferManager.update_player_team_in_encyclopedia(player_id, new_team)

func get_active_negotiations() -> Array:
	var negotiations_list = []
	
	for player_id in active_negotiations.keys():
		var negotiation = active_negotiations[player_id]
		
		# Solo incluir negociaciones no completadas
		if negotiation.status == "completed":
			continue
		
		var negotiation_display = {
			"id": player_id,
			"player_name": negotiation.player_data.name,
			"current_offer": negotiation.current_offer,
			"status": get_status_display_text(negotiation.status),
			"internal_status": negotiation.status,
			"agent_response": null,
			"can_interact": can_interact_with_negotiation(negotiation.status),
			"days_since_action": DayManager.get_current_day() - negotiation.last_action_day
		}
		
		# Buscar si hay respuesta recibida para esta negociación
		if negotiation.status == "response_received":
			negotiation_display.agent_response = get_latest_response_for_player(player_id)
		
		negotiations_list.append(negotiation_display)
	
	return negotiations_list

func get_negotiation_by_id(negotiation_id: String) -> Dictionary:
	if active_negotiations.has(negotiation_id):
		var negotiation = active_negotiations[negotiation_id]
		var negotiation_data = {
			"id": negotiation_id,
			"player_name": negotiation.player_data.name,
			"current_offer": negotiation.current_offer,
			"status": "Pendiente",
			"agent_response": null
		}
		
		# Buscar si hay respuesta pendiente para esta negociación
		for pending in pending_negotiations:
			if pending.player_id == negotiation_id:
				negotiation_data.agent_response = pending.response
				negotiation_data.status = "Respuesta recibida"
				break
		
		return negotiation_data
	else:
		return {}

func get_negotiation_status(player_id: String) -> Dictionary:
	if active_negotiations.has(player_id):
		return {"active": true, "data": active_negotiations[player_id]}
	else:
		return {"active": false}

func accept_counter_offer(negotiation_id: String) -> Dictionary:
	if not active_negotiations.has(negotiation_id):
		return {"success": false, "message": "No hay negociación activa para este jugador"}
	
	var negotiation = active_negotiations[negotiation_id]
	
	# Debug: mostrar datos de la negociación
	print("TransferMarketManager: DEBUG - Negociación: ", negotiation)
	print("TransferMarketManager: DEBUG - tiene latest_response: ", negotiation.has("latest_response"))
	print("TransferMarketManager: DEBUG - tiene agent_counter: ", negotiation.has("agent_counter"))
	if negotiation.has("agent_counter"):
		print("TransferMarketManager: DEBUG - agent_counter valor: ", negotiation.agent_counter)
	
	# Obtener el precio de la contraoferta de la respuesta actual
	var counter_offer_amount = 0
	
	# Prioridad 1: latest_response (más reciente)
	if negotiation.has("latest_response") and negotiation.latest_response != null and negotiation.latest_response.has("counter_offer"):
		counter_offer_amount = negotiation.latest_response.counter_offer
		print("TransferMarketManager: DEBUG - Precio obtenido de latest_response: €", counter_offer_amount)
	# Prioridad 2: agent_counter
	elif negotiation.has("agent_counter") and negotiation.agent_counter > 0:
		counter_offer_amount = negotiation.agent_counter
		print("TransferMarketManager: DEBUG - Precio obtenido de agent_counter: €", counter_offer_amount)
	# Prioridad 3: pending_negotiations (fallback)
	else:
		for pending in pending_negotiations:
			if pending.player_id == negotiation_id and pending.response.has("counter_offer"):
				counter_offer_amount = pending.response.counter_offer
				print("TransferMarketManager: DEBUG - Precio obtenido de pending: €", counter_offer_amount)
				break
	
	print("TransferMarketManager: DEBUG - Precio final determinado: €", counter_offer_amount)
	
	if counter_offer_amount == 0:
		print("TransferMarketManager: ERROR - No se pudo determinar el precio de la contraoferta")
		return {"success": false, "message": "No hay contraoferta para aceptar"}
	
	print("TransferMarketManager: Intentando aceptar contraoferta por €", counter_offer_amount)
	
	# Verificar si el jugador tiene suficiente dinero
	print("TransferMarketManager: DEBUG - Dinero actual antes de verificar: €", GameManager.get_money())
	print("TransferMarketManager: DEBUG - ¿Puede permitírselo? ", GameManager.can_afford(counter_offer_amount))
	
	if not GameManager.can_afford(counter_offer_amount):
		return {"success": false, "message": "No tienes suficiente dinero para aceptar esta contraoferta"}
	
	# Realizar la transferencia
	print("TransferMarketManager: DEBUG - Dinero antes de gastar: €", GameManager.get_money())
	var money_spent_result = GameManager.spend_money(counter_offer_amount)
	print("TransferMarketManager: DEBUG - ¿Se gastó el dinero correctamente? ", money_spent_result)
	print("TransferMarketManager: DEBUG - Dinero después de gastar: €", GameManager.get_money())
	
	var player_data = negotiation.player_data
	
	# Añadir jugador al equipo
	var new_player = {
		"id": player_data.id,
		"name": player_data.name,
		"position": player_data.position,
		"overall": player_data.overall,
		"shooting": player_data.get("shooting", 70),
		"heading": player_data.get("heading", 70),
		"short_pass": player_data.get("short_pass", 70),
		"long_pass": player_data.get("long_pass", 70),
		"dribbling": player_data.get("dribbling", 70),
		"speed": player_data.get("speed", 70),
		"marking": player_data.get("marking", 70),
		"tackling": player_data.get("tackling", 70),
		"reflexes": player_data.get("reflexes", 70),
		"positioning": player_data.get("positioning", 70),
		"stamina": player_data.get("stamina", 70),
		"concentration": player_data.get("concentration", 70),
		"experience": 0,
		"image": player_data.image,
		"description": player_data.description
	}
	
	PlayersManager.add_new_player(new_player)
	
	# Actualizar enciclopedia
	update_player_team_in_encyclopedia(player_data.id, "FC Bufas")
	
	# Limpiar negociación
	active_negotiations.erase(negotiation_id)
	
	# Quitar negociaciones pendientes para este jugador
	for i in range(pending_negotiations.size() - 1, -1, -1):
		if pending_negotiations[i].player_id == negotiation_id:
			pending_negotiations.remove_at(i)
	
	# Quitar jugador del mercado
	for i in range(available_players.size()):
		if available_players[i].id == negotiation_id:
			available_players.remove_at(i)
			break
	
	print("TransferMarketManager: ¡Transferencia completada! ", player_data.name, " se une a FC Bufas por €", counter_offer_amount)
	
	return {"success": true, "message": "¡Transferencia completada! %s se une a FC Bufas por €%s" % [player_data.name, counter_offer_amount]}

func reject_counter_offer(negotiation_id: String) -> Dictionary:
	if not active_negotiations.has(negotiation_id):
		return {"success": false, "message": "No hay negociación activa para este jugador"}
	
	# Limpiar negociación
	active_negotiations.erase(negotiation_id)
	
	# Quitar negociaciones pendientes para este jugador
	for i in range(pending_negotiations.size() - 1, -1, -1):
		if pending_negotiations[i].player_id == negotiation_id:
			pending_negotiations.remove_at(i)
	
	print("TransferMarketManager: Negociación rechazada para jugador ", negotiation_id)
	
	return {"success": true, "message": "Has rechazado la contraoferta. La negociación ha terminado."}

func cancel_negotiation(player_id: String):
	active_negotiations.erase(player_id)
	
	# Quitar negociaciones pendientes
	for i in range(pending_negotiations.size() - 1, -1, -1):
		if pending_negotiations[i].player_id == player_id:
			pending_negotiations.remove_at(i)

func complete_negotiation(player_id: String) -> Dictionary:
	if not active_negotiations.has(player_id):
		return {"success": false, "message": "No hay negociación activa para este jugador"}
	
	# Marcar la negociación como completada
	active_negotiations[player_id].status = "completed"
	
	print("TransferMarketManager: Negociación marcada como completada para jugador ", player_id)
	
	return {"success": true, "message": "Negociación cerrada correctamente."}

# Funciones auxiliares para el manejo de estados
func get_status_display_text(internal_status: String) -> String:
	match internal_status:
		"pending_initial_response":
			return "Esperando respuesta inicial..."
		"pending_counter_response":
			return "Esperando respuesta a contraoferta..."
		"response_received":
			return "Respuesta recibida - ¡Acción requerida!"
		"completed":
			return "Negociación completada"
		_:
			return "Estado desconocido"

func can_interact_with_negotiation(internal_status: String) -> bool:
	# Solo se puede interactuar cuando hay una respuesta recibida
	return internal_status == "response_received"

func get_latest_response_for_player(player_id: String) -> Dictionary:
	# Buscar en active_negotiations si ya se procesó una respuesta
	if active_negotiations.has(player_id):
		var negotiation = active_negotiations[player_id]
		if negotiation.has("latest_response"):
			return negotiation.latest_response
	
	# Si no hay respuesta guardada, crear una basada en los datos actuales
	var negotiation = active_negotiations[player_id]
	if negotiation.agent_counter > 0:
		return {
			"status": "counter_offer",
			"counter_offer": negotiation.agent_counter,
			"message": "Contraoferta recibida"
		}
	
	return {}
