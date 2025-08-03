extends Node3D

# Minijuego de resistencia en 3D - Inter de Panzones
# Primera persona con tutorial como otros minijuegos

@onready var player = $Player
@onready var camera = $Player/Camera3D
@onready var panzones_group = $Panzones
@onready var stamina_bar = $UI/StaminaBar
@onready var stamina_label = $UI/StaminaLabel
@onready var timer_label = $UI/TimerLabel
@onready var instruction_panel = $UI/InstructionPanel
@onready var instruction_text = $UI/InstructionPanel/InstructionText
@onready var start_button = $UI/InstructionPanel/StartButton
@onready var result_panel = $UI/ResultPanel
@onready var result_text = $UI/ResultPanel/ResultText
@onready var continue_button = $UI/ResultPanel/ContinueButton
@onready var crosshair_panel = $UI/CrosshairPanel

# Variables del jugador - Primera persona
var player_speed = 5.0
var sprint_speed = 8.0
var mouse_sensitivity = 0.002
var player_velocity = Vector3.ZERO
var is_sprinting = false

# Sistema de stamina
var max_stamina = 100.0
var current_stamina = 100.0
var stamina_drain_rate = 30.0  # Por segundo al sprintar
var stamina_regen_rate = 20.0  # Por segundo en reposo
var stamina_collision_penalty = 25.0  # Pérdida por colisión

# Variables del juego
var game_time = 60.0  # 60 segundos de juego
var time_remaining = 60.0
var game_active = false
var game_completed = false
var tutorial_shown = false

# Variables de los panzones
var panzones = []
var panzon_speed = 4.0
var panzon_chase_range = 15.0
var panzon_collision_range = 2.5

# Límites del campo
var field_bounds = Vector2(50, 30)  # Tamaño del campo

# Señales
signal training_completed(success: bool)

func _ready():
	print("StaminaMiniGame3D: Iniciando minijuego de resistencia 3D")
	setup_game()
	setup_panzones()
	show_tutorial()

func setup_game():
	# Configurar UI inicial
	stamina_bar.max_value = max_stamina
	stamina_bar.value = current_stamina
	update_timer_display()
	
	# Configurar posición inicial del jugador en el centro del campo
	player.position = Vector3(0, 3, 0)
	
	# Configurar control de mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Conectar señales
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	
	print("StaminaMiniGame3D: Configuración inicial completada")

func setup_panzones():
	# Obtener todos los panzones del grupo
	for child in panzones_group.get_children():
		if child is CharacterBody3D:
			panzones.append({
				"body": child,
				"target_position": Vector3.ZERO,
				"movement_timer": 0.0,
				"state": "patrol"  # patrol, chase
			})
	
	print("StaminaMiniGame3D: Configurados ", panzones.size(), " panzones")

func start_game():
	game_active = true
	print("StaminaMiniGame3D: ¡Juego iniciado!")

func _process(delta):
	if not game_active or game_completed:
		return
	
	# Actualizar tiempo
	time_remaining -= delta
	update_timer_display()
	
	# Verificar condiciones de fin de juego
	if time_remaining <= 0:
		complete_game(true)  # Éxito por sobrevivir
	elif current_stamina <= 0:
		complete_game(false)  # Fallo por agotamiento

func _physics_process(delta):
	if not game_active or game_completed:
		return
	
	handle_player_movement(delta)
	handle_stamina_system(delta)
	handle_panzones_ai(delta)
	check_collisions()

func handle_player_movement(delta):
	var input_vector = Vector3.ZERO
	
	# Obtener input del jugador
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_action_pressed("move_down"):
		input_vector.z += 1
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("move_up"):
		input_vector.z -= 1
	
	# Detectar sprint
	is_sprinting = Input.is_action_pressed("ui_accept") or Input.is_action_pressed("sprint")
	
	# Normalizar input y aplicar velocidad
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		var speed = sprint_speed if (is_sprinting and current_stamina > 0) else player_speed
		player_velocity.x = input_vector.x * speed
		player_velocity.z = input_vector.z * speed
	else:
		# Aplicar fricción
		player_velocity.x = lerp(player_velocity.x, 0.0, delta * 8.0)
		player_velocity.z = lerp(player_velocity.z, 0.0, delta * 8.0)
	
	# Aplicar gravedad (mínima, solo para mantener en el suelo)
	player_velocity.y = -2.0
	
	# Mover el jugador
	player.velocity = player_velocity
	player.move_and_slide()
	
	# Limitar al campo
	limit_player_to_field()

func limit_player_to_field():
	var pos = player.position
	pos.x = clamp(pos.x, -field_bounds.x, field_bounds.x)
	pos.z = clamp(pos.z, -field_bounds.y, field_bounds.y)
	player.position = pos

func handle_stamina_system(delta):
	if is_sprinting and current_stamina > 0 and player_velocity.length() > 0.1:
		# Drenar stamina al sprintar
		current_stamina -= stamina_drain_rate * delta
		current_stamina = max(0, current_stamina)
	else:
		# Regenerar stamina en reposo
		current_stamina += stamina_regen_rate * delta
		current_stamina = min(max_stamina, current_stamina)
	
	# Actualizar UI
	stamina_bar.value = current_stamina
	
	# Cambiar color de la barra según el nivel
	if current_stamina < 20:
		stamina_bar.modulate = Color.RED
	elif current_stamina < 50:
		stamina_bar.modulate = Color.YELLOW
	else:
		stamina_bar.modulate = Color.GREEN

func handle_panzones_ai(delta):
	for panzon_data in panzones:
		var panzon = panzon_data.body
		var distance_to_player = panzon.position.distance_to(player.position)
		
		# Determinar estado del panzon
		if distance_to_player <= panzon_chase_range:
			panzon_data.state = "chase"
		else:
			panzon_data.state = "patrol"
		
		# Movimiento según estado
		var target_velocity = Vector3.ZERO
		
		if panzon_data.state == "chase":
			# Perseguir al jugador
			var direction = (player.position - panzon.position).normalized()
			target_velocity = direction * panzon_speed
		else:
			# Patrullar de manera aleatoria
			panzon_data.movement_timer -= delta
			if panzon_data.movement_timer <= 0:
				# Elegir nueva dirección aleatoria
				panzon_data.target_position = Vector3(
					randf_range(-field_bounds.x * 0.8, field_bounds.x * 0.8),
					1,
					randf_range(-field_bounds.y * 0.8, field_bounds.y * 0.8)
				)
				panzon_data.movement_timer = randf_range(2.0, 4.0)
			
			# Moverse hacia la posición objetivo
			var direction = (panzon_data.target_position - panzon.position).normalized()
			target_velocity = direction * (panzon_speed * 0.5)
		
		# Aplicar velocidad con gravedad
		target_velocity.y = -2.0
		panzon.velocity = target_velocity
		panzon.move_and_slide()
		
		# Mantener los panzones en el campo
		var pos = panzon.position
		pos.x = clamp(pos.x, -field_bounds.x, field_bounds.x)
		pos.z = clamp(pos.z, -field_bounds.y, field_bounds.y)
		panzon.position = pos

func check_collisions():
	for panzon_data in panzones:
		var panzon = panzon_data.body
		var distance = panzon.position.distance_to(player.position)
		
		if distance <= panzon_collision_range:
			# Colisión detectada
			handle_collision()
			break

func handle_collision():
	# Penalizar stamina por colisión
	current_stamina -= stamina_collision_penalty
	current_stamina = max(0, current_stamina)
	
	# Empujar al jugador ligeramente
	var push_direction = (player.position - get_closest_panzon_position()).normalized()
	player.position += push_direction * 2.0
	
	# Efecto visual (color rojo temporal)
	create_collision_effect()
	
	print("StaminaMiniGame3D: ¡Colisión! Stamina reducida")

func get_closest_panzon_position() -> Vector3:
	var closest_pos = Vector3.ZERO
	var min_distance = 999.0
	
	for panzon_data in panzones:
		var distance = panzon_data.body.position.distance_to(player.position)
		if distance < min_distance:
			min_distance = distance
			closest_pos = panzon_data.body.position
	
	return closest_pos

func create_collision_effect():
	# Crear un efecto visual temporal de colisión
	# Por ahora, hacer parpadear la cámara
	var tween = create_tween()
	tween.tween_method(set_camera_intensity, 1.0, 0.5, 0.1)
	tween.tween_method(set_camera_intensity, 0.5, 1.0, 0.1)

func set_camera_intensity(intensity: float):
	# Cambiar la intensidad de la cámara/ambiente
	var env = camera.environment
	if env:
		pass  # Aquí se podría ajustar el brillo si tuviéramos un Environment

func update_timer_display():
	var minutes = int(time_remaining / 60)
	var seconds = int(time_remaining) % 60
	timer_label.text = "Tiempo: %02d:%02d" % [minutes, seconds]

func complete_game(success: bool):
	game_completed = true
	game_active = false
	
	print("StaminaMiniGame3D: Juego completado - Éxito: ", success)
	
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
	crosshair_panel.visible = false
	result_text.text = result_string
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Funciones de tutorial
func show_tutorial():
	"""Mostrar el panel de tutorial al inicio"""
	game_active = false
	instruction_panel.visible = true
	result_panel.visible = false
	crosshair_panel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	print("StaminaMiniGame3D: Tutorial mostrado")

func _on_start_pressed():
	"""Cuando se presiona el botón de iniciar"""
	print("StaminaMiniGame3D: Iniciando juego desde tutorial")
	instruction_panel.visible = false
	crosshair_panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	game_active = true
	time_remaining = game_time
	current_stamina = max_stamina
	update_timer_display()

func _on_continue_pressed():
	"""Cuando se presiona continuar después del resultado"""
	print("StaminaMiniGame3D: Continuando al siguiente entrenamiento")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	training_completed.emit(current_stamina > 0)

# Control de primera persona con mouse
func _input(event):
	# Control de mouse para primera persona
	if game_active and event is InputEventMouseMotion:
		# Rotar el jugador horizontalmente
		player.rotate_y(-event.relative.x * mouse_sensitivity)
		# Rotar la cámara verticalmente
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		# Limitar la rotación vertical
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	# Salir del minijuego con ESC
	if event.is_action_pressed("ui_cancel"):
		if game_active:
			complete_game(false)
		else:
			# Si estamos en tutorial, salir directamente
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			training_completed.emit(false)
