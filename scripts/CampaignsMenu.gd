extends Control

# 🎯 MENU COMPLETO DE CAMPAÑAS
# Sistema de gestión de campañas a medio plazo para el FC Bufas

# Referencias a nodos principales
var background
var title_label
var subtitle_label
var tab_container
var back_button

# Variables para animaciones
var entry_tween: Tween
var button_hover_tweens = {}
var original_scales = {}

# Variables para el sistema de campañas
var active_campaigns_container: VBoxContainer
var available_campaigns_container: VBoxContainer
var history_campaigns_container: VBoxContainer

func _ready():
	print("🎯 CampaignsMenu: Inicializando menú de campañas...")
	
	# Inicializar referencias a nodos
	init_node_references()
	
	# Configurar estilos
	setup_styles()
	
	# Crear contenido de las pestañas
	create_tabs_content()
	
	# Conectar señales
	connect_signals()
	
	# Configurar animaciones
	setup_animations()
	
	# Actualizar contenido inicial
	update_campaigns_display()
	
	# Iniciar animación de entrada
	start_entrance_animation()
	
	print("🎯 CampaignsMenu: Menú de campañas listo")

func init_node_references():
	"""Inicializa las referencias a los nodos de la escena"""
	background = get_node_or_null("Background")
	title_label = get_node_or_null("UILayer/TitleContainer/TitleLabel")
	subtitle_label = get_node_or_null("UILayer/TitleContainer/SubtitleLabel")
	tab_container = get_node_or_null("UILayer/MainContainer/TabContainer")
	back_button = get_node_or_null("UILayer/BackButton")
	
	# Verificar que los nodos críticos existan
	if not title_label or not tab_container or not back_button:
		print("⚠️ CampaignsMenu: Algunos nodos críticos no fueron encontrados")
		print("Title: ", title_label != null, ", TabContainer: ", tab_container != null, ", BackButton: ", back_button != null)
	else:
		print("✅ CampaignsMenu: Todos los nodos inicializados correctamente")

func setup_styles():
	"""Configura los estilos visuales del menú"""
	# Estilo del título principal
	if title_label:
		title_label.text = "🎯 GESTIÓN DE CAMPAÑAS"
		title_label.add_theme_font_size_override("font_size", 48)
		title_label.add_theme_color_override("font_color", Color.YELLOW)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Estilo del subtítulo
	if subtitle_label:
		subtitle_label.text = "Proyectos a medio plazo para aumentar fama, dinero e imagen del club"
		subtitle_label.add_theme_font_size_override("font_size", 16)
		subtitle_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
		subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Estilo del botón de volver
	if back_button:
		back_button.text = "← Volver a la Oficina"
		back_button.add_theme_font_size_override("font_size", 20)
		back_button.add_theme_color_override("font_color", Color.WHITE)

func create_tabs_content():
	"""Crea el contenido de las pestañas de campañas"""
	if not tab_container:
		print("❌ TabContainer no encontrado")
		return
	
	# Limpiar pestañas existentes
	for child in tab_container.get_children():
		child.queue_free()
	
	# Pestaña 1: Campañas Activas
	var active_tab = create_active_campaigns_tab()
	active_tab.name = "🟢 ACTIVAS"
	tab_container.add_child(active_tab)
	
	# Pestaña 2: Campañas Disponibles
	var available_tab = create_available_campaigns_tab()
	available_tab.name = "📋 DISPONIBLES"
	tab_container.add_child(available_tab)
	
	# Pestaña 3: Historial
	var history_tab = create_history_campaigns_tab()
	history_tab.name = "📚 HISTORIAL"
	tab_container.add_child(history_tab)

func create_active_campaigns_tab() -> ScrollContainer:
	"""Crea la pestaña de campañas activas"""
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 500)
	
	var main_container = VBoxContainer.new()
	main_container.add_theme_constant_override("separation", 15)
	scroll.add_child(main_container)
	
	# Título de la sección
	var section_title = Label.new()
	section_title.text = "Campañas en Progreso"
	section_title.add_theme_font_size_override("font_size", 24)
	section_title.add_theme_color_override("font_color", Color.CYAN)
	main_container.add_child(section_title)
	
	# Descripción
	var description = Label.new()
	description.text = "Estas campañas están actualmente en curso y progresan automáticamente."
	description.add_theme_font_size_override("font_size", 14)
	description.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_container.add_child(description)
	
	# Container para las campañas activas
	active_campaigns_container = VBoxContainer.new()
	active_campaigns_container.add_theme_constant_override("separation", 10)
	main_container.add_child(active_campaigns_container)
	
	return scroll

func create_available_campaigns_tab() -> ScrollContainer:
	"""Crea la pestaña de campañas disponibles"""
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 500)
	
	var main_container = VBoxContainer.new()
	main_container.add_theme_constant_override("separation", 15)
	scroll.add_child(main_container)
	
	# Título de la sección
	var section_title = Label.new()
	section_title.text = "Campañas Disponibles"
	section_title.add_theme_font_size_override("font_size", 24)
	section_title.add_theme_color_override("font_color", Color.GREEN)
	main_container.add_child(section_title)
	
	# Descripción
	var description = Label.new()
	description.text = "Selecciona una campaña para iniciar. Cada campaña tiene diferentes costos, duraciones y beneficios."
	description.add_theme_font_size_override("font_size", 14)
	description.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_container.add_child(description)
	
	# Container para las campañas disponibles
	available_campaigns_container = VBoxContainer.new()
	available_campaigns_container.add_theme_constant_override("separation", 10)
	main_container.add_child(available_campaigns_container)
	
	return scroll

func create_history_campaigns_tab() -> ScrollContainer:
	"""Crea la pestaña de historial de campañas"""
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 500)
	
	var main_container = VBoxContainer.new()
	main_container.add_theme_constant_override("separation", 15)
	scroll.add_child(main_container)
	
	# Título de la sección
	var section_title = Label.new()
	section_title.text = "Historial de Campañas"
	section_title.add_theme_font_size_override("font_size", 24)
	section_title.add_theme_color_override("font_color", Color.GOLD)
	main_container.add_child(section_title)
	
	# Descripción
	var description = Label.new()
	description.text = "Campañas completadas y sus resultados obtenidos."
	description.add_theme_font_size_override("font_size", 14)
	description.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_container.add_child(description)
	
	# Container para el historial
	history_campaigns_container = VBoxContainer.new()
	history_campaigns_container.add_theme_constant_override("separation", 8)
	main_container.add_child(history_campaigns_container)
	
	return scroll

func connect_signals():
	"""Conecta las señales de los botones"""
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	
	# Conectar a eventos del CampaignsManager
	if CampaignsManager:
		if CampaignsManager.has_signal("campaign_completed"):
			CampaignsManager.campaign_completed.connect(_on_campaign_completed)
		if CampaignsManager.has_signal("campaign_started"):
			CampaignsManager.campaign_started.connect(_on_campaign_started)
		if CampaignsManager.has_signal("campaign_cancelled"):
			CampaignsManager.campaign_cancelled.connect(_on_campaign_cancelled)

func setup_animations():
	"""Configura las animaciones de hover para los botones"""
	if back_button:
		original_scales[back_button] = back_button.scale
		setup_button_hover_animation(back_button)

func setup_button_hover_animation(button):
	"""Configura animación de hover para un botón"""
	button.mouse_entered.connect(func(): _on_button_hovered(button))
	button.mouse_exited.connect(func(): _on_button_unhovered(button))

func _on_button_hovered(button):
	"""Animación cuando el cursor entra en un botón"""
	if button_hover_tweens.has(button) and button_hover_tweens[button]:
		button_hover_tweens[button].kill()
	
	button_hover_tweens[button] = get_tree().create_tween()
	button_hover_tweens[button].tween_property(button, "scale", Vector2(1.1, 1.1), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_button_unhovered(button):
	"""Animación cuando el cursor sale de un botón"""
	if button_hover_tweens.has(button) and button_hover_tweens[button]:
		button_hover_tweens[button].kill()
	
	button_hover_tweens[button] = get_tree().create_tween()
	button_hover_tweens[button].tween_property(button, "scale", original_scales[button], 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func start_entrance_animation():
	"""Inicia la animación de entrada del menú"""
	if entry_tween:
		entry_tween.kill()
	
	entry_tween = get_tree().create_tween()
	
	# Fade in del fondo
	if background:
		background.modulate = Color(1, 1, 1, 0)
		entry_tween.tween_property(background, "modulate:a", 1, 1.5)
	
	# Fade in de elementos UI
	for element in [title_label, subtitle_label, tab_container, back_button]:
		if element:
			element.modulate = Color(1, 1, 1, 0)
			entry_tween.parallel().tween_property(element, "modulate:a", 1, 1.0).set_delay(0.3)

func update_campaigns_display():
	"""Actualiza la visualización de todas las campañas"""
	update_active_campaigns()
	update_available_campaigns()
	update_history_campaigns()

func update_active_campaigns():
	"""Actualiza la visualización de campañas activas"""
	if not active_campaigns_container or not CampaignsManager:
		return
	
	# Limpiar contenido anterior
	for child in active_campaigns_container.get_children():
		child.queue_free()
	
	var active_campaigns = CampaignsManager.get_active_campaigns()
	
	if active_campaigns.is_empty():
		var no_campaigns = Label.new()
		no_campaigns.text = "No hay campañas activas actualmente."
		no_campaigns.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_campaigns.add_theme_color_override("font_color", Color.GRAY)
		no_campaigns.add_theme_font_size_override("font_size", 16)
		active_campaigns_container.add_child(no_campaigns)
	else:
		for campaign in active_campaigns:
			var campaign_card = create_active_campaign_card(campaign)
			active_campaigns_container.add_child(campaign_card)

func update_available_campaigns():
	"""Actualiza la visualización de campañas disponibles"""
	if not available_campaigns_container or not CampaignsManager:
		return
	
	# Limpiar contenido anterior
	for child in available_campaigns_container.get_children():
		child.queue_free()
	
	var available_campaigns = CampaignsManager.get_available_campaigns()
	
	if available_campaigns.is_empty():
		var no_campaigns = Label.new()
		no_campaigns.text = "No hay campañas disponibles en este momento."
		no_campaigns.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_campaigns.add_theme_color_override("font_color", Color.GRAY)
		no_campaigns.add_theme_font_size_override("font_size", 16)
		available_campaigns_container.add_child(no_campaigns)
	else:
		for campaign in available_campaigns:
			var campaign_card = create_available_campaign_card(campaign)
			available_campaigns_container.add_child(campaign_card)

func update_history_campaigns():
	"""Actualiza la visualización del historial de campañas"""
	if not history_campaigns_container or not CampaignsManager:
		return
	
	# Limpiar contenido anterior
	for child in history_campaigns_container.get_children():
		child.queue_free()
	
	var completed_campaigns = CampaignsManager.get_completed_campaigns()
	
	if completed_campaigns.is_empty():
		var no_history = Label.new()
		no_history.text = "No se han completado campañas aún."
		no_history.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_history.add_theme_color_override("font_color", Color.GRAY)
		no_history.add_theme_font_size_override("font_size", 16)
		history_campaigns_container.add_child(no_history)
	else:
		for campaign in completed_campaigns:
			var history_item = create_campaign_history_item(campaign)
			history_campaigns_container.add_child(history_item)

func create_active_campaign_card(campaign: Dictionary) -> Panel:
	"""Crea una tarjeta para una campaña activa"""
	var card = Panel.new()
	card.custom_minimum_size = Vector2(0, 140)
	
	# Estilo de la tarjeta
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.3, 0.4, 0.9)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color.CYAN
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	card.add_theme_stylebox_override("panel", style)
	
	# Contenido de la tarjeta
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
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
	campaign_title.add_theme_font_size_override("font_size", 18)
	campaign_title.add_theme_color_override("font_color", Color.WHITE)
	left_column.add_child(campaign_title)
	
	# Descripción
	var campaign_desc = Label.new()
	campaign_desc.text = campaign.description
	campaign_desc.add_theme_font_size_override("font_size", 12)
	campaign_desc.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	campaign_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_column.add_child(campaign_desc)
	
	# Progreso
	var progress_text = CampaignsManager.get_campaign_progress_text(campaign)
	var progress_label = Label.new()
	progress_label.text = "🔄 Progreso: " + progress_text
	progress_label.add_theme_font_size_override("font_size", 14)
	progress_label.add_theme_color_override("font_color", Color.YELLOW)
	left_column.add_child(progress_label)
	
	# Columna derecha: Acciones y progreso
	var right_column = VBoxContainer.new()
	right_column.custom_minimum_size = Vector2(200, 0)
	hbox.add_child(right_column)
	
	# Barra de progreso
	var progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = campaign.duration
	progress_bar.value = campaign.progress
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = Vector2(0, 20)
	right_column.add_child(progress_bar)
	
	# Información de tiempo restante
	var remaining = campaign.duration - campaign.progress
	var time_info = Label.new()
	var time_unit = "partidos" if campaign.duration_type == "matches" else "días"
	time_info.text = "⏰ Restante: " + str(remaining) + " " + time_unit
	time_info.add_theme_font_size_override("font_size", 11)
	time_info.add_theme_color_override("font_color", Color.ORANGE)
	right_column.add_child(time_info)
	
	# Botón cancelar
	var cancel_button = Button.new()
	cancel_button.text = "❌ Cancelar Campaña"
	cancel_button.add_theme_color_override("font_color", Color.RED)
	cancel_button.pressed.connect(func(): cancel_campaign_confirm(campaign))
	right_column.add_child(cancel_button)
	
	return card

func create_available_campaign_card(campaign: Dictionary) -> Panel:
	"""Crea una tarjeta para una campaña disponible"""
	var card = Panel.new()
	card.custom_minimum_size = Vector2(0, 160)
	
	# Estilo de la tarjeta
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.25, 0.1, 0.9)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color.GREEN
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	card.add_theme_stylebox_override("panel", style)
	
	# Contenido de la tarjeta
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
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
	campaign_title.add_theme_font_size_override("font_size", 18)
	campaign_title.add_theme_color_override("font_color", Color.WHITE)
	left_column.add_child(campaign_title)
	
	# Descripción
	var campaign_desc = Label.new()
	campaign_desc.text = campaign.description
	campaign_desc.add_theme_font_size_override("font_size", 12)
	campaign_desc.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	campaign_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_column.add_child(campaign_desc)
	
	# Detalles de la campaña
	var effects = campaign.get("effects", {})
	var details_text = get_campaign_details_text(campaign)
	var details_label = Label.new()
	details_label.text = details_text
	details_label.add_theme_font_size_override("font_size", 11)
	details_label.add_theme_color_override("font_color", Color.CYAN)
	left_column.add_child(details_label)
	
	# Columna derecha: Costo y acciones
	var right_column = VBoxContainer.new()
	right_column.custom_minimum_size = Vector2(180, 0)
	hbox.add_child(right_column)
	
	# Costo de la campaña
	if campaign.cost > 0:
		var cost_label = Label.new()
		cost_label.text = "💰 Costo: " + str(campaign.cost) + "€"
		cost_label.add_theme_font_size_override("font_size", 14)
		cost_label.add_theme_color_override("font_color", Color.ORANGE)
		right_column.add_child(cost_label)
	else:
		var free_label = Label.new()
		free_label.text = "✨ GRATUITA"
		free_label.add_theme_font_size_override("font_size", 14)
		free_label.add_theme_color_override("font_color", Color.GREEN)
		right_column.add_child(free_label)
	
	# Duración
	var duration_label = Label.new()
	var duration_text = str(campaign.duration)
	if campaign.duration_type == "matches":
		duration_text += " partidos"
	else:
		duration_text += " días"
	duration_label.text = "⏱️ Duración: " + duration_text
	duration_label.add_theme_font_size_override("font_size", 12)
	duration_label.add_theme_color_override("font_color", Color.YELLOW)
	right_column.add_child(duration_label)
	
	# Botón iniciar
	var start_button = Button.new()
	start_button.text = "🚀 Iniciar Campaña"
	start_button.add_theme_color_override("font_color", Color.WHITE)
	start_button.pressed.connect(func(): start_campaign_confirm(campaign))
	right_column.add_child(start_button)
	
	return card

func create_campaign_history_item(campaign: Dictionary) -> Panel:
	"""Crea un elemento del historial de campañas"""
	var item = Panel.new()
	item.custom_minimum_size = Vector2(0, 100)
	
	# Estilo del item
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color.GOLD
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	item.add_theme_stylebox_override("panel", style)
	
	# Contenido del item
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	item.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	# Título
	var title = Label.new()
	title.text = campaign.icon + " " + campaign.name + " - ✅ COMPLETADA"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	vbox.add_child(title)
	
	# Detalles de finalización
	var start_day = campaign.get("start_day", 1)
	var completion_info = Label.new()
	completion_info.text = "📅 Iniciada día " + str(start_day) + " • Duración: " + str(campaign.duration) + " " + campaign.duration_type
	completion_info.add_theme_font_size_override("font_size", 11)
	completion_info.add_theme_color_override("font_color", Color.GRAY)
	vbox.add_child(completion_info)
	
	# Resultados obtenidos
	var effects = campaign.get("effects", {})
	if not effects.is_empty():
		var results_text = "🎁 Resultados: "
		var results = []
		if effects.has("fame_gain"):
			results.append("+" + str(effects.fame_gain) + " fama")
		if effects.has("money_gain"):
			results.append("+" + str(effects.money_gain) + "€")
		if effects.has("money_per_match"):
			var total_money = effects.money_per_match * campaign.duration
			results.append("+" + str(total_money) + "€ total")
		
		results_text += " • ".join(results)
		
		var results_label = Label.new()
		results_label.text = results_text
		results_label.add_theme_font_size_override("font_size", 12)
		results_label.add_theme_color_override("font_color", Color.CYAN)
		vbox.add_child(results_label)
	
	return item

func get_campaign_details_text(campaign: Dictionary) -> String:
	"""Genera el texto de detalles de una campaña"""
	var details = []
	
	# Efectos de la campaña
	var effects = campaign.get("effects", {})
	if effects.has("fame_gain"):
		details.append("🎆 +" + str(effects.fame_gain) + " fama")
	if effects.has("money_gain"):
		details.append("💰 +" + str(effects.money_gain) + "€")
	if effects.has("money_per_match"):
		details.append("💰 +" + str(effects.money_per_match) + "€ por partido")
	if effects.has("moral_boost"):
		details.append("😊 +moral del equipo")
	
	# Nivel de riesgo
	var risk_level = campaign.get("risk_level", "low")
	var risk_text = ""
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
		confirm_text += "\n\n💰 Costo: " + str(campaign.cost) + "€"
		
		# Verificar si el jugador tiene suficiente dinero
		if GameManager and GameManager.get_money() < campaign.cost:
			confirm_text += "\n\n⚠️ No tienes suficiente dinero para esta campaña."
	
	# Agregar detalles de beneficios
	var effects = campaign.get("effects", {})
	if not effects.is_empty():
		confirm_text += "\n\n🎁 Beneficios esperados:"
		if effects.has("fame_gain"):
			confirm_text += "\n• +" + str(effects.fame_gain) + " fama"
		if effects.has("money_per_match"):
			confirm_text += "\n• +" + str(effects.money_per_match) + "€ por partido"
		if effects.has("moral_boost"):
			confirm_text += "\n• Mejora de moral del equipo"
	
	var confirmation = ConfirmationDialog.new()
	confirmation.dialog_text = confirm_text
	confirmation.title = "🚀 Confirmar Campaña"
	add_child(confirmation)
	
	confirmation.confirmed.connect(func():
		if CampaignsManager.start_campaign(campaign.id):
			print("✅ Campaña iniciada: ", campaign.name)
			update_campaigns_display()
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
		confirm_text += "\n\n⚠️ Penalización: " + str(penalty) + "€"
		confirm_text += "\n(50% del costo original)"
	
	var confirmation = ConfirmationDialog.new()
	confirmation.dialog_text = confirm_text
	confirmation.title = "❌ Confirmar Cancelación"
	add_child(confirmation)
	
	confirmation.confirmed.connect(func():
		if CampaignsManager.cancel_campaign(campaign.instance_id):
			print("❌ Campaña cancelada: ", campaign.name)
			update_campaigns_display()
		else:
			print("❌ No se pudo cancelar la campaña: ", campaign.name)
		confirmation.queue_free()
	)
	
	confirmation.popup_centered()

# Callbacks para eventos del CampaignsManager
func _on_campaign_completed(campaign_data: Dictionary):
	"""Se llama cuando se completa una campaña"""
	print("🎯 CampaignsMenu: Campaña completada - ", campaign_data.name)
	update_campaigns_display()

func _on_campaign_started(campaign_data: Dictionary):
	"""Se llama cuando se inicia una campaña"""
	print("🎯 CampaignsMenu: Campaña iniciada - ", campaign_data.name)
	update_campaigns_display()

func _on_campaign_cancelled(campaign_data: Dictionary):
	"""Se llama cuando se cancela una campaña"""
	print("🎯 CampaignsMenu: Campaña cancelada - ", campaign_data.name)
	update_campaigns_display()

func _on_back_button_pressed():
	"""Volver a la oficina de Yazawa"""
	print("🎯 CampaignsMenu: Volviendo a la oficina...")
	get_tree().change_scene_to_file("res://scenes/YazawaOfficeMenu.tscn")

# Función para manejar la tecla ESC (volver atrás)
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
