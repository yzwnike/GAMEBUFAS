extends Control

@onready var hover_info_panel = $UILayer/HoverInfo
@onready var info_label = $UILayer/HoverInfo/InfoLabel
@onready var day_label = $UILayer/DayContainer/DayLabel
@onready var title_container = $UILayer/TitleContainer
@onready var day_container = $UILayer/DayContainer
@onready var background = $Background
@onready var mail_button = $UILayer/MailButton
@onready var campaigns_button = $UILayer/CampaignsButton

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
	
	# Crear panel de estadísticas del club
	create_stats_panel()
	
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
	# CHEAT: Pulsar M para mostrar correos
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_M:
			toggle_mail_button() # Muestra u oculta el botón de correos
	
	# CHEAT: Pulsar D para probar la transición de día
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_D:
			test_day_transition()

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
	
	print("InteractiveMenu: Área clickeada: ", area_name)
	
	# Determinar la escena de destino
	var target_scene = ""
	match area_name:
		"estadio":
			print("Accediendo al Torneo Tiki-Taka...")
			target_scene = "res://scenes/TournamentMenu.tscn"
		"campo":
			print("Accediendo al Campo de Entrenamiento...")
			target_scene = "res://scenes/TrainingMenu.tscn"
		"barrio":
			print("Accediendo al Barrio...")
			target_scene = "res://scenes/NeighborhoodMenu.tscn"
	
	# Iniciar transición con zoom
	start_zoom_transition(area_name, target_scene)

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

# ========== SISTEMA DE CAMPAÑAS ==========


func update_campaigns_button_state():
	"""Actualiza el estado visual del botón de campañas"""
	if not campaigns_button or not CampaignsManager:
		return
	
	var active_campaigns = CampaignsManager.get_active_campaigns()
	
	if active_campaigns.size() > 0:
		# Botón verde cuando hay campañas activas
		campaigns_button.modulate = Color.GREEN
		print("🎯 Botón de campañas - VERDE - campañas activas: ", active_campaigns.size())
	else:
		# Botón normal cuando no hay campañas activas
		campaigns_button.modulate = Color.WHITE
		print("🎯 Botón de campañas - BLANCO - sin campañas activas")

func open_campaigns_popup():
	"""Abre el popup de campañas"""
	print("🎯 Abriendo popup de campañas...")
	
	if not CampaignsManager:
		print("❌ CampaignsManager no disponible")
		return
	
	# Crear el popup
	var popup = create_campaigns_popup()
	add_child(popup)
	
	# Mostrar con animación
	popup.popup_centered()

func create_campaigns_popup() -> AcceptDialog:
	"""Crea el popup de gestión de campañas"""
	var popup = AcceptDialog.new()
	popup.title = "🎯 GESTIÓN DE CAMPAÑAS"
	popup.size = Vector2(800, 600)
	popup.unresizable = false
	
	# Crear contenido principal
	var main_container = VBoxContainer.new()
	main_container.add_theme_constant_override("separation", 15)
	popup.add_child(main_container)
	
	# Título y descripción
	var title = Label.new()
	title.text = "Campañas del FC Bufas"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.YELLOW)
	main_container.add_child(title)
	
	var description = Label.new()
	description.text = "Las campañas son proyectos a medio plazo que aumentan fama, dinero o la imagen del club."
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.add_theme_font_size_override("font_size", 12)
	description.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_container.add_child(description)
	
	# Crear pestañas
	var tab_container = TabContainer.new()
	tab_container.custom_minimum_size = Vector2(0, 500)
	main_container.add_child(tab_container)
	
	# Pestaña: Campañas Activas
	var active_tab = create_active_campaigns_tab()
	active_tab.name = "🟢 Activas"
	tab_container.add_child(active_tab)
	
	# Pestaña: Campañas Disponibles
	var available_tab = create_available_campaigns_tab()
	available_tab.name = "📋 Disponibles"
	tab_container.add_child(available_tab)
	
	# Pestaña: Historial
	var history_tab = create_campaigns_history_tab()
	history_tab.name = "📚 Historial"
	tab_container.add_child(history_tab)
	
	return popup

func create_active_campaigns_tab() -> ScrollContainer:
	"""Crea la pestaña de campañas activas"""
	var scroll = ScrollContainer.new()
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	scroll.add_child(container)
	
	var active_campaigns = CampaignsManager.get_active_campaigns()
	
	if active_campaigns.is_empty():
		var no_campaigns = Label.new()
		no_campaigns.text = "No hay campañas activas actualmente."
		no_campaigns.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_campaigns.add_theme_color_override("font_color", Color.GRAY)
		container.add_child(no_campaigns)
	else:
		for campaign in active_campaigns:
			var campaign_card = create_active_campaign_card(campaign)
			container.add_child(campaign_card)
	
	return scroll

func create_active_campaign_card(campaign: Dictionary) -> Panel:
	"""Crea una tarjeta para una campaña activa"""
	var card = Panel.new()
	card.custom_minimum_size = Vector2(0, 120)
	
	# Estilo de la tarjeta
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.3, 0.4, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color.CYAN
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	card.add_theme_stylebox_override("panel", style)
	
	# Contenido de la tarjeta
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)
	
	var hbox = HBoxContainer.new()
	margin.add_child(hbox)
	
	# Columna izquierda: Info principal
	var left_column = VBoxContainer.new()
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(left_column)
	
	# Título de la campaña
	var campaign_title = Label.new()
	campaign_title.text = campaign.icon + " " + campaign.name
	campaign_title.add_theme_font_size_override("font_size", 16)
	campaign_title.add_theme_color_override("font_color", Color.WHITE)
	left_column.add_child(campaign_title)
	
	# Descripción
	var campaign_desc = Label.new()
	campaign_desc.text = campaign.description
	campaign_desc.add_theme_font_size_override("font_size", 11)
	campaign_desc.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	campaign_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_column.add_child(campaign_desc)
	
	# Progreso
	var progress_text = CampaignsManager.get_campaign_progress_text(campaign)
	var progress_label = Label.new()
	progress_label.text = "Progreso: " + progress_text
	progress_label.add_theme_font_size_override("font_size", 12)
	progress_label.add_theme_color_override("font_color", Color.YELLOW)
	left_column.add_child(progress_label)
	
	# Columna derecha: Acciones
	var right_column = VBoxContainer.new()
	right_column.custom_minimum_size = Vector2(120, 0)
	hbox.add_child(right_column)
	
	# Barra de progreso
	var progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = campaign.duration
	progress_bar.value = campaign.progress
	progress_bar.show_percentage = false
	right_column.add_child(progress_bar)
	
	# Botón cancelar
	var cancel_button = Button.new()
	cancel_button.text = "❌ Cancelar"
	cancel_button.add_theme_color_override("font_color", Color.RED)
	cancel_button.pressed.connect(func(): cancel_campaign_confirm(campaign))
	right_column.add_child(cancel_button)
	
	return card

func create_available_campaigns_tab() -> ScrollContainer:
	"""Crea la pestaña de campañas disponibles"""
	var scroll = ScrollContainer.new()
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	scroll.add_child(container)
	
	var available_campaigns = CampaignsManager.get_available_campaigns()
	
	if available_campaigns.is_empty():
		var no_campaigns = Label.new()
		no_campaigns.text = "No hay campañas disponibles en este momento."
		no_campaigns.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_campaigns.add_theme_color_override("font_color", Color.GRAY)
		container.add_child(no_campaigns)
	else:
		for campaign in available_campaigns:
			var campaign_card = create_available_campaign_card(campaign)
			container.add_child(campaign_card)
	
	return scroll

func create_available_campaign_card(campaign: Dictionary) -> Panel:
	"""Crea una tarjeta para una campaña disponible"""
	var card = Panel.new()
	card.custom_minimum_size = Vector2(0, 140)
	
	# Estilo de la tarjeta
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.2, 0.1, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color.GREEN
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	card.add_theme_stylebox_override("panel", style)
	
	# Contenido de la tarjeta
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)
	
	var hbox = HBoxContainer.new()
	margin.add_child(hbox)
	
	# Columna izquierda: Info principal
	var left_column = VBoxContainer.new()
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(left_column)
	
	# Título de la campaña
	var campaign_title = Label.new()
	campaign_title.text = campaign.icon + " " + campaign.name
	campaign_title.add_theme_font_size_override("font_size", 16)
	campaign_title.add_theme_color_override("font_color", Color.WHITE)
	left_column.add_child(campaign_title)
	
	# Descripción
	var campaign_desc = Label.new()
	campaign_desc.text = campaign.description
	campaign_desc.add_theme_font_size_override("font_size", 11)
	campaign_desc.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	campaign_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_column.add_child(campaign_desc)
	
	# Detalles
	var details = get_campaign_details_text(campaign)
	var details_label = Label.new()
	details_label.text = details
	details_label.add_theme_font_size_override("font_size", 10)
	details_label.add_theme_color_override("font_color", Color.CYAN)
	left_column.add_child(details_label)
	
	# Columna derecha: Acciones
	var right_column = VBoxContainer.new()
	right_column.custom_minimum_size = Vector2(140, 0)
	hbox.add_child(right_column)
	
	# Coste
	if campaign.cost > 0:
		var cost_label = Label.new()
		cost_label.text = "💰 Costo: " + str(campaign.cost)
		cost_label.add_theme_font_size_override("font_size", 12)
		cost_label.add_theme_color_override("font_color", Color.ORANGE)
		right_column.add_child(cost_label)
	else:
		var free_label = Label.new()
		free_label.text = "✨ GRATIS"
		free_label.add_theme_font_size_override("font_size", 12)
		free_label.add_theme_color_override("font_color", Color.GREEN)
		right_column.add_child(free_label)
	
	# Botón iniciar
	var start_button = Button.new()
	start_button.text = "🚀 Iniciar"
	start_button.add_theme_color_override("font_color", Color.WHITE)
	start_button.pressed.connect(func(): start_campaign_confirm(campaign))
	right_column.add_child(start_button)
	
	return card

func create_campaigns_history_tab() -> ScrollContainer:
	"""Crea la pestaña de historial de campañas"""
	var scroll = ScrollContainer.new()
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	scroll.add_child(container)
	
	var completed_campaigns = CampaignsManager.get_completed_campaigns()
	
	if completed_campaigns.is_empty():
		var no_history = Label.new()
		no_history.text = "No se han completado campañas aún."
		no_history.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_history.add_theme_color_override("font_color", Color.GRAY)
		container.add_child(no_history)
	else:
		for campaign in completed_campaigns:
			var history_item = create_campaign_history_item(campaign)
			container.add_child(history_item)
	
	return scroll

func create_campaign_history_item(campaign: Dictionary) -> Panel:
	"""Crea un elemento del historial de campañas"""
	var item = Panel.new()
	item.custom_minimum_size = Vector2(0, 80)
	
	# Estilo del item
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.6)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color.GRAY
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	item.add_theme_stylebox_override("panel", style)
	
	# Contenido del item
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	item.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	# Título
	var title = Label.new()
	title.text = campaign.icon + " " + campaign.name + " - COMPLETADA"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	vbox.add_child(title)
	
	# Detalles
	var start_day = campaign.get("start_day", 1)
	var details = Label.new()
	details.text = "Iniciada día " + str(start_day) + " • Duración: " + str(campaign.duration) + " " + campaign.duration_type
	details.add_theme_font_size_override("font_size", 10)
	details.add_theme_color_override("font_color", Color.GRAY)
	vbox.add_child(details)
	
	return item

func get_campaign_details_text(campaign: Dictionary) -> String:
	"""Genera el texto de detalles de una campaña"""
	var details = []
	
	# Duración
	var duration_text = str(campaign.duration)
	if campaign.duration_type == "matches":
		duration_text += " partidos"
	else:
		duration_text += " días"
	details.append("⏱️ " + duration_text)
	
	# Efectos
	var effects = campaign.get("effects", {})
	if effects.has("fame_gain"):
		details.append("🎆 +" + str(effects.fame_gain) + " fama")
	if effects.has("money_per_match"):
		details.append("💰 +" + str(effects.money_per_match) + " por partido")
	
	# Nivel de riesgo
	var risk_level = campaign.get("risk_level", "low")
	var risk_text = ""
	var risk_color = ""
	match risk_level:
		"low":
			risk_text = "🟢 Riesgo Bajo"
		"medium":
			risk_text = "🟡 Riesgo Medio"
		"high":
			risk_text = "🔴 Riesgo Alto"
	details.append(risk_text)
	
	return " • ".join(details)

func start_campaign_confirm(campaign: Dictionary):
	"""Confirma y inicia una campaña"""
	var confirm_text = "¿Iniciar la campaña '" + campaign.name + "'?"
	if campaign.cost > 0:
		confirm_text += "\n\nCosto: " + str(campaign.cost) + " monedas"
	
	var confirmation = ConfirmationDialog.new()
	confirmation.dialog_text = confirm_text
	confirmation.title = "Confirmar Campaña"
	add_child(confirmation)
	
	confirmation.confirmed.connect(func():
		if CampaignsManager.start_campaign(campaign.id):
			print("✅ Campaña iniciada: ", campaign.name)
			update_campaigns_button_state()
			# Cerrar el popup actual y reabrir para actualizar
			get_viewport().get_children()[-1].queue_free()
			open_campaigns_popup()
		else:
			print("❌ No se pudo iniciar la campaña: ", campaign.name)
		confirmation.queue_free()
	)
	
	confirmation.popup_centered()

func cancel_campaign_confirm(campaign: Dictionary):
	"""Confirma y cancela una campaña"""
	var confirm_text = "¿Cancelar la campaña '" + campaign.name + "'?"
	if campaign.cost > 0:
		var penalty = int(campaign.cost * 0.5)
		confirm_text += "\n\nPenalización: " + str(penalty) + " monedas"
	
	var confirmation = ConfirmationDialog.new()
	confirmation.dialog_text = confirm_text
	confirmation.title = "Confirmar Cancelación"
	add_child(confirmation)
	
	confirmation.confirmed.connect(func():
		if CampaignsManager.cancel_campaign(campaign.instance_id):
			print("❌ Campaña cancelada: ", campaign.name)
			update_campaigns_button_state()
			# Cerrar el popup actual y reabrir para actualizar
			get_viewport().get_children()[-1].queue_free()
			open_campaigns_popup()
		else:
			print("❌ No se pudo cancelar la campaña: ", campaign.name)
		confirmation.queue_free()
	)
	
	confirmation.popup_centered()

