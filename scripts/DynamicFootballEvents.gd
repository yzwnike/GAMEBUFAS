extends Control

# --- Simulador de eventos dinámicos para el partido de fútbol ---

var score_label
var time_label
var event_panel
var event_description
var event_choices_container
var feedback_panel
var feedback_label

var dynamic_events = []
var match_events = []
var current_event_index = 0
var total_events = 10
var score_blue = 0
var score_red = 0
var debug_enabled = true  # Variable para activar/desactivar debug

# Variables para el sistema de eventos encadenados
var last_event_position = ""
var last_event_success = false
var force_next_position = ""  # Forzar la siguiente posición si está definida

func _ready():
    print("=== DynamicFootballEvents: INICIANDO ===")  
    
    # Obtener nodos manualmente
    score_label = get_node("UIPanel/ScoreLabel")
    time_label = get_node("UIPanel/TimeLabel")
    event_panel = get_node("EventPanel")
    event_description = get_node("EventPanel/EventDescription")
    event_choices_container = get_node("EventPanel/EventChoices")
    feedback_panel = get_node("FeedbackPanel")
    feedback_label = get_node("FeedbackPanel/FeedbackLabel")
    
    print("DynamicFootballEvents: Nodos obtenidos")
    
    # Verificar que los nodos existan
    if not score_label:
        print("ERROR: score_label no encontrado")
    else:
        print("OK: score_label encontrado")
    if not time_label:
        print("ERROR: time_label no encontrado")
    else:
        print("OK: time_label encontrado")
    if not event_panel:
        print("ERROR: event_panel no encontrado")
    else:
        print("OK: event_panel encontrado")
    if not event_description:
        print("ERROR: event_description no encontrado")
    else:
        print("OK: event_description encontrado")
    if not event_choices_container:
        print("ERROR: event_choices_container no encontrado")
    else:
        print("OK: event_choices_container encontrado")
    if not feedback_panel:
        print("ERROR: feedback_panel no encontrado")
    else:
        print("OK: feedback_panel encontrado")
    if not feedback_label:
        print("ERROR: feedback_label no encontrado")
    else:
        print("OK: feedback_label encontrado")
    
    print("DynamicFootballEvents: Cargando eventos...")
    load_dynamic_events()
    print("DynamicFootballEvents: Configurando eventos del partido...")
    setup_match_events()  
    print("DynamicFootballEvents: Iniciando partido...")
    start_match()

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
                    "action": "tackle",
                    "success_text": "%s realiza un tackle limpio y recupera el balón.",
                    "fail_text": "%s falla el tackle y comete falta."
                },
                {
                    "text": "Posicionarse para cerrar espacios",
                    "substat": "positioning",
                    "action": "contain",
                    "success_text": "%s se posiciona bien y cierra todos los espacios.",
                    "fail_text": "%s se posiciona mal y deja huecos peligrosos."
                }
            ]
        },
        # EVENTO CENTROCAMPISTA
        {
            "position": "Centrocampista",
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

# Elegir un evento basado en las probabilidades especificadas por posición
func choose_event_based_on_probability():
    # Si hay una posición forzada, usarla y resetear
    if force_next_position != "":
        var forced_pos = force_next_position
        force_next_position = ""  # Resetear después de usar
        if debug_enabled:
            print("=== EVENTO FORZADO ===")
            print("Posición forzada: " + forced_pos)
            print("Razón: Evento anterior (" + last_event_position + ") " + ("acertó" if last_event_success else "falló"))
            print("=====================")
        return forced_pos
    
    # Probabilidades normales: Portero 10%, Defensa 40%, Mediocentro 40%, Delantero 10%
    var roll = randi_range(1, 100)
    if debug_enabled:
        print("=== SELECCIÓN DE EVENTO ===")
        print("Roll: " + str(roll))
    
    if roll <= 10:
        if debug_enabled:
            print("Evento seleccionado: Portero (1-10)")
        return "Portero"
    elif roll <= 50:
        if debug_enabled:
            print("Evento seleccionado: Defensa (11-50)")
        return "Defensa"
    elif roll <= 90:
        if debug_enabled:
            print("Evento seleccionado: Centrocampista (51-90)")
        return "Centrocampista"
    else:
        if debug_enabled:
            print("Evento seleccionado: Delantero (91-100)")
            print("========================")
        return "Delantero"

# Procesar todos los eventos y seleccionar jugadores
func process_all_events():
    for i in range(total_events):
        var position = choose_event_based_on_probability()
        var event = find_event_for_position(position)
        if event:
            process_dynamic_event(event)

# Encontrar un evento para la posición especificada
func find_event_for_position(position: String):
    for event in dynamic_events:
        if event.position == position:
            return event
    return null

# Procesar evento dinámico: seleccionar jugador y formatear textos
func process_dynamic_event(event):
    var selected_player = get_random_player_by_position(event.position)
    if not selected_player:
        return
    
    event.text = event.text % selected_player.name
    for choice in event.choices:
        choice.success_text = choice.success_text % selected_player.name
        choice.fail_text = choice.fail_text % selected_player.name
        choice.player = selected_player

# Obtener jugador aleatorio por posición
func get_random_player_by_position(position: String):
    if not LineupManager:
        return null
    
    var current_formation = LineupManager.get_current_formation()
    var lineup_data = LineupManager.get_lineup_data(current_formation)
    
    if not lineup_data:
        return null
    
    # Mapear posiciones a las keys de la alineación
    match position:
        "Portero":
            return lineup_data.get("GK")
        "Defensa":
            # Elegir defensa aleatoriamente
            var def_positions = ["DEF1", "DEF2", "DEF3"]
            var available_defenders = []
            for pos in def_positions:
                if lineup_data.has(pos):
                    available_defenders.append(lineup_data[pos])
            if available_defenders.size() > 0:
                return available_defenders[randi() % available_defenders.size()]
        "Centrocampista":
            # Elegir mediocampista aleatoriamente
            var mid_positions = ["MID1", "MID2"]
            var available_midfielders = []
            for pos in mid_positions:
                if lineup_data.has(pos):
                    available_midfielders.append(lineup_data[pos])
            if available_midfielders.size() > 0:
                return available_midfielders[randi() % available_midfielders.size()]
        "Delantero":
            return lineup_data.get("ATT1")
    
    return null

# Configurar eventos del partido
func setup_match_events():
    match_events.clear()
    # Ya no generamos todos los eventos al inicio
    # Los eventos se generarán dinámicamente durante el partido

# Crear evento procesado con jugador específico
func create_processed_event(event):
    var selected_player = get_random_player_by_position(event.position)
    if not selected_player:
        return null
    
    var processed_event = {
        "text": event.text % selected_player.name,
        "choices": []
    }
    
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
    
    return processed_event

# Iniciar el partido
func start_match():
    score_blue = 0
    score_red = 0
    current_event_index = 0
    feedback_panel.visible = false
    update_score_display()
    _next_event()

# Avanzar al siguiente evento
func _next_event():
    if current_event_index >= total_events:
        end_match()
        return
    
    # GENERAR EVENTO DINÁMICAMENTE
    var position = choose_event_based_on_probability()
    var event_template = find_event_for_position(position)
    
    if not event_template:
        print("ERROR: No se encontró evento para posición: " + position)
        _next_event()  # Intentar con otro evento
        return
    
    var current_event = create_processed_event(event_template)
    
    if not current_event:
        print("ERROR: No se pudo crear evento procesado")
        _next_event()  # Intentar con otro evento
        return
    
    # Mostrar panel de evento
    event_panel.visible = true
    feedback_panel.visible = false
    event_description.text = current_event.text
    
    # Limpiar y crear botones de elección
    for child in event_choices_container.get_children():
        child.queue_free()
    
    for choice in current_event.choices:
        # IMPORTANTE: Añadir la posición del evento a cada choice para usar en resolve_action
        choice.event_position = position
        var button = Button.new()
        button.text = choice.text
        button.pressed.connect(func(): _on_choice_selected(choice))
        event_choices_container.add_child(button)
    
    current_event_index += 1

# Manejar selección de opción
func _on_choice_selected(choice):
    event_panel.visible = false
    var result_text = resolve_action(choice)
    
    # Mostrar feedback
    feedback_label.text = result_text
    feedback_panel.visible = true
    
    var feedback_timer = get_tree().create_timer(3.0)
    await feedback_timer.timeout
    
    _next_event()

# Resolver acción basada en substats
func resolve_action(choice) -> String:
    var success_chance = calculate_success_probability(choice)
    var roll = randi_range(1, 100)
    var success = roll < success_chance
    
    # USAR LA POSICIÓN DEL EVENTO (NO DEL JUGADOR)
    var current_position = choice.get("event_position", "")
    
    if debug_enabled:
        print("=== RESOLVE ACTION DEBUG ===")
        print("Jugador: " + choice.player.name)
        print("Posición del evento: " + current_position)
        print("Roll: " + str(roll) + " vs " + str(success_chance))
        print("Resultado: " + ("EXITOSO" if success else "FALLIDO"))
        print("=============================")
    
    var feedback = ""
    
    if success:
        feedback = choice.success_text
        match choice.action:
            "score_goal": score_blue += 1
    else:
        feedback = choice.fail_text
        # En algunos casos de fallo, el rival puede marcar
        match choice.action:
            "concede_goal":
                score_red += 1
    
    # APLICAR LÓGICA DE ENCADENAMIENTO
    # Guardar información del evento actual
    last_event_position = current_position
    last_event_success = success
    
    # Aplicar reglas de encadenamiento
    if current_position == "Defensa" and not success:
        # Si un Defensa FALLA -> siguiente evento 100% Portero
        force_next_position = "Portero"
        if debug_enabled:
            print("=== ENCADENAMIENTO ACTIVADO ===")
            print("Defensa falló -> Próximo evento será 100% Portero")
            print("==============================")
    elif current_position == "Centrocampista" and success:
        # Si un Mediocentro ACIERTA -> siguiente evento 100% Delantero
        force_next_position = "Delantero"
        if debug_enabled:
            print("=== ENCADENAMIENTO ACTIVADO ===")
            print("Centrocampista acertó -> Próximo evento será 100% Delantero")
            print("==============================")
    
    update_score_display()
    return feedback

# Actualizar marcador
func update_score_display():
    score_label.text = "BUFAS %d - %d DEPORTIVO MAGADIOS" % [score_blue, score_red]
    var time_display = (current_event_index * 9)  # Simula 9 minutos por evento
    time_label.text = "Minuto: %d" % time_display

# Finalizar partido
func end_match():
    event_panel.visible = false
    feedback_panel.visible = true
    
    var result_text = "¡Final del partido!\nResultado: BUFAS %d - %d DEPORTIVO MAGADIOS" % [score_blue, score_red]
    var match_result = ""
    
    if score_blue > score_red:
        result_text += "\n\n¡VICTORIA!"
        match_result = "win"
    elif score_red > score_blue:
        result_text += "\n\nDerrota."
        match_result = "loss"
    else:
        result_text += "\n\nEmpate."
        match_result = "draw"
    
    feedback_label.text = result_text
    
    # Registrar resultado
    GameManager.add_match_result(score_blue, score_red)
    GameManager.set_story_flag("post_match_branch", match_result if match_result != "draw" else "loss")
    
    # Transición después de 3 segundos
    var transition_timer = get_tree().create_timer(3.0)
    await transition_timer.timeout
    
    GameManager.change_scene("res://scenes/BranchingDialogue.tscn")

# Actualizar tiempo
func _process(delta):
    var time_display = (current_event_index * 9)
    time_label.text = "Minuto: %d" % time_display

# Calcular probabilidad de éxito basada en substats
func calculate_success_probability(choice) - int:
    # Si no tiene substat definido, usar un valor por defecto
    if not choice.has("substat") or not choice.has("player"):
        return 50
    
    # Obtener el valor del substat específico del jugador
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
    var probability = max(5, min(95, modified_substat - 15))

    if debug_enabled:
        print("=== Probabilidad de Éxito (Dinámico) ===")
        print("Jugador: " + player.name)
        print("Substat: " + choice.substat)
        print("Valor base del Substat: " + str(substat_value))
        print("Moral actual: " + str(current_morale))
        print("Modificador de moral: " + str(morale_modifier))
        print("Substat con moral: " + str(modified_substat))
        print("Probabilidad final: " + str(probability) + "%")
        print("===============================")

    return probability

