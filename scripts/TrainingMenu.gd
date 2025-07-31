extends Control

@onready var squad_button = $MarginContainer/VBoxContainer/MenuButtons/SquadButton
@onready var training_button = $MarginContainer/VBoxContainer/MenuButtons/TrainingButton
@onready var inventory_button = $MarginContainer/VBoxContainer/MenuButtons/InventoryButton
@onready var back_button = $MarginContainer/VBoxContainer/BackButton
@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel

func _ready():
	print("TrainingMenu: Inicializando menú de entrenamiento...")
	
	# Configurar estilos de botones y título
	setup_styles()
	
	# Conectar señales de botones
	connect_buttons()

	# Configurar oponente actual para el entrenamiento
	setup_training_opponent()
	
	# Actualizar estado del botón de entrenamiento
	update_training_button()

	print("TrainingMenu: Menú de entrenamiento listo")

func setup_styles():
	# Estilo del título
	var title_settings = LabelSettings.new()
	title_settings.font_size = 56
	title_settings.font_color = Color.WHITE
	title_settings.outline_size = 4
	title_settings.outline_color = Color.BLACK
	title_label.label_settings = title_settings
	
	# Configurar botones principales con estilo grande
	setup_button_style(squad_button, Color.ORANGE, 24)
	setup_button_style(training_button, Color.LIME_GREEN, 24)
	setup_button_style(inventory_button, Color.CYAN, 24)
	setup_button_style(back_button, Color.GRAY, 18)

func setup_button_style(button: Button, color: Color, font_size: int):
	button.add_theme_font_size_override("font_size", font_size)

func connect_buttons():
	squad_button.pressed.connect(_on_squad_button_pressed)
	training_button.pressed.connect(_on_training_button_pressed)
	inventory_button.pressed.connect(_on_inventory_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)

func _on_squad_button_pressed():
	print("TrainingMenu: Botón 'Ver Plantilla' presionado")
	# Cargar la escena de la plantilla
	get_tree().change_scene_to_file("res://scenes/SquadView.tscn")

func _on_training_button_pressed():
	print("TrainingMenu: Botón 'Iniciar Entrenamiento' presionado")
	# Simulación simple de entrenamiento - otorgar experiencia
	var players_manager = get_node("/root/PlayersManager")
	if players_manager != null:
		players_manager.add_experience_after_training()
		print("¡Entrenamiento completado! Todos los jugadores ganaron 2 puntos de experiencia.")

	# Marcar entrenamiento como completado en TrainingManager
	TrainingManager.complete_training()
	print("TrainingMenu: Entrenamiento marcado como completado")

	# Avanzar un día después del entrenamiento
	if DayManager:
		DayManager.advance_day()
		print("TrainingMenu: Día avanzado después del entrenamiento")

	update_training_button()

func _on_inventory_button_pressed():
	print("TrainingMenu: Botón 'Inventario' presionado")
	get_tree().change_scene_to_file("res://scenes/InventoryMenu.tscn")

func _on_back_button_pressed():
	print("TrainingMenu: Volviendo al menú principal...")
	get_tree().change_scene_to_file("res://scenes/InteractiveMenu.tscn")

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
			TrainingManager.set_current_opponent(opponent_team.name)
			print("TrainingMenu: Configurado entrenamiento vs ", opponent_team.name)

func update_training_button():
	"""Actualiza el estado del botón de entrenamiento según el estado del entrenamiento"""
	var opponent = TrainingManager.get_current_opponent()
	var training_completed = TrainingManager.has_completed_training()
	
	if training_completed and opponent != "":
		training_button.text = "ENTRENAMIENTO COMPLETADO, HORA DE JUGAR"
		training_button.disabled = true
		training_button.modulate = Color.GRAY  # Hacer el botón más oscuro
	elif opponent != "":
		training_button.text = "INICIAR ENTRENAMIENTO vs " + opponent
		training_button.disabled = false
		training_button.modulate = Color.WHITE
	else:
		training_button.text = "INICIAR ENTRENAMIENTO"
		training_button.disabled = false
		training_button.modulate = Color.WHITE

# Función para manejar la tecla ESC (volver atrás)
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
