extends Control

# Minijuego de resistencia horizontal - Inter de Panzones
# Controla tu stamina mientras pasas el balón en el campo

@onready var player1 = $GameField/Player1
@onready var player2 = $GameField/Player2
@onready var ball = $GameField/Ball
@onready var game_field = $GameField
@onready var panzones_group = $GameField/Panzones
@onready var goal_area = $GameField/GoalArea
@onready var goalkeeper = $GameField/GoalArea/Goalkeeper
@onready var aim_arrow = $GameField/AimArrow

@onready var progress_bar = $UI/ProgressBar
@onready var level_label = $UI/LevelLabel
@onready var timer_label = $UI/TimerLabel
@onready var stamina_bar = $UI/StaminaBar
@onready var instruction_panel = $UI/InstructionPanel
@onready var instruction_text = $UI/InstructionPanel/InstructionText
@onready var start_button = $UI/InstructionPanel/StartButton
@onready var result_panel = $UI/ResultPanel
@onready var result_text = $UI/ResultPanel/ResultText
@onready var continue_button = $UI/ResultPanel/ContinueButton

# Variables de jugadores
var current_player = 1  # 1 o 2
var player_speed = 200.0
var ball_speed = 400.0
var slow_speed = 50.0  # Velocidad cuando stamina = 0

# Variables de IA para crear espacios
var ai_target_position = Vector2.ZERO
var ai_movement_timer = 0.0
var ai_change_direction_interval = 5.0  # Cambia dirección cada 5 segundos para ser más errático
var ai_current_behavior = "seeking_space"  # "seeking_space", "orbiting", "random_zone", "waiting"
var ai_behavior_timer = 0.0
var ai_speed_multiplier = 1.0

# Sistema de stamina
var max_stamina = 100.0
var current_stamina = 100.0
var stamina_drain_rate = 15.0  # Por segundo al moverse con balón
var stamina_sprint_drain_rate = 30.0  # Por segundo al sprintar con balón
var stamina_regen_rate = 25.0  # Por segundo sin balón
var min_speed_multiplier = 0.3  # Velocidad mínima cuando no hay stamina

# Variables del campo
# El campo es estático
var field_scroll_speed = 0.0  # Desactivado
var field_moving = false
var level_duration = 60.0  # Segundos por nivel, ajustado para el juego sin movimiento
var current_level = 1
var max_levels = 3
var level_timer = 0.0

# Variables del balón
var ball_with_player = true
var ball_target = Vector2.ZERO
var ball_moving = false


# Variables de los panzones (comentadas temporalmente)
# var panzones = []
# var panzon_speed = 80.0
# var panzon_spawn_timer = 0.0
# var panzon_spawn_interval = 3.0

# Variables del juego
var game_active = false
var game_completed = false
var field_progress = 0.0  # 0 a 1, progreso hacia la portería
var total_field_height = 1200.0  # Altura total del campo
var game_time = 180.0  # 3 minutos de juego
var time_remaining = 180.0

# Señales
signal training_completed(success: bool)

func _ready():
	print("StaminaMiniGame2D: Iniciando minijuego de avance vertical")
	setup_game()
	show_tutorial()

func _input(event):
	# Detectar pausa con Escape
	if event.is_action_pressed("ui_pause"):
		if PauseManager:
			PauseManager.toggle_pause()

func setup_game():
	# Configurar posiciones iniciales
	player1.position = Vector2(-50, 0)
	player2.position = Vector2(50, 0)
	ball.position = player1.position
	
	# Configurar UI inicial
	progress_bar.max_value = 1.0
	progress_bar.value = 0.0
	stamina_bar.max_value = max_stamina
	stamina_bar.value = current_stamina
	update_level_display()
	
	# Configurar portería en el lateral derecho del campo
	var viewport_size = get_viewport().get_visible_rect().size
	var half_width = viewport_size.x / 2
	goal_area.position = Vector2(half_width - 100, 0)
	goalkeeper.position = Vector2(0, 0)
	
	# Configurar flecha de apuntado (inicialmente oculta)
	aim_arrow.visible = false

	# Conectar señales
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)

	print("StaminaMiniGame2D: Configuración inicial completada")

func start_game():
	game_active = true
	current_level = 1
	level_timer = 0.0
	field_progress = 0.0
	field_moving = true
	print("StaminaMiniGame2D: ¡Juego iniciado!")

func _process(delta):
	if not game_active or game_completed:
		return

	# Actualizar el temporizador de nivel
	level_timer += delta
	if level_timer >= level_duration:
		# Detener el desplazamiento del campo y activar la portería
		field_moving = false
	
	# Actualizar timer del juego
	time_remaining -= delta
	update_timer_display()
	
	# Verificar si se acabó el tiempo sin completar
	if time_remaining <= 0:
		complete_game(false)  # Fallo por tiempo
	
	# Campo estático, sin desplazamiento

	# Calcula el progreso como función del tiempo
	progress_bar.value = 1.0 - (time_remaining / game_time)

	# Actualizar movimiento del balón si está en movimiento
	if ball_moving:
		var direction = (ball_target - ball.position).normalized()
		ball.position += direction * ball_speed * delta
		if ball.position.distance_to(ball_target) < 10:
			ball_moving = false
	
	# Chequear si el balón alcanza la portería (lateral derecha)
	var goal_global_pos = goal_area.global_position + goalkeeper.position
	if ball.global_position.distance_squared_to(goal_global_pos) < 2500:
		complete_game(true)

func _physics_process(delta):
	if not game_active or game_completed:
		return
	
	handle_player_movement(delta)
	handle_ai_movement(delta)
	check_collisions()
	update_stamina_ui()

func handle_player_movement(delta):
	var input_vector = Vector2.ZERO
	
	# Controlar al jugador con el balón
	var player = player1 if current_player == 1 else player2
	
	# Controles WASD y flechas
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_vector.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_vector.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_vector.y -= 1
	
	# Detectar sprint (solo si tienes balón)
	var is_sprinting = ball_with_player and (Input.is_action_pressed("ui_accept") or Input.is_action_pressed("sprint"))
	
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		
		# Si tienes el balón, se drena stamina al moverse
		if ball_with_player:
			var effective_speed
			if current_stamina <= 0:
				# Sin stamina, muy lento (más lento que panzones)
				effective_speed = slow_speed
			else:
				# Con stamina, velocidad normal
				effective_speed = player_speed
				
				if is_sprinting:
					effective_speed = player_speed * 1.5
					current_stamina -= stamina_sprint_drain_rate * delta
				else:
					current_stamina -= stamina_drain_rate * delta
				
				current_stamina = max(current_stamina, 0)
			
			player.position += input_vector * effective_speed * delta
		else:
			# Sin balón, movimiento normal sin coste
			player.position += input_vector * player_speed * delta

	# Regenerar stamina si no se tiene el balón
	if not ball_with_player:
		current_stamina += stamina_regen_rate * delta
		current_stamina = min(current_stamina, max_stamina)

	# Limitar jugador dentro del campo
	limit_player_to_field()
	
	# Actualizar la posición del balón si está con el jugador
	if ball_with_player:
		ball.position = player.position

	# Control de pase movido a _input()

	# Mostrar la flecha de apuntado
	aim_arrow.visible = ball_with_player
	if ball_with_player:
		aim_arrow.position = player.position
		var mouse_pos = get_global_mouse_position()
		var player_global_pos = player.global_position
		var direction_to_cursor = (mouse_pos - player_global_pos)
		aim_arrow.rotation = direction_to_cursor.angle()
	

func update_stamina_ui():
	# Actualizar barra de stamina
	stamina_bar.value = current_stamina
	
	# Cambiar color según el nivel de stamina
	if current_stamina < 20:
		stamina_bar.modulate = Color.RED
		# Reproducir sonido de stamina baja (solo una vez por caida)
		if current_stamina > 0 and current_stamina < 20:
			# Solo sonar una vez cuando baja de 20
			var should_play_low_stamina = not has_meta("low_stamina_sound_played")
			if should_play_low_stamina and GameAudioUtils:
				GameAudioUtils.play_stamina_low()
				set_meta("low_stamina_sound_played", true)
	elif current_stamina < 50:
		stamina_bar.modulate = Color.YELLOW
	else:
		stamina_bar.modulate = Color.GREEN
		# Resetear el flag cuando la stamina se recupera
		if has_meta("low_stamina_sound_played"):
			remove_meta("low_stamina_sound_played")

func limit_player_to_field():
	var player = player1 if current_player == 1 else player2
	var pos = player.position
	# Obtener el tamaño real de la pantalla visible
	var viewport_size = get_viewport().get_visible_rect().size
	var half_width = viewport_size.x / 2
	var half_height = viewport_size.y / 2
	
	# Límites del campo = exactamente lo visible en pantalla con margen pequeño
	pos.x = clamp(pos.x, -half_width + 50, half_width - 50)
	pos.y = clamp(pos.y, -half_height + 50, half_height - 50)
	player.position = pos

func handle_ai_movement(delta):
	# Obtener el jugador que no está activo (el compañero)
	var ai_player = player2 if current_player == 1 else player1
	
	# Actualizar timers
	ai_movement_timer += delta
	ai_behavior_timer += delta
	
	# LÓGICA CORREGIDA:
	if ball_with_player:
		# Si alguien tiene el balón, comportamiento errático para crear espacios
		erratic_space_seeking_behavior(ai_player, delta)
	elif ball_moving:
		# Si el balón se está moviendo, ir a interceptarlo
		move_to_intercept_ball(ai_player, delta)
	else:
		# BALÓN SUELTO - ir directamente por él pero de forma inteligente
		move_to_ball_intelligently(ai_player, delta)
	
	# Aplicar los mismos límites del campo para el AI
	var pos = ai_player.position
	var viewport_size = get_viewport().get_visible_rect().size
	var half_width = viewport_size.x / 2
	var half_height = viewport_size.y / 2
	
	pos.x = clamp(pos.x, -half_width + 50, half_width - 50)
	pos.y = clamp(pos.y, -half_height + 50, half_height - 50)
	ai_player.position = pos

func create_passing_options(ai_player: Node2D, delta: float):
	# Crear espacios y opciones de pase moviéndose inteligentemente
	var active_player = player1 if current_player == 1 else player2
	
	# Cambiar objetivo cada cierto tiempo o si no tiene objetivo
	if ai_movement_timer >= ai_change_direction_interval or ai_target_position == Vector2.ZERO:
		ai_movement_timer = 0.0
		generate_new_ai_target(ai_player, active_player)
	
	# Moverse hacia el objetivo
	if ai_target_position != Vector2.ZERO:
		var direction = (ai_target_position - ai_player.position).normalized()
		var ai_speed = player_speed * 0.7  # Más lento para crear espacios
		ai_player.position += direction * ai_speed * delta
		
		# Si llegó cerca del objetivo, generar uno nuevo
		if ai_player.position.distance_to(ai_target_position) < 40:
			generate_new_ai_target(ai_player, active_player)

func erratic_space_seeking_behavior(ai_player: Node2D, delta: float):
	# Cambia el comportamiento cada ai_change_direction_interval
	if ai_behavior_timer >= ai_change_direction_interval:
		ai_behavior_timer = 0.0
		# Cambia a un comportamiento aleatorio
		var behaviors = ["seeking_space", "orbiting", "random_zone", "waiting"]
		ai_current_behavior = behaviors[randi() % behaviors.size()]

	match ai_current_behavior:
		"seeking_space":
			generate_new_ai_target(ai_player, player1 if current_player == 2 else player2)
			ai_speed_multiplier = 1.0
		"orbiting":
			orbit_around_player(ai_player, delta)
			ai_speed_multiplier = 0.5
		"random_zone":
			move_to_random_zone(ai_player, delta)
			ai_speed_multiplier = 1.5
		"waiting":
			# Quedarse quieto
			ai_speed_multiplier = 0
	
	# Aplicar el movimiento
	if ai_target_position != Vector2.ZERO:
		var direction = (ai_target_position - ai_player.position).normalized()
		ai_player.position += direction * player_speed * ai_speed_multiplier * delta

func generate_new_ai_target(ai_player: Node2D, active_player: Node2D):
	# Generar posiciones que creen buenas opciones de pase en el campo horizontal
	var viewport_size = get_viewport().get_visible_rect().size
	var half_width = viewport_size.x / 2
	var half_height = viewport_size.y / 2
	
	# Opciones de movimiento inteligente para juego horizontal
	var options = []
	
	# 1. Moverse hacia la portería (lateral derecho)
	options.append(Vector2(ai_player.position.x + 100, ai_player.position.y))
	
# 2. Abrirse verticalmente para crear espacios
	if ai_player.position.y > 0:
		options.append(Vector2(ai_player.position.x + 50, -half_height / 2))  # Arriba
	else:
		options.append(Vector2(ai_player.position.x + 50, half_height / 2))   # Abajo
	
	# 3. Crear triángulo con el jugador activo
	var perpendicular = Vector2(active_player.position.y - ai_player.position.y, ai_player.position.x - active_player.position.x).normalized() * 80
	options.append(active_player.position + perpendicular)
	
	# 4. Posición de apoyo atrás
	options.append(Vector2(active_player.position.x - randf_range(50, 100), active_player.position.y + randf_range(-60, 60)))
	
	# Elegir la mejor opción (la más cerca de la portería)
	var best_option = ai_player.position
	var best_score = -999.0
	
	for option in options:
		# Verificar que esté dentro del campo
		if option.x >= -half_width + 60 and option.x <= half_width - 60 and option.y >= -half_height + 60 and option.y <= half_height - 60:
			# Puntuación: priorizar avanzar hacia la portería (derecha)
			var score = option.x  # Mientras más a la derecha, mejor score
			if score > best_score:
				best_score = score
				best_option = option
	
	ai_target_position = best_option

func move_to_intercept_ball(ai_player: Node2D, delta: float):
	# Ir hacia donde va a parar el balón
	var direction = (ball_target - ai_player.position).normalized()
	var ai_speed = player_speed * 1.1  # Un poco más rápido para interceptar
	ai_player.position += direction * ai_speed * delta

func move_to_ball_intelligently(ai_player: Node2D, delta: float):
	# NO ir directamente hacia el balón, sino comportarse erráticamente
	# Llamar al comportamiento errático en lugar de ir directo al balón
	erratic_space_seeking_behavior(ai_player, delta)

func move_to_ball(ai_player: Node2D, delta: float):
	# Ir hacia el balón libre - MÁS RÁPIDO (MANTENER PARA COMPATIBILIDAD)
	var direction = (ball.position - ai_player.position).normalized()
	var ai_speed = player_speed * 1.1  # Más rápido para alcanzar balones sueltos
	ai_player.position += direction * ai_speed * delta
	print("AI moviéndose hacia balón suelto en:", ball.position)

func update_level_display():
	level_label.text = "Nivel: %d/%d" % [current_level, max_levels]


# PANZONES DESHABILITADOS TEMPORALMENTE
#func spawn_panzon():
#	# Spawn de panzones desde arriba del campo - crear programaticamente
#	var new_panzon = CharacterBody2D.new()
#	var sprite = Sprite2D.new()
#	var collision = CollisionShape2D.new()
#	var shape = RectangleShape2D.new()
#	
#	# Configurar sprite
#	sprite.modulate = Color(1, 0.4, 0.4, 1)
#	sprite.scale = Vector2(15, 15)
#	
#	# Configurar colisión
#	shape.size = Vector2(15, 15)
#	collision.shape = shape
#	
#	# Ensamblar nodo
#	new_panzon.add_child(sprite)
#	new_panzon.add_child(collision)
#	new_panzon.position = Vector2(randf_range(-150, 150), -100)
#	
#	panzones_group.add_child(new_panzon)
#	panzones.append({
#		"body": new_panzon,
#		"target_position": Vector2.ZERO,
#		"movement_timer": randf_range(1.0, 3.0),
#		"state": "chase"
#	})

#func handle_panzones_ai(delta):
#	# Spawn de nuevos panzones
#	panzon_spawn_timer += delta
#	if panzon_spawn_timer >= panzon_spawn_interval:
#		spawn_panzon()
#		panzon_spawn_timer = 0.0
#	
#	# Mover panzones existentes
#	for i in range(panzones.size() - 1, -1, -1):
#		var panzon_data = panzones[i]
#		var panzon = panzon_data.body
#		
#		# Los panzones van directamente hacia el balón
#		var direction = (ball.position - panzon.position).normalized()
#		panzon.position += direction * panzon_speed * delta
#		
#		# Eliminar panzones que salen del campo
#		if panzon.position.y > 700:
#			panzon.queue_free()
#			panzones.remove_at(i)

func check_collisions():
	# PANZONES DESHABILITADOS - Chequear colisiones con panzones y el balón
	#for panzon_data in panzones:
	#	var panzon = panzon_data.body
	#	var distance = panzon.position.distance_to(ball.position)
	#	
	#	if distance <= 30:  # Radio de colisión con el balón
	#		handle_collision(panzon)
	#		break
	
	# Chequear si el balón llega a un punto
	if ball_moving:
		if ball.position.distance_to(ball_target) < 10:
			ball_moving = false
			# NO cambiar jugador aquí, ya se cambió al hacer el pase

	# Verificar si el jugador tiene el balón
	if ball_moving == false:
		var player = player1 if current_player == 1 else player2
		if player.position.distance_to(ball.position) < 10:
			ball_with_player = true

#func handle_collision(panzon):
#	# Perder y terminar el juego
#	print("StaminaMiniGame2D: ¡Colisión con panzón! Juego terminado")
#	complete_game(false)

#func get_closest_panzon_position() -> Vector2:
#	var closest_pos = Vector2.ZERO
#	var min_distance = 999.0
#	var current_player_node = player1 if current_player == 1 else player2
#	
#	for panzon_data in panzones:
#		var distance = panzon_data.body.position.distance_to(current_player_node.position)
#		if distance < min_distance:
#			min_distance = distance
#			closest_pos = panzon_data.body.position
#	
#	return closest_pos

func create_collision_effect():
	# Crear un efecto visual temporal de colisión
	# Efecto de parpadeo del fondo
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 0.7, 0.7), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)


func update_timer_display():
	var minutes = int(time_remaining / 60)
	var seconds = int(time_remaining) % 60
	timer_label.text = "Tiempo: %02d:%02d" % [minutes, seconds]

func complete_game(success: bool):
	game_completed = true
	game_active = false
	
	print("StaminaMiniGame2D: Juego completado - Éxito: ", success)

	# Reproducir sonido según el resultado
	if GameAudioUtils:
		if success:
			GameAudioUtils.play_success_sound()
		else:
			GameAudioUtils.play_error_sound()

	# Mostrar resultado
	show_result(success)

	# Emitir señal después de un breve delay
	await get_tree().create_timer(2.0).timeout
	training_completed.emit(success)

func show_result(success: bool):
	var result_string = ""
	if success:
		if current_stamina > 60:
			result_string = "¡EXCELENTE!\n\nResistencia superior\nStamina final: %.0f%%\n\n¡Los panzones no pudieron contigo!" % current_stamina
		elif current_stamina > 30:
			result_string = "¡BIEN!\n\nBuena resistencia\nStamina final: %.0f%%\n\n¡Aguantaste como un campeón!" % current_stamina
		else:
			result_string = "¡APROBADO!\n\nResistencia justa\nStamina final: %.0f%%\n\n¡Por poco, pero lo lograste!" % current_stamina
	else:
		result_string = "¡AGOTADO!\n\nNecesitas más resistencia\nLos panzones te cansaron\n\n¡Inténtalo de nuevo!"
	
	# Mostrar panel de resultado
	result_panel.visible = true
	result_text.text = result_string

# Funciones de tutorial
func show_tutorial():
	"""Mostrar el panel de tutorial al inicio"""
	game_active = false
	instruction_panel.visible = true
	result_panel.visible = false
	print("StaminaMiniGame2D: Tutorial mostrado")

func _on_start_pressed():
	"""Cuando se presiona el botón de iniciar"""
	print("StaminaMiniGame2D: Iniciando juego desde tutorial")
	
	# Reproducir sonido de botón
	if GameAudioUtils:
		GameAudioUtils.play_button_click()
	
	instruction_panel.visible = false
	game_active = true
	time_remaining = game_time
	current_stamina = max_stamina
	update_timer_display()

func _on_continue_pressed():
	"""Cuando se presiona continuar después del resultado"""
	print("StaminaMiniGame2D: Continuando al diálogo post-entrenamiento")
	
	# Reproducir sonido de botón
	if GameAudioUtils:
		GameAudioUtils.play_button_click()
	
	# Cambiar a la escena de diálogo post-entrenamiento
	get_tree().change_scene_to_file("res://scenes/PostTrainingDialogueScene.tscn")

# Control de input para el minijuego 2D
func _input(event):
	# Control de pase con el ratón
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if game_active and not game_completed:
			print("DEBUG: Click detectado, ball_with_player=", ball_with_player)
			if ball_with_player:
				# Reproducir sonido de pase
				if GameAudioUtils:
					GameAudioUtils.play_ball_pass()
				
				# Pasar el balón hacia el cursor
				var mouse_pos = get_global_mouse_position()
				ball_target = game_field.to_local(mouse_pos)
				ball_with_player = false
				ball_moving = true
				# CAMBIAR INMEDIATAMENTE AL OTRO JUGADOR
				current_player = 2 if current_player == 1 else 1
				print("StaminaMiniGame2D: Pase realizado, ahora controlas Player", current_player)
			else:
				# Reproducir sonido de error
				if GameAudioUtils:
					GameAudioUtils.play_error_sound()
				print("DEBUG: No se puede pasar, jugador no tiene balón")
	
	# Salir del minijuego con ESC
	if event.is_action_pressed("ui_cancel"):
		if game_active:
			complete_game(false)
		else:
			# Si estamos en tutorial, salir directamente
			training_completed.emit(false)

func orbit_around_player(ai_player: Node2D, delta: float):
	var active_player = player1 if current_player == 1 else player2
	var direction_to_player = (active_player.position - ai_player.position).normalized()
	var perpendicular_direction = Vector2(-direction_to_player.y, direction_to_player.x)
	ai_target_position = active_player.position + perpendicular_direction * 100  # Órbita de 100 unidades alrededor del jugador

func move_to_random_zone(ai_player: Node2D, delta: float):
	if ai_target_position == Vector2.ZERO or ai_player.position.distance_to(ai_target_position) < 10:
		var viewport_size = get_viewport().get_visible_rect().size
		ai_target_position = Vector2(randi() % int(viewport_size.x) - viewport_size.x / 2, randi() % int(viewport_size.y) - viewport_size.y / 2)  # Posición aleatoria en el campo

