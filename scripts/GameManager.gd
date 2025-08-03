extends Node

# GameManager - Controlador principal del juego
# Maneja las transiciones entre la novela visual y la simulación de fútbol

signal money_updated(new_amount: int)
signal tickets_updated(new_amount: int)
signal inventory_updated()
signal match_completed(resultado: Dictionary)
signal season_ended()
signal fame_updated(new_amount: int, reason: String)

var current_scene_path = ""
var previous_scene_path = ""

# Sistema de dinero, fama e inventario
var money: int = 22000  # Dinero inicial + 20k para testing
var tickets_bufas: int = 3  # Tickets Bufas iniciales para debug
var fame: int = 100  # Puntos de fama del club (iniciar con algunos fanes)
var inventory: Dictionary = {
	# Ítems de testing para debug
	"discurso_capitan": 3,  # Para aumentar moral
	"test_bad_news": 5,     # Para reducir moral y testing del sistema de correos
	"stamina_small": 2      # Para testing de stamina
} # {item_id: quantity}

# Sistema de historial de fama
var fame_history: Array[Dictionary] = []  # [{"day": int, "change": int, "reason": String, "new_total": int}]
var max_fame_history_entries: int = 10  # Máximo de entradas en el historial

# Estados del juego
enum GameState {
	MAIN_MENU,
	VISUAL_NOVEL,
	TEAM_MANAGEMENT,
	MATCH_SIMULATION,
	PAUSE_MENU
}

var current_state = GameState.MAIN_MENU

# Variables de progreso del juego
var story_progress = {}
var team_stats = {
	"wins": 0,
	"losses": 0,
	"draws": 0,
	"goals_for": 0,
	"goals_against": 0
}

# Configuración del equipo FC Bufas
var team_formation = "4-3-3"
var starting_eleven = []
var team_chemistry = 50.0

# Sistema de guardado
var save_file_path = "user://savegame.json"
var auto_save_enabled = true
var has_unsaved_progress = false

# Sistema de diálogos dinámicos
var current_dialogue_data = []

signal scene_changed
signal game_state_changed

func _ready():
	print("=== GameManager._ready() ejecutado ===")
	# Habilitar procesamiento de input para cheats
	set_process_unhandled_input(true)
	
	# CONFIGURACIÓN NORMAL DEL JUEGO
	# El juego comienza desde el MainMenu por defecto
	print("Iniciando juego desde MainMenu...")
	
	# Configuración inicial limpia
	current_state = GameState.MAIN_MENU
	
	# MODO DEBUG: Descomenta estas líneas para probar diferentes partes del juego
	# DEBUG - OPCIÓN 1: Debug del partido 3vs3
	# set_story_flag("chapter1_completed", true)
	# set_story_flag("ready_for_3v3_match", true)
	# set_story_flag("rival_team", "perma pablo javo")
	
	# DEBUG - OPCIÓN 2: Debug directo al capítulo 2 + partido 7vs7
	# set_story_flag("chapter1_completed", true)
	# set_story_flag("load_chapter_2", true)
	
	# DEBUG - OPCIÓN 3: Debug del último diálogo del prólogo
	# set_story_flag("chapter1_completed", true)
	# set_story_flag("chapter_2_7v7", true)
	# set_story_flag("post_match_branch", "win_7v7")
	
	# Cargar progreso del juego si existe (deshabilitado para testing)
	# load_game()  # Comentado para evitar cargar partidas guardadas durante desarrollo
	
	# Conectar señales (si es necesario)
	# get_tree().tree_changed.connect(_on_tree_changed)
	
	# Establecer rival inicial si RivalTeamsManager está disponible
	if RivalTeamsManager:
		RivalTeamsManager.update_rival_from_next_match()

func change_scene(scene_path):
	previous_scene_path = current_scene_path
	current_scene_path = scene_path
	
	# Efecto de transición
	transition_to_scene(scene_path)

func transition_to_scene(scene_path):
	# Crear efecto de fade out/in
	var transition = create_transition_overlay()
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(transition, "modulate:a", 1.0, 0.5)
	await tween.finished
	
	# Cambiar escena
	get_tree().change_scene_to_file(scene_path)
	
	# La transición de fade in se manejará en la nueva escena
	emit_signal("scene_changed")

func create_transition_overlay():
	var overlay = ColorRect.new()
	overlay.color = Color.BLACK
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.modulate.a = 0.0
	get_tree().current_scene.add_child(overlay)
	return overlay

func set_game_state(new_state):
	current_state = new_state
	emit_signal("game_state_changed", new_state)

# Sistema de guardado y carga
func save_game():
	var save_data = {
		"story_progress": story_progress,
		"team_stats": team_stats,
		"team_formation": team_formation,
		"starting_eleven": starting_eleven,
		"team_chemistry": team_chemistry,
		"current_scene": current_scene_path,
		"current_day": DayManager.get_current_day() if DayManager else 1,
		"current_match_day": LeagueManager.current_match_day if LeagueManager else 1,
		"match_results": LeagueManager.match_results if LeagueManager else [],
		"money": money,
		"tickets_bufas": tickets_bufas,
		"fame": fame,
		"inventory": inventory,
		"save_timestamp": Time.get_unix_time_from_system()
	}
	
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		has_unsaved_progress = false
		print("Juego guardado correctamente - Día ", save_data.get("current_day", 1))
		return true
	else:
		print("Error al guardar el juego")
		return false

func load_game():
	var file = FileAccess.open(save_file_path, FileAccess.READ)
	if file:
		var save_data_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(save_data_text)
		if parse_result == OK:
			var save_data = json.data
			story_progress = save_data.get("story_progress", {})
			team_stats = save_data.get("team_stats", team_stats)
			team_formation = save_data.get("team_formation", "4-3-3")
			starting_eleven = save_data.get("starting_eleven", [])
			team_chemistry = save_data.get("team_chemistry", 50.0)
			money = save_data.get("money", 22000)
			tickets_bufas = save_data.get("tickets_bufas", 3)
			fame = save_data.get("fame", 0)
			inventory = save_data.get("inventory", {})
			
			# Restaurar día actual en DayManager
			var saved_day = save_data.get("current_day", 1)
			if DayManager:
				DayManager.current_day = saved_day
			
			# Restaurar estado de la liga en LeagueManager
			var saved_match_day = save_data.get("current_match_day", 1)
			var saved_match_results = save_data.get("match_results", [])
			if LeagueManager:
				LeagueManager.current_match_day = saved_match_day
				LeagueManager.match_results = saved_match_results
				print("Liga restaurada - Jornada: ", saved_match_day, ", Partidos jugados: ", saved_match_results.size())
			
			has_unsaved_progress = false
			print("Juego cargado correctamente - Día ", saved_day)
			return true
		else:
			print("Error al parsear el archivo de guardado")
			return false
	else:
		print("No se encontró archivo de guardado previo")
		return false

# Funciones para el progreso de la historia
func set_story_flag(flag_name, value):
	story_progress[flag_name] = value

func get_story_flag(flag_name, default_value = false):
	return story_progress.get(flag_name, default_value)

# Variables para el último partido jugado
var last_match_result: Dictionary = {}

# Funciones para estadísticas del equipo
func add_match_result(goals_for, goals_against):
	team_stats.goals_for += goals_for
	team_stats.goals_against += goals_against
	
	# Determinar el resultado del partido
	var result = ""
	if goals_for > goals_against:
		team_stats.wins += 1
		result = "win"
	elif goals_for < goals_against:
		team_stats.losses += 1
		result = "loss"
	else:
		team_stats.draws += 1
		result = "draw"
	
	# Guardar información del último partido
	last_match_result = {
		"goals_for": goals_for,
		"goals_against": goals_against,
		"result": result,
		"timestamp": Time.get_unix_time_from_system(),
		"victoria": result == "win",
		"goles_jugador": goals_for,
		"goles_rival": goals_against,
		"max_goles_jugador": 1  # TODO: Implementar seguimiento de goles individuales
	}
	
	print("Último resultado guardado: ", last_match_result)
	
	# Procesar cambios de fama basados en el resultado
	process_match_fame_changes(goals_for, goals_against, result)
	
	# Completar el partido en el LeagueManager
	if LeagueManager:
		LeagueManager.complete_match(goals_for, goals_against)
		print("Partido completado en LeagueManager")
	
	# Emitir señal de partido completado para EncargosManager
	match_completed.emit(last_match_result)
	
	# Cargar diálogo post-partido específico del rival actual
	# NOTA: El avance de día se hará DESPUÉS del diálogo en BranchingDialogue.process_post_match_actions()
	if RivalTeamsManager:
		var post_match_dialogue_path = RivalTeamsManager.get_post_match_dialogue_path()
		if post_match_dialogue_path != "" and ResourceLoader.exists(post_match_dialogue_path):
			print("Cargando diálogo post-partido del rival: ", post_match_dialogue_path)
			# Cargar y configurar el diálogo post-partido
			load_post_match_dialogue_from_rival(post_match_dialogue_path, result)
			# Ir al diálogo post-partido usando BranchingDialogue
			get_tree().change_scene_to_file("res://scenes/BranchingDialogue.tscn")
			return
	
	# Obtener el próximo partido y cargar escena
	if LeagueManager:
		var next_match = LeagueManager.get_next_match()
		if next_match:
			print("Próximo partido: ", next_match.home_team, " vs ", next_match.away_team, " (Jornada ", next_match.match_day, ")")
			# Actualizar rival para el próximo partido
			if RivalTeamsManager:
				RivalTeamsManager.update_rival_from_next_match()
			return
		else:
			print("🏆 ¡La liga ha terminado! No hay más partidos.")
			# Mostrar pantalla de final de temporada
			process_season_end_bonus()
			get_tree().change_scene_to_file("res://scenes/SeasonEndScreen.tscn")
	
	# Guardar automáticamente después de cada partido
	save_game()

func get_last_match_result() -> Dictionary:
	return last_match_result

func get_win_percentage():
	var total_matches = team_stats.wins + team_stats.losses + team_stats.draws
	if total_matches == 0:
		return 0.0
	return float(team_stats.wins) / float(total_matches) * 100.0

# Funciones para la gestión del equipo
func set_formation(formation):
	team_formation = formation
	# Recalcular química del equipo basado en la formación
	calculate_team_chemistry()

func calculate_team_chemistry():
	# Lógica básica para calcular la química del equipo
	# Se puede expandir con más factores
	team_chemistry = 50.0  # Base
	
	# Bonus por partidos ganados
	team_chemistry += min(team_stats.wins * 2, 30)
	
	# Penalty por partidos perdidos
	team_chemistry -= min(team_stats.losses * 1, 20)
	
	# Mantener entre 0 y 100
	team_chemistry = clamp(team_chemistry, 0.0, 100.0)

func _on_tree_changed():
	# Función llamada cuando cambia la estructura del árbol de nodos
	pass

# Funciones para diálogos dinámicos
func load_post_match_dialogue():
	var branch = get_story_flag("post_match_branch", "loss")
	
	# Intentar usar el archivo genérico de Deportivo Magadios como fallback
	var dialogue_file_path = "res://data/post_match_dialogues/DeportivoMagadiosPostMatch.json"
	
	var file = FileAccess.open(dialogue_file_path, FileAccess.READ)
	if not file:
		print("Error: No se pudo cargar el archivo de diálogo post-partido genérico")
		# Crear un diálogo mínimo como último recurso
		return create_minimal_post_match_dialogue(branch)
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("Error al parsear el JSON de diálogo post-partido genérico")
		return create_minimal_post_match_dialogue(branch)
	
	var dialogue_data = json.data
	var branch_key = branch + "_branch"
	
	if dialogue_data.has(branch_key):
		current_dialogue_data = dialogue_data[branch_key]
		print("Diálogo post-partido genérico cargado: rama ", branch)
		return current_dialogue_data
	else:
		print("Error: No se encontró la rama de diálogo ", branch_key, " en archivo genérico")
		return create_minimal_post_match_dialogue(branch)

func get_current_dialogue_data():
	return current_dialogue_data

func clear_dialogue_data():
	current_dialogue_data = []

func create_minimal_post_match_dialogue(branch: String) -> Array:
	"""Crea un diálogo mínimo como último recurso cuando todos los archivos fallan"""
	print("Creando diálogo post-partido mínimo para rama: ", branch)
	
	var minimal_dialogue = []
	
	match branch:
		"win":
			minimal_dialogue = [
				{
					"character": "narrator",
					"text": "¡Victoria! El equipo ha conseguido una gran victoria.",
					"background": "campo"
				},
				{
					"character": "yazawa",
					"text": "¡Buen trabajo, equipo! Hemos dado todo en el campo."
				}
			]
		"loss":
			minimal_dialogue = [
				{
					"character": "narrator",
					"text": "Derrota. A pesar del esfuerzo, hoy no ha podido ser.",
					"background": "campo"
				},
				{
					"character": "yazawa",
					"text": "No pasa nada, chicos. La próxima vez lo haremos mejor."
				}
			]
		"draw":
			minimal_dialogue = [
				{
					"character": "narrator",
					"text": "Empate. Un resultado justo tras un partido muy reñido.",
					"background": "campo"
				},
				{
					"character": "yazawa",
					"text": "Ha sido un partido difícil. Empatar no está mal."
				}
			]
		_:
			# Fallback genérico
			minimal_dialogue = [
				{
					"character": "narrator",
					"text": "El partido ha terminado. Es hora de volver a casa.",
					"background": "campo"
				}
			]
	
	current_dialogue_data = minimal_dialogue
	return minimal_dialogue

func load_post_match_dialogue_from_rival(dialogue_path: String, match_result: String):
	"""Carga diálogo post-partido específico del rival actual"""
	var file = FileAccess.open(dialogue_path, FileAccess.READ)
	if not file:
		print("Error: No se pudo cargar el archivo de diálogo post-partido del rival: ", dialogue_path)
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("Error al parsear el JSON de diálogo post-partido del rival")
		return
	
	var dialogue_data = json.data
	var branch_key = match_result + "_branch"
	
	if dialogue_data.has(branch_key):
		current_dialogue_data = dialogue_data[branch_key]
		# Establecer flag para que el sistema sepa qué rama usar
		set_story_flag("post_match_branch", match_result)
		print("Diálogo post-partido del rival cargado: rama ", match_result)
	else:
		print("Error: No se encontró la rama de diálogo ", branch_key, " en el archivo del rival")
		# Fallback al diálogo genérico
		load_post_match_dialogue()

# Sistema de autoguardado
func auto_save():
	if auto_save_enabled:
		print("Auto-guardando progreso...")
		return save_game()
	return false

func mark_progress_unsaved():
	has_unsaved_progress = true

func has_save_file() -> bool:
	return FileAccess.file_exists(save_file_path)

# Función para salir al menú principal guardando progreso
func return_to_main_menu():
	print("Regresando al menú principal...")
	
	# Auto-guardar antes de salir
	if has_unsaved_progress or auto_save_enabled:
		auto_save()
	
	# Cambiar al menú principal
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func load_chapter_dialogue(chapter_number: int):
	var dialogue_file_path = "res://data/chapter" + str(chapter_number) + "_dialogue.json"
	
	var file = FileAccess.open(dialogue_file_path, FileAccess.READ)
	if not file:
		print("Error: No se pudo cargar el archivo de diálogo del capítulo ", chapter_number)
		return []
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("Error al parsear el JSON del capítulo ", chapter_number)
		return []
	
	var dialogue_data = json.data
	
	if dialogue_data.has("dialogue"):
		current_dialogue_data = dialogue_data["dialogue"]
		print("Capítulo ", chapter_number, " cargado: ", dialogue_data.get("title", "Sin título"))
		return current_dialogue_data
	else:
		print("Error: No se encontró diálogo en el capítulo ", chapter_number)
		return []

func quit_game():
	save_game()
	get_tree().quit()

# Función para completar el prólogo y pasar al menú interactivo
func complete_prologue():
	print("=== PRÓLOGO COMPLETADO ===")
	
	# Marcar el prólogo como completado
	set_story_flag("prologue_completed", true)
	
	# Establecer el día inicial del juego principal
	if DayManager:
		DayManager.current_day = 1
	
	# Guardar el progreso
	auto_save()
	
	# Cambiar al menú interactivo
	print("Transicionando al menú interactivo...")
	get_tree().change_scene_to_file("res://scenes/InteractiveMenu.tscn")

func start_new_game():
	print("=== INICIANDO NUEVO JUEGO ===")
	
	# Limpiar progreso anterior
	story_progress.clear()
	team_stats = {
		"wins": 0,
		"losses": 0,
		"draws": 0,
		"goals_for": 0,
		"goals_against": 0
	}
	
	# Reiniciar valores iniciales
	money = 2000  # Dinero inicial normal (sin debug)
	tickets_bufas = 0
	inventory.clear()
	
	# Establecer estado inicial
	current_state = GameState.VISUAL_NOVEL
	
	# Iniciar el prólogo
	print("Cargando prólogo...")
	get_tree().change_scene_to_file("res://scenes/PrologueScene.tscn")

# Funciones de tickets Bufas
func get_tickets_bufas() -> int:
	return tickets_bufas

func add_tickets_bufas(amount: int):
	tickets_bufas += amount
	tickets_updated.emit(tickets_bufas)
	print("GameManager: Tickets Bufas actualizados - ", tickets_bufas)

func spend_tickets_bufas(amount: int) -> bool:
	if tickets_bufas >= amount:
		tickets_bufas -= amount
		tickets_updated.emit(tickets_bufas)
		print("GameManager: Tickets Bufas gastados - ", amount, ". Tickets Bufas restantes: ", tickets_bufas)
		return true
	else:
		print("GameManager: No hay suficientes Tickets Bufas para gastar ", amount)
		return false

func can_afford_tickets(amount: int) -> bool:
	return tickets_bufas >= amount

# Funciones de dinero e inventario
func get_money() -> int:
	return money

func add_money(amount: int):
	money += amount
	money_updated.emit(money)
	print("GameManager: Dinero actualizado - ", money)

# ========== SISTEMA COMPLETO DE FAMA ==========

# Funciones básicas de fama
func get_fame() -> int:
	return fame

func add_fame(amount: int, reason: String = "Sin especificar"):
	var old_fame = fame
	fame += amount
	fame = max(0, fame)  # No permitir fama negativa
	
	# Añadir al historial
	add_to_fame_history(amount, reason)
	
	# Emitir señal
	fame_updated.emit(fame, reason)
	
	print("📈 GameManager: Fama ", "aumentó" if amount > 0 else "disminuyó", " en ", abs(amount), " (", reason, "). Total: ", fame)

func lose_fame(amount: int, reason: String = "Sin especificar"):
	"""Función específica para perder fama (más clara semánticamente)"""
	add_fame(-amount, reason)

func spend_fame(amount: int) -> bool:
	if fame >= amount:
		fame -= amount
		fame_updated.emit(fame, "Gasto de fama")
		print("GameManager: Fama gastada - ", amount, ". Fama restante: ", fame)
		return true
	else:
		print("GameManager: No hay suficiente fama para gastar ", amount)
		return false

# Sistema de historial de fama
func add_to_fame_history(change: int, reason: String):
	"""Añade una entrada al historial de cambios de fama"""
	var current_day = DayManager.get_current_day() if DayManager else 1
	
	var entry = {
		"day": current_day,
		"change": change,
		"reason": reason,
		"new_total": fame,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	fame_history.push_front(entry)
	
	# Limitar el historial a las últimas X entradas
	if fame_history.size() > max_fame_history_entries:
		fame_history = fame_history.slice(0, max_fame_history_entries)

func get_fame_history() -> Array[Dictionary]:
	"""Devuelve el historial de cambios de fama"""
	return fame_history

func get_recent_fame_changes(count: int = 5) -> Array[Dictionary]:
	"""Devuelve los últimos N cambios de fama"""
	return fame_history.slice(0, min(count, fame_history.size()))

# Sistema de ingresos basados en fama
func calculate_match_earnings() -> int:
	"""Calcula los ingresos base de un partido según la fama"""
	var base_earnings = 50  # Ingresos mínimos por partido
	var fame_bonus = int(fame * 0.5)  # 0.5 monedas por cada punto de fama
	
	var total_earnings = base_earnings + fame_bonus
	print("💰 Ingresos del partido: ", base_earnings, " (base) + ", fame_bonus, " (fama) = ", total_earnings)
	
	return total_earnings

func calculate_season_bonus() -> int:
	"""Calcula la prima de final de temporada basada en la fama total"""
	var bonus_multiplier = 2.0  # Multiplicador para la prima de temporada
	var season_bonus = int(fame * bonus_multiplier)
	
	print("🏆 Prima de temporada: ", fame, " fama × ", bonus_multiplier, " = ", season_bonus, " monedas")
	
	return season_bonus

# Funciones de fama por resultados de partidos
func process_match_fame_changes(goals_for: int, goals_against: int, result: String):
	"""Procesa los cambios de fama basados en el resultado del partido"""
	var fame_change = 0
	var reason = ""
	
	match result:
		"win":
			# Victorias dan fama
			var goal_difference = goals_for - goals_against
			fame_change = 10 + (goal_difference * 2)  # Base 10 + 2 por cada gol de diferencia
			reason = "Victoria " + str(goals_for) + "-" + str(goals_against)
			
			# Bonus por goleadas
			if goal_difference >= 3:
				fame_change += 5
				reason += " (¡Goleada!)"
			
		"loss":
			# Derrotas quitan fama
			var goal_difference = goals_against - goals_for
			fame_change = -5 - (goal_difference * 1)  # Base -5 - 1 por cada gol de diferencia
			reason = "Derrota " + str(goals_for) + "-" + str(goals_against)
			
			# Penalización extra por goleadas en contra
			if goal_difference >= 3:
				fame_change -= 5
				reason += " (Goleada recibida)"
			
		"draw":
			# Empates dan poca fama
			fame_change = 2
			reason = "Empate " + str(goals_for) + "-" + str(goals_against)
	
	if fame_change != 0:
		add_fame(fame_change, reason)
	
	# Calcular y añadir ingresos del partido
	var match_earnings = calculate_match_earnings()
	add_money(match_earnings)

func process_season_end_bonus():
	"""Procesa la prima de final de temporada"""
	var season_bonus = calculate_season_bonus()
	if season_bonus > 0:
		add_money(season_bonus)
		add_fame(10, "Bonus de final de temporada")
		print("🎉 ¡Prima de temporada otorgada! +", season_bonus, " monedas y +10 fama")

# Eventos de fama para encargos y decisiones
func process_fame_event(event_type: String, choice: String = "") -> Dictionary:
	"""Procesa eventos que afectan a la fama (para encargos, decisiones, etc.)"""
	var result = {"fame_change": 0, "money_change": 0, "description": ""}
	
	match event_type:
		"sponsorship_controversial":
			if choice == "accept":
				result.fame_change = 15
				result.money_change = 5000
				result.description = "Patrocinio polémico aceptado - Mayor exposición"
			else:
				result.fame_change = -5
				result.money_change = 0
				result.description = "Patrocinio rechazado - Oportunidad perdida"
			
		"media_interview":
			if choice == "positive":
				result.fame_change = 8
				result.description = "Entrevista positiva en medios"
			else:
				result.fame_change = -3
				result.description = "Declaraciones polémicas"
			
		"community_event":
			result.fame_change = 12
			result.money_change = -1000
			result.description = "Participación en evento comunitario"
			
		"scandal":
			result.fame_change = -20
			result.description = "Escándalo del equipo"
	
	if result.fame_change != 0:
		add_fame(result.fame_change, result.description)
	if result.money_change != 0:
		add_money(result.money_change)
	
	return result

# Funciones de información sobre fama
func get_fame_level_description() -> String:
	"""Devuelve una descripción del nivel actual de fama"""
	if fame >= 1000:
		return "⭐⭐⭐ CLUB LEGENDARIO"
	elif fame >= 500:
		return "⭐⭐ CLUB RECONOCIDO"
	elif fame >= 200:
		return "⭐ CLUB EMERGENTE"
	elif fame >= 50:
		return "📈 CLUB EN CRECIMIENTO"
	else:
		return "🌱 CLUB NOVATO"

func get_estimated_daily_earnings() -> int:
	"""Estima los ingresos diarios basados en la fama actual"""
	return int(fame * 0.1)  # 0.1 monedas por día por cada punto de fama

func spend_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		money_updated.emit(money)
		print("GameManager: Dinero gastado - ", amount, ". Dinero restante: ", money)
		return true
	else:
		print("GameManager: No hay suficiente dinero para gastar ", amount)
		return false

func can_afford(amount: int) -> bool:
	return money >= amount

func get_inventory() -> Dictionary:
	return inventory

func add_item_to_inventory(item_id: String, quantity: int):
	if inventory.has(item_id):
		inventory[item_id] += quantity
	else:
		inventory[item_id] = quantity
	
	inventory_updated.emit()
	print("GameManager: Inventario actualizado - ", inventory)

# Sistema de cheats
# Variable para controlar si se saltan las transiciones
var skip_transitions_enabled = false

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		# Cheat: Tecla R - Saltar al día siguiente con entrenamiento completado
		if event.keycode == KEY_R:
			activate_day_skip_cheat()
		# Cheat: Numpad2 - Saltar a jornada 2 (Patrulla Canina) con jornada 1 completada
		elif event.keycode == KEY_KP_2:
			activate_skip_to_patrulla_canina_cheat()
		# Cheat: Tecla G - Toggle skip transiciones y animaciones
		elif event.keycode == KEY_G:
			activate_skip_transitions_cheat()

func activate_day_skip_cheat():
	print("🎮 CHEAT ACTIVADO: Completando entrenamiento y avanzando día")
	
	# Completar entrenamiento si existe TrainingManager
	if TrainingManager:
		TrainingManager.complete_training()
		print("✅ Entrenamiento completado")
	
	# Avanzar al día siguiente
	if DayManager:
		DayManager.advance_day_with_origin("training")
		print("📅 Día avanzado a: ", DayManager.get_current_day())
	else:
		print("❌ Error: DayManager no disponible")

func activate_skip_to_patrulla_canina_cheat():
	print("🎮 CHEAT NUMPAD2: Saltando a jornada 2 (Patrulla Canina) con jornada 1 completada")
	
	# 1. SIMULAR RESULTADO DEL PARTIDO JORNADA 1 (FC Bufas 1-0 Deportivo Magadios)
	print("⚽ Simulando partido: FC Bufas 1-0 Deportivo Magadios")
	if LeagueManager:
		# Completar el partido de la jornada 1 con victoria 1-0
		LeagueManager.complete_match(1, 0)
		print("✅ Partido jornada 1 completado en LeagueManager")
	
	# 1.5. SIMULAR PARTIDOS EN TODAS LAS LIGAS (LeaguesManager)
	if LeaguesManager:
		print("🏆 Simulando partidos de las 3 divisiones (LeaguesManager)...")
		# Simular resultado del partido del jugador para activar la simulación automática
		var player_match_result = {
			"home_goals": 1,
			"away_goals": 0,
			"is_home": true,
			"opponent": "Deportivo Magadios"
		}
		LeaguesManager._on_player_match_completed(player_match_result)
		print("✅ Partidos de las 3 divisiones simulados")
	
	# 2. ACTUALIZAR ESTADÍSTICAS DEL EQUIPO
	team_stats.wins += 1
	team_stats.goals_for += 1
	team_stats.goals_against += 0
	print("📈 Estadísticas actualizadas: ", team_stats)
	
	# 3. AGREGAR FAMA Y DINERO POR LA VICTORIA
	process_match_fame_changes(1, 0, "win")
	print("🎆 Fama y dinero por victoria añadidos")
	
	# 4. MARCAR ENTRENAMIENTO DE JORNADA 1 COMO COMPLETADO
	if TrainingManager:
		# Establecer el oponente de jornada 1 y marcar como completado
		TrainingManager.set_current_opponent("Deportivo Magadios", 1)
		TrainingManager.complete_training()
		print("✅ Entrenamiento jornada 1 marcado como completado")
	
	# 5. AVANZAR AL DÍA 3
	if DayManager:
		DayManager.current_day = 3
		print("📅 Día avanzado directamente a: ", DayManager.get_current_day())
	
	# 6. CONFIGURAR PATRULLA CANINA COMO RIVAL ACTUAL
	if RivalTeamsManager:
		RivalTeamsManager.set_current_rival("patrulla_canina")
		print("🐶 Rival establecido: Patrulla Canina")
	
	# 7. RESETEAR ESTADO DE ENTRENAMIENTO PARA NUEVA JORNADA
	if TrainingManager:
		# Ahora establecer Patrulla Canina como nuevo oponente (jornada 2) sin entrenamiento completado
		TrainingManager.set_current_opponent("Patrulla Canina", 2)
		print("🎯 Nuevo entrenamiento configurado: vs Patrulla Canina (Jornada 2)")
	
	# 8. GUARDAR PROGRESO
	auto_save()
	print("💾 Progreso guardado")
	
	# 9. IR AL MENÚ INTERACTIVO PARA PODER ENTRENAR
	print("🌅 Transicionando al menú interactivo - Listo para entrenar vs Patrulla Canina")
	get_tree().change_scene_to_file("res://scenes/InteractiveMenu.tscn")

func activate_skip_transitions_cheat():
	skip_transitions_enabled = !skip_transitions_enabled
	print("🎮 CHEAT TECLA G: Skip transiciones y animaciones ", "ACTIVADO" if skip_transitions_enabled else "DESACTIVADO")

func is_skip_transitions_enabled() -> bool:
	return skip_transitions_enabled
