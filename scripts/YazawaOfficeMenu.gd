extends Control

# Referencias a nodos
var encargos_button
var campanas_button
var estadisticas_button
var ligas_button
var back_button
var title_label
var subtitle_label
var background
var color_overlay
var buttons_container
var yazawa_portrait_container
var yazawa_portrait
var portrait_glow
var gold_particles

# Referencia al visor de ligas
var leagues_viewer: Control

# Variables para animaciones
var entry_tween: Tween
var button_hover_tweens = {}
var original_scales = {}

# Variable para controlar si mostrar animación de entrada
var show_entrance_animation: bool = true

func _ready():
	print("YazawaOfficeMenu: Inicializando oficina de Yazawa...")
	
	# Inicializar referencias a nodos de forma segura
	init_node_references()
	
	# Configurar estilos de botones y título
	setup_styles()
	
	# Conectar señales de botones
	connect_buttons()
	
	# Configurar animaciones
	setup_animations()
	
	# Verificar si venir desde la transición (botón OFICINA)
	check_entrance_source()
	
	# Iniciar animación de entrada solo si corresponde
	if show_entrance_animation:
		start_entrance_animation()
	else:
		skip_to_final_state()

	print("YazawaOfficeMenu: Oficina de Yazawa lista")

func setup_styles():
	# Estilo del título
	if title_label:
		var title_settings = LabelSettings.new()
		title_settings.font_size = 64
		title_settings.font_color = Color.WHITE
		title_settings.outline_size = 4
		title_settings.outline_color = Color.BLACK
		title_label.label_settings = title_settings
	
	# Estilo del subtítulo
	if subtitle_label:
		var subtitle_settings = LabelSettings.new()
		subtitle_settings.font_size = 24
		subtitle_settings.font_color = Color(1, 0.9, 0.7, 1)
		subtitle_settings.outline_size = 2
		subtitle_settings.outline_color = Color.BLACK
		subtitle_label.label_settings = subtitle_settings
	
	# Configurar botones principales
	if encargos_button: setup_button_style(encargos_button, Color.ORANGE, 32)
	if campanas_button: setup_button_style(campanas_button, Color.CYAN, 32)
	if estadisticas_button: setup_button_style(estadisticas_button, Color.YELLOW, 28)
	if back_button: setup_button_style(back_button, Color.GRAY, 20)

func setup_button_style(button: Button, color: Color, font_size: int):
	if button:
		button.add_theme_font_size_override("font_size", font_size)

func connect_buttons():
	if encargos_button: encargos_button.pressed.connect(_on_encargos_button_pressed)
	if campanas_button: campanas_button.pressed.connect(_on_campanas_button_pressed)
	if estadisticas_button: estadisticas_button.pressed.connect(_on_estadisticas_button_pressed)
	if ligas_button: ligas_button.pressed.connect(_on_ligas_button_pressed)
	if back_button: back_button.pressed.connect(_on_back_button_pressed)
	
	# Inicializar el visor de ligas
	init_leagues_viewer()

func _on_encargos_button_pressed():
	print("YazawaOfficeMenu: Botón 'Encargos' presionado")
	print("YazawaOfficeMenu: Intentando cambiar a EncargosMenu.tscn")
	
	# Verificar si el archivo existe
	if ResourceLoader.exists("res://scenes/EncargosMenu.tscn"):
		print("YazawaOfficeMenu: Archivo EncargosMenu.tscn encontrado")
		get_tree().change_scene_to_file("res://scenes/EncargosMenu.tscn")
	else:
		print("ERROR: Archivo EncargosMenu.tscn no encontrado")
		# Mostrar mensaje temporal
		show_temp_message("Sistema de Encargos próximamente disponible")

func _on_campanas_button_pressed():
	print("YazawaOfficeMenu: Botón 'Campañas' presionado")
	print("YazawaOfficeMenu: Intentando cambiar a CampaignsMenu.tscn")
	
	# Verificar si el archivo existe
	if ResourceLoader.exists("res://scenes/CampaignsMenu.tscn"):
		print("YazawaOfficeMenu: Archivo CampaignsMenu.tscn encontrado")
		get_tree().change_scene_to_file("res://scenes/CampaignsMenu.tscn")
	else:
		print("ERROR: Archivo CampaignsMenu.tscn no encontrado")
		# Mostrar mensaje temporal
		show_temp_message("Sistema de Campañas próximamente disponible")

func _on_estadisticas_button_pressed():
	print("YazawaOfficeMenu: Botón 'Estadísticas' presionado")
	print("YazawaOfficeMenu: Intentando cambiar a EstadisticasMenu.tscn")
	
	# Verificar si el archivo existe
	if ResourceLoader.exists("res://scenes/EstadisticasMenu.tscn"):
		print("YazawaOfficeMenu: Archivo EstadisticasMenu.tscn encontrado")
		get_tree().change_scene_to_file("res://scenes/EstadisticasMenu.tscn")
	else:
		print("ERROR: Archivo EstadisticasMenu.tscn no encontrado")
		# Mostrar mensaje temporal
		show_temp_message("Estadísticas próximamente disponibles")

func _on_ligas_button_pressed():
	print("YazawaOfficeMenu: Botón 'Otras Ligas' presionado")
	if leagues_viewer:
		hide_office_ui()
		leagues_viewer.show_leagues()
	else:
		print("ERROR: LeaguesViewer no está inicializado")
		show_temp_message("Sistema de Ligas no disponible")

func _on_back_button_pressed():
	print("YazawaOfficeMenu: Volviendo al campo de entrenamiento...")
	start_exit_transition()

func show_temp_message(message: String):
	"""Muestra un mensaje temporal cuando una funcionalidad no está implementada"""
	print("YazawaOfficeMenu: Mostrando mensaje: ", message)
	# Por ahora solo imprime, más adelante se puede añadir una ventana modal

# Configurar animaciones de botón y entrada
func setup_animations():
	entry_tween = get_tree().create_tween()
	
	# Configurar botones para hover
	for button in [encargos_button, campanas_button, estadisticas_button, ligas_button, back_button]:
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

# === CONTROL DE ANIMACIÓN DE ENTRADA ===

func check_entrance_source():
	"""Verifica si venimos desde la transición 3D (botón OFICINA) o desde un submenú"""
	# Revisar si hay una marca en GameManager que indique que venimos desde la transición
	if GameManager and GameManager.has_method("get_story_flag"):
		show_entrance_animation = GameManager.get_story_flag("from_office_transition")
		if show_entrance_animation:
			GameManager.set_story_flag("from_office_transition", false)  # Resetear para próximas veces
	else:
		# Si no hay GameManager, asumir que NO venimos de la transición
		show_entrance_animation = false
	
	print("🔄 Verificación de origen: animación = ", show_entrance_animation)

func skip_to_final_state():
	"""Salta directamente al estado final sin animación"""
	print("⏩ Saltando animación - mostrando estado final directamente")
	
	# Establecer todos los elementos en su estado final
	for button in [encargos_button, campanas_button, estadisticas_button, ligas_button, back_button]:
		if button:
			button.modulate = Color(1, 1, 1, 1)
			button.scale = Vector2(1.0, 1.0)
	
	if title_label:
		title_label.modulate = Color(1, 1, 1, 1)
		title_label.scale = Vector2(1.0, 1.0)
	
	if subtitle_label:
		subtitle_label.modulate = Color(1, 1, 1, 1)
	
	if yazawa_portrait:
		yazawa_portrait.modulate = Color(1, 1, 1, 1)
		yazawa_portrait.scale = Vector2(1.0, 1.0)
		# Iniciar efecto de respiración
		start_portrait_breathing_effect()
	
	# Configurar partículas en estado normal
	if gold_particles:
		gold_particles.amount = 50
		gold_particles.initial_velocity_max = 30.0
		gold_particles.emitting = true

# Animación de entrada inicial del menú (VERSIÓN CORTA)
func start_entrance_animation():
	print("🎆 Iniciando animación de entrada épica de la oficina presidencial...")
	
	if entry_tween:
		entry_tween.kill()  # Detener cualquier animación previa
	
	entry_tween = get_tree().create_tween()
	entry_tween.set_parallel(true)
	
	# Hacer todos los elementos invisibles inicialmente
	for button in [encargos_button, campanas_button, estadisticas_button, ligas_button, back_button]:
		if button:
			button.modulate = Color(1, 1, 1, 0)
			button.scale = Vector2(0.8, 0.8)
	
	if title_label:
		title_label.modulate = Color(1, 1, 1, 0)
		title_label.scale = Vector2(0.8, 0.8)
	
	if subtitle_label:
		subtitle_label.modulate = Color(1, 1, 1, 0)
	
	if yazawa_portrait:
		yazawa_portrait.modulate = Color(1, 1, 1, 0)
		yazawa_portrait.scale = Vector2(0.9, 0.9)
	
	# Intensificar partículas al inicio
	if gold_particles:
		gold_particles.amount = 150
		gold_particles.initial_velocity_max = 50.0
		gold_particles.emitting = true
	
	# FASE 1: Título presidencial dramático (0.1s)
	entry_tween.tween_property(title_label, "modulate:a", 1.0, 0.4).set_delay(0.1)
	entry_tween.tween_property(title_label, "scale", Vector2(1.05, 1.05), 0.2).set_delay(0.1)
	entry_tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.3)
	
	# FASE 2: Subtítulo elegante (0.5s)
	entry_tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.3).set_delay(0.5)
	
	# FASE 3: Retrato de Yazawa con efecto dramático (0.7s)
	if yazawa_portrait:
		entry_tween.tween_property(yazawa_portrait, "modulate:a", 1.0, 0.4).set_delay(0.7)
		entry_tween.tween_property(yazawa_portrait, "scale", Vector2(1.0, 1.0), 0.3).set_delay(0.7)
		# Efecto de respiración continuo para el retrato
		start_portrait_breathing_effect()
	
	# FASE 4: Botones principales con retraso escalonado (1.0s)
	var main_buttons = [encargos_button, campanas_button]
	for i in range(main_buttons.size()):
		var button = main_buttons[i]
		if button:
			var delay = 1.0 + (i * 0.15)
			entry_tween.tween_property(button, "modulate:a", 1.0, 0.3).set_delay(delay)
			entry_tween.tween_property(button, "scale", Vector2(1.02, 1.02), 0.15).set_delay(delay)
			entry_tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.15).set_delay(delay + 0.15)
	
	# FASE 5: Botones secundarios (1.4s)
	var secondary_buttons = [estadisticas_button, ligas_button]
	for i in range(secondary_buttons.size()):
		var button = secondary_buttons[i]
		if button:
			var delay = 1.4 + (i * 0.1)
			entry_tween.tween_property(button, "modulate:a", 1.0, 0.25).set_delay(delay)
			entry_tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.25).set_delay(delay)
	
	# FASE 6: Botón de salida (1.7s)
	if back_button:
		entry_tween.tween_property(back_button, "modulate:a", 1.0, 0.25).set_delay(1.7)
		entry_tween.tween_property(back_button, "scale", Vector2(1.0, 1.0), 0.25).set_delay(1.7)
	
	# FASE 7: Efecto final épico - destello dorado (2.0s)
	entry_tween.tween_callback(func(): create_golden_flash_effect()).set_delay(2.0)
	
	print("✨ Animación de entrada presidencial iniciada - duración total: 2.5s")

# Inicializar referencias a nodos de forma segura
func init_node_references():
	encargos_button = get_node_or_null("MarginContainer/VBoxContainer/ButtonsContainer/MainButtonRow/EncargosButton")
	campanas_button = get_node_or_null("MarginContainer/VBoxContainer/ButtonsContainer/MainButtonRow/CampanasButton")
	estadisticas_button = get_node_or_null("MarginContainer/VBoxContainer/ButtonsContainer/SecondaryButtonRow/EstadisticasButton")
	ligas_button = get_node_or_null("MarginContainer/VBoxContainer/ButtonsContainer/SecondaryButtonRow/LigasButton")
	back_button = get_node_or_null("MarginContainer/VBoxContainer/BackButton")
	title_label = get_node_or_null("MarginContainer/VBoxContainer/TitleLabel")
	subtitle_label = get_node_or_null("MarginContainer/VBoxContainer/SubtitleLabel")
	background = get_node_or_null("Background")
	color_overlay = get_node_or_null("ColorOverlay")
	buttons_container = get_node_or_null("MarginContainer/VBoxContainer/ButtonsContainer")
	yazawa_portrait_container = get_node_or_null("YazawaPortraitContainer")
	yazawa_portrait = get_node_or_null("YazawaPortraitContainer/YazawaPortrait")
	portrait_glow = get_node_or_null("YazawaPortraitContainer/PortraitGlow")
	gold_particles = get_node_or_null("GoldParticles")
	
	# Verificar que los nodos críticos existan
	if not encargos_button or not campanas_button or not estadisticas_button or not back_button:
		print("ERROR: No se pudieron encontrar todos los botones necesarios")
		print("Encargos: ", encargos_button != null, ", Campañas: ", campanas_button != null)
		print("Estadísticas: ", estadisticas_button != null, ", Back: ", back_button != null)
		return false
	
	print("YazawaOfficeMenu: Todos los nodos inicializados correctamente")
	return true

# Transición de salida simple hacia el TrainingMenu
func start_exit_transition():
	# Crear tween de salida simple (solo fade out)
	var exit_tween = get_tree().create_tween()
	
	# Fade out rápido sin zoom
	exit_tween.tween_property(self, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Cambiar a TrainingMenu cuando termine la animación
	exit_tween.tween_callback(func(): change_to_training_menu()).set_delay(0.3)
	
	print("YazawaOfficeMenu: Iniciando transición de salida simple")

# Cambiar al TrainingMenu
func change_to_training_menu():
	get_tree().change_scene_to_file("res://scenes/TrainingMenu.tscn")

func init_leagues_viewer():
	"""Inicializa el visor de ligas"""
	print("YazawaOfficeMenu: Inicializando visor de ligas...")
	
	# Cargar la escena del visor de ligas
	var leagues_viewer_scene = preload("res://scenes/LeaguesViewer.tscn")
	if leagues_viewer_scene:
		leagues_viewer = leagues_viewer_scene.instantiate()
		leagues_viewer.hide()  # Empezar oculto
		add_child(leagues_viewer)
		print("🏆 Visor de ligas inicializado correctamente")
	else:
		print("❌ Error: No se pudo cargar LeaguesViewer.tscn")

func hide_office_ui():
	"""Oculta la interfaz de la oficina"""
	print("🔒 Ocultando interfaz de la oficina")
	
	# Ocultar elementos específicos de la oficina
	if background: background.hide()
	var margin_container = get_node_or_null("MarginContainer")
	if margin_container: margin_container.hide()
	var color_rect = get_node_or_null("ColorRect")
	if color_rect: color_rect.hide()

func show_office_ui():
	"""Muestra la interfaz de la oficina"""
	print("🔓 Mostrando interfaz de la oficina")
	
	# Mostrar elementos específicos de la oficina
	if background: background.show()
	var margin_container = get_node_or_null("MarginContainer")
	if margin_container: margin_container.show()
	var color_rect = get_node_or_null("ColorRect")
	if color_rect: color_rect.show()
	
	# Ocultar el visor de ligas
	if leagues_viewer:
		leagues_viewer.hide()

# === EFECTOS ESPECIALES ÉPICOS ===

func start_portrait_breathing_effect():
	"""Efecto de respiración continuo para el retrato de Yazawa"""
	if yazawa_portrait:
		var breathing_tween = create_tween()
		breathing_tween.set_loops()
		breathing_tween.tween_property(yazawa_portrait, "scale", Vector2(1.02, 1.02), 2.0)
		breathing_tween.tween_property(yazawa_portrait, "scale", Vector2(1.0, 1.0), 2.0)
		print("🫁 Efecto de respiración del retrato activado")

func create_golden_flash_effect():
	"""Crea un destello dorado épico al final de la animación"""
	print("✨ Creando destello dorado épico...")
	
	# Crear overlay de destello
	var flash_overlay = ColorRect.new()
	flash_overlay.name = "GoldenFlash"
	flash_overlay.color = Color(1, 0.8, 0.2, 0)  # Dorado transparente
	flash_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash_overlay.z_index = 1000
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	self.add_child(flash_overlay)
	
	# Animación del destello
	var flash_tween = create_tween()
	flash_tween.tween_property(flash_overlay, "color:a", 0.4, 0.2)
	flash_tween.tween_property(flash_overlay, "color:a", 0.0, 0.5)
	flash_tween.tween_callback(func(): flash_overlay.queue_free())
	
	# Intensificar partículas durante el destello
	if gold_particles:
		gold_particles.amount = 300
		gold_particles.initial_velocity_max = 80.0
		# Volver a normal después de 2 segundos
		get_tree().create_timer(2.0).timeout.connect(func():
			if gold_particles:
				gold_particles.amount = 50
				gold_particles.initial_velocity_max = 30.0
		)
	
	# Efecto de pulso en todos los botones
	for button in [encargos_button, campanas_button, estadisticas_button, ligas_button]:
		if button:
			var pulse_tween = create_tween()
			pulse_tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.2, 1), 0.1)
			pulse_tween.tween_property(button, "modulate", Color(1, 1, 1, 1), 0.3)
	
	# Efecto especial en el título
	if title_label:
		var title_flash_tween = create_tween()
		title_flash_tween.tween_property(title_label, "modulate", Color(1.5, 1.5, 1.5, 1), 0.15)
		title_flash_tween.tween_property(title_label, "modulate", Color(1, 1, 1, 1), 0.4)
	
	print("🌟 Destello dorado épico completado")

# Función para manejar la tecla ESC (volver atrás)
func _input(event):
	if event.is_action_pressed("ui_cancel") and back_button:
		_on_back_button_pressed()
