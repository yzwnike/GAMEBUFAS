extends Control

# Minijuego de pases vs caos - "Pases de Precisión vs Caos Canino"
# Vista de arriba donde debes hacer pases precisos mientras perros corren caóticamente

@onready var game_area = $GameArea
@onready var ball = $GameArea/Ball
@onready var timer_label = $UI/HUD/TimerLabel
@onready var level_label = $UI/HUD/LevelLabel
@onready var passes_label = $UI/HUD/PassesLabel
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

# Sistema de niveles
var current_level = 1
var max_levels = 3
var level_completed = [false, false, false]
var game_time = 30.0  # 30 segundos por nivel

# Variables del juego
var game_active = false
var time_remaining = 0.0
var passes_completed = 0
var passes_attempted = 0
var target_passes = 10  # Objetivo: 10 pases exitosos
var success_threshold = 7  # Mínimo para aprobar

# Jugadores y perros
var players = []
var dogs = []
var num_players = 4
var num_dogs = 2  # Inicia con 2 perros, aumenta por nivel

# Variables del balón
var ball_position = Vector2.ZERO
var ball_target = null
var ball_moving = false
var ball_speed = 200.0

# Efectos de sonido y visuales
var bark_timer = 0.0
var screen_shake_timer = 0.0
var screen_shake_intensity = 0.0

signal training_completed(success: bool)

func _ready():
	print("ChaosPassingMiniGame: Iniciando minijuego de pases vs caos")
	setup_ui()
	setup_game_area()
	game_active = false

func setup_ui():
	result_panel.visible = false
	
	# Configurar el nivel actual
	level_label.text = "NIVEL " + str(current_level) + "/" + str(max_levels)
	passes_label.text = "PASES: 0/" + str(target_passes)
	accuracy_label.text = "PRECISIÓN: 0%"
	
	# Configurar el texto de instrucciones según el nivel
	if current_level == 1:
		instruction_panel.visible = true
		instruction_text.text = "🐕 PASES vs CAOS CANINO - NIVEL 1\n\n" + \
			"OBJETIVO: Completar " + str(target_passes) + " pases precisos\n" + \
			"CONTROLES: Click en jugadores para pasar el balón\n" + \
			"¡CUIDADO!: Si un perro toca el balón, PIERDES\n" + \
			"REQUISITO: Mínimo " + str(success_threshold) + " pases exitosos\n" + \
			"DURACIÓN: 30 segundos\n\n" + \
			"¡Evita a los perros que rondan el cuadrado!"
	else:
		instruction_panel.visible = true
		var difficulty = ["FÁCIL", "MEDIO", "DIFÍCIL"][current_level - 1]
		instruction_text.text = "🐕 NIVEL " + str(current_level) + " - " + difficulty + "\n\n" + \
			"¡Más perros y más caos!\n" + \
			"Los ladridos serán más intensos.\n\n" + \
			"¡Presiona INICIAR para continuar!"
	
	start_button.pressed.connect(_on_start_pressed)
	
	# Conectar botones del resultado
	retry_button.pressed.connect(_on_retry_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	next_level_button.pressed.connect(_on_next_level_pressed)
	next_level_button.visible = false
	
	# Configurar fondo
	setup_background()

func setup_background():
	# Fondo verde campo de fútbol
	background.color = Color(0.2, 0.8, 0.3, 1.0)

func setup_game_area():
	var game_center = game_area.size / 2
	
	# Limpiar jugadores y perros anteriores
	for player in players:
		if player and is_instance_valid(player):
			player.queue_free()
	for dog in dogs:
		if dog and is_instance_valid(dog):
			dog.queue_free()
	
	players.clear()
	dogs.clear()
	
	# Crear jugadores en cuadrado perfecto centrado en el GameArea
	var center = game_area.size / 2
	var square_size = 200.0  # Lado del cuadrado
	var half_square = square_size / 2
	
	var player_positions = [
		Vector2(center.x - half_square, center.y - half_square),  # Jugador 1 - Esquina superior izquierda
		Vector2(center.x + half_square, center.y - half_square),  # Jugador 2 - Esquina superior derecha
		Vector2(center.x - half_square, center.y + half_square),  # Jugador 3 - Esquina inferior izquierda
		Vector2(center.x + half_square, center.y + half_square)   # Jugador 4 - Esquina inferior derecha
	]
	
	for i in range(num_players):
		var player = create_player(player_positions[i], i + 1)
		players.append(player)
		game_area.add_child(player)
	
	# Crear perros según el nivel - posicionarlos erráticamente dentro del cuadrado
	num_dogs = current_level + 1  # Nivel 1: 2 perros, Nivel 2: 3 perros, Nivel 3: 4 perros
	for i in range(num_dogs):
		# Posicionar perros aleatoriamente dentro del área del cuadrado expandida
		var dog_pos = Vector2(
			randf_range(center.x - half_square - 50, center.x + half_square + 50),
			randf_range(center.y - half_square - 50, center.y + half_square + 50)
		)
		
		var dog = create_dog(dog_pos, i + 1)
		dogs.append(dog)
		game_area.add_child(dog)
	
	# Configurar balón
	setup_ball()

func create_player(pos: Vector2, number: int) -> Control:
	var player = Control.new()
	player.position = pos
	player.set_meta("player_number", number)
	
	# Sprite del jugador (círculo azul)
	var sprite = ColorRect.new()
	sprite.size = Vector2(40, 40)
	sprite.color = Color(0.2, 0.5, 1.0, 0.9)
	sprite.position = Vector2(-20, -20)
	player.add_child(sprite)
	
	# Borde blanco
	var border = ColorRect.new()
	border.size = Vector2(44, 44)
	border.color = Color.WHITE
	border.position = Vector2(-22, -22)
	player.add_child(border)
	player.move_child(border, 0)
	
	# Número del jugador
	var label = Label.new()
	label.text = str(number)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.position = Vector2(-8, -12)
	sprite.add_child(label)
	
	return player

func create_dog(pos: Vector2, number: int) -> Control:
	var dog = Control.new()
	dog.position = pos
	
	# Sprite del perro (círculo naranja con emoji)
	var sprite = ColorRect.new()
	sprite.size = Vector2(35, 35)
	sprite.color = Color(1.0, 0.6, 0.2, 0.9)
	sprite.position = Vector2(-17.5, -17.5)
	dog.add_child(sprite)
	
	# Borde
	var border = ColorRect.new()
	border.size = Vector2(39, 39)
	border.color = Color(0.8, 0.4, 0.1)
	border.position = Vector2(-19.5, -19.5)
	dog.add_child(border)
	dog.move_child(border, 0)
	
	# Emoji de perro
	var emoji = Label.new()
	emoji.text = "🐕"
	emoji.add_theme_font_size_override("font_size", 20)
	emoji.position = Vector2(-10, -15)
	sprite.add_child(emoji)
	
	# Variables de movimiento errático del perro
	dog.set_meta("speed", randf_range(80, 120) * (1.0 + current_level * 0.2))  # Velocidad de movimiento
	dog.set_meta("direction", Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized())  # Dirección inicial aleatoria
	dog.set_meta("direction_timer", 0.0)  # Timer para cambiar dirección
	dog.set_meta("bark_timer", randf_range(1.0, 3.0))
	dog.set_meta("square_center", game_area.size / 2)  # Centro del cuadrado para mantener el área
	dog.set_meta("square_size", 200.0)  # Tamaño del cuadrado de juego
	
	# Variables para comportamiento bouncing y cierre de espacios
	dog.set_meta("behavior_type", get_dog_behavior_for_level(number - 1))  # Tipo de comportamiento según nivel (number-1 porque number va de 1 a N)
	dog.set_meta("bounce_direction", Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized())  # Dirección de bouncing
	dog.set_meta("alternating_timer", 0.0)  # Timer para alternar comportamientos
	dog.set_meta("alternating_state", "bouncing")  # Estado actual para perros alternantes
	
	return dog

func get_dog_behavior_for_level(dog_index: int) -> String:
	"""Determinar comportamiento del perro según el nivel y su índice"""
	match current_level:
		1:
			# Nivel 1: Todos los perros hacen bouncing
			return "bouncing"
		2:
			# Nivel 2: 2 perros bouncing, 1 perro cierra espacios
			if dog_index < 2:
				return "bouncing"
			else:
				return "gap_closing"
		3:
			# Nivel 3: 2 perros bouncing, 1 cierra espacios, 1 alterna
			if dog_index < 2:
				return "bouncing"
			elif dog_index == 2:
				return "gap_closing"
			else:
				return "alternating"
		_:
			return "bouncing"

func handle_bouncing_movement(dog: Control, delta: float) -> void:
	"""Manejar movimiento de rebote tipo logo de Windows"""
	var bounce_direction = dog.get_meta("bounce_direction")
	var speed = dog.get_meta("speed")
	var square_center = dog.get_meta("square_center")
	var square_size = dog.get_meta("square_size")
	
	# Calcular nueva posición
	var new_pos = dog.position + bounce_direction * speed * delta
	
	# Límites del cuadrado
	var left_limit = square_center.x - square_size / 2
	var right_limit = square_center.x + square_size / 2
	var top_limit = square_center.y - square_size / 2
	var bottom_limit = square_center.y + square_size / 2
	
	# Verificar rebotes y cambiar dirección
	if new_pos.x <= left_limit or new_pos.x >= right_limit:
		bounce_direction.x *= -1  # Rebotar horizontalmente
		new_pos.x = clamp(new_pos.x, left_limit, right_limit)
	
	if new_pos.y <= top_limit or new_pos.y >= bottom_limit:
		bounce_direction.y *= -1  # Rebotar verticalmente
		new_pos.y = clamp(new_pos.y, top_limit, bottom_limit)
	
	# Actualizar posición y dirección
	dog.position = new_pos
	dog.set_meta("bounce_direction", bounce_direction)

func handle_gap_closing_movement(dog: Control, delta: float) -> void:
	"""Manejar movimiento de cierre de espacios entre jugadores"""
	var speed = dog.get_meta("speed")
	var direction_timer = dog.get_meta("direction_timer", 0.0)
	var current_direction = dog.get_meta("direction")
	
	# Buscar el espacio más grande entre jugadores
	var largest_gap = 0.0
	var gap_center = Vector2.ZERO
	var found_gap = false
	
	for i in range(players.size()):
		for j in range(i + 1, players.size()):
			var gap_distance = players[i].position.distance_to(players[j].position)
			if gap_distance > largest_gap:
				largest_gap = gap_distance
				gap_center = (players[i].position + players[j].position) / 2
				found_gap = true
	
	# Dirigirse hacia el centro del espacio más grande
	var target_direction = current_direction
	if found_gap:
		target_direction = (gap_center - dog.position).normalized()
	
	# Añadir algo de movimiento errático
	direction_timer += delta
	if direction_timer > randf_range(0.5, 1.5):
		# Cambio errático ocasional
		var erratic_component = Vector2(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3))
		target_direction = (target_direction + erratic_component).normalized()
		direction_timer = 0.0
	
	# Mover el perro
	var new_pos = dog.position + target_direction * speed * delta
	
	# Mantener dentro de los límites del cuadrado
	var square_center = dog.get_meta("square_center")
	var square_size = dog.get_meta("square_size")
	new_pos.x = clamp(new_pos.x, square_center.x - square_size / 2, square_center.x + square_size / 2)
	new_pos.y = clamp(new_pos.y, square_center.y - square_size / 2, square_center.y + square_size / 2)
	
	dog.position = new_pos
	dog.set_meta("direction", target_direction)
	dog.set_meta("direction_timer", direction_timer)

func setup_ball():
	# Solo emoji del balón, más grande y visible
	var emoji = Label.new()
	emoji.text = "⚽"
	emoji.add_theme_font_size_override("font_size", 24)
	emoji.position = Vector2(-12, -12)
	ball.add_child(emoji)
	
	# Posicionar balón en el primer jugador
	if players.size() > 0:
		ball.position = players[0].position
		ball_position = players[0].position
	
	# Asegurar que el balón esté por encima de todo
	ball.z_index = 10

func _on_start_pressed():
	instruction_panel.visible = false
	start_game()

func start_game():
	game_active = true
	time_remaining = game_time
	passes_completed = 0
	passes_attempted = 0
	update_ui()

func _process(delta):
	if not game_active:
		return
	
	# Actualizar tiempo
	time_remaining -= delta
	if time_remaining <= 0:
		end_game()
		return
	
	# Mover perros
	move_dogs(delta)
	
	# Mover balón si está en movimiento
	if ball_moving:
		move_ball(delta)
	
	# Efectos de sonido y visuales
	update_effects(delta)
	
	# Actualizar UI
	update_ui()

# Detectar input del mouse global
func _input(event):
	if not game_active:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Convertir posición global del mouse a posición local del GameArea
		var local_pos = event.position - game_area.global_position
		handle_click_at_position(local_pos)

func move_dogs(delta):
	for dog in dogs:
		if not is_instance_valid(dog):
			continue

		# Obtener comportamiento del perro
		var behavior_type = dog.get_meta("behavior_type")
		
		# Ejecutar comportamiento según tipo
		match behavior_type:
			"bouncing":
				handle_bouncing_movement(dog, delta)
			"gap_closing":
				handle_gap_closing_movement(dog, delta)
			"alternating":
				handle_alternating_movement(dog, delta)
			_:
				# Comportamiento por defecto: bouncing
				handle_bouncing_movement(dog, delta)

		# Ladrar ocasionalmente
		var bark_timer = dog.get_meta("bark_timer") - delta
		if bark_timer <= 0:
			trigger_bark_effect()
			dog.set_meta("bark_timer", randf_range(2.0, 4.0))
		else:
			dog.set_meta("bark_timer", bark_timer)

func handle_alternating_movement(dog: Control, delta: float) -> void:
	"""Manejar movimiento alternante entre bouncing y gap_closing"""
	var alternating_timer = dog.get_meta("alternating_timer", 0.0)
	var alternating_state = dog.get_meta("alternating_state", "bouncing")
	
	# Alternar cada 3-5 segundos
	alternating_timer += delta
	if alternating_timer > randf_range(3.0, 5.0):
		if alternating_state == "bouncing":
			alternating_state = "gap_closing"
		else:
			alternating_state = "bouncing"
		alternating_timer = 0.0
		print("🐕 Perro alternante cambiando a: ", alternating_state)
	
	# Ejecutar comportamiento actual
	if alternating_state == "bouncing":
		handle_bouncing_movement(dog, delta)
	else:
		handle_gap_closing_movement(dog, delta)
	
	# Actualizar metadatos
	dog.set_meta("alternating_timer", alternating_timer)
	dog.set_meta("alternating_state", alternating_state)

func move_ball(delta):
	if not ball_target:
		ball_moving = false
		return
	
	var direction = (ball_target.position - ball.position).normalized()
	var distance = ball.position.distance_to(ball_target.position)
	
	if distance < 10.0:
		# Balón ha llegado al jugador
		ball.position = ball_target.position
		ball_moving = false
		passes_completed += 1
		print("¡Pase completado! Total: ", passes_completed)
	else:
		# Mover balón hacia el objetivo
		ball.position += direction * ball_speed * delta
		
		# Verificar si algún perro intercepta el balón - PERDIDA INMEDIATA
		for dog in dogs:
			if is_instance_valid(dog) and ball.position.distance_to(dog.position) < 25.0:
				# ¡Interceptado! - PIERDES INMEDIATAMENTE
				ball_moving = false
				ball.position = dog.position
				trigger_interception_effect()
				print("¡BALÓN INTERCEPTADO - PIERDES EL NIVEL!")
				# Reiniciar nivel inmediatamente
				restart_level()
				return

# Manejar click en una posición específica - detectar jugador más cercano
func handle_click_at_position(click_pos: Vector2):
	print("Click detectado en posición: ", click_pos)
	print("GameArea global_position: ", game_area.global_position)
	print("Ball position: ", ball.position)
	
	if not game_active:
		print("Juego no activo")
		return
	
	if ball_moving:
		print("Balón ya se está moviendo")
		return
	
	# Encontrar el jugador más cercano al click
	var closest_player = null
	var closest_distance = 999999.0
	
	for player in players:
		if not is_instance_valid(player):
			continue
			
		var distance = click_pos.distance_to(player.position)
		print("Distancia a jugador ", player.get_meta("player_number"), ": ", distance)
		if distance < closest_distance:
			closest_distance = distance
			closest_player = player
	
	# Solo procesar si el click está cerca de un jugador (radio de 60 píxeles - más tolerante)
	if closest_player == null or closest_distance > 60.0:
		print("Click fuera de rango de jugadores. Distancia más cercana: ", closest_distance)
		return
	
	print("Jugador más cercano encontrado a distancia: ", closest_distance)
	var player_num = closest_player.get_meta("player_number")
	print("Jugador seleccionado: ", player_num)
	
	# Verificar que no estés clickeando el mismo jugador que tiene el balón (más tolerante)
	var ball_distance_to_target = ball.position.distance_to(closest_player.position)
	print("Distancia del balón al jugador objetivo: ", ball_distance_to_target)
	
	if ball_distance_to_target < 40.0:
		print("No puedes pasar a ti mismo - jugador muy cerca del balón")
		return
	
	# FORZAR inicio del pase para testing - quitar validaciones restrictivas
	print("¡INICIANDO PASE FORZADO para testing!")
	ball_target = closest_player
	ball_moving = true
	passes_attempted += 1
	print("¡Pase iniciado hacia jugador ", player_num, " en posición: ", closest_player.position)
	print("ball_moving establecido a: ", ball_moving)
	print("ball_target establecido a: ", ball_target)

func trigger_bark_effect():
	# Efecto de ladrido: shake de pantalla leve
	screen_shake_timer = 0.3
	screen_shake_intensity = randf_range(2.0, 5.0) * current_level
	print("¡WOOF! 🐕")

func trigger_interception_effect():
	# Efecto más intenso cuando interceptan
	screen_shake_timer = 0.8
	screen_shake_intensity = 8.0 * current_level

# Reiniciar nivel inmediatamente tras interceptación
func restart_level():
	print("¡REINICIANDO NIVEL TRAS INTERCEPTACIÓN!")
	game_active = false
	
	# Esperar un breve momento para que el jugador vea la interceptación
	await get_tree().create_timer(1.5).timeout
	
	# Mostrar pantalla de pérdida
	show_loss_screen("interceptación")

func update_effects(delta):
	# Screen shake por ladridos - aplicar a los elementos dentro del GameArea, no al GameArea mismo
	if screen_shake_timer > 0:
		screen_shake_timer -= delta
		var shake_offset = Vector2(
			randf_range(-screen_shake_intensity, screen_shake_intensity),
			randf_range(-screen_shake_intensity, screen_shake_intensity)
		)
		# Aplicar shake solo al campo de fondo, no a todo el GameArea
		var field_bg = game_area.get_node("FieldBackground")
		if field_bg:
			field_bg.position = shake_offset
	else:
		# Restaurar posición normal del campo de fondo
		var field_bg = game_area.get_node("FieldBackground")
		if field_bg:
			field_bg.position = Vector2.ZERO

func update_ui():
	var minutes = int(time_remaining) / 60
	var seconds = int(time_remaining) % 60
	timer_label.text = "TIEMPO: %02d:%02d" % [minutes, seconds]
	
	passes_label.text = "PASES: %d/%d" % [passes_completed, target_passes]
	
	var accuracy = 0
	if passes_attempted > 0:
		accuracy = int((float(passes_completed) / float(passes_attempted)) * 100)
	accuracy_label.text = "PRECISIÓN: %d%%" % accuracy

func end_game():
	game_active = false
	# Verificar si se alcanzó el umbral mínimo
	var success = passes_completed >= success_threshold
	if success:
		show_results()  # Mostrar pantalla de éxito
	else:
		show_loss_screen("tiempo")  # Mostrar pantalla de pérdida por tiempo

func show_results():
	result_panel.visible = true
	var result_text = result_panel.get_node("ResultText")
	
	var success = passes_completed >= success_threshold
	var accuracy = 0
	if passes_attempted > 0:
		accuracy = int((float(passes_completed) / float(passes_attempted)) * 100)
	
	if success:
		level_completed[current_level - 1] = true
		if passes_completed >= target_passes:
			result_text.text = "🏆 ¡PERFECTO!\n\n" + \
				"Pases completados: %d/%d\n" % [passes_completed, target_passes] + \
				"Precisión: %d%%\n\n" % accuracy + \
				"¡Has mantenido la calma total ante el caos!"
		else:
			result_text.text = "✅ ¡BIEN HECHO!\n\n" + \
				"Pases completados: %d/%d\n" % [passes_completed, target_passes] + \
				"Precisión: %d%%\n\n" % accuracy + \
				"Solo te desconcentraste un poco."
	else:
		result_text.text = "😅 NECESITAS PRÁCTICA\n\n" + \
			"Pases completados: %d/%d\n" % [passes_completed, target_passes] + \
			"Precisión: %d%%\n\n" % accuracy + \
			"Te contagiaste del caos canino.\n¡Más paciencia la próxima vez!"
	
	# Configurar botones
	if current_level < max_levels and success:
		next_level_button.visible = true
		continue_button.visible = false
		retry_button.visible = false
	else:
		next_level_button.visible = false
		continue_button.visible = true
		retry_button.visible = false

# Mostrar pantalla de pérdida - solo botón reiniciar
func show_loss_screen(reason: String):
	result_panel.visible = true
	var result_text = result_panel.get_node("ResultText")
	
	var accuracy = 0
	if passes_attempted > 0:
		accuracy = int((float(passes_completed) / float(passes_attempted)) * 100)
	
	# Mensaje según la razón de la pérdida
	if reason == "interceptación":
		result_text.text = "🐕 ¡HAS PERDIDO!\n\n" + \
			"¡Un perro interceptó el balón!\n\n" + \
			"Pases realizados: %d\n" % passes_completed + \
			"Precisión: %d%%\n\n" % accuracy + \
			"¡Inténtalo de nuevo!"
	else:
		result_text.text = "⏰ ¡TIEMPO AGOTADO!\n\n" + \
			"No lograste %d pases exitosos\n" % success_threshold + \
			"en 30 segundos.\n\n" + \
			"Pases realizados: %d\n" % passes_completed + \
			"Precisión: %d%%\n\n" % accuracy + \
			"¡Inténtalo de nuevo!"
	
	# Solo mostrar botón de reiniciar
	retry_button.visible = true
	continue_button.visible = false
	next_level_button.visible = false

func _on_retry_pressed():
	result_panel.visible = false
	setup_game_area()
	setup_ui()

func _on_next_level_pressed():
	current_level += 1
	result_panel.visible = false
	setup_game_area()
	setup_ui()

func _on_continue_pressed():
	# Calcular éxito general
	var total_success = true
	for completed in level_completed:
		if not completed:
			total_success = false
			break
	
	print("ChaosPassingMiniGame: Entrenamiento completado - Éxito: ", total_success)
	training_completed.emit(total_success)
	
	# Ir al post-entrenamiento (genérico para todos los equipos)
	get_tree().change_scene_to_file("res://scenes/PostTrainingDialogueScene.tscn")
