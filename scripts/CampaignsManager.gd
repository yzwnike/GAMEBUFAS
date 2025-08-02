extends Node

# CampaignsManager - Sistema de campañas a medio plazo
# Maneja campañas publicitarias, colaboraciones, eventos solidarios, etc.

signal campaign_started(campaign_data: Dictionary)
signal campaign_completed(campaign_data: Dictionary)
signal campaign_progress_updated(campaign_id: String, progress: int, total: int)
signal campaign_random_event(campaign_id: String, event_data: Dictionary)

# Datos de campañas activas y disponibles
var active_campaigns: Array[Dictionary] = []
var completed_campaigns: Array[Dictionary] = []
var available_campaigns: Array[Dictionary] = []

# ID único para campañas
var next_campaign_id: int = 1

func _ready():
	print("🎯 CampaignsManager: Inicializando sistema de campañas...")
	
	# Conectar a señales del GameManager para el progreso automático
	if GameManager:
		if GameManager.has_signal("match_completed"):
			GameManager.match_completed.connect(_on_match_completed)
	
	# Conectar a DayManager para campañas basadas en días
	if DayManager and DayManager.has_signal("day_advanced"):
		DayManager.day_advanced.connect(_on_day_advanced)
	
	# Inicializar campañas disponibles
	initialize_available_campaigns()
	
	print("🎯 CampaignsManager: Sistema listo con ", available_campaigns.size(), " campañas disponibles")

func initialize_available_campaigns():
	"""Inicializa las campañas disponibles en el juego"""
	available_campaigns = [
		{
			"id": "local_publicity",
			"name": "Campaña Publicitaria Local",
			"description": "Publicidad en medios locales para aumentar la base de fanes",
			"type": "publicity",
			"duration_type": "matches", # "matches" o "days"
			"duration": 3,
			"cost": 5000,
			"effects": {
				"fame_gain": 3000,
				"money_change": -5000
			},
			"risk_level": "low", # "low", "medium", "high"
			"random_events": ["publicity_success", "media_criticism"],
			"requirements": {
				"min_fame": 0,
				"min_money": 5000
			},
			"icon": "📺"
		},
		{
			"id": "influencer_collab",
			"name": "Colaboración con Influencer",
			"description": "Colaboración con un influencer popular para ganar exposición",
			"type": "collaboration",
			"duration_type": "matches",
			"duration": 2,
			"cost": 0,
			"effects": {
				"fame_gain": 10000
			},
			"risk_level": "high",
			"random_events": ["influencer_scandal", "viral_success", "controversy"],
			"requirements": {
				"min_fame": 100
			},
			"icon": "📱"
		},
		{
			"id": "charity_campaign",
			"name": "Campaña Solidaria",
			"description": "Actividades benéficas que mejoran la imagen del club",
			"type": "charity",
			"duration_type": "matches",
			"duration": 4,
			"cost": 0,
			"effects": {
				"fame_gain": 5000,
				"moral_boost": 10
			},
			"risk_level": "low",
			"random_events": ["community_appreciation", "positive_media"],
			"requirements": {
				"min_fame": 50
			},
			"icon": "❤️"
		},
		{
			"id": "neighborhood_tour",
			"name": "Tour por Barrios",
			"description": "Visitas a barrios locales, genera ingresos y puede descubrir jugadores",
			"type": "tour",
			"duration_type": "matches",
			"duration": 5,
			"cost": 2000,
			"effects": {
				"money_per_match": 800,
				"discovery_chance": 0.3
			},
			"risk_level": "medium",
			"random_events": ["player_discovery", "equipment_damage", "local_support"],
			"requirements": {
				"min_money": 2000
			},
			"icon": "🚌"
		},
		{
			"id": "social_media_boost",
			"name": "Campaña en Redes Sociales",
			"description": "Presencia activa en redes sociales durante varias semanas",
			"type": "digital",
			"duration_type": "days",
			"duration": 14,
			"cost": 3000,
			"effects": {
				"fame_gain": 8000,
				"money_change": -3000
			},
			"risk_level": "medium",
			"random_events": ["viral_moment", "negative_comments", "algorithm_boost"],
			"requirements": {
				"min_money": 3000,
				"min_fame": 200
			},
			"icon": "💻"
		}
	]

func get_available_campaigns() -> Array[Dictionary]:
	"""Devuelve las campañas disponibles que cumplen los requisitos"""
	var available: Array[Dictionary] = []
	
	for campaign in available_campaigns:
		if can_start_campaign(campaign):
			available.append(campaign)
	
	return available

func can_start_campaign(campaign: Dictionary) -> bool:
	"""Verifica si se pueden cumplir los requisitos para iniciar una campaña"""
	if not GameManager:
		return false
	
	var requirements = campaign.get("requirements", {})
	
	# Verificar dinero mínimo
	if requirements.has("min_money"):
		if GameManager.get_money() < requirements.min_money:
			return false
	
	# Verificar fama mínima
	if requirements.has("min_fame"):
		if GameManager.get_fame() < requirements.min_fame:
			return false
	
	# Verificar que no esté ya activa
	for active in active_campaigns:
		if active.id == campaign.id:
			return false
	
	return true

func start_campaign(campaign_id: String) -> bool:
	"""Inicia una campaña específica"""
	var campaign_template = null
	
	# Buscar la campaña en las disponibles
	for available in available_campaigns:
		if available.id == campaign_id:
			campaign_template = available
			break
	
	if not campaign_template:
		print("❌ CampaignsManager: Campaña no encontrada: ", campaign_id)
		return false
	
	# Verificar requisitos
	if not can_start_campaign(campaign_template):
		print("❌ CampaignsManager: No se cumplen los requisitos para: ", campaign_template.name)
		return false
	
	# Crear instancia de campaña activa
	var active_campaign = campaign_template.duplicate(true)
	active_campaign["instance_id"] = next_campaign_id
	active_campaign["progress"] = 0
	active_campaign["start_day"] = DayManager.get_current_day() if DayManager else 1
	active_campaign["events_triggered"] = []
	
	next_campaign_id += 1
	
	# Aplicar costes iniciales
	if active_campaign.cost > 0 and GameManager:
		GameManager.spend_money(active_campaign.cost)
	
	# Añadir a campañas activas
	active_campaigns.append(active_campaign)
	
	print("✅ CampaignsManager: Campaña iniciada - ", active_campaign.name)
	campaign_started.emit(active_campaign)
	
	return true

func _on_match_completed(match_result: Dictionary):
	"""Se llama cuando se completa un partido - avanza campañas basadas en partidos"""
	for campaign in active_campaigns:
		if campaign.duration_type == "matches":
			advance_campaign_progress(campaign)

func _on_day_advanced(new_day: int):
	"""Se llama cuando avanza un día - avanza campañas basadas en días"""
	for campaign in active_campaigns:
		if campaign.duration_type == "days":
			advance_campaign_progress(campaign)

func advance_campaign_progress(campaign: Dictionary):
	"""Avanza el progreso de una campaña específica"""
	campaign.progress += 1
	
	print("📈 CampaignsManager: Progreso campaña '", campaign.name, "': ", campaign.progress, "/", campaign.duration)
	campaign_progress_updated.emit(campaign.instance_id, campaign.progress, campaign.duration)
	
	# Verificar eventos aleatorios
	check_random_events(campaign)
	
	# Aplicar efectos progresivos (por ejemplo, dinero por partido)
	apply_progressive_effects(campaign)
	
	# Verificar si la campaña está completa
	if campaign.progress >= campaign.duration:
		complete_campaign(campaign)

func apply_progressive_effects(campaign: Dictionary):
	"""Aplica efectos que ocurren durante el progreso de la campaña"""
	var effects = campaign.get("effects", {})
	
	# Dinero por partido/día
	if effects.has("money_per_match") and GameManager:
		GameManager.add_money(effects.money_per_match)
		print("💰 Campaña '", campaign.name, "' generó: +", effects.money_per_match, " monedas")

func check_random_events(campaign: Dictionary):
	"""Verifica y ejecuta eventos aleatorios de la campaña"""
	var random_events = campaign.get("random_events", [])
	if random_events.is_empty():
		return
	
	# Probabilidad base según el nivel de riesgo
	var risk_probabilities = {
		"low": 0.1,
		"medium": 0.2,
		"high": 0.3
	}
	
	var risk_level = campaign.get("risk_level", "low")
	var event_chance = risk_probabilities.get(risk_level, 0.1)
	
	if randf() < event_chance:
		trigger_random_event(campaign)

func trigger_random_event(campaign: Dictionary):
	"""Ejecuta un evento aleatorio de la campaña"""
	var random_events = campaign.get("random_events", [])
	if random_events.is_empty():
		return
	
	var event_type = random_events[randi() % random_events.size()]
	
	# Evitar eventos repetidos
	if campaign.events_triggered.has(event_type):
		return
	
	campaign.events_triggered.append(event_type)
	
	var event_data = create_random_event(event_type, campaign)
	
	print("🎲 CampaignsManager: Evento aleatorio en '", campaign.name, "': ", event_data.title)
	campaign_random_event.emit(campaign.instance_id, event_data)
	
	# Aplicar efectos del evento
	apply_event_effects(event_data)

func create_random_event(event_type: String, campaign: Dictionary) -> Dictionary:
	"""Crea los datos de un evento aleatorio específico"""
	var events_database = {
		"publicity_success": {
			"title": "¡Publicidad Exitosa!",
			"description": "La campaña publicitaria ha tenido mejor recepción de la esperada",
			"effects": {"fame_bonus": 2000},
			"icon": "✨"
		},
		"media_criticism": {
			"title": "Críticas en Medios",
			"description": "Algunos medios han criticado la campaña publicitaria",
			"effects": {"fame_penalty": -1000},
			"icon": "📰"
		},
		"influencer_scandal": {
			"title": "Escándalo del Influencer",
			"description": "El influencer se ha visto envuelto en una polémica",
			"effects": {"fame_penalty": -5000, "moral_penalty": -5},
			"icon": "💥"
		},
		"viral_success": {
			"title": "¡Contenido Viral!",
			"description": "El contenido con el influencer se ha vuelto viral",
			"effects": {"fame_bonus": 15000},
			"icon": "🚀"
		},
		"controversy": {
			"title": "Controversia",
			"description": "La colaboración ha generado debates en redes sociales",
			"effects": {"fame_bonus": 3000, "moral_penalty": -3},
			"icon": "⚡"
		},
		"community_appreciation": {
			"title": "Reconocimiento Comunitario",
			"description": "La comunidad local ha reconocido los esfuerzos solidarios",
			"effects": {"fame_bonus": 3000, "moral_bonus": 5},
			"icon": "🏆"
		},
		"player_discovery": {
			"title": "¡Talento Descubierto!",
			"description": "Durante el tour se ha descubierto un jugador prometedor",
			"effects": {"discovery_success": true},
			"icon": "⭐"
		},
		"equipment_damage": {
			"title": "Daño al Equipamiento",
			"description": "Parte del equipamiento se ha dañado durante el tour",
			"effects": {"money_penalty": -1500},
			"icon": "🔧"
		},
		"viral_moment": {
			"title": "Momento Viral",
			"description": "Un momento de la campaña se ha vuelto viral en redes",
			"effects": {"fame_bonus": 5000},
			"icon": "📱"
		},
		"algorithm_boost": {
			"title": "Boost del Algoritmo",
			"description": "El algoritmo ha favorecido el contenido del club",
			"effects": {"fame_bonus": 3000},
			"icon": "🔄"
		}
	}
	
	return events_database.get(event_type, {
		"title": "Evento Desconocido",
		"description": "Ha ocurrido algo inesperado",
		"effects": {},
		"icon": "❓"
	})

func apply_event_effects(event_data: Dictionary):
	"""Aplica los efectos de un evento aleatorio"""
	var effects = event_data.get("effects", {})
	
	if not GameManager:
		return
	
	# Efectos de fama
	if effects.has("fame_bonus"):
		GameManager.add_fame(effects.fame_bonus, event_data.title)
	if effects.has("fame_penalty"):
		GameManager.add_fame(effects.fame_penalty, event_data.title)
	
	# Efectos de dinero
	if effects.has("money_bonus"):
		GameManager.add_money(effects.money_bonus)
	if effects.has("money_penalty"):
		GameManager.add_money(effects.money_penalty)
	
	# Efectos de moral (si tienes sistema de moral)
	if effects.has("moral_bonus"):
		print("😊 Moral del equipo aumentada: +", effects.moral_bonus)
		# TODO: Implementar cuando tengas sistema de moral
	if effects.has("moral_penalty"):
		print("😞 Moral del equipo reducida: ", effects.moral_penalty)
		# TODO: Implementar cuando tengas sistema de moral
	
	# Descubrimiento de jugadores
	if effects.has("discovery_success"):
		print("⭐ ¡Jugador descubierto durante la campaña!")
		# TODO: Integrar con sistema de descubrimiento de jugadores

func complete_campaign(campaign: Dictionary):
	"""Completa una campaña y aplica sus efectos finales"""
	print("✅ CampaignsManager: Campaña completada - ", campaign.name)
	
	# Aplicar efectos finales
	apply_final_effects(campaign)
	
	# Mover a campañas completadas
	completed_campaigns.append(campaign)
	active_campaigns.erase(campaign)
	
	campaign_completed.emit(campaign)

func apply_final_effects(campaign: Dictionary):
	"""Aplica los efectos finales de una campaña completada"""
	var effects = campaign.get("effects", {})
	
	if not GameManager:
		return
	
	# Ganancia de fama
	if effects.has("fame_gain"):
		GameManager.add_fame(effects.fame_gain, "Campaña: " + campaign.name)
	
	# Cambio de dinero (ya aplicado al inicio si era coste)
	if effects.has("money_change") and effects.money_change > 0:
		GameManager.add_money(effects.money_change)

# Funciones de información
func get_active_campaigns() -> Array[Dictionary]:
	"""Devuelve las campañas actualmente activas"""
	var result: Array[Dictionary] = []
	result.assign(active_campaigns)
	return result

func get_completed_campaigns() -> Array[Dictionary]:
	"""Devuelve las campañas completadas"""
	var result: Array[Dictionary] = []
	result.assign(completed_campaigns)
	return result

func get_campaign_progress_text(campaign: Dictionary) -> String:
	"""Devuelve el texto de progreso de una campaña"""
	var duration_text = ""
	if campaign.duration_type == "matches":
		duration_text = " partidos"
	else:
		duration_text = " días"
	
	return str(campaign.progress) + "/" + str(campaign.duration) + duration_text

func cancel_campaign(campaign_instance_id: int) -> bool:
	"""Cancela una campaña activa (con penalización)"""
	for i in range(active_campaigns.size()):
		if active_campaigns[i].instance_id == campaign_instance_id:
			var campaign = active_campaigns[i]
			
			# Penalización por cancelar
			if GameManager:
				var penalty = campaign.cost * 0.5  # Se pierde la mitad de la inversión
				if penalty > 0:
					GameManager.spend_money(int(penalty))
					print("💸 Penalización por cancelar campaña: -", int(penalty), " monedas")
			
			active_campaigns.remove_at(i)
			print("❌ Campaña cancelada: ", campaign.name)
			return true
	
	return false

func get_campaign_summary() -> Dictionary:
	"""Devuelve un resumen del estado de las campañas"""
	return {
		"active_count": active_campaigns.size(),
		"completed_count": completed_campaigns.size(),
		"available_count": get_available_campaigns().size()
	}
