extends Control

@onready var fichajes_button = $MarginContainer/VBoxContainer/MainButtonContainer/FichajesButton
@onready var encyclopedia_button = $MarginContainer/VBoxContainer/SecondaryButtons/FirstRow/EncyclopediaButton
@onready var shop_button = $MarginContainer/VBoxContainer/SecondaryButtons/FirstRow/ShopButton
@onready var transfer_market_button = $MarginContainer/VBoxContainer/SecondaryButtons/SecondRow/TransferMarketButton
@onready var back_button = $MarginContainer/VBoxContainer/BackButton
@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel
@onready var background = $Background

# Variables para animaciones
var entry_tween: Tween
var button_hover_tweens = {}
var original_scales = {}

func _ready():
	print("NeighborhoodMenu: Inicializando menú del barrio...")
	
	# Configurar estilos de botones y título
	setup_styles()
	
	# Conectar señales de botones
	connect_buttons()
	
	# Configurar animaciones
	setup_animations()
	
	# Iniciar animación de entrada
	start_entrance_animation()
	
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

# Configurar animaciones de botón y entrada
func setup_animations():
	entry_tween = get_tree().create_tween()
	
	# Configurar botones para hover
	for button in [fichajes_button, encyclopedia_button, shop_button, transfer_market_button, back_button]:
		if button:
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
	for button in [fichajes_button, encyclopedia_button, shop_button, transfer_market_button, back_button]:
		if button:
			button.modulate = Color(1, 1, 1, 0)
			entry_tween.parallel().tween_property(button, "modulate:a", 1, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Animar el título
	if title_label:
		title_label.modulate = Color(1, 1, 1, 0)
		entry_tween.parallel().tween_property(title_label, "modulate:a", 1, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Animar el fondo
	if background:
		background.modulate = Color(1, 1, 1, 0)
		entry_tween.parallel().tween_property(background, "modulate:a", 1, 2.0)

func _on_back_button_pressed():
	print("NeighborhoodMenu: Volviendo al menú principal...")
	start_exit_transition()

# Transición de salida simple hacia el InteractiveMenu
func start_exit_transition():
	# Crear tween de salida simple (solo fade out)
	var exit_tween = get_tree().create_tween()
	
	# Fade out rápido sin zoom
	exit_tween.tween_property(self, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Cambiar a InteractiveMenu cuando termine la animación
	exit_tween.tween_callback(func(): change_to_interactive_menu()).set_delay(0.3)
	
	print("NeighborhoodMenu: Iniciando transición de salida simple")

# Cambiar al InteractiveMenu y activar transición de retorno
func change_to_interactive_menu():
	var interactive_scene = preload("res://scenes/InteractiveMenu.tscn")
	var interactive_instance = interactive_scene.instantiate()
	interactive_instance.is_first_time = false  # No es la primera vez
	interactive_instance.last_selected_area = "barrio"  # Volvemos del barrio
	
	get_tree().root.add_child(interactive_instance)
	get_tree().current_scene = interactive_instance
	queue_free()
	
	# Llamar a la transición de retorno
	interactive_instance.start_return_transition()

# Función para manejar la tecla ESC (volver atrás)
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
