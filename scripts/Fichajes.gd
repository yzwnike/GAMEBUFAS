extends Control

@onready var gacha_button = $MarginContainer/VBoxContainer/GachaButton
@onready var ruleta_button = $MarginContainer/VBoxContainer/RuletaButton
@onready var back_button = $MarginContainer/VBoxContainer/BackButton
@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel

func _ready():
	print("Fichajes: Inicializando sistema de fichajes...")
	
	# Configurar estilos
	setup_styles()
	
	# Conectar señales de botones
	connect_buttons()
	
	print("Fichajes: Sistema de fichajes listo")

func setup_styles():
	# Estilo del título
	var title_settings = LabelSettings.new()
	title_settings.font_size = 48
	title_settings.font_color = Color.WHITE
	title_settings.outline_size = 3
	title_settings.outline_color = Color.BLACK
	title_label.label_settings = title_settings
	
	# Botones principales
	setup_main_button_style(gacha_button)
	setup_main_button_style(ruleta_button)
	
	# Botón de regreso
	setup_secondary_button_style(back_button, 18)

func setup_main_button_style(button: Button):
	button.add_theme_font_size_override("font_size", 28)
	button.custom_minimum_size = Vector2(350, 80)

func setup_secondary_button_style(button: Button, font_size: int):
	button.add_theme_font_size_override("font_size", font_size)
	button.custom_minimum_size = Vector2(200, 50)

func connect_buttons():
	gacha_button.pressed.connect(_on_gacha_button_pressed)
	ruleta_button.pressed.connect(_on_ruleta_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)

func _on_gacha_button_pressed():
	print("Fichajes: Botón 'GACHAPÓN DE FICHAJES' presionado")
	# Cargar escena del gachapón
	get_tree().change_scene_to_file("res://scenes/GachaponScene.tscn")

func _on_ruleta_button_pressed():
	print("Fichajes: Botón 'LA RULETA' presionado")
	# TODO: Cargar escena de la ruleta
	# get_tree().change_scene_to_file("res://scenes/RuletaScene.tscn")

func _on_back_button_pressed():
	print("Fichajes: Volviendo al menú del barrio...")
	get_tree().change_scene_to_file("res://scenes/NeighborhoodMenu.tscn")

# Función para manejar la tecla ESC (volver atrás)
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()

