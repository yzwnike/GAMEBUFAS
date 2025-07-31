extends Control

@onready var play_button = $MarginContainer/VBoxContainer/MenuButtons/PlayButton
@onready var ranking_button = $MarginContainer/VBoxContainer/MenuButtons/RankingButton
@onready var back_button = $MarginContainer/VBoxContainer/BackButton
@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel

func _ready():
	print("TournamentMenu: Inicializando menú del torneo...")
	
	# Configurar estilos de botones y título
	setup_styles()
	
	# Conectar señales de botones
	connect_buttons()
	
	print("TournamentMenu: Menú del torneo listo")

func setup_styles():
	# Estilo del título
	var title_settings = LabelSettings.new()
	title_settings.font_size = 64
	title_settings.font_color = Color.WHITE
	title_settings.outline_size = 4
	title_settings.outline_color = Color.BLACK
	title_label.label_settings = title_settings
	
	# Configurar botones principales con estilo grande
	setup_button_style(play_button, Color.GREEN, 24)
	setup_button_style(ranking_button, Color.BLUE, 24)
	setup_button_style(back_button, Color.GRAY, 18)

func setup_button_style(button: Button, color: Color, font_size: int):
	# Por ahora solo configuramos el tamaño de fuente
	# En Godot 4, los estilos de botón se manejan mejor con themes
	button.add_theme_font_size_override("font_size", font_size)

func connect_buttons():
	play_button.pressed.connect(_on_play_button_pressed)
	ranking_button.pressed.connect(_on_ranking_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)

func _on_play_button_pressed():
	print("TournamentMenu: Botón 'Jugar Siguiente Partido' presionado")
	# Cargar la pantalla pre-partido
	get_tree().change_scene_to_file("res://scenes/PreMatchMenu.tscn")

func _on_ranking_button_pressed():
	print("TournamentMenu: Botón 'Ver Clasificación' presionado")
	# Cargar la escena de clasificación
	get_tree().change_scene_to_file("res://scenes/Ranking.tscn")

func _on_back_button_pressed():
	print("TournamentMenu: Volviendo al menú principal...")
	get_tree().change_scene_to_file("res://scenes/InteractiveMenu.tscn")

# Función para manejar la tecla ESC (volver atrás)
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
