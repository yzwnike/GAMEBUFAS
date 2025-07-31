extends Control

# Minijuego de marcaje individual - 3 niveles de dificultad
# Vista de dron 2D donde debes marcar a un jugador rival

@onready var game_area = $GameArea
@onready var player_character = $GameArea/PlayerCharacter
@onready var rival_character = $GameArea/RivalCharacter
@onready var timer_label = $UI/HUD/TimerLabel
@onready var level_label = $UI/HUD/LevelLabel
@onready var distance_bar = $UI/HUD/DistanceBar
@onready var accuracy_label = $UI/HUD/AccuracyLabel
@onready var instruction_label = $UI/HUD/InstructionLabel
@onready var instruction_panel = $UI/InstructionPanel
@onready var instruction_text = $UI/InstructionPanel/InstructionText
@onready var start_button = $UI/InstructionPanel/StartButton
@onready var result_panel = $UI/ResultPanel
@onready var retry_button = $UI/ResultPanel/RetryButton
@onready var continue_button = $UI/ResultPanel/ContinueButton
@onready var next_level_button = $UI/ResultPanel/NextLevelButton
@onready var background = $Background

# Elementos de contador y transiciones
@onready var countdown_label = null
@onready var level_transition_panel = null
@onready var level_transition_label = null

# Variables de control
var countdown_active = false
var countdown_timer = 0.0
var countdown_value = 3

# Sistema de niveles
var current_level = 1
var max_levels = 3
var level_completed = [false, false, false]
var game_time = 20.0  # 20 segundos por nivel

# Variables del juego
var max_distance = 150.0
var warning_distance = 100.0
var current_distance = 0.0
var game_active = false
var time_remaining = 0.0
var success_time = 0.0
var level_start_time = 0.0

# Variables del movimiento del rival (más dinámicas)
var rival_base_speed = 60.0
var rival_current_speed = 60.0
var rival_direction = Vector2.ZERO
var direction_change_timer = 0.0
var direction_change_interval = 1.5
var speed_change_timer = 0.0
var speed_change_interval = 0.8
var is_sprinting = false
var sprint_duration = 0.0

# Variables del jugador
var player_speed = 140.0

# Efectos visuales
var trail_points = []
var max_trail_points = 20
var particle_timer = 0.0

signal training_completed(success: bool)

func _ready():
	print("MarkingMiniGame: Iniciando minijuego de marcaje")
	setup_ui()
	setup_characters()
	# No iniciar el juego automáticamente, esperar a que el usuario presione INICIAR
	game_active = false

func setup_ui():
	result_panel.visible = false
	
	# Configurar el nivel actual
	level_label.text = "NIVEL " + str(current_level) + "/" + str(max_levels)
	
	# Configurar el texto de instrucciones según el nivel
	if current_level == 1:
		instruction_panel.visible = true
		instruction_text.text = "🎯 TUTORIAL - NIVEL 1\n\n" + \
			"OBJETIVO: Mantente cerca del rival (círculo rojo)\n" + \
			"CONTROLES: WASD o flechas direccionales\n" + \
			"REQUISITO: Estar cerca 70% del tiempo\n" + \
			"DURACIÓN: 20 segundos\n\n" + \
			"¡Presiona INICIAR cuando estés listo!"
	else:
		instruction_panel.visible = true
		var difficulty = ["FÁCIL", "MEDIO", "DIFÍCIL"][current_level - 1]
		instruction_text.text = "🔥 NIVEL " + str(current_level) + " - " + difficulty + "\n\n" + \
			"El rival será más rápido y errático.\n" + \
			"¡Mantente concentrado!\n\n" + \
			"¡Presiona INICIAR para continuar!"
	
	start_button.pressed.connect(_on_start_pressed)
	
	# Conectar botones del resultado
	retry_button.pressed.connect(_on_retry_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	next_level_button.pressed.connect(_on_next_level_pressed)
	next_level_button.visible = false
	
	# Configurar barra de distancia
	distance_bar.max_value = max_distance
	distance_bar.value = 0
	
	# Configurar fondo con gradiente
	setup_background()

func setup_characters():
	# Posición inicial
	var game_center = game_area.size / 2
	player_character.position = game_center + Vector2(-50, 0)
	rival_character.position = game_center + Vector2(50, 0)
	
	# Configurar apariencia de personajes
	setup_player_appearance()
	setup_rival_appearance()
	
	# Dirección inicial aleatoria para el rival
	rival_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

func setup_player_appearance():
	# Limpiar personaje anterior
	for child in player_character.get_children():
		child.queue_free()
	
	# Crear sprite del jugador (círculo azul con cara)
	var player_sprite = ColorRect.new()
	player_sprite.size = Vector2(50, 50)
	player_sprite.color = Color(0.2, 0.5, 1.0, 0.9)  # Azul más llamativo
	player_sprite.position = Vector2(-25, -25)
	player_character.add_child(player_sprite)
	
	# Añadir borde
	var border = ColorRect.new()
	border.size = Vector2(54, 54)
	border.color = Color.WHITE
	border.position = Vector2(-27, -27)
	player_character.add_child(border)
	player_character.move_child(border, 0)  # Mover al fondo
	
	# Añadir cara sonriente
	var face = Label.new()
	face.text = "😎"  # Cara genial con gafas
	face.add_theme_font_size_override("font_size", 28)
	face.position = Vector2(-15, -18)
	player_sprite.add_child(face)
	
	# Añadir nombre con fondo
	var name_bg = ColorRect.new()
	name_bg.size = Vector2(40, 20)
	name_bg.color = Color(0, 0, 0, 0.7)
	name_bg.position = Vector2(-20, -45)
	player_character.add_child(name_bg)
	
	var name_label = Label.new()
	name_label.text = "TÚ"
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color.CYAN)
	name_label.position = Vector2(-15, -45)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_character.add_child(name_label)

func setup_rival_appearance():
	# Limpiar rival anterior
	for child in rival_character.get_children():
		child.queue_free()
	
	# Crear sprite del rival (círculo rojo con cara)
	var rival_sprite = ColorRect.new()
	rival_sprite.size = Vector2(50, 50)
	rival_sprite.color = Color(1.0, 0.3, 0.3, 0.9)  # Rojo más suave
	rival_sprite.position = Vector2(-25, -25)
	rival_character.add_child(rival_sprite)
	
	# Añadir borde
	var border = ColorRect.new()
	border.size = Vector2(54, 54)
	border.color = Color.WHITE
	border.position = Vector2(-27, -27)
	rival_character.add_child(border)
	rival_character.move_child(border, 0)  # Mover al fondo
	
	# Añadir cara concentrada
	var face = Label.new()
	face.text = "😤"  # Cara concentrada/frustrada
	face.add_theme_font_size_override("font_size", 28)
	face.position = Vector2(-15, -18)
	rival_sprite.add_child(face)
	
	# Añadir nombre con fondo
	var name_bg = ColorRect.new()
	name_bg.size = Vector2(50, 20)
	name_bg.color = Color(0, 0, 0, 0.7)
	name_bg.position = Vector2(-25, -45)
	rival_character.add_child(name_bg)
	
	var name_label = Label.new()
	name_label.text = "RIVAL"
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color.ORANGE)
	name_label.position = Vector2(-25, -45)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rival_character.add_child(name_label)

func start_game():
	game_active = true
	time_remaining = game_time
	success_time = 0.0
	print("MarkingMiniGame: Juego iniciado - ", game_time, " segundos")

func _process(delta):
	# CHEAT DE TESTING: Pulsar T para completar instantáneamente
	if Input.is_key_pressed(KEY_T):
		test_complete_all_levels()
		return
	
	# Manejar countdown si está activo
	if countdown_active:
		countdown_timer -= delta
		if countdown_timer <= 0:
			countdown_value -= 1
			if countdown_value >= 0:
				update_countdown_display()
				countdown_timer = 0.6
			else:
				# Terminar countdown e iniciar juego
				countdown_active = false
				countdown_label.visible = false
				start_game()
				return
	
	# Manejar lógica del juego si está activo
	if not game_active:
		return
	
	# Actualizar timer
	time_remaining -= delta
	timer_label.text = "Tiempo: " + str(int(time_remaining)) + "s"
	
	# Mover jugador
	handle_player_input(delta)
	
	# Mover rival
	move_rival_enhanced(delta)
	
	# Calcular distancia
	calculate_distance()
	
	# Actualizar UI
	update_ui_enhanced()
	
	# Verificar condiciones de fin
	check_game_conditions()

func handle_player_input(delta):
	var input_vector = Vector2.ZERO
	
	# Detectar input
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_vector.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_vector.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_vector.y += 1
	
	# Mover jugador
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		var new_position = player_character.position + input_vector * player_speed * delta
		
		# Mantener dentro del área de juego
		new_position.x = clamp(new_position.x, 20, game_area.size.x - 20)
		new_position.y = clamp(new_position.y, 20, game_area.size.y - 20)
		
		player_character.position = new_position

func move_rival(delta):
	# Cambiar dirección ocasionalmente
	direction_change_timer -= delta
	if direction_change_timer <= 0:
		rival_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		direction_change_timer = direction_change_interval
		
		# Ocasionalmente ir hacia el jugador para hacerlo más desafiante
		if randf() < 0.3:
			var to_player = (player_character.position - rival_character.position).normalized()
			rival_direction = to_player * 0.5 + rival_direction * 0.5
	
	# Mover rival
	var new_position = rival_character.position + rival_direction * rival_current_speed * delta
	
	# Mantener dentro del área de juego
	new_position.x = clamp(new_position.x, 20, game_area.size.x - 20)
	new_position.y = clamp(new_position.y, 20, game_area.size.y - 20)
	
	# Si choca con los bordes, cambiar dirección
	if new_position.x <= 20 or new_position.x >= game_area.size.x - 20:
		rival_direction.x *= -1
	if new_position.y <= 20 or new_position.y >= game_area.size.y - 20:
		rival_direction.y *= -1
	
	rival_character.position = new_position

func calculate_distance():
	current_distance = player_character.position.distance_to(rival_character.position)
	
	# Si está en rango correcto, acumular tiempo de éxito
	if current_distance <= warning_distance:
		success_time += get_process_delta_time()

func update_ui():
	# Actualizar barra de distancia
	distance_bar.value = min(current_distance, max_distance)
	
	# Cambiar color según distancia
	if current_distance <= warning_distance:
		distance_bar.modulate = Color.GREEN
		instruction_label.text = "¡Perfecto! Mantente así"
		instruction_label.modulate = Color.GREEN
	elif current_distance <= max_distance:
		distance_bar.modulate = Color.YELLOW
		instruction_label.text = "¡Cuidado! Acércate más"
		instruction_label.modulate = Color.YELLOW
	else:
		distance_bar.modulate = Color.RED
		instruction_label.text = "¡DEMASIADO LEJOS! ¡Acércate YA!"
		instruction_label.modulate = Color.RED

func check_game_conditions():
	# Fallo: demasiado lejos por mucho tiempo
	if current_distance > max_distance:
		end_game(false, "¡Te alejaste demasiado del rival!")
		return
	
	# Éxito: tiempo completado
	if time_remaining <= 0:
		var success_percentage = (success_time / game_time) * 100
		if success_percentage >= 70:  # Necesita estar 70% del tiempo en rango correcto
			end_game(true, "¡Excelente marcaje! " + str(int(success_percentage)) + "% de precisión")
		else:
			end_game(false, "Necesitas mantener mejor la marca. Solo " + str(int(success_percentage)) + "% de precisión")

func end_game(success: bool, message: String):
	game_active = false
	print("MarkingMiniGame: Juego terminado - Éxito: ", success)
	
	# Mostrar resultado
	result_panel.visible = true
	var result_label = result_panel.get_node("ResultLabel")
	result_label.text = message
	
	if success:
		result_label.modulate = Color.GREEN
		level_completed[current_level - 1] = true
		
		# Mostrar botones según si quedan niveles
		# SIEMPRE mostrar "SIGUIENTE NIVEL" incluso en el nivel 3
		# para que pueda pasar a show_final_dialogue()
		next_level_button.visible = true
		continue_button.visible = false
		if current_level < max_levels:
			next_level_button.text = "SIGUIENTE NIVEL"
		else:
			next_level_button.text = "FINALIZAR ENTRENAMIENTO"
		
		retry_button.visible = false
	else:
		result_label.modulate = Color.RED
		continue_button.visible = false
		next_level_button.visible = false
		retry_button.visible = true
	
	# Emitir señal
	emit_signal("training_completed", success)

func _on_retry_pressed():
	print("MarkingMiniGame: Reintentando...")
	result_panel.visible = false
	setup_characters()
	start_game()

func _on_continue_pressed():
	print("MarkingMiniGame: Entrenamiento completado exitosamente")
	
	# Completar el entrenamiento y otorgar experiencia
	complete_training_success()
	
	# Volver al menú de entrenamiento
	get_tree().change_scene_to_file("res://scenes/TrainingMenu.tscn")

func complete_training_success():
	print("MarkingMiniGame: Completando entrenamiento con éxito...")
	
	# Otorgar experiencia a los jugadores
	var players_manager = get_node("/root/PlayersManager")
	if players_manager != null:
		players_manager.add_experience_after_training()
		print("¡Entrenamiento completado! Todos los jugadores ganaron 2 puntos de experiencia.")
	
	# Marcar el entrenamiento como completado
	if TrainingManager:
		TrainingManager.complete_training()
		print("MarkingMiniGame: Entrenamiento marcado como completado")
	
	# Avanzar el día después de completar el entrenamiento con origen training
	if DayManager:
		DayManager.advance_day_with_origin("training")
		print("MarkingMiniGame: Día avanzado después del entrenamiento")

# === FUNCIONES NUEVAS AÑADIDAS ===

func setup_background():
	# Crear fondo con gradiente más profesional
	var bg_rect = ColorRect.new()
	bg_rect.size = get_viewport().get_visible_rect().size
	bg_rect.color = Color(0.1, 0.15, 0.2, 1.0)  # Azul oscuro
	background.add_child(bg_rect)
	
	# Añadir líneas de campo de fútbol
	var field_lines = create_field_lines()
	background.add_child(field_lines)

func create_field_lines() -> Control:
	var lines_container = Control.new()
	lines_container.size = game_area.size
	
	# Líneas horizontales
	for i in range(5):
		var line = ColorRect.new()
		line.size = Vector2(game_area.size.x, 2)
		line.position = Vector2(0, i * (game_area.size.y / 4))
		line.color = Color(0.3, 0.6, 0.3, 0.3)  # Verde tenue
		lines_container.add_child(line)
	
	# Líneas verticales
	for i in range(5):
		var line = ColorRect.new()
		line.size = Vector2(2, game_area.size.y)
		line.position = Vector2(i * (game_area.size.x / 4), 0)
		line.color = Color(0.3, 0.6, 0.3, 0.3)
		lines_container.add_child(line)
	
	return lines_container

func _on_start_pressed():
	print("MarkingMiniGame: Iniciando contador para nivel ", current_level)
	instruction_panel.visible = false
	setup_level_difficulty()
	start_countdown()

func setup_level_difficulty():
	# Configurar dificultad según el nivel
	match current_level:
		1:  # Tutorial - Fácil
			rival_base_speed = 50.0
			direction_change_interval = 2.0
			speed_change_interval = 1.5
		2:  # Intermedio
			rival_base_speed = 80.0
			direction_change_interval = 1.2
			speed_change_interval = 0.8
		3:  # Difícil (muy desafiante)
			rival_base_speed = 90.0  # Aumentado para mayor dificultad
			direction_change_interval = 0.5  # Cambia dirección aún más frecuentemente
			speed_change_interval = 0.6  # Cambia velocidad más a menudo
	
	rival_current_speed = rival_base_speed

func move_rival_enhanced(delta):
	# Movimiento más dinámico y errático
	
	# Cambio de velocidad errático
	speed_change_timer -= delta
	if speed_change_timer <= 0:
		speed_change_timer = speed_change_interval
		
		# Decidir si hacer sprint o ir lento
		var rand_action = randf()
		if rand_action < 0.3:  # 30% sprint
			is_sprinting = true
			sprint_duration = randf_range(0.5, 1.2)  # Duración más corta
			# Velocidad de sprint ajustada según el nivel
			var sprint_multiplier = 2.8 if current_level == 3 else 3.5  # Nivel 3 menos extremo
			rival_current_speed = rival_base_speed * randf_range(2.0, sprint_multiplier)
		elif rand_action < 0.5:  # 20% lento
			is_sprinting = false
			rival_current_speed = rival_base_speed * randf_range(0.3, 0.6)  # Muy lento
		else:  # 50% velocidad normal con variación
			is_sprinting = false
			rival_current_speed = rival_base_speed * randf_range(0.8, 1.2)
	
	# Reducir duración de sprint
	if is_sprinting:
		sprint_duration -= delta
		if sprint_duration <= 0:
			is_sprinting = false
			rival_current_speed = rival_base_speed
	
	# Cambio de dirección más frecuente
	direction_change_timer -= delta
	if direction_change_timer <= 0:
		direction_change_timer = direction_change_interval + randf_range(-0.3, 0.3)
		
		# Direcciones más erráticas
		var rand_dir = randf()
		if rand_dir < 0.4:  # 40% dirección completamente aleatoria
			rival_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		elif rand_dir < 0.7:  # 30% hacia/alejándose del jugador
			var to_player = (player_character.position - rival_character.position).normalized()
			if randf() < 0.5:
				rival_direction = to_player  # Hacia el jugador
			else:
				rival_direction = -to_player  # Alejándose
		else:  # 30% dirección perpendicular al jugador
			var to_player = (player_character.position - rival_character.position).normalized()
			rival_direction = Vector2(-to_player.y, to_player.x)  # Perpendicular
			if randf() < 0.5:
				rival_direction = -rival_direction
	
	# Mover rival con la nueva velocidad
	var new_position = rival_character.position + rival_direction * rival_current_speed * delta
	
	# Mantener dentro del área de juego con rebote más realista
	var margin = 30
	if new_position.x <= margin or new_position.x >= game_area.size.x - margin:
		rival_direction.x *= -1
		new_position.x = clamp(new_position.x, margin, game_area.size.x - margin)
	if new_position.y <= margin or new_position.y >= game_area.size.y - margin:
		rival_direction.y *= -1
		new_position.y = clamp(new_position.y, margin, game_area.size.y - margin)
	
	rival_character.position = new_position
	
	# Actualizar apariencia del rival según su estado
	update_rival_visual_state()

func update_rival_visual_state():
	# Cambiar emoji según velocidad
	# Buscar el label de la cara de forma más segura
	var face_label = null
	for child in rival_character.get_children():
		if child is ColorRect:  # El sprite principal
			for grandchild in child.get_children():
				if grandchild is Label:
					face_label = grandchild
					break
			if face_label != null:
				break
	
	# Solo cambiar el emoji si encontramos el label
	if face_label != null:
		if is_sprinting:
			face_label.text = "😠"  # Cara enojada cuando hace sprint
			rival_character.modulate = Color(1.2, 0.8, 0.8, 1.0)  # Tinte rojizo
		elif rival_current_speed < rival_base_speed * 0.7:
			face_label.text = "😴"  # Cara somnolienta cuando va lento
			rival_character.modulate = Color(0.8, 0.8, 1.2, 1.0)  # Tinte azulado
		else:
			face_label.text = "😤"  # Cara normal
			rival_character.modulate = Color.WHITE
	else:
		# Solo cambiar el color si no encontramos el label
		if is_sprinting:
			rival_character.modulate = Color(1.2, 0.8, 0.8, 1.0)  # Tinte rojizo
		elif rival_current_speed < rival_base_speed * 0.7:
			rival_character.modulate = Color(0.8, 0.8, 1.2, 1.0)  # Tinte azulado
		else:
			rival_character.modulate = Color.WHITE

func update_ui_enhanced():
	# Actualizar barra de distancia
	distance_bar.value = min(current_distance, max_distance)
	
	# Actualizar precisión en tiempo real
	var current_accuracy = (success_time / (game_time - time_remaining)) * 100 if game_time - time_remaining > 0 else 0
	accuracy_label.text = "Precisión: " + str(int(current_accuracy)) + "%"
	
	# Colores y mensajes más dinámicos
	if current_distance <= warning_distance:
		distance_bar.modulate = Color.GREEN
		accuracy_label.modulate = Color.GREEN
	elif current_distance <= max_distance:
		distance_bar.modulate = Color.YELLOW
		accuracy_label.modulate = Color.YELLOW
	else:
		distance_bar.modulate = Color.RED
		accuracy_label.modulate = Color.RED
	
	# Efectos visuales adicionales
	if current_distance <= warning_distance:
		# Efecto de partículas verdes cuando está cerca
		particle_timer += get_process_delta_time()
		if particle_timer > 0.1:  # cada 100ms crear un partícula
			create_success_particle()
			particle_timer = 0.0

func create_success_particle():
	# Crear pequeña partícula verde entre jugador y rival
	var particle = ColorRect.new()
	particle.size = Vector2(4, 4)
	particle.color = Color.GREEN
	var mid_point = (player_character.position + rival_character.position) / 2
	particle.position = mid_point + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	game_area.add_child(particle)
	
	# Animar la partícula para que desaparezca
	var tween = create_tween()
	tween.tween_property(particle, "modulate:a", 0.0, 0.5)
	tween.tween_callback(particle.queue_free)

func _on_next_level_pressed():
	print("MarkingMiniGame: Avanzando al siguiente nivel")
	print("DEBUG: current_level = ", current_level, ", max_levels = ", max_levels)
	current_level += 1
	print("DEBUG: current_level después del incremento = ", current_level)
	if current_level > max_levels:
		print("DEBUG: ¡Llamando a show_final_dialogue()!")
		# Completar todo el entrenamiento - Mostrar diálogo final
		show_final_dialogue()
	else:
		print("DEBUG: Mostrando transición al nivel ", current_level)
		# Mostrar transición al siguiente nivel
		show_level_transition()

func show_level_transition():
	result_panel.visible = false
	
	# Crear panel de transición si no existe
	if level_transition_panel == null:
		level_transition_panel = ColorRect.new()
		level_transition_panel.size = get_viewport().get_visible_rect().size
		level_transition_panel.color = Color(0, 0, 0, 0.8)
		level_transition_panel.position = Vector2.ZERO
		add_child(level_transition_panel)
		
		level_transition_label = Label.new()
		level_transition_label.add_theme_font_size_override("font_size", 48)
		level_transition_label.add_theme_color_override("font_color", Color.YELLOW)
		level_transition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_transition_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		level_transition_label.size = level_transition_panel.size
		level_transition_panel.add_child(level_transition_label)
	
	var difficulty_names = ["FÁCIL", "MEDIO", "DIFÍCIL"]
	level_transition_label.text = "🔥 NIVEL " + str(current_level) + " - " + difficulty_names[current_level - 1] + " 🔥"
	level_transition_panel.visible = true
	
	# Animar la transición
	var tween = create_tween()
	tween.tween_property(level_transition_label, "modulate:a", 1.0, 0.5)
	tween.tween_interval(2.0)
	tween.tween_property(level_transition_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(start_next_level)

func start_next_level():
	level_transition_panel.visible = false
	setup_ui()
	setup_characters()
	game_active = false

func start_countdown():
	# Crear label de contador si no existe
	if countdown_label == null:
		countdown_label = Label.new()
		countdown_label.add_theme_font_size_override("font_size", 120)
		countdown_label.add_theme_color_override("font_color", Color.RED)
		countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		countdown_label.size = get_viewport().get_visible_rect().size
		countdown_label.position = Vector2.ZERO
		add_child(countdown_label)
	
	countdown_active = true
	countdown_value = 3
	countdown_timer = 0.6  # Reducido de 1.0 a 0.6 segundos
	update_countdown_display()
	
	# Usar _process para manejar el countdown
	set_process(true)

func update_countdown_display():
	if countdown_value > 0:
		countdown_label.text = str(countdown_value)
		countdown_label.modulate = Color.RED
	else:
		countdown_label.text = "¡GO!"
		countdown_label.modulate = Color.GREEN
	
	# Efecto de escala
	var tween = create_tween()
	tween.tween_property(countdown_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(countdown_label, "scale", Vector2(1.0, 1.0), 0.1)


func show_final_dialogue():
	print("DEBUG: show_final_dialogue() llamada!")
	result_panel.visible = false
	print("DEBUG: result_panel ocultado")
	
	# Cambiar a la escena de diálogo post-entrenamiento con sistema completo
	print("DEBUG: Cambiando a PostTrainingDialogueScene...")
	get_tree().change_scene_to_file("res://scenes/PostTrainingDialogueScene.tscn")

func create_final_dialogue_scene() -> Control:
	var dialogue_container = Control.new()
	dialogue_container.size = get_viewport().get_visible_rect().size
	
	# Fondo negro
	var bg = ColorRect.new()
	bg.size = dialogue_container.size
	bg.color = Color(0, 0, 0, 0.9)
	dialogue_container.add_child(bg)
	
	# Título
	var title = Label.new()
	title.text = "🏆 ¡ENTRENAMIENTO COMPLETADO! 🏆"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 50)
	title.size = Vector2(dialogue_container.size.x, 100)
	dialogue_container.add_child(title)
	
	# Crear 4 personajes aleatorios con diálogos de humor negro
	var player_names = get_random_player_names()
	var dialogues = create_dark_humor_dialogues(player_names)
	
	var y_pos = 200
	for i in range(4):
		var player_panel = create_player_dialogue_panel(player_names[i], dialogues[i], y_pos)
		dialogue_container.add_child(player_panel)
		y_pos += 120
	
	# Botón para continuar
	var continue_btn = Button.new()
	continue_btn.text = "CONTINUAR AL SIGUIENTE DÍA"
	continue_btn.size = Vector2(300, 50)
	continue_btn.position = Vector2((dialogue_container.size.x - 300) / 2, dialogue_container.size.y - 100)
	continue_btn.pressed.connect(_on_final_continue_pressed)
	dialogue_container.add_child(continue_btn)
	
	return dialogue_container

func get_random_player_names() -> Array:
	var names = ["Paco", "Manolo", "Juanito", "Pepito", "Kiko", "Chema", "Curro", "Fran", "Dani", "Rafa"]
	names.shuffle()
	return names.slice(0, 4)

func create_dark_humor_dialogues(names: Array) -> Array:
	var dialogues = []
	var dark_jokes = [
		"Joder, ¿habéis visto como me han puesto las marcas? Ni un pulpo me habría agobiado más...",
		"Después de este entrenamiento, creo que ya sé lo que sienten las sardinas enlatadas.",
		"Mi abuela corre más rápido que yo después de esta paliza. Y eso que está en silla de ruedas.",
		"He sudado tanto que mi camiseta parece que ha pasado por una lavadora... sin detergente.",
		"Yazawa nos ha machacado tanto que hasta los conos del entrenamiento me dan pena.",
		"Creo que mi marca personal de hoy ha sido no desmayarme. Pequeñas victorias, ya sabéis.",
		"Mi novia me ha dicho que huelo a fútbol. No era un cumplido, era una queja.",
		"Después de correr tanto, mis piernas han presentado una demanda por maltrato laboral."
	]
	
	dark_jokes.shuffle()
	for i in range(4):
		dialogues.append(dark_jokes[i])
	
	return dialogues

func create_player_dialogue_panel(name: String, dialogue: String, y_pos: int) -> Control:
	var panel = Control.new()
	panel.size = Vector2(800, 100)
	panel.position = Vector2(50, y_pos)
	
	# Fondo del panel
	var bg = ColorRect.new()
	bg.size = panel.size
	bg.color = Color(0.2, 0.2, 0.2, 0.8)
	panel.add_child(bg)
	
	# Avatar (emoji aleatorio)
	var avatar = Label.new()
	var emojis = ["😅", "😂", "🤔", "😢", "🙄", "😤", "🤷‍♂️", "😬"]
	avatar.text = emojis[randi() % emojis.size()]
	avatar.add_theme_font_size_override("font_size", 40)
	avatar.position = Vector2(10, 10)
	avatar.size = Vector2(80, 80)
	avatar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(avatar)
	
	# Nombre del jugador
	var name_label = Label.new()
	name_label.text = name + ":"
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color.CYAN)
	name_label.position = Vector2(100, 10)
	name_label.size = Vector2(200, 30)
	panel.add_child(name_label)
	
	# Diálogo
	var dialogue_label = Label.new()
	dialogue_label.text = dialogue
	dialogue_label.add_theme_font_size_override("font_size", 14)
	dialogue_label.add_theme_color_override("font_color", Color.WHITE)
	dialogue_label.position = Vector2(100, 40)
	dialogue_label.size = Vector2(680, 50)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(dialogue_label)
	
	return panel

func _on_final_continue_pressed():
	print("MarkingMiniGame: Finalizando entrenamiento con diálogo completado")
	
	# Ejecutar todo el proceso de finalización
	complete_training_success()
	
	# Pequeño delay antes de cambiar escena para mostrar logs
	await get_tree().create_timer(0.5).timeout
	
	# Cambiar a la escena del menú de entrenamiento
	get_tree().change_scene_to_file("res://scenes/TrainingMenu.tscn")

# === FUNCIÓN DE TESTING ===
func test_complete_all_levels():
	print("🔥 CHEAT ACTIVADO: Completando todos los niveles instantáneamente...")
	
	# Ocultar todos los paneles
	instruction_panel.visible = false
	result_panel.visible = false
	if countdown_label:
		countdown_label.visible = false
	if level_transition_panel:
		level_transition_panel.visible = false
	
	# Detener cualquier juego activo
	game_active = false
	countdown_active = false
	
	# Marcar todos los niveles como completados
	for i in range(max_levels):
		level_completed[i] = true
	
	# Establecer al nivel 3 y simular finalización exitosa
	current_level = max_levels
	
	# Mostrar el panel de resultado del nivel 3 completado
	result_panel.visible = true
	var result_label = result_panel.get_node("ResultLabel")
	result_label.text = "🔥 CHEAT: ¡Todos los niveles completados! 🔥"
	result_label.modulate = Color.GOLD
	
	# Mostrar botón de finalizar entrenamiento
	next_level_button.visible = true
	next_level_button.text = "FINALIZAR ENTRENAMIENTO"
	continue_button.visible = false
	retry_button.visible = false
	
	print("🎯 TESTING: Ahora puedes hacer clic en 'FINALIZAR ENTRENAMIENTO' para probar el diálogo final")
