extends Control

# Referencias a nodos (con get_node_or_null para evitar errores)
var play_button
var ranking_button
var back_button
var title_label
var background

# Variables para animaciones
var entry_tween: Tween
var button_hover_tweens = {}
var original_scales = {}

func _ready():
	print("TournamentMenu: Inicializando menú del torneo...")
	
	# Inicializar referencias a nodos de forma segura
	if not init_node_references():
		return
	
	# Configurar estilos de botones y título
	setup_styles()
	
	# Conectar señales de botones
	connect_buttons()
	
	# Configurar animaciones
	setup_animations()
	
	# Iniciar animación de entrada
	start_entrance_animation()
	
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
	start_exit_transition()

# Configurar animaciones de botón y entrada
func setup_animations():
	entry_tween = get_tree().create_tween()
	
	# Configurar botones para hover
	for button in [play_button, ranking_button, back_button]:
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
	for button in [play_button, ranking_button, back_button]:
		if button:
			button.modulate = Color(1, 1, 1, 0)
			entry_tween.parallel().tween_property(button, "modulate:a", 1, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Animar el fondo
	if background:
		background.modulate = Color(1, 1, 1, 0)
		entry_tween.parallel().tween_property(background, "modulate:a", 1, 2.0)

# Inicializar referencias a nodos de forma segura
func init_node_references():
	play_button = get_node_or_null("MarginContainer/VBoxContainer/MenuButtons/PlayButton")
	ranking_button = get_node_or_null("MarginContainer/VBoxContainer/MenuButtons/RankingButton")
	back_button = get_node_or_null("MarginContainer/VBoxContainer/BackButton")
	title_label = get_node_or_null("MarginContainer/VBoxContainer/TitleLabel")
	background = get_node_or_null("Background")
	
	# Verificar que los nodos críticos existan
	if not play_button or not ranking_button or not back_button:
		print("ERROR: No se pudieron encontrar todos los botones necesarios en TournamentMenu")
		return false
	
	if not title_label:
		print("WARNING: No se encontró el title_label en TournamentMenu")
	
	if not background:
		print("WARNING: No se encontró el background en TournamentMenu")
	
	print("TournamentMenu: Nodos inicializados correctamente")
	return true

# Transición de salida simple hacia el InteractiveMenu
func start_exit_transition():
	# Crear tween de salida simple (solo fade out)
	var exit_tween = get_tree().create_tween()
	
	# Fade out rápido sin zoom
	exit_tween.tween_property(self, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Cambiar a InteractiveMenu cuando termine la animación
	exit_tween.tween_callback(func(): change_to_interactive_menu()).set_delay(0.3)
	
	print("TournamentMenu: Iniciando transición de salida simple")

# Cambiar al InteractiveMenu y activar transición de retorno
func change_to_interactive_menu():
	var interactive_scene = preload("res://scenes/InteractiveMenu.tscn")
	var interactive_instance = interactive_scene.instantiate()
	interactive_instance.is_first_time = false  # No es la primera vez
	interactive_instance.last_selected_area = "estadio"  # Volvemos del estadio
	
	get_tree().root.add_child(interactive_instance)
	get_tree().current_scene = interactive_instance
	queue_free()
	
	# Llamar a la transición de retorno
	interactive_instance.start_return_transition()

# Función para manejar la tecla ESC (volver atrás)
func _input(event):
	if event.is_action_pressed("ui_cancel") and back_button:
		_on_back_button_pressed()
