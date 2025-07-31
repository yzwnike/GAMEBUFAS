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
	
	# Avanzar un día después del entrenamiento
	if DayManager:
		DayManager.advance_day()
		print("TrainingMenu: Día avanzado después del entrenamiento")
	
	# TODO: Implementar minijuego de entrenamiento más complejo en el futuro

func _on_inventory_button_pressed():
	print("TrainingMenu: Botón 'Inventario' presionado")
	get_tree().change_scene_to_file("res://scenes/InventoryMenu.tscn")

func _on_back_button_pressed():
	print("TrainingMenu: Volviendo al menú principal...")
	get_tree().change_scene_to_file("res://scenes/InteractiveMenu.tscn")

# Función para manejar la tecla ESC (volver atrás)
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
