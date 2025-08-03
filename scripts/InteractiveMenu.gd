extends Control

@onready var hover_info_panel = $UILayer/HoverInfo
@onready var info_label = $UILayer/HoverInfo/InfoLabel
@onready var day_label = $UILayer/DayContainer/DayLabel
@onready var title_container = $UILayer/TitleContainer
@onready var day_container = $UILayer/DayContainer
@onready var background = $Background
@onready var mail_button = $UILayer/MailButton
@onready var settings_button = $UILayer/SettingsButton
@onready var background_music_player = $BackgroundMusicPlayer

# Referencias a nodos del panel de estadísticas
var stats_panel: Panel
var money_label: Label
var fame_label: Label
var fame_level_label: Label
var record_label: Label
var tickets_label: Label
var fame_history_container: VBoxContainer
var shine_effect: ColorRect
var shine_tween: Tween

# Variables para animaciones
var hover_tween: Tween
var entry_tween: Tween
var transition_tween: Tween
var area_buttons = {}
var original_positions = {}
var original_scales = {}
var original_background_position: Vector2
var original_background_scale: Vector2
var is_transitioning = false

# Variables para controlar estados de transición
var is_first_time = true
var last_selected_area = ""
var returning_from_submenu = false
var skip_animation = false

func _ready():
	print("InteractiveMenu: Inicializando menú interactivo...")
	
	# Verificar que todos los nodos existen
	var estadio_area = $ClickableAreas/EstadioArea
	var campo_area = $ClickableAreas/CampoArea
	var barrio_area = $ClickableAreas/BarrioArea
	
	if not estadio_area or not campo_area or not barrio_area:
		print("ERROR: No se pudieron encontrar todas las áreas clickables")
		return
	
	# Configurar rival por defecto si no hay ninguno establecido
	setup_default_rival()
	
	print("InteractiveMenu: Conectando señales...")
	
	# Conectar señales de hover
	estadio_area.mouse_entered.connect(func(): _on_area_hovered("estadio"))
	estadio_area.mouse_exited.connect(self._on_area_exited)
	
	campo_area.mouse_entered.connect(func(): _on_area_hovered("campo"))
	campo_area.mouse_exited.connect(self._on_area_exited)
	
	barrio_area.mouse_entered.connect(func(): _on_area_hovered("barrio"))
	barrio_area.mouse_exited.connect(self._on_area_exited)
	
	# Conectar señales de clic
	estadio_area.pressed.connect(func(): _on_area_clicked("estadio"))
	campo_area.pressed.connect(func(): _on_area_clicked("campo"))
	barrio_area.pressed.connect(func(): _on_area_clicked("barrio"))
	
	# Configurar botón de correos
	setup_mail_button()
	
	# Configurar botón de ajustes
	setup_settings_button()
	
	# Crear panel de estadísticas del club
	create_stats_panel()
	
	# Configurar música de fondo
	setup_background_music()
	
	# Actualizar visualización del día
	update_day_display()
	
	# Conectar a las señales del GameManager para actualizar estadísticas
	if GameManager:
		if GameManager.has_signal("fame_updated"):
			GameManager.fame_updated.connect(_on_fame_updated)
		if GameManager.has_signal("money_updated"):
			GameManager.money_updated.connect(_on_money_updated)
	
	# Conectar a la señal de cambio de día
	if DayManager.has_signal("day_advanced"):
		DayManager.day_advanced.connect(_on_day_advanced)
	if DayManager.has_signal("day_changed"):
		DayManager.day_changed.connect(update_day_display)
	
	# Guardar botones de área y posiciones originales
	area_buttons["estadio"] = estadio_area
	area_buttons["campo"] = campo_area
	area_buttons["barrio"] = barrio_area
	
	for area_name in area_buttons:
		original_positions[area_name] = area_buttons[area_name].position
	
	# Guardar posición y escala originales del fondo
	original_background_position = background.position
	original_background_scale = background.scale
	
	# Crear shader material para el fondo (comentado temporalmente)
	# setup_background_shader()
	
	# Verificar si venimos de la pantalla de correos usando MetaData
	var from_mail_menu = false
	if has_meta("from_mail_menu"):
		from_mail_menu = get_meta("from_mail_menu")
		remove_meta("from_mail_menu")
	
	# Solo hacer la animación completa la primera vez
	# Las siguientes veces (cuando volvemos de submenús) usaremos start_return_transition()
	if is_first_time and not from_mail_menu:
		start_entrance_animation()
	else:
		# Aparecer directamente en modo normal sin animación
		setup_normal_state()
	
	print("InteractiveMenu: Menú interactivo listo")

func _input(event):
	# Detectar pausa con Escape
	if event.is_action_pressed("ui_pause"):
		if PauseManager:
			PauseManager.toggle_pause()
	
	# CHEAT: Pulsar M para mostrar correos
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_M:
			toggle_mail_button() # Muestra u oculta el botón de correos
	
	# CHEAT: Pulsar D para probar la transición de día
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_D:
			test_day_transition()
	
	# CHEAT: Pulsar G para ir directamente al final del último diálogo de entrenamiento
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_G:
			go_to_training_dialogue_end()
	
	# CHEAT: Pulsar 2 para saltar a jornada 2 (Patrulla Canina) con jornada 1 completada
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_2:
			GameManager.activate_skip_to_patrulla_canina_cheat()
	

func test_day_transition():
	print("🌅 CHEAT: Probando transición de día...")
	DayManager.advance_day_with_origin("training")

func _on_area_hovered(area_name):
	hover_info_panel.visible = true
	
	match area_name:
		"estadio":
			info_label.text = "Torneo Tiki-Taka: Compite en el torneo de fútbol 7 y demuestra quién es el mejor equipo."
		"campo":
			info_label.text = "Campo de Entrenamiento: Mejora tus habilidades y las de tu equipo."
		"barrio":
			info_label.text = "El Barrio: Fichajes, enciclopedia de jugadores y tienda de suplementos."

func _on_area_exited():
	hover_info_panel.visible = false

func _on_area_clicked(area_name):
	if is_transitioning:
		return
	
	# Reproducir sonido de navegación
	if GameAudioUtils:
		GameAudioUtils.play_menu_navigate()
	
	print("🔍 Debug: Área clickeada: ", area_name)
	
	# Debug: Mostrar información del RivalTeamsManager
	if RivalTeamsManager:
		var current_rival = RivalTeamsManager.get_current_rival_id()
		print("🔍 Debug: Rival actual: ", current_rival)
		var match_path = RivalTeamsManager.get_match_dialogue_path()
		var training_path = RivalTeamsManager.get_training_dialogue_path()
		print("🔍 Debug: Match dialogue path: ", match_path)
		print("🔍 Debug: Training dialogue path: ", training_path)
	else:
		print("❌ Debug: RivalTeamsManager no disponible")
	
	# Determinar la escena de destino
	var target_scene = ""
	match area_name:
		"estadio":
			print("🏟️ Debug: Accediendo al Torneo/Estadio...")
			target_scene = "res://scenes/TournamentMenu.tscn"
			
		"campo":
			print("⚽ Debug: Accediendo al Entrenamiento...")
			target_scene = "res://scenes/TrainingMenu.tscn"
			
		"barrio":
			print("🏡 Debug: Accediendo al Barrio...")
			target_scene = "res://scenes/NeighborhoodMenu.tscn"
	
	# Solo iniciar transición si tenemos una escena de destino
	if target_scene != "":
		start_zoom_transition(area_name, target_scene)
	else:
		print("ERROR: No se pudo determinar la escena de destino para ", area_name)

# Animación de entrada inicial del menú
func start_entrance_animation():
	entry_tween = get_tree().create_tween()
	
	# Animar la entrada con fade in solamente (más simple y estable)
	for area_name in area_buttons:
		var button = area_buttons[area_name]
		button.modulate = Color(1, 1, 1, 0)  # Empezar invisible
		entry_tween.parallel().tween_property(button, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Animar el título principal
	title_container.modulate = Color(1, 1, 1, 0)  # Comienza invisible
	entry_tween.tween_property(title_container, "modulate:a", 1, 1.0)
	
	# Animar el fondo para efectos visuales iniciales
	background.modulate = Color(1, 1, 1, 0)
	entry_tween.tween_property(background, "modulate:a", 1, 2.0)

# Configurar botón de correos - siempre visible
func setup_mail_button():
	# El botón siempre es visible
	mail_button.visible = true
	mail_button.pressed.connect(open_mail_menu)
	
	# Conectar a las señales del MailManager
	if MailManager:
		MailManager.new_mail_received.connect(_on_new_mail_received)
		MailManager.load_mails_data()  # Cargar correos guardados
		# Actualizar el color inicial
		update_mail_button_color()
	
	print("📧 Botón de correos configurado y visible")

# Configurar botón de ajustes - siempre visible
func setup_settings_button():
	# El botón siempre es visible
	settings_button.visible = true
	settings_button.pressed.connect(show_settings_wheel)
	
	print("⚙️ Botón de ajustes configurado y visible")

# Lógica para determinar si hay correos no leídos
func has_unread_mail() -> bool:
	if MailManager:
		return MailManager.has_unread_mails()
	return false

# Lógica para determinar si hay negociaciones activas
func has_active_negotiations() -> bool:
	return false # TODO: Implementar cuando tengamos negociaciones

# Acción al presionar el botón de correos
func open_mail_menu():
	print("📧 Abrir menú de correos")
	
	# Reproducir sonido de botón
	if GameAudioUtils:
		GameAudioUtils.play_button_click()
	
	if MailManager:
		# Marcar todos los correos como leídos
		var unread_mails = MailManager.get_unread_mails()
		for mail in unread_mails:
			MailManager.mark_mail_as_read(mail.id)
		# Actualizar color del botón
		update_mail_button_color()
	# Abrir la interfaz de correos
	get_tree().change_scene_to_file("res://scenes/MailMenu.tscn")

# Alternar visibilidad del botón de correos
func toggle_mail_button():
	mail_button.visible = not mail_button.visible

# Callback cuando llega un nuevo correo
func _on_new_mail_received(mail_data: Dictionary):
	print("📧 Nuevo correo recibido de: ", mail_data.player_name)
	update_mail_button_color()

# Actualizar color del botón de correos
func update_mail_button_color():
	if has_unread_mail():
		# Botón rojo cuando hay correos no leídos
		mail_button.modulate = Color.RED
		print("📧 Botón de correos - ROJO - hay correos no leídos (", MailManager.get_unread_count(), ")")
	else:
		# Botón normal cuando no hay correos
		mail_button.modulate = Color.WHITE
		print("📧 Botón de correos - BLANCO - no hay correos nuevos")

# Configuración de shader de fondo
func setup_background_shader():
	# Intentar cargar el shader, pero no fallar si no existe
	var shader_path = "res://shaders/background.gdshader"
	if ResourceLoader.exists(shader_path):
		background.material = ShaderMaterial.new()
		var shader = load(shader_path)
		background.material.shader = shader
		print("InteractiveMenu: Shader de fondo cargado correctamente")
	else:
		print("InteractiveMenu: Shader de fondo no encontrado, continuando sin efectos")

# Actualizar visualización del día actual
func update_day_display():
	var current_day = DayManager.get_current_day()
	day_label.text = "Día %d" % current_day

func _on_day_advanced(new_day: int):
	print("🌅 InteractiveMenu: Día avanzado a ", new_day, ", actualizando UI...")
	update_day_display()

# Configurar estado normal sin animación
func setup_normal_state():
	# Establecer el estado del fondo y elementos UI al estado inicial sin animaciones
	self.modulate.a = 1.0
	background.scale = original_background_scale
	background.position = original_background_position
	
	# Restaurar visibilidad de los botones y elementos UI
	for area_name in area_buttons:
		var button = area_buttons[area_name]
		button.modulate.a = 1.0
	
	title_container.modulate.a = 1.0
	day_container.modulate.a = 1.0

# Transición de retorno desde un submenú (tras hacer zoom en un área)
func start_return_transition():
	# Configurar estado inicial: aparecer con el zoom del área donde estuvimos
	# Usar exactamente los mismos valores que en el zoom de ida
	var zoom_offsets = {
		"estadio": Vector2(0, -600),      # Torneo - mismos valores que zoom de ida
		"campo": Vector2(-1400, -1300),  # Entrenamiento - mismos valores que zoom de ida
		"barrio": Vector2(-2800, -900)   # Barrio - mismos valores que zoom de ida
	}
	
	var area_zoom_offset = zoom_offsets.get(last_selected_area, Vector2.ZERO)
	
	background.scale = Vector2(2.5, 2.5)
	background.position = original_background_position + area_zoom_offset
	
	# Crear tween de recuperación para retornar al estado inicial
	transition_tween = get_tree().create_tween()
	transition_tween.set_parallel(true)
	
	# Restaurar fondo a su estado original
	transition_tween.tween_property(background, "scale", original_background_scale, 0.8).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	transition_tween.tween_property(background, "position", original_background_position, 0.8).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	# Fade in de los botones y elementos UI
	for area_name in area_buttons:
		var button = area_buttons[area_name]
		button.modulate.a = 0.0
		transition_tween.tween_property(button, "modulate:a", 1.0, 0.6).set_delay(0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Fade in de elementos UI
	title_container.modulate.a = 0.0
	day_container.modulate.a = 0.0
	transition_tween.tween_property(title_container, "modulate:a", 1.0, 0.6).set_delay(0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	transition_tween.tween_property(day_container, "modulate:a", 1.0, 0.6).set_delay(0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# Transición con zoom al hacer clic en un área
func start_zoom_transition(area_name: String, target_scene: String):
	is_transitioning = true
	
	# Guardar el área seleccionada para cuando volvamos
	last_selected_area = area_name
	is_first_time = false  # Ya no es la primera vez
	
	# Ocultar panel de información
	hover_info_panel.visible = false
	
	# Obtener el botón del área seleccionada para calcular posición
	var selected_button = area_buttons[area_name]
	
	# Crear el tween de transición
	transition_tween = get_tree().create_tween()
	transition_tween.set_parallel(true)
	
	# Definir posiciones de zoom basadas en las ubicaciones visuales en la imagen de fondo
	# Para hacer zoom al centro de la imagen, necesitamos mover el fondo hacia arriba-izquierda
	var zoom_offsets = {
		"estadio": Vector2(0, -600),    # Torneo - izquierda, ligeramente abajo
		"campo": Vector2(-1400, -1300),    # Entrenamiento - centro de la imagen (mover fondo para centrar)
		"barrio": Vector2(-2800, -900)     # Barrio - derecha, ligeramente abajo
	}
	
	# Obtener el offset de zoom para el área seleccionada
	var zoom_offset = zoom_offsets.get(area_name, Vector2.ZERO)
	
	# Calcular la posición objetivo del fondo
	var background_target_pos = original_background_position + zoom_offset
	
	# Fase 1: Zoom del fondo hacia el área seleccionada
	# Escalar el fondo (zoom in)
	transition_tween.tween_property(background, "scale", Vector2(2.5, 2.5), 0.8).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	
	# Mover el fondo para mostrar el área visual correcta
	transition_tween.tween_property(background, "position", background_target_pos, 0.8).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	
	# Fade out de todos los botones
	for button_name in area_buttons:
		transition_tween.tween_property(area_buttons[button_name], "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Fade out de elementos UI
	transition_tween.tween_property(title_container, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	transition_tween.tween_property(day_container, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Fase 2: Fade out de toda la pantalla después del zoom
	transition_tween.tween_property(self, "modulate:a", 0.0, 0.4).set_delay(0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Cambiar a la escena de destino cuando termine la animación
	transition_tween.tween_callback(func(): get_tree().change_scene_to_file(target_scene)).set_delay(1.0)
	
	print("InteractiveMenu: Iniciando transición con zoom del fondo hacia ", area_name)

# ========== SISTEMA DE PANEL DE ESTADÍSTICAS DEL CLUB ==========

func create_stats_panel():
	"""Crea el panel de estadísticas del club con fama, dinero y otros datos"""
	print("📈 Creando panel de estadísticas del club...")
	
	# Crear el panel principal
	stats_panel = Panel.new()
	stats_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	stats_panel.position = Vector2(20, 80)  # Posición en la esquina superior izquierda
	stats_panel.size = Vector2(300, 200)  # Tamaño del panel
	
	# Estilo del panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.2, 0.85)  # Fondo semi-transparente
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color.WHITE
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	stats_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Añadir el panel a la UI
	add_child(stats_panel)
	
	# Container principal del panel
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 8)
	stats_panel.add_child(main_vbox)
	
	# Margin interno
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	main_vbox.add_child(margin)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 6)
	margin.add_child(content_vbox)
	
	# Título del panel
	var title = Label.new()
	title.text = "FC BUFAS - ESTADÍSTICAS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color.YELLOW)
	content_vbox.add_child(title)
	
	# Separator
	var separator = HSeparator.new()
	content_vbox.add_child(separator)
	
	# Crear Grid Container
	var grid = GridContainer.new()
	grid.columns = 2
	content_vbox.add_child(grid)

	# Dinero
	money_label = Label.new()
	money_label.text = "💰 Dinero: "
	money_label.add_theme_font_size_override("font_size", 14)
	money_label.add_theme_color_override("font_color", Color.WHITE)
	grid.add_child(money_label)
	
	# Fama
	fame_label = Label.new()
	fame_label.text = "🎆 Fama: "
	fame_label.add_theme_font_size_override("font_size", 14)
	fame_label.add_theme_color_override("font_color", Color.CYAN)
	grid.add_child(fame_label)
	
	# Nivel de fama
	fame_level_label = Label.new()
	fame_level_label.text = "Nivel de Fama: "
	fame_level_label.add_theme_font_size_override("font_size", 12)
	fame_level_label.add_theme_color_override("font_color", Color(1, 0.9, 0.7, 1))
	grid.add_child(fame_level_label)
	
	# Récord del equipo
	record_label = Label.new()
	record_label.text = "🏆 Récord: "
	record_label.add_theme_font_size_override("font_size", 12)
	record_label.add_theme_color_override("font_color", Color.WHITE)
	grid.add_child(record_label)

	# Tickets
	tickets_label = Label.new()
	tickets_label.text = "🎫 Tickets Bufas: "
	tickets_label.add_theme_font_size_override("font_size", 12)
	tickets_label.add_theme_color_override("font_color", Color.GOLD)
	grid.add_child(tickets_label)

	# Agregar efecto de reflejo
	shine_effect = ColorRect.new()
	shine_effect.color = Color(1, 1, 1, 0.15)
	shine_effect.size = Vector2(30, stats_panel.size.y)
	shine_effect.position = Vector2(-shine_effect.size.x, 0)
	stats_panel.add_child(shine_effect)
	
	# Configurar tween de efecto de reflejo
	start_shine_effect()

	# Container para historial de fama (scrollable)
	var history_scroll = ScrollContainer.new()
	history_scroll.custom_minimum_size = Vector2(0, 80)
	content_vbox.add_child(history_scroll)
	
	fame_history_container = VBoxContainer.new()
	fame_history_container.add_theme_constant_override("separation", 2)
	history_scroll.add_child(fame_history_container)
	
	# Actualizar contenido inicial
	update_stats_panel()
	
	print("📈 Panel de estadísticas creado correctamente")

func update_stats_panel():
	"""Actualiza todo el contenido del panel de estadísticas"""
	if not GameManager:
		return
	
	# Actualizar dinero
	if money_label:
		money_label.text = "💰 " + str(GameManager.get_money())
	
	# Actualizar fama
	if fame_label:
		fame_label.text = "🎆 " + str(GameManager.get_fame())
	
	# Actualizar nivel de fama
	if fame_level_label:
		fame_level_label.text = GameManager.get_fame_level_description()
	
	# Actualizar récord del equipo
	if record_label:
		var wins = GameManager.team_stats.get("wins", 0)
		var losses = GameManager.team_stats.get("losses", 0)
		var draws = GameManager.team_stats.get("draws", 0)
		record_label.text = "🏆 " + str(wins) + "V-" + str(losses) + "D-" + str(draws) + "E"
	
	# Actualizar tickets bufas
	if tickets_label:
		tickets_label.text = "🎫 " + str(GameManager.get_tickets_bufas())
	
	# Actualizar historial de fama
	update_fame_history_display()

func update_fame_history_display():
	"""Actualiza la visualización del historial de fama"""
	if not fame_history_container or not GameManager:
		return
	
	# Limpiar historial anterior
	for child in fame_history_container.get_children():
		child.queue_free()
	
	# Título del historial
	var history_title = Label.new()
	history_title.text = "Cambios de Fama Recientes:"
	history_title.add_theme_font_size_override("font_size", 10)
	history_title.add_theme_color_override("font_color", Color.YELLOW)
	fame_history_container.add_child(history_title)
	
	# Obtener historial reciente
	var recent_changes = GameManager.get_recent_fame_changes(5)
	
	if recent_changes.is_empty():
		var no_history = Label.new()
		no_history.text = "- Sin cambios aún -"
		no_history.add_theme_font_size_override("font_size", 9)
		no_history.add_theme_color_override("font_color", Color.GRAY)
		fame_history_container.add_child(no_history)
	else:
		for entry in recent_changes:
			var history_entry = Label.new()
			var change_text = ""
			var change_color = Color.WHITE
			
			if entry.change > 0:
				change_text = "+" + str(entry.change)
				change_color = Color.GREEN
			else:
				change_text = str(entry.change)
				change_color = Color.RED
			
			history_entry.text = "Día " + str(entry.day) + ": " + change_text + " (" + entry.reason + ")"
			history_entry.add_theme_font_size_override("font_size", 9)
			history_entry.add_theme_color_override("font_color", change_color)
			history_entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			fame_history_container.add_child(history_entry)

# Callbacks para actualización automática del panel
func _on_fame_updated(new_amount: int, reason: String):
	"""Se llama cuando cambia la fama"""
	print("📈 InteractiveMenu: Fama actualizada - ", new_amount, " (", reason, ")")
	update_stats_panel()

func _on_money_updated(new_amount: int):
	"""Se llama cuando cambia el dinero"""
	print("💰 InteractiveMenu: Dinero actualizado - ", new_amount)
	update_stats_panel()

# Función para iniciar el efecto de reflejo constante
func start_shine_effect():
	"""Inicia el efecto de reflejo constante en el panel de estadísticas"""
	if not shine_effect or not stats_panel:
		return
	
	# Crear el tween con bucle infinito
	shine_tween = get_tree().create_tween()
	shine_tween.set_loops()
	
	# Animación del reflejo: mover de izquierda a derecha
	shine_tween.tween_property(shine_effect, "position:x", stats_panel.size.x + shine_effect.size.x, 3.0)
	shine_tween.tween_property(shine_effect, "position:x", -shine_effect.size.x, 0.1)
	shine_tween.tween_interval(2.0)  # Pausa entre animaciones


# Configurar rival por defecto
func setup_default_rival():
	"""Configura el rival basado en el próximo partido de la liga"""
	if RivalTeamsManager:
		# Primero intentar actualizar el rival basado en el próximo partido
		RivalTeamsManager.update_rival_from_next_match()
		
		# Verificar si se estableció correctamente
		var current_rival_id = RivalTeamsManager.get_current_rival_id()
		if current_rival_id == "":
			print("⚠️ InteractiveMenu: No se pudo establecer rival desde LeagueManager, usando rival por defecto")
			# Solo como respaldo, configurar el primer equipo disponible
			var all_teams = RivalTeamsManager.get_all_teams()
			if not all_teams.is_empty():
				var first_team_id = all_teams.keys()[0]
				RivalTeamsManager.set_current_rival(first_team_id)
				print("📋 InteractiveMenu: Rival por defecto establecido: ", first_team_id)
			else:
				print("❌ InteractiveMenu: No hay equipos rivales configurados")
		else:
			print("✅ InteractiveMenu: Rival establecido desde liga: ", current_rival_id)
	else:
		print("❌ InteractiveMenu: RivalTeamsManager no disponible")

# Función para transición al final del último diálogo de entrenamiento
func go_to_training_dialogue_end():
	print("🚀 CHEAT: Transicionando al final del último diálogo de entrenamiento...")
	
	# Configurar metadata para que el DialogueSystem sepa que debe cargar un diálogo específico
	# y saltar directamente a la línea deseada (índice 9, que corresponde a la línea de Yazawa)
	get_tree().set_meta("jump_to_specific_line", true)
	get_tree().set_meta("dialogue_file_path", "res://data/training_dialogues/post_training_dialogue.json")
	get_tree().set_meta("target_line_index", 9)  # Índice de la línea: "Venga, ya está bien de quejas..."
	
	# Ir a la escena de diálogo
	get_tree().change_scene_to_file("res://scenes/DialogueScene.tscn")

# Función para mostrar la ruedita de ajustes
func show_settings_wheel():
	print("🎵 Mostrando menú de ajustes de audio...")
	
	# Reproducir sonido de menu
	if GameAudioUtils:
		GameAudioUtils.play_button_click()
	
	# Crear instancia del menú de ajustes
	var audio_settings_scene = preload("res://scenes/AudioSettingsMenu.tscn")
	var audio_settings_menu = audio_settings_scene.instantiate()
	
	# Conectar señal de cierre
	audio_settings_menu.close_requested.connect(_on_audio_settings_closed.bind(audio_settings_menu))
	
	# Añadir a la escena
	add_child(audio_settings_menu)
	audio_settings_menu.show_menu()

func _on_audio_settings_closed(menu_instance):
	print("🎵 Cerrando menú de ajustes de audio...")
	if menu_instance:
		menu_instance.queue_free()

# ========== SISTEMA DE MÚSICA DE FONDO ==========

func setup_background_music():
	"""Configura la música de fondo del menú principal"""
	print("🎵 Configurando música de fondo del menú principal...")
	
	if not background_music_player:
		print("❌ Error: No se encontró el reproductor de música de fondo")
		return
	
	# Cargar la música de título
	var music_path = "res://assets/audio/music/Title.ogg"
	if ResourceLoader.exists(music_path):
		var music_resource = load(music_path)
		background_music_player.stream = music_resource
		background_music_player.autoplay = false
		background_music_player.bus = "Music"
		
		# Configurar el loop
		if music_resource is AudioStreamOggVorbis:
			music_resource.loop = true
		
		# Aplicar el volumen de música desde el AudioManager
		if AudioManager:
			var music_volume = AudioManager.get_music_volume()
			background_music_player.volume_db = linear_to_db(music_volume)
			print("🎵 Volumen de música aplicado: ", music_volume, " (", background_music_player.volume_db, " dB)")
		
		# Conectar a las señales del AudioManager para cambios de volumen
		if AudioManager.has_signal("music_volume_changed"):
			AudioManager.music_volume_changed.connect(_on_music_volume_changed)
		
		# Iniciar la música
		background_music_player.play()
		print("🎵 Música de fondo iniciada: Title.ogg")
	else:
		print("❌ Error: No se pudo cargar la música de título en: ", music_path)

func _on_music_volume_changed(new_volume: float):
	"""Callback cuando cambia el volumen de música desde los ajustes"""
	if background_music_player:
		background_music_player.volume_db = linear_to_db(new_volume)
		print("🎵 Volumen de música actualizado: ", new_volume, " (", background_music_player.volume_db, " dB)")

func stop_background_music():
	"""Detiene la música de fondo (útil al cambiar de escena)"""
	if background_music_player and background_music_player.playing:
		background_music_player.stop()
		print("🎵 Música de fondo detenida")

