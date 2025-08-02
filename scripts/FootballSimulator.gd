extends Control

# --- Simulador de Fútbol Estilo Novela Visual ---

@onready var score_label = $UIPanel/ScoreLabel
@onready var time_label = $UIPanel/TimeLabel
@onready var event_panel = $EventPanel
@onready var event_description = $EventPanel/EventDescription
@onready var event_choices_container = $EventPanel/EventChoices
@onready var player_image = $EventPanel/PlayerImage
@onready var feedback_panel = $FeedbackPanel
@onready var feedback_label = $FeedbackPanel/FeedbackLabel

# --- Estados del Juego ---
var score_blue = 0
var score_red = 0
var current_event_index = 0
var total_events = 10
var match_events = []

# --- Variables para eventos dinámicos ---
var dynamic_events = []
var played_players = []  # Jugadores que participaron en el partido dinámico

# --- Variables para debugging y eventos encadenados ---
var force_next_position = ""  # Para forzar la siguiente posición después de un éxito
var debug_enabled = true
var is_dynamic_match = false  # Variable para controlar si es un partido dinámico

# --- Configuración de colores para bordes ---
var attack_color = Color(0, 1, 0, 1)  # Verde brillante y opaco
var defense_color = Color(1, 0, 0, 1)  # Rojo brillante y opaco
var neutral_color = Color(1, 1, 1, 1)  # Blanco brillante

func _ready():
	# CONFIGURACIÓN AUTOMÁTICA PARA TESTING
	GameManager.set_story_flag("match_type", "dynamic")
	GameManager.set_story_flag("rival_team", "Deportivo Magadios")
	
	# LIMPIAR ALINEACIÓN ANTERIOR Y CARGAR DESDE ARCHIVO
	print("=== INICIALIZANDO ALINEACIÓN ===")
	if LineupManager:
		LineupManager.clear_lineup()
		print("Alineación anterior limpiada")
		
		# CARGAR ALINEACIÓN DESDE ARCHIVO
		load_lineup_from_file()
		
		# VERIFICAR ALINEACIÓN CARGADA
		var saved_lineup = LineupManager.get_saved_lineup()
		if saved_lineup and saved_lineup.players:
			print("=== ALINEACIÓN CARGADA EXITOSAMENTE ===")
			print("Formación: ", saved_lineup.formation)
			print("Jugadores en alineación: ", saved_lineup.players.size())
			for key in saved_lineup.players.keys():
				var player = saved_lineup.players[key]
				if player:
					print("  " + key + ": " + player.name + " (" + player.get("position", "Sin posición") + ")")
				else:
					print("  " + key + ": [VACÍO]")
			print("=========================================")
		else:
			print("ADVERTENCIA: No se pudo cargar alineación. Usará eventos estáticos.")
	else:
		print("ERROR: LineupManager no disponible")
	
	
	# Detectar tipo de partido
	var match_type = GameManager.get_story_flag("match_type", "3v3")
	var rival_team = GameManager.get_story_flag("rival_team", "equipo desconocido")
	
	if match_type == "7v7":
		print("=== SIMULACIÓN 7v7 - FC BUFAS ===")
		print("¡Partido clandestino! Tu equipo: Yazawa, Pablo, Perma, Javo, Fan + 2 más")
		total_events = 12  # Partidos 7v7 son más largos
	else:
		print("=== SIMULACIÓN 3v3 DEBUG ===")
		print("Enfrentando a: ", rival_team)
		total_events = 10
	
	print("Modo debug activado")
	
	setup_events()
	start_match()

func _process(delta):
	# Actualizar el tiempo es lo único que hacemos en _process
	var time_display = (current_event_index * 9) # Simula 9 minutos por evento
	time_label.text = "Minuto: %d" % time_display

# --- Lógica del Partido ---

func start_match():
	score_blue = 0
	score_red = 0
	current_event_index = 0
	played_players.clear()  # Limpiar lista de jugadores que participaron
	feedback_panel.visible = false
	_next_event()

func _next_event():
	if current_event_index >= total_events:
		end_match()
		return
	
	# GENERAR EVENTO DINÁMICAMENTE PARA PARTIDOS DINÁMICOS
	var current_event
	if is_dynamic_match:
		# Generar evento dinámico en tiempo real
		var position = choose_event_based_on_probability()
		var event_template = find_event_for_position(position)
		
		if not event_template:
			print("ERROR: No se encontró evento para posición: " + position)
			_next_event()  # Intentar con otro evento
			return
		
		current_event = create_processed_event(event_template)
		
		if not current_event:
			print("ERROR: No se pudo crear evento procesado")
			_next_event()  # Intentar con otro evento
			return
		
		if debug_enabled:
			print("=== EVENTO DINÁMICO GENERADO ===")
			print("Posición: " + position)
			print("Evento: " + current_event.text)
			print("================================")
	else:
		# Para partidos estáticos, usar la lista pre-generada
		if match_events.size() == 0:
			print("ERROR CRITICO: No hay eventos generados. Usando eventos estáticos como fallback")
			match_events = get_3v3_events()
			if match_events.size() == 0:
				print("ERROR CRITICO: Tampoco se pudieron cargar eventos estáticos")
				return
		
		if current_event_index >= match_events.size():
			print("ERROR: Índice fuera de rango. Eventos disponibles: ", match_events.size(), ", Índice actual: ", current_event_index)
			end_match()
			return
		
		current_event = match_events[current_event_index]
	
	# Determinar tipo de evento y establecer color del borde
	var event_type = get_event_type(current_event)
	var border_color = get_border_color(event_type)
	
	# Mostrar panel de evento
	event_panel.visible = true
	feedback_panel.visible = false
	event_description.text = current_event.text
	
	# Actualizar imagen del jugador si es un evento dinámico
	update_player_image(current_event)
	
	# Aplicar color del borde al panel de eventos
	if event_panel.has_method("add_theme_stylebox_override"):
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.1, 0.1, 0.1, 0.95)  # Fondo más oscuro para contraste
		# Bordes mucho más gruesos y visibles
		style_box.border_width_left = 8
		style_box.border_width_right = 8
		style_box.border_width_top = 8
		style_box.border_width_bottom = 8
		style_box.border_color = border_color
		# Esquinas más redondeadas para mejor apariencia
		style_box.corner_radius_top_left = 12
		style_box.corner_radius_top_right = 12
		style_box.corner_radius_bottom_left = 12
		style_box.corner_radius_bottom_right = 12
		# Añadir sombra interior para más efecto visual
		style_box.shadow_color = border_color
		style_box.shadow_size = 2
		event_panel.add_theme_stylebox_override("panel", style_box)
	
	# Limpiar y crear botones de elección
	for child in event_choices_container.get_children():
		child.queue_free()

	for choice in current_event.choices:
		var button = Button.new()
		button.text = choice.text
		button.pressed.connect(func(): _on_choice_selected(choice))
		event_choices_container.add_child(button)
	
	current_event_index += 1

func _on_choice_selected(choice):
	event_panel.visible = false
	var result_text = resolve_action(choice)
	
	# Mostrar feedback y esperar
	feedback_label.text = result_text
	feedback_panel.visible = true
	
	var feedback_timer = get_tree().create_timer(3.0) # Mostrar feedback por 3 segundos
	await feedback_timer.timeout
	
	_next_event()

func resolve_action(choice) -> String:
	# Calcular probabilidad según el tipo de evento
	var success_chance = 50  # Valor por defecto
	if choice.has("player") and choice.has("substat"):
		# Eventos dinámicos: usar substats
		success_chance = calculate_success_probability(choice)
	else:
		# Eventos tradicionales: usar dificultad
		success_chance = 100 - choice.get("difficulty", 50)
	
	# Debug info
	if debug_enabled:
		print("======= EVENTO ACTUAL =======")
		print("Resolving action: '" + choice.text + "'")
		if choice.has("player"):
			print("Jugador: " + choice.player.name)
		if choice.has("substat"):
			print("Substat utilizado: " + choice.substat)
		print("Probabilidad de éxito: " + str(success_chance) + "%")
		if force_next_position != "":
			print("FORZANDO próximo evento a: " + force_next_position)
	
	var roll = randi_range(1, 100)
	var success = roll <= success_chance
	
	if debug_enabled:
		print("Tirada: " + str(roll) + " vs " + str(success_chance))
		print("Resultado: " + ("ÉXITO" if success else "FALLO"))
	
	# APLICAR LÓGICA DE ENCADENAMIENTO
	# Determinar la posición actual del evento
	var current_position = ""
	if choice.has("player"):
		current_position = choice.player.get("position", "")
	
	# Lógica de encadenamiento
	if success and current_position == "Mediocentro":
		# Si un Mediocentro ACIERTA -> siguiente evento 100% Delantero
		force_next_position = "Delantero"
		if debug_enabled:
			print("=== ENCADENAMIENTO ACTIVADO ===")
			print("Mediocentro acertó -> Próximo evento será 100% Delantero")
			print("Acción exitosa: " + choice.action)
			print("==============================")
	elif not success and current_position == "Defensa":
		# Si un Defensa FALLA -> siguiente evento 100% Portero
		force_next_position = "Portero"
		if debug_enabled:
			print("=== ENCADENAMIENTO ACTIVADO ===")
			print("Defensa falló -> Próximo evento será 100% Portero")
			print("==============================")
	
	var feedback = ""

	if success:
		feedback = choice.success_text
		match choice.action:
			"score_goal": 
				score_blue += 1
				if debug_enabled:
					print("¡GOL MARCADO! Yazawa's Team: " + str(score_blue))
			"concede_goal": 
				# Éxito en concede_goal significa que se EVITA el gol
				if debug_enabled:
					print("¡GOL DEL RIVAL EVITADO! Buena defensa.")
	else:
		feedback = choice.fail_text
		# Casos específicos donde el rival marca al fallar
		match choice.action:
			"concede_goal":
				score_red += 1
				if debug_enabled:
					print("¡GOL DEL RIVAL! Equipo Rival: " + str(score_red))
			"block_shot":
				if "marca a placer" in choice.fail_text or "marca con comodidad" in choice.fail_text or "marca desde los once metros" in choice.fail_text:
					score_red += 1
					if debug_enabled:
						print("¡GOL DEL RIVAL por fallo en bloqueo! Equipo Rival: " + str(score_red))
			"tackle":
				if "marca con comodidad" in choice.fail_text or "marca desde los once metros" in choice.fail_text:
					score_red += 1
					if debug_enabled:
						print("¡GOL DEL RIVAL por fallo en tackle! Equipo Rival: " + str(score_red))
			"contain":
				if "marca" in choice.fail_text:
					score_red += 1
					if debug_enabled:
						print("¡GOL DEL RIVAL por fallo en contención! Equipo Rival: " + str(score_red))
			"pass_short":
				if "marca el rebote" in choice.fail_text:
					score_red += 1
					if debug_enabled:
						print("¡GOL DEL RIVAL en rebote! Equipo Rival: " + str(score_red))
				elif not is_dynamic_match and randi_range(1, 100) < 25:
					feedback += "\n¡El rival roba el balón y marca en un contraataque!"
					score_red += 1
					if debug_enabled:
						print("¡GOL DEL RIVAL en contraataque! Equipo Rival: " + str(score_red))

	score_label.text = "Yazawa's Team %d - %d Equipo Rival" % [score_blue, score_red]
	
	if debug_enabled:
		print("Marcador actual: Yazawa " + str(score_blue) + " - " + str(score_red) + " Rival")
		print("==============================")
	
	return feedback

func calculate_success_probability(choice) -> int:
	# Verificar si tiene substat y jugador
	if not choice.has("substat") or not choice.has("player"):
		return 50

	# Obtener el valor del substat
	var player = choice.player
	var substat_value = player.get(choice.substat, 50)
	
	# Obtener la moral actual del jugador
	var current_morale = player.get("current_morale", 5)
	
	# Calcular modificador de moral
	# Moral 5 = 0 modificador, cada punto arriba/abajo de 5 da +1/-1
	var morale_modifier = current_morale - 5
	
	# Aplicar modificador de moral al substat
	var modified_substat = substat_value + morale_modifier

	# Calcular probabilidad: substat modificado - 15
	var probability = modified_substat - 15

	# Asegurar la probabilidad está en el rango 5% a 95%
	probability = max(5, min(95, probability))

	if debug_enabled:
		print("=== Probabilidad de Éxito ===")
		print("Jugador: " + player.name)
		print("Substat: " + choice.substat)
		print("Valor base del Substat: " + str(substat_value))
		print("Moral actual: " + str(current_morale))
		print("Modificador de moral: " + str(morale_modifier))
		print("Substat con moral: " + str(modified_substat))
		print("Probabilidad final: " + str(probability) + "%")
		print("============================")

	return probability

func load_dynamic_events():
	dynamic_events = [
		# EVENTO PORTERO
		{
			"position": "Portero",
			"text": "¡Tiro sorpresivo desde fuera del área! %s tiene que reaccionar rápidamente.",
			"choices": [
				{
					"text": "Estirarse al máximo para desviar con la mano",
					"substat": "reflexes",
					"action": "concede_goal",
					"success_text": "%s realiza una parada espectacular desviando el balón con la punta de los dedos.",
					"fail_text": "%s se estira pero no llega al balón."
				},
				{
					"text": "Anticipar el rebote y posicionarse",
					"substat": "positioning",
					"action": "concede_goal",
					"success_text": "%s se posiciona bien y captura el rebote.",
					"fail_text": "%s se posiciona mal y el rebote es aprovechado por el rival."
				},
				{
					"text": "Gritar para agrupar a la defensa",
					"substat": "concentration",
					"action": "concede_goal",
					"success_text": "%s organiza la defensa que bloquea el disparo.",
					"fail_text": "%s grita pero la defensa no reacciona a tiempo."
				}
			]
		},
		# EVENTO DEFENSA
		{
			"position": "Defensa",
			"text": "¡El delantero rival avanza con peligro! %s debe actuar.",
			"choices": [
				{
					"text": "Marcar estrechamente al atacante",
					"substat": "marking",
					"action": "defend",
					"success_text": "%s marca perfectamente y el atacante no puede avanzar.",
					"fail_text": "%s pierde el marcaje y el atacante se escapa."
				},
				{
					"text": "Hacer una entrada para robar el balón",
					"substat": "tackling",
					"action": "defend",
					"success_text": "%s realiza un tackle limpio y recupera el balón.",
					"fail_text": "%s falla el tackle y comete falta."
				},
				{
					"text": "Posicionarse para cerrar espacios",
					"substat": "positioning",
					"action": "defend",
					"success_text": "%s se posiciona bien y cierra todos los espacios.",
					"fail_text": "%s se posiciona mal y deja huecos peligrosos."
				}
			]
		},
		# EVENTO MEDIOCENTRO (corrigiendo el nombre)
		{
			"position": "Mediocentro",
			"text": "¡%s recibe el balón en el centro del campo con tiempo para decidir!",
			"choices": [
				{
					"text": "Pase corto al compañero más cercano",
					"substat": "short_pass",
					"action": "pass_short",
					"success_text": "%s hace un pase corto preciso que mantiene la posesión.",
					"fail_text": "%s falla el pase corto y lo intercepta el rival."
				},
				{
					"text": "Pase largo al delantero",
					"substat": "long_pass",
					"action": "pass_long",
					"success_text": "%s ejecuta un pase largo perfecto al delantero.",
					"fail_text": "%s envía el pase largo fuera del alcance del delantero."
				},
				{
					"text": "Regatear y avanzar con el balón",
					"substat": "dribbling",
					"action": "dribble",
					"success_text": "%s supera a dos rivales con un regate espectacular.",
					"fail_text": "%s pierde el balón al intentar el regate."
				}
			]
		},
		# EVENTO DELANTERO
		{
			"position": "Delantero",
			"text": "¡Oportunidad de gol! %s está solo en el área rival.",
			"choices": [
				{
					"text": "Disparo potente al arco",
					"substat": "shooting",
					"action": "score_goal",
					"success_text": "%s dispara con potencia y anota un golazo.",
					"fail_text": "%s dispara fuerte pero el balón se va por encima del arco."
				},
				{
					"text": "Remate de cabeza",
					"substat": "heading",
					"action": "score_goal",
					"success_text": "%s cabecea perfectamente y marca de cabeza.",
					"fail_text": "%s falla el cabezazo y el balón se va fuera."
				},
				{
					"text": "Amagar y buscar mejor ángulo",
					"substat": "dribbling",
					"action": "dribble_shot",
					"success_text": "%s engaña al portero con una amague y marca.",
					"fail_text": "%s demora demasiado y un defensa le quita el balón."
				}
			]
		}
	]
	
func setup_match_events():
	match_events.clear()
	played_players.clear()  # Asegurar que esté limpio
	# NO GENERAR TODOS LOS EVENTOS AL INICIO
	# Los eventos se generarán dinámicamente durante el partido
	
	if debug_enabled:
		print("=== SISTEMA DINÁMICO ACTIVADO ===")
		print("Los eventos se generarán durante el partido con encadenamiento")
		print("======================================")

func choose_event_based_on_probability():
	# Si hay una posición forzada, usarla
	if force_next_position != "":
		var forced_position = force_next_position
		force_next_position = ""  # Resetear después de usar
		if debug_enabled:
			print("Usando evento FORZADO: " + forced_position)
		return forced_position
	
	# Si no, usar probabilidades normales
	# 10% Portero, 40% Defensa, 40% Mediocentro, 10% Delantero
	var roll = randi_range(1, 100)
	if debug_enabled:
		print("Evento aleatorio - tirada: " + str(roll))
	
	if roll <= 10:
		if debug_enabled:
			print("Selección: Portero (1-10)")
		return "Portero"
	elif roll <= 50:  # 10 + 40 = 50
		if debug_enabled:
			print("Selección: Defensa (11-50)")
		return "Defensa"
	elif roll <= 90:  # 50 + 40 = 90
		if debug_enabled:
			print("Selección: Mediocentro (51-90)")
		return "Mediocentro"
	else:  # 91-100 (10%)
		if debug_enabled:
			print("Selección: Delantero (91-100)")
		return "Delantero"

func create_processed_event(event):
	var selected_player = get_random_player_by_position(event.position)
	if not selected_player:
		if debug_enabled:
			print("ERROR: No se pudo seleccionar jugador para posición " + event.position)
		return null

	if debug_enabled:
		print("=== CREANDO EVENTO PROCESADO ===")
		print("Posición del evento: " + event.position)
		print("Jugador seleccionado: " + selected_player.name)
		print("Texto del evento: " + (event.text % selected_player.name))

	var processed_event = {
		"text": event.text % selected_player.name,
		"choices": [],
		"event_position": event.position  # Añadir para debug
	}

	# Registrar que este jugador participó en el partido
	if selected_player.id not in played_players:
		played_players.append(selected_player.id)
		if debug_enabled:
			print("Jugador añadido a la lista de participantes: ", selected_player.name, " (ID: ", selected_player.id, ")")

	for choice in event.choices:
		var processed_choice = {
			"text": choice.text,
			"action": choice.action,
			"substat": choice.substat,
			"player": selected_player,
			"success_text": choice.success_text % selected_player.name,
			"fail_text": choice.fail_text % selected_player.name
		}
		processed_event.choices.append(processed_choice)
	
	if debug_enabled:
		print("=== EVENTO PROCESADO CREADO ===")
	
	return processed_event

func find_event_for_position(position: String):
	for event in dynamic_events:
		if event.position == position:
			return event
	return null

func get_random_player_by_position(position: String):
	if not LineupManager:
		if debug_enabled:
			print("ERROR: LineupManager no disponible")
		return null
	
	var saved_lineup = LineupManager.get_saved_lineup()
	if not saved_lineup:
		if debug_enabled:
			print("ERROR: No hay alineación guardada")
		return null
	
	# DEBUG EXTRA: Mostrar toda la información del lineup
	if debug_enabled:
		print("=== DEBUG DETALLADO LINEUP ===")
		print("Formación guardada: ", saved_lineup.formation)
		print("Jugadores guardados:")
		for key in saved_lineup.players.keys():
			var player = saved_lineup.players[key]
			if player:
				print("  " + key + ": " + player.name + " (" + player.get("position", "Sin posición") + ")")
			else:
				print("  " + key + ": [NULL]")
		print("================================")
	
	var lineup_data = saved_lineup.players
	var formation = saved_lineup.formation  # Usar la formación real guardada
	if not lineup_data:
		if debug_enabled:
			print("ERROR: No hay datos de jugadores en la alineación")
		return null
	
	if debug_enabled:
		print("=== BÚSQUEDA DE JUGADOR ===")
		print("Formación detectada: " + str(formation))
		print("Buscando jugador para posición: " + position)
		print("Jugadores disponibles en alineación: " + str(lineup_data.size()))
	
	# Buscar jugadores por posición real - ahora recorremos todos los jugadores guardados
	var available_players = []
	for key in lineup_data.keys():
		var player = lineup_data[key]
		if player != null and player.has("position") and player.position == position:
			available_players.append(player)
	
	if available_players.size() > 0:
		var selected_player = available_players[randi() % available_players.size()]
		if debug_enabled:
			print("Jugadores disponibles para " + position + ": " + str(available_players.size()))
			var player_names = []
			for p in available_players:
				player_names.append(p.name)
			print("Lista de jugadores: " + str(player_names))
			print(position + " seleccionado: " + selected_player.name)
		return selected_player
	else:
		if debug_enabled:
			print("ERROR: No hay jugadores disponibles en la alineación para la posición " + position)
			# Mostrar todos los jugadores disponibles para debug
			print("Jugadores en la alineación:")
			for key in lineup_data.keys():
				var player = lineup_data[key]
				if player != null:
					var player_pos = player.get("position", "Sin posición")
					print("  " + player.name + " - Posición: " + str(player_pos))
		return null
	
	if debug_enabled:
		print("=== FIN BÚSQUEDA ===")
	return null

func get_player_position(player) -> String:
	# Función para determinar la posición de un jugador basándose en la alineación
	if not LineupManager:
		return ""
	
	var saved_lineup = LineupManager.get_saved_lineup()
	if not saved_lineup or not saved_lineup.players:
		return ""
	
	var lineup_data = saved_lineup.players
	
	# Buscar en qué posición está el jugador
	for position_key in lineup_data.keys():
		var position_player = lineup_data[position_key]
		if position_player and position_player.name == player.name:
			if position_key.begins_with("GK"):
				return "Portero"
			elif position_key.begins_with("DEF"):
				return "Defensa"
			elif position_key.begins_with("MID"):
				return "Centrocampista"
			elif position_key.begins_with("ATT"):
				return "Delantero"
	
	return ""

func end_match():
	event_panel.visible = false
	feedback_panel.visible = true
	
	var result_text = "¡Final del partido!\nResultado: Yazawa's Team %d - %d Equipo Rival" % [score_blue, score_red]
	var match_result = ""
	
	if score_blue > score_red:
		result_text += "\n\n¡VICTORIA!"
		match_result = "win"
	elif score_red > score_blue:
		result_text += "\n\nDerrota."
		match_result = "loss"
	else:
		result_text += "\n\nEmpate."
		match_result = "draw"  # Puedes decidir si el empate va por la ruta de victoria o derrota
	
	feedback_label.text = result_text
	
	# Registrar el resultado en el GameManager
	GameManager.add_match_result(score_blue, score_red)
	
	# La moral se actualizará en BranchingDialogue.gd junto con la stamina
	if debug_enabled:
		print("=== RESULTADO FINAL ===")
		print("Marcador final: Yazawa ", score_blue, " - ", score_red, " Rival")
		print("La moral se actualizará en el diálogo post-partido")
		print("=========================")
	
	# Preparar la transición al diálogo post-partido después de 3 segundos
	var transition_timer = get_tree().create_timer(3.0)
	await transition_timer.timeout
	
	# Decidir qué ruta de diálogo usar según el tipo de partido
	var match_type = GameManager.get_story_flag("match_type", "3v3")
	var dialogue_branch = ""
	
	if match_type == "7v7":
		# Para partidos 7v7, usar las ramas específicas
		if match_result == "win":
			dialogue_branch = "win_7v7"
		else:
			# Para derrotas y empates en 7v7, usar la rama de derrota 7v7
			dialogue_branch = "loss_7v7"
	elif match_type == "dynamic":
		# Para partidos dinámicos, usar las ramas estándar
		dialogue_branch = match_result if match_result != "draw" else "loss"
	else:
		# Para partidos 3v3, usar las ramas originales
		dialogue_branch = match_result if match_result != "draw" else "loss"
	
	GameManager.set_story_flag("post_match_branch", dialogue_branch)
	
	# Cargar la escena de diálogo branching
	GameManager.change_scene("res://scenes/BranchingDialogue.tscn")

# --- Base de datos de eventos ---

# --- Funciones para determinar tipo de evento y color ---

func get_event_type(event) -> String:
	# Analizar el texto del evento para determinar si es ataque, defensa o neutral
	var event_text = event.text.to_lower()
	
	# Palabras clave para eventos defensivos (en contra)
	var defense_keywords = ["rival", "delantero rival", "pase filtrado del rival", 
						   "defiendes", "su delantero", "gol del rival", "te encara", "córner en contra",
						   "tiro libre peligroso", "se planta solo en tu área", "saque de banda rival",
						   "mediocampista rival", "centro peligroso", "situación crítica"]
	
	# Palabras clave para eventos de ataque (a favor)
	var attack_keywords = ["yazawa avanza", "oportunidad de gol", "solo frente al portero", 
						  "llegas a línea", "córner a favor", "contraataque", "yazawa recibe",
						  "tiro libre a favor", "yazawa está en el área", "saque de banda en campo rival",
						  "yazawa se encuentra", "contraataque rápido", "penalti a favor",
						  "última jugada", "falta a favor", "mano del rival", "rebota en el travesaño"]
	
	for keyword in defense_keywords:
		if event_text.find(keyword) != -1:
			return "defense"
	
	for keyword in attack_keywords:
		if event_text.find(keyword) != -1:
			return "attack"
	
	return "neutral"

func get_border_color(event_type: String) -> Color:
	match event_type:
		"attack":
			return attack_color
		"defense":
			return defense_color
		_:
			return neutral_color

func setup_events():
	var all_events = []
# Cargar eventos según el tipo de partido
	var match_type = GameManager.get_story_flag("match_type", "3v3")
	if match_type == "7v7":
		is_dynamic_match = false
		all_events = get_7v7_events()
	elif match_type == "dynamic":
		is_dynamic_match = true
		load_dynamic_events()
		setup_match_events()
		return
	else:
		is_dynamic_match = false
		all_events = get_3v3_events()

	match_events.clear()
	for i in range(total_events):
		match_events.append(all_events[randi() % all_events.size()])

func get_3v3_events():
	return [
		# --- EVENTOS DE ATAQUE ---
		{
			"text": "Yazawa avanza por el centro. ¿Qué debería hacer?",
			"choices": [
				{"text": "Buscar un pase filtrado para tu delantero", "action": "pass_long", "difficulty": 40, 
				 "success_text": "¡Gran pase de Yazawa! Dejas a tu delantero solo contra el portero.", "fail_text": "El pase es demasiado fuerte y el portero lo atrapa."},
				{"text": "Intentar un regate para superar al defensa", "action": "dribble", "difficulty": 60, 
				 "success_text": "¡Yazawa se va por velocidad y se planta en el área!", "fail_text": "El defensa le roba el balón limpiamente."}
			]
		},
		{
			"text": "¡Oportunidad de gol! Estás solo frente al portero. ¿Cómo defines?",
			"choices": [
				{"text": "Disparo potente al centro", "action": "score_goal", "difficulty": 30, 
				 "success_text": "¡GOOOOL! ¡El portero no puede hacer nada!", "fail_text": "¡El portero adivina tu intención y para el disparo!"},
				{"text": "Vaselina suave por encima del portero", "action": "score_goal", "difficulty": 55, 
				 "success_text": "¡GOOOOLAZO! ¡Qué clase! La picas por encima del portero.", "fail_text": "El portero aguanta y atrapa el balón fácilmente."}
			]
		},
		{
			"text": "Llegas a línea de fondo. ¿Qué haces?",
			"choices": [
				{"text": "Centro al primer palo", "action": "pass_long", "difficulty": 45,
				"success_text": "¡Buen centro! Tu compañero remata, pero el portero la saca a córner.", "fail_text": "El centro es malo y se va por la línea de fondo."},
				{"text": "Recortar y buscar el disparo", "action": "dribble_shoot", "difficulty": 65,
				"success_text": "¡Recorte fantástico y disparo que se va rozando el palo!", "fail_text": "El defensa adivina tu intención y te roba el balón."}
			]
		},
		{
			"text": "Yazawa recibe un pase en el área chica. ¡Momento decisivo!",
			"choices": [
				{"text": "Disparo de primera intención", "action": "score_goal", "difficulty": 25,
				"success_text": "¡GOLAZO! ¡Disparo perfecto al ángulo superior!", "fail_text": "¡El disparo sale desviado por poco!"},
				{"text": "Controlar y buscar mejor ángulo", "action": "score_goal", "difficulty": 45,
				"success_text": "¡Control perfecto y definición magistral!", "fail_text": "Un defensa aparece de la nada y bloquea el disparo."}
			]
		},
		{
			"text": "¡Tiro libre a favor desde 25 metros! Gran oportunidad para Yazawa.",
			"choices": [
				{"text": "Disparo directo buscando la escuadra", "action": "score_goal", "difficulty": 70,
				"success_text": "¡GOOOLAZO OLÍMPICO! ¡El balón se clava en el ángulo!", "fail_text": "El balón se estrella contra la barrera."},
				{"text": "Centro al área buscando a un compañero", "action": "pass_long", "difficulty": 35,
				"success_text": "¡Gran centro! Tu compañero cabecea, pero el portero hace una gran parada.", "fail_text": "El centro es muy débil y el portero lo atrapa sin problemas."}
			]
		},
		{
			"text": "Yazawa está en el área rival con el balón controlado. ¡Hay que definir!",
			"choices": [
				{"text": "Disparo cruzado al palo largo", "action": "score_goal", "difficulty": 35,
				"success_text": "¡GOOOL! ¡Disparo perfecto que se cuela por el palo largo!", "fail_text": "El portero se estira y desvía el balón a córner."},
				{"text": "Amagar el disparo y buscar el pase", "action": "pass_short", "difficulty": 50,
				"success_text": "¡Jugada genial! Dejas al compañero solo para marcar.", "fail_text": "La defensa lee tu intención y corta el pase."}
			]
		},
		{
			"text": "¡Saque de banda en campo rival! Yazawa puede crear peligro.",
			"choices": [
				{"text": "Saque largo al área rival", "action": "pass_long", "difficulty": 55,
				"success_text": "¡Saque perfecto! Se arma una batalla en el área rival.", "fail_text": "El saque es demasiado largo y se va por la línea de fondo."},
				{"text": "Pase corto para mantener posesión", "action": "pass_short", "difficulty": 20,
				"success_text": "Mantienes la posesión y sigues presionando.", "fail_text": "El rival presiona y pierdes el balón inmediatamente."}
			]
		},
		{
			"text": "¡Yazawa se encuentra con el balón en la media luna! Posición de disparo.",
			"choices": [
				{"text": "Disparo potente de media distancia", "action": "score_goal", "difficulty": 60,
				"success_text": "¡GOLAZO! ¡El balón entra como un misil por la escuadra!", "fail_text": "Disparo potente pero el portero vuela y la saca con una mano."},
				{"text": "Buscar pase en profundidad", "action": "pass_long", "difficulty": 40,
				"success_text": "¡Pase perfecto! Tu delantero queda mano a mano.", "fail_text": "El pase es interceptado por la defensa rival."}
			]
		},
		{
			"text": "¡Contraataque rápido! Yazawa corre con el balón y dos compañeros lo apoyan.",
			"choices": [
				{"text": "Seguir avanzando en solitario", "action": "dribble", "difficulty": 50,
				"success_text": "¡Yazawa se va por velocidad y llega al área!", "fail_text": "Un defensa aparece y te quita el balón."},
				{"text": "Pase al compañero mejor posicionado", "action": "pass_short", "difficulty": 25,
				"success_text": "¡Pase perfecto! Tu compañero tiene una gran ocasión de gol.", "fail_text": "El pase llega un poco retrasado y se pierde la ocasión."}
			]
		},
		{
			"text": "¡Yazawa recibe un centro perfecto en el área! ¡Es tu momento!",
			"choices": [
				{"text": "Remate de cabeza al primer palo", "action": "score_goal", "difficulty": 40,
				"success_text": "¡GOOOOL! ¡Cabezazo imparable al primer palo!", "fail_text": "El cabezazo se va por encima del travesaño."},
				{"text": "Control de pecho y disparo", "action": "score_goal", "difficulty": 55,
				"success_text": "¡Control perfecto y disparo colocado que se cuela por la escuadra!", "fail_text": "El control no es bueno y pierdes la ocasión."}
			]
		},
		
		# --- EVENTOS DE MEDIOCAMPO ---
		{
			"text": "Recibes el balón en tu propio campo, sin presión. ¿Cómo inicias la jugada?",
			"choices": [
				{"text": "Pase corto y seguro a Marcos", "action": "pass_short", "difficulty": 10,
				"success_text": "Inicias la jugada con calma, manteniendo la posesión.", "fail_text": "Un pase sorprendentemente malo. Regalas el balón."},
				{"text": "Balonazo largo buscando al delantero", "action": "pass_long", "difficulty": 70,
				"success_text": "¡El balón vuela por los aires y tu delantero lo controla!", "fail_text": "El pase es impreciso y se pierde por la banda."}
			]
		},
		{
			"text": "Yazawa tiene el balón en el centro del campo. Los rivales presionan.",
			"choices": [
				{"text": "Regate para liberarse de la presión", "action": "dribble", "difficulty": 45,
				"success_text": "¡Gran regate! Te liberas de dos rivales y avanzas.", "fail_text": "El rival te anticipa y roba el balón."},
				{"text": "Pase rápido hacia la banda", "action": "pass_short", "difficulty": 30,
				"success_text": "Pase preciso hacia la banda, escapas de la presión.", "fail_text": "El pase es interceptado por un rival."}
			]
		},
		{
			"text": "El balón rebota en el centro del campo. ¡Yazawa y un rival corren hacia él!",
			"choices": [
				{"text": "Acelerar al máximo para llegar primero", "action": "dribble", "difficulty": 40,
				"success_text": "¡Llegas primero y recuperas la posesión!", "fail_text": "El rival llega antes y se lleva el balón."},
				{"text": "Entrada fuerte pero limpia", "action": "tackle", "difficulty": 60,
				"success_text": "¡Entrada perfecta! Ganas el balón limpiamente.", "fail_text": "Entrada demasiado fuerte. ¡Falta y tarjeta!"}
			]
		},
		{
			"text": "Yazawa intercepta un pase rival en el mediocampo. ¡Oportunidad!",
			"choices": [
				{"text": "Pase inmediato al ataque", "action": "pass_long", "difficulty": 45,
				"success_text": "¡Pase rápido que pilla descolocada a la defensa!", "fail_text": "El pase es impreciso y lo recupera el rival."},
				{"text": "Avanzar con el balón controlado", "action": "dribble", "difficulty": 35,
				"success_text": "Avanzas con calma y organizas el ataque.", "fail_text": "Un rival te presiona y pierdes el balón."}
			]
		},
		{
			"text": "¡Momento clave! Yazawa tiene el balón en 3/4 de campo. ¿Cómo asistes?",
			"choices": [
				{"text": "Pase al hueco para el delantero", "action": "pass_long", "difficulty": 50,
				"success_text": "¡Asistencia perfecta! Tu delantero queda solo ante el portero.", "fail_text": "El pase se va largo y el portero lo controla."},
				{"text": "Pared con el mediocampista", "action": "pass_short", "difficulty": 30,
				"success_text": "¡Pared perfecta! Sigues avanzando hacia el área.", "fail_text": "El pase de vuelta es malo y pierdes la posesión."}
			]
		},
		{
			"text": "Yazawa conduce el balón por la banda izquierda. Hay espacio para avanzar.",
			"choices": [
				{"text": "Continuar por la banda hacia línea de fondo", "action": "dribble", "difficulty": 40,
				"success_text": "¡Excelente avance! Llegas a posición de centro.", "fail_text": "El lateral rival te cierra el paso y te saca el balón."},
				{"text": "Cortar hacia el centro del campo", "action": "dribble", "difficulty": 55,
				"success_text": "¡Gran regate! Te plantas en posición de disparo.", "fail_text": "Un defensa central corta tu avance."}
			]
		},
		
		# --- EVENTOS DE DEFENSA ---
		{
			"text": "¡Pase filtrado del rival! Su delantero se queda solo contra tu portero.",
			"choices": [
				{"text": "¡Confiar en tu portero!", "action": "concede_goal", "difficulty": 40,
				"success_text": "¡PARADÓN! ¡Tu portero hace una parada increíble y evita el gol!", "fail_text": "¡Gol del rival! No pudo hacer nada para evitarlo."},
				{"text": "Marcos intenta un último esfuerzo para bloquear", "action": "block_shot", "difficulty": 75,
				"success_text": "¡Marcos se lanza y bloquea el disparo en el último segundo!", "fail_text": "Marcos no llega a tiempo y el rival marca a placer."}
			]
		},
		{
			"text": "El delantero rival te encara en la banda. ¿Cómo lo defiendes?",
			"choices": [
				{"text": "Hacer una entrada agresiva para robar el balón", "action": "tackle", "difficulty": 65,
				"success_text": "¡Entrada perfecta! Recuperas la posesión.", "fail_text": "Llegas tarde y cometes una falta peligrosa."},
				{"text": "Contenerlo y forzar el error", "action": "contain", "difficulty": 30,
				"success_text": "Aguantas bien la posición y el rival acaba perdiendo el balón.", "fail_text": "El rival te desborda con un regate y se mete en el área."}
			]
		},
		{
			"text": "¡Córner en contra! El balón viene directo hacia ti en el área.",
			"choices": [
				{"text": "Despejar de cabeza con fuerza", "action": "clear_ball", "difficulty": 25,
				"success_text": "¡Despeje perfecto! Alejas el peligro de tu área.", "fail_text": "El despeje sale flojo y el rival remata de nuevo."},
				{"text": "Intentar controlar el balón", "action": "pass_short", "difficulty": 60,
				"success_text": "¡Control perfecto! Inicias un contraataque.", "fail_text": "Fallas el control y un rival marca el rebote."}
			]
		},
		{
			"text": "¡El rival tiene un tiro libre peligroso desde el borde del área!",
			"choices": [
				{"text": "Formar barrera y confiar en el portero", "action": "concede_goal", "difficulty": 35,
				"success_text": "¡La barrera funciona! El balón pega en la pared humana.", "fail_text": "¡GOLAZO del rival! El balón se cuela por encima de la barrera."},
				{"text": "Salir a presionar al ejecutor", "action": "tackle", "difficulty": 70,
				"success_text": "¡Presión perfecta! El rival falla el tiro libre.", "fail_text": "Llegas tarde y el rival marca con comodidad."}
			]
		},
		{
			"text": "¡El delantero rival se planta solo en tu área! ¡Situación crítica!",
			"choices": [
				{"text": "Entrada desesperada para evitar el gol", "action": "tackle", "difficulty": 80,
				"success_text": "¡SALVADA HEROICA! Robas el balón en el último segundo.", "fail_text": "¡Penalti y tarjeta! El rival marca desde los once metros."},
				{"text": "Retroceder y cerrar el ángulo", "action": "contain", "difficulty": 45,
				"success_text": "Fuerzas al rival a un disparo difícil que sale desviado.", "fail_text": "El rival tiene tiempo para acomodarse y marca."}
			]
		},
		{
			"text": "¡Saque de banda rival cerca de tu área! Peligro inminente.",
			"choices": [
				{"text": "Marcar estrechamente al delantero rival", "action": "contain", "difficulty": 30,
				"success_text": "Marcaje perfecto. El rival no puede controlar el balón.", "fail_text": "El delantero rival se escapa del marcaje y crea peligro."},
				{"text": "Intentar interceptar el saque", "action": "tackle", "difficulty": 60,
				"success_text": "¡Interceptación perfecta! Recuperas la posesión.", "fail_text": "Fallas la interceptación y quedas fuera de posición."}
			]
		},
		{
			"text": "¡El mediocampista rival intenta un disparo lejano! ¿Cómo reaccionas?",
			"choices": [
				{"text": "Saltar para bloquear el disparo", "action": "block_shot", "difficulty": 50,
				"success_text": "¡Bloqueo perfecto! El balón pega en tu cuerpo.", "fail_text": "No llegas al balón y el portero debe hacer una parada difícil."},
				{"text": "Dejar que el portero se encargue", "action": "concede_goal", "difficulty": 25,
				"success_text": "¡Buena decisión! Tu portero atrapa el balón sin problemas.", "fail_text": "¡GOLAZO! Disparo imparable que se cuela por la escuadra."}
			]
		},
		{
			"text": "¡El delantero rival hace un centro peligroso! Hay que despejar.",
			"choices": [
				{"text": "Despeje de cabeza hacia la banda", "action": "clear_ball", "difficulty": 35,
				"success_text": "¡Despeje inteligente! El balón sale por la banda lejos del área.", "fail_text": "El despeje sale mal y cae a los pies de un rival."},
				{"text": "Intentar ganar el balón para contraatacar", "action": "pass_short", "difficulty": 65,
				"success_text": "¡Recuperación perfecta! Inicias un contraataque inmediato.", "fail_text": "Fallas al controlar y un rival marca de remate."}
			]
		},
		
		# --- EVENTOS DE CONTRAATAQUE ---
		{
			"text": "¡Robas el balón en tu campo! ¡Oportunidad de contraataque!",
			"choices": [
				{"text": "Pase largo inmediato al delantero", "action": "pass_long", "difficulty": 50,
				"success_text": "¡Pase milimétrico! Tu delantero corre solo hacia la portería.", "fail_text": "El pase es interceptado por un defensa rival."},
				{"text": "Avanzar con el balón para atraer a los defensas", "action": "dribble_advance", "difficulty": 40,
				"success_text": "Atraes a varios rivales y liberas espacio para tus compañeros.", "fail_text": "Un rival te cierra el paso y pierdes el balón."}
			]
		},
		{
			"text": "¡Contraataque letal! Yazawa corre con dos compañeros en superioridad 3 vs 2.",
			"choices": [
				{"text": "Continuar con el balón hasta el área", "action": "dribble", "difficulty": 40,
				"success_text": "¡Avance perfecto! Te plantas en el área con ventaja.", "fail_text": "Un defensa te hace una entrada y corta el contraataque."},
				{"text": "Pase al compañero mejor posicionado", "action": "pass_short", "difficulty": 25,
				"success_text": "¡Asistencia perfecta! Tu compañero define ante el portero.", "fail_text": "El pase llega mal y se pierde la oportunidad de oro."}
			]
		},
		{
			"text": "¡Recuperas el balón tras un rebote! El rival está desorganizado.",
			"choices": [
				{"text": "Acelerar hacia la portería rival", "action": "dribble", "difficulty": 45,
				"success_text": "¡Gran aceleración! Dejas atrás a varios rivales.", "fail_text": "Un defensa se recupera y te quita el balón."},
				{"text": "Buscar pase rápido al ataque", "action": "pass_long", "difficulty": 35,
				"success_text": "¡Pase perfecto! Aprovechas la desorganización rival.", "fail_text": "El pase es impreciso y lo intercepta la defensa."}
			]
		},
		
		# --- EVENTOS ESPECIALES ---
		{
			"text": "¡Córner a favor! ¿Cómo lo ejecutas?",
			"choices": [
				{"text": "Centro cerrado buscando el primer palo", "action": "score_goal", "difficulty": 75, 
				 "success_text": "¡GOOOL! ¡Remate de cabeza imparable!", "fail_text": "El portero rival sale y despeja el balón con los puños."},
				{"text": "Pase en corto para sorprender", "action": "pass_short", "difficulty": 35, 
				 "success_text": "La jugada ensayada sale bien y mantienes la posesión cerca del área.", "fail_text": "La defensa rival está atenta y corta el pase."}
			]
		},
		{
			"text": "¡PENALTI A FAVOR! Yazawa se coloca frente al punto de penalti.",
			"choices": [
				{"text": "Disparo potente al centro", "action": "score_goal", "difficulty": 20,
				"success_text": "¡GOOOOL! ¡Penalti perfecto al centro!", "fail_text": "¡El portero adivina y para el penalti!"},
				{"text": "Disparo colocado a la esquina", "action": "score_goal", "difficulty": 35,
				"success_text": "¡GOLAZO! ¡Penalti colocado imposible de parar!", "fail_text": "¡El portero vuela y hace una parada espectacular!"}
			]
		},
		{
			"text": "¡Última jugada del partido! Yazawa tiene el balón y el marcador está igualado.",
			"choices": [
				{"text": "Disparo desesperado desde lejos", "action": "score_goal", "difficulty": 75,
				"success_text": "¡GOLAZO DE LA VICTORIA! ¡Disparo increíble en el último segundo!", "fail_text": "El disparo se va por encima y se acaba el tiempo."},
				{"text": "Buscar pase para una mejor posición", "action": "pass_short", "difficulty": 45,
				"success_text": "¡Pase perfecto! Un compañero marca el gol de la victoria.", "fail_text": "El pase llega mal y se acaba el tiempo. ¡Empate!"}
			]
		},
		{
			"text": "¡El árbitro pita falta a favor en zona peligrosa! Posición inmejorable.",
			"choices": [
				{"text": "Tiro libre directo con efecto", "action": "score_goal", "difficulty": 65,
				"success_text": "¡GOLAZO OLÍMPICO! ¡El balón hace una parábola perfecta!", "fail_text": "El balón pasa rozando el travesaño."},
				{"text": "Pase raso al área pequeña", "action": "pass_short", "difficulty": 40,
				"success_text": "¡Jugada perfecta! Un compañero empuja el balón a gol.", "fail_text": "El portero sale bien y atrapa el balón."}
			]
		},
		{
			"text": "¡Mano del rival en el área! ¡PENALTI Y TARJETA ROJA!",
			"choices": [
				{"text": "Penalti colocado esperando al portero", "action": "score_goal", "difficulty": 25,
				"success_text": "¡GOOOOL! ¡Penalti perfecto! Esperas al portero y colocas al otro lado.", "fail_text": "¡Increíble! El portero se queda en el centro y para tu penalti."},
				{"text": "Disparo fuerte a media altura", "action": "score_goal", "difficulty": 30,
				"success_text": "¡GOLAZO! ¡Penalti imparable a media altura!", "fail_text": "El portero hace una parada espectacular con el pie."}
			]
		},
		{
			"text": "¡El balón rebota en el travesaño y cae en el área! ¡Todos van a por él!",
			"choices": [
				{"text": "Lanzarse al suelo para empujar el balón", "action": "score_goal", "difficulty": 50,
				"success_text": "¡GOOOOL! ¡Te lanzas como un portero y empujas el balón dentro!", "fail_text": "Un defensa rival llega antes y despeja el balón."},
				{"text": "Esperar a que baje el balón para rematar", "action": "score_goal", "difficulty": 60,
				"success_text": "¡GOLAZO! ¡Remate perfecto de volea al fondo de la red!", "fail_text": "El balón rebota en varios jugadores y sale por la línea de fondo."}
			]
		}
	]

func skip_entire_dialogue():
	# Esta función no aplica al simulador de fútbol ya que no es un diálogo
	# pero la incluimos para compatibilidad
	print("FootballSimulator: skip_entire_dialogue llamado, pero no es aplicable en el simulador")
	# Podríamos hacer que termine el partido inmediatamente como "cheat"
	# end_match()

# Función para cargar alineación desde archivo
func load_lineup_from_file():
	var file = FileAccess.open("user://saved_lineup.json", FileAccess.READ)
	if not file:
		print("No hay archivo de alineación guardado")
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result == OK:
		var data = json.data
		var saved_lineup = {}
		var last_used_formation = ""
		
		if data.has("saved_lineup"):
			saved_lineup = data["saved_lineup"]
			print("✓ Alineación cargada desde archivo - Jugadores: ", saved_lineup.size())
		if data.has("last_used_formation"):
			last_used_formation = data["last_used_formation"]
			print("✓ Formación cargada: ", last_used_formation)
		
		# Guardar en LineupManager para que esté disponible
		if saved_lineup.size() > 0 and last_used_formation != "":
			LineupManager.save_lineup(last_used_formation, saved_lineup)
			print("✓ Alineación transferida a LineupManager")
	else:
		print("ERROR: No se pudo parsear el archivo de alineación")

func update_player_image(event):
	# Verificar que player_image existe
	if not player_image:
		if debug_enabled:
			print("ADVERTENCIA: player_image no está disponible")
		return
	
	# Actualizar la imagen del jugador solo para eventos dinámicos
	if not event.has("choices") or event.choices.size() == 0:
		player_image.texture = null
		return
	
	# Obtener el jugador del primer choice (todos deberían tener el mismo jugador)
	var first_choice = event.choices[0]
	if not first_choice.has("player"):
		player_image.texture = null
		return
	
	var player = first_choice.player
	if not player.has("image_path"):
		# Si no tiene image_path, ocultar la imagen
		player_image.texture = null
		if debug_enabled:
			print("No se encontró image_path para el jugador: " + player.name)
		return
	
	# Cargar la imagen del jugador
	var image_path = player.image_path
	var texture = load(image_path)
	
	if texture:
		player_image.texture = texture
		if debug_enabled:
			print("Imagen cargada para " + player.name + ": " + image_path)
	else:
		player_image.texture = null
		if debug_enabled:
			print("No se pudo cargar la imagen para " + player.name + ": " + image_path)

func get_7v7_events():
	return [
		# --- EVENTOS DE ATAQUE (7vs7) ---
		{
			"text": "Yazawa, tienes el balón en el mediocampo. Pablo te pide el balón a la espalda de la defensa.",
			"choices": [
				{"text": "Enviar un pase largo y preciso a Pablo", "action": "pass_long", "difficulty": 35, 
				 "success_text": "¡Pase perfecto! Pablo controla y se planta solo ante el portero.", "fail_text": "El pase es interceptado. ¡Qué lástima!"},
				{"text": "Ignorar a Pablo y seguir tu propia jugada", "action": "dribble", "difficulty": 55, 
				 "success_text": "¡Decisión arriesgada pero funciona! Superas a tu marcador y creas una ocasión de gol.", "fail_text": "Pierdes el balón. Pablo te mira con desaprobación."}
			]
		},
		{
			"text": "Perma está desmarcado en la banda, pidiendo un centro. Parece que va a intentar uno de sus remates acrobáticos.",
			"choices": [
				{"text": "Centrar al área para que Perma remate", "action": "pass_long", "difficulty": 40, 
				 "success_text": "¡Centro medido! Perma salta y conecta una chilena espectacular que se va rozando el larguero.", "fail_text": "El centro es demasiado corto y un defensa lo despeja."},
				{"text": "Hacer una pared con Javo para acercarte más al área", "action": "pass_short", "difficulty": 30, 
				 "success_text": "¡Buena combinación con Javo! Ganas metros y te sitúas en una posición más peligrosa.", "fail_text": "Javo no te devuelve bien el balón y perdéis la posesión."}
			]
		},
		{
			"text": "¡Contraataque de FC Bufas! Javo lidera la jugada y te la pasa. Fan corre por la otra banda gritando: '¡PÁSAMELA, SOY UN EXPRESO!'",
			"choices": [
				{"text": "Confiar en la velocidad de Fan y darle un pase al hueco", "action": "pass_long", "difficulty": 50, 
				 "success_text": "¡Fan es sorprendentemente rápido! Llega al balón y manda un centro peligroso que casi acaba en gol.", "fail_text": "Fan tropieza con sus propios pies y se cae. La defensa rival recupera el balón riéndose."},
				{"text": "Devolverle el balón a Javo para que él decida", "action": "pass_short", "difficulty": 20, 
				 "success_text": "Javo, con su visión de juego, encuentra un hueco y dispara. ¡El portero hace un paradón!", "fail_text": "El pase es predecible y la defensa corta la línea de pase."}
			]
		},
		
		# --- EVENTOS DE DEFENSA (7vs7) ---
		{
			"text": "El equipo rival ataca en tromba. Pablo está mal posicionado. ¿Qué haces?",
			"choices": [
				{"text": "Gritarle a Pablo para que corrija su posición", "action": "contain", "difficulty": 25,
				 "success_text": "Pablo reacciona a tiempo, corta la línea de pase y recupera el balón. ¡Bien hecho!", "fail_text": "Pablo se ofende por tus gritos y se queda parado. El rival aprovecha y crea una ocasión de gol."},
				{"text": "Cubrir tú mismo el hueco que ha dejado Pablo", "action": "tackle", "difficulty": 60,
				 "success_text": "¡Haces una entrada providencial y robas el balón! Sacrificio por el equipo.", "fail_text": "Llegas tarde y cometes una falta en la frontal del área."}
			]
		},
		{
			"text": "Córner para el equipo rival. Perma se sube encima de un defensa para intentar despejar. El árbitro no lo ha visto.",
			"choices": [
				{"text": "Aprovechar la distracción y atacar el balón", "action": "clear_ball", "difficulty": 40,
				 "success_text": "¡Mientras todos miran a Perma, tú te elevas y despejas el balón con autoridad!", "fail_text": "Perma se resbala, cae sobre ti y ambos acabáis en el suelo. El rival remata a placer."},
				{"text": "Pedirle a Fan que te traiga un refresco", "action": "contain", "difficulty": 90,
				 "success_text": "Fan, en un acto de velocidad sobrehumana, va a la banda, coge un refresco y vuelve a tiempo para despejar el balón con la botella. El árbitro está tan confundido que no pita nada.", "fail_text": "El árbitro os ve y pita penalti por conducta antideportiva. Fan te trae el refresco a modo de consolación."}
			]
		}
	]
