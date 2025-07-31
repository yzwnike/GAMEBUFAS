extends Control

@onready var fichajes_button = $MarginContainer/VBoxContainer/MainButtonContainer/FichajesButton
@onready var encyclopedia_button = $MarginContainer/VBoxContainer/SecondaryButtons/FirstRow/EncyclopediaButton
@onready var shop_button = $MarginContainer/VBoxContainer/SecondaryButtons/FirstRow/ShopButton
@onready var transfer_market_button = $MarginContainer/VBoxContainer/SecondaryButtons/SecondRow/TransferMarketButton
@onready var back_button = $MarginContainer/VBoxContainer/BackButton
@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel

func _ready():
	print("NeighborhoodMenu: Inicializando menú del barrio...")
	
	# Configurar estilos de botones y título
	setup_styles()
	
	# Conectar señales de botones
	connect_buttons()
	
	print("NeighborhoodMenu: Menú del barrio listo")

func setup_styles():
	# Estilo del título
	var title_settings = LabelSettings.new()
	title_settings.font_size = 64
	title_settings.font_color = Color.WHITE
	title_settings.outline_size = 4
	title_settings.outline_color = Color.BLACK
	title_label.label_settings = title_settings
	
	# Botón principal FICHAJES - Grande y destacado
	setup_main_button_style(fichajes_button)
	
	# Botones secundarios - Más pequeños
	setup_secondary_button_style(encyclopedia_button, 18)
	setup_secondary_button_style(shop_button, 18)
	setup_secondary_button_style(transfer_market_button, 18)
	setup_secondary_button_style(back_button, 16)

func setup_main_button_style(button: Button):
	# Configurar el botón FICHAJES con estilo especial
	button.add_theme_font_size_override("font_size", 36)
	
	# Hacer el botón más grande
	button.custom_minimum_size = Vector2(400, 100)
	
	# Crear configuración de LabelSettings para un estilo especial
	print("NeighborhoodMenu: Configurando estilo especial para botón FICHAJES")

func setup_secondary_button_style(button: Button, font_size: int):
	button.add_theme_font_size_override("font_size", font_size)

func connect_buttons():
	fichajes_button.pressed.connect(_on_fichajes_button_pressed)
	encyclopedia_button.pressed.connect(_on_encyclopedia_button_pressed)
	shop_button.pressed.connect(_on_shop_button_pressed)
	transfer_market_button.pressed.connect(_on_transfer_market_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)

func _on_fichajes_button_pressed():
	print("NeighborhoodMenu: Botón 'FICHAJES' presionado")
	# Cargar la escena de fichajes
	get_tree().change_scene_to_file("res://scenes/Fichajes.tscn")

func _on_encyclopedia_button_pressed():
	print("NeighborhoodMenu: Botón 'Enciclopedia de Jugadores' presionado")
	get_tree().change_scene_to_file("res://scenes/PlayerEncyclopedia.tscn")

func _on_shop_button_pressed():
	print("NeighborhoodMenu: Botón 'Tienda de Suplementos' presionado")
	get_tree().change_scene_to_file("res://scenes/SupplementShop.tscn")

func _on_transfer_market_button_pressed():
	print("NeighborhoodMenu: Botón 'Mercado de Traspasos' presionado")
	get_tree().change_scene_to_file("res://scenes/TransferMarketMenu.tscn")

func _on_back_button_pressed():
	print("NeighborhoodMenu: Volviendo al menú principal...")
	get_tree().change_scene_to_file("res://scenes/InteractiveMenu.tscn")

# Función para manejar la tecla ESC (volver atrás)
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
