extends Control

# Referencias a nodos (con get_node_or_null para evitar errores)
var squad_button
var training_button
var inventory_button
var back_button
var title_label
var day_label
var background
var menu_buttons

# Variables para animaciones
var entry_tween: Tween
var button_hover_tweens = {}
var original_scales = {}

func _ready():
	print("TrainingMenu: Inicializando menú de entrenamiento...")
	
	# Inicializar referencias a nodos de forma segura
	init_node_references()
	
	# Configurar estilos de botones y título
	setup_styles()
	
	# Conectar señales de botones
	connect_buttons()
	
	# Configurar oponente actual para el entrenamiento
	setup_training_opponent()
	
	# Actualizar estado del botón de entrenamiento
	update_training_button()
	
	# Actualizar indicador de día
	update_day_display()
	
	# Configurar animaciones
	setup_animations()
	
	# Iniciar animación de entrada
	start_entrance_animation()

	print("TrainingMenu: Menú de entrenamiento listo")

func setup_styles():
	# Estilo del título
	if title_label:
		var title_settings = LabelSettings.new()
		title_settings.font_size = 56
		title_settings.font_color = Color.WHITE
		title_settings.outline_size = 4
		title_settings.outline_color = Color.BLACK
		title_label.label_settings = title_settings
	
	# Configurar botones principales con estilo grande
	if squad_button: setup_button_style(squad_button, Color.ORANGE, 24)
	if training_button: setup_button_style(training_button, Color.LIME_GREEN, 24)
	if inventory_button: setup_button_style(inventory_button, Color.CYAN, 24)
	if back_button: setup_button_style(back_button, Color.GRAY, 18)

func setup_button_style(button: Button, color: Color, font_size: int):
	if button:
		button.add_theme_font_size_override("font_size", font_size)

func connect_buttons():
	if squad_button: squad_button.pressed.connect(_on_squad_button_pressed)
	if training_button: training_button.pressed.connect(_on_training_button_pressed)
	if inventory_button: inventory_button.pressed.connect(_on_inventory_button_pressed)
	if back_button: back_button.pressed.connect(_on_back_button_pressed)

func _on_squad_button_pressed():
	print("TrainingMenu: Botón 'Ver Plantilla' presionado")
	# Cargar la escena de la plantilla
	get_tree().change_scene_to_file("res://scenes/SquadView.tscn")

func _on_training_button_pressed():
	# Verificar si se puede entrenar
	if not TrainingManager.can_train():
		if TrainingManager.is_match_day():
			print("TrainingMenu: No se puede entrenar en día de partido")
		elif TrainingManager.has_completed_training():
			print("TrainingMenu: El entrenamiento ya está completado")
		return
	
	print("TrainingMenu: Botón 'Iniciar Entrenamiento' presionado")
	
	# COMENTADO: Simulación simple de entrenamiento
	# var players_manager = get_node("/root/PlayersManager")
	# if players_manager != null:
	#	players_manager.add_experience_after_training()
	#	print("¡Entrenamiento completado! Todos los jugadores ganaron 2 puntos de experiencia.")
	# TrainingManager.complete_training()
	# if DayManager:
	#	DayManager.advance_day()
	# update_training_button()
	# update_day_display()
	
	# NUEVO: Cargar escena de diálogo de entrenamiento dinámico
	get_tree().change_scene_to_file("res://scenes/TrainingDialogueScene.tscn")

func _on_inventory_button_pressed():
	print("TrainingMenu: Botón 'Inventario' presionado")
	get_tree().change_scene_to_file("res://scenes/InventoryMenu.tscn")

func _on_back_button_pressed():
	print("TrainingMenu: Volviendo al menú principal...")
	start_exit_transition()

func setup_training_opponent():
	"""Configura el oponente actual para el entrenamiento"""
	var match = LeagueManager.get_next_match()
	if match:
		# Determinar quién es el rival de FC Bufas
		var opponent_id = ""
		if match.home_team == "fc_bufas":
			opponent_id = match.away_team
		else:
			opponent_id = match.home_team
		
		var opponent_team = LeagueManager.get_team_by_id(opponent_id)
		if opponent_team:
			TrainingManager.set_current_opponent(opponent_team.name, match.match_day)
			print("TrainingMenu: Configurado entrenamiento vs ", opponent_team.name)

func update_training_button():
	"""Actualiza el estado del botón de entrenamiento según el estado del entrenamiento"""
	var opponent = TrainingManager.get_current_opponent()
	var training_completed = TrainingManager.has_completed_training()
	var is_match_day = TrainingManager.is_match_day()
	var current_day = DayManager.get_current_day()
	
	print("TrainingMenu: Actualizando botón - Día: ", current_day, ", Opponent: '", opponent, "', Completed: ", training_completed, ", MatchDay: ", is_match_day)
	
	# Día de partido - no se puede entrenar
	if is_match_day:
		training_button.text = "DÍA DE PARTIDO - NO ENTRENAR"
		training_button.disabled = true
		training_button.modulate = Color(0.7, 0.3, 0.3, 1.0)  # Rojo oscuro
		print("TrainingMenu: Botón deshabilitado - día de partido")
	# Entrenamiento completado
	elif training_completed and opponent != "":
		training_button.text = "ENTRENAMIENTO COMPLETADO, HORA DE JUGAR"
		training_button.disabled = true
		training_button.modulate = Color(0.5, 0.5, 0.5, 1.0)  # Hacer el botón más oscuro
		print("TrainingMenu: Botón deshabilitado - entrenamiento completado")
	# Día de entrenamiento disponible
	elif opponent != "":
		training_button.text = "INICIAR ENTRENAMIENTO vs " + opponent
		training_button.disabled = false
		training_button.modulate = Color.WHITE
		print("TrainingMenu: Botón habilitado para entrenamiento vs ", opponent)
	else:
		training_button.text = "INICIAR ENTRENAMIENTO"
		training_button.disabled = false
		training_button.modulate = Color.WHITE
		print("TrainingMenu: Botón habilitado - sin oponente específico")

func update_day_display():
	"""Actualiza la visualización del día actual"""
	if day_label:
		var current_day = DayManager.get_current_day()
		var day_type = "ENTRENAMIENTO" if current_day % 2 == 1 else "PARTIDO"
		day_label.text = "Día %d - %s" % [current_day, day_type]
		
		# Configurar estilo del label de día
		var day_settings = LabelSettings.new()
		day_settings.font_size = 20
		day_settings.font_color = Color.YELLOW if day_type == "ENTRENAMIENTO" else Color.ORANGE
		day_settings.outline_size = 2
		day_settings.outline_color = Color.BLACK
		day_label.label_settings = day_settings

# Configurar animaciones de botón y entrada
func setup_animations():
	entry_tween = get_tree().create_tween()
	
	# Configurar botones para hover
	for button in [squad_button, training_button, inventory_button, back_button]:
		original_scales[button] = button.scale
		setup_button_hover_animation(button)

# Configuración de animación para hover en botones
func setup_button_hover_animation(button):
	button.mouse_entered.connect(func(): _on_button_hovered(button))
	button.mouse_exited.connect(func(): _on_button_unhovered(button))

func _on_button_hovered(button):
	if button_hover_tweens.has(button) and button_hover_tweens[button]:
		button_hover_tweens[button].kill()
	
	button_hover_tweens[button] = get_tree().create_tween()
	button_hover_tweens[button].tween_property(button, "scale", Vector2(1.1, 1.1), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_button_unhovered(button):
	if button_hover_tweens.has(button) and button_hover_tweens[button]:
		button_hover_tweens[button].kill()
	
	button_hover_tweens[button] = get_tree().create_tween()
	button_hover_tweens[button].tween_property(button, "scale", original_scales[button], 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# Animación de entrada inicial del menú
func start_entrance_animation():
	if entry_tween:
		entry_tween.kill()  # Detener cualquier animación previa
	
	entry_tween = get_tree().create_tween()

	# Animar la entrada de los botones
	for button in [squad_button, training_button, inventory_button, back_button]:
		if button:
			button.modulate = Color(1, 1, 1, 0)
			entry_tween.parallel().tween_property(button, "modulate:a", 1, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Animar el fondo
	if background:
		background.modulate = Color(1, 1, 1, 0)
		entry_tween.parallel().tween_property(background, "modulate:a", 1, 2.0)

# Inicializar referencias a nodos de forma segura
func init_node_references():
	squad_button = get_node_or_null("MarginContainer/VBoxContainer/MenuButtons/SquadButton")
	training_button = get_node_or_null("MarginContainer/VBoxContainer/MenuButtons/TrainingButton")
	inventory_button = get_node_or_null("MarginContainer/VBoxContainer/MenuButtons/InventoryButton")
	back_button = get_node_or_null("MarginContainer/VBoxContainer/BackButton")
	title_label = get_node_or_null("MarginContainer/VBoxContainer/TitleLabel")
	day_label = get_node_or_null("MarginContainer/VBoxContainer/DayLabel")
	background = get_node_or_null("Background")
	menu_buttons = get_node_or_null("MarginContainer/VBoxContainer/MenuButtons")
	
	# Verificar que los nodos críticos existan
	if not squad_button or not training_button or not inventory_button or not back_button:
		print("ERROR: No se pudieron encontrar todos los botones necesarios")
		return false
	
	print("TrainingMenu: Todos los nodos inicializados correctamente")
	return true

# Transición de salida simple hacia el InteractiveMenu
func start_exit_transition():
	# Crear tween de salida simple (solo fade out)
	var exit_tween = get_tree().create_tween()
	
	# Fade out rápido sin zoom
	exit_tween.tween_property(self, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Cambiar a InteractiveMenu cuando termine la animación
	exit_tween.tween_callback(func(): change_to_interactive_menu()).set_delay(0.3)
	
	print("TrainingMenu: Iniciando transición de salida simple")

# Cambiar al InteractiveMenu y activar transición de retorno
func change_to_interactive_menu():
	var interactive_scene = preload("res://scenes/InteractiveMenu.tscn")
	var interactive_instance = interactive_scene.instantiate()
	interactive_instance.is_first_time = false  # No es la primera vez
	interactive_instance.last_selected_area = "campo"  # Volvemos del campo
	
	get_tree().root.add_child(interactive_instance)
	get_tree().current_scene = interactive_instance
	queue_free()
	
	# Llamar a la transición de retorno
	interactive_instance.start_return_transition()

# Función para manejar la tecla ESC (volver atrás)
func _input(event):
	if event.is_action_pressed("ui_cancel") and back_button:
		_on_back_button_pressed()

