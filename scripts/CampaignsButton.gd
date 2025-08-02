extends Button

# Script independiente para el botón de campañas
# Maneja todo el sistema de UI de campañas de forma autónoma

func _ready():
	"""Inicializa el botón de campañas"""
	print("🎯 CampaignsButton: Inicializando...")
	
	# Configurar el botón
	visible = true
	pressed.connect(open_campaigns_popup)
	
	# Actualizar estado visual inicial
	update_button_state()
	
	# Conectar a eventos del CampaignsManager
	if CampaignsManager:
		if CampaignsManager.has_signal("campaign_completed"):
			CampaignsManager.campaign_completed.connect(_on_campaign_completed)
		if CampaignsManager.has_signal("campaign_started"):
			CampaignsManager.campaign_started.connect(_on_campaign_started)
		if CampaignsManager.has_signal("campaign_cancelled"):
			CampaignsManager.campaign_cancelled.connect(_on_campaign_cancelled)
	
	print("🎯 CampaignsButton: Botón configurado correctamente")

func update_button_state():
	"""Actualiza el estado visual del botón según las campañas activas"""
	if not CampaignsManager:
		return
	
	var active_campaigns = CampaignsManager.get_active_campaigns()
	
	if active_campaigns.size() > 0:
		# Botón verde cuando hay campañas activas
		modulate = Color.GREEN
		print("🎯 Botón de campañas - VERDE - campañas activas: ", active_campaigns.size())
	else:
		# Botón normal cuando no hay campañas activas
		modulate = Color.WHITE
		print("🎯 Botón de campañas - BLANCO - sin campañas activas")

func open_campaigns_popup():
	"""Abre el popup de gestión de campañas"""
	print("🎯 Abriendo popup de campañas...")
	
	if not CampaignsManager:
		print("❌ CampaignsManager no disponible")
		return
	
	# Crear el popup
	var popup = create_campaigns_popup()
	get_tree().current_scene.add_child(popup)
	
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
	get_tree().current_scene.add_child(confirmation)
	
	confirmation.confirmed.connect(func():
		if CampaignsManager.start_campaign(campaign.id):
			print("✅ Campaña iniciada: ", campaign.name)
			update_button_state()
			# Cerrar el popup actual y reabrir para actualizar
			_close_current_popup()
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
	get_tree().current_scene.add_child(confirmation)
	
	confirmation.confirmed.connect(func():
		if CampaignsManager.cancel_campaign(campaign.instance_id):
			print("❌ Campaña cancelada: ", campaign.name)
			update_button_state()
			# Cerrar el popup actual y reabrir para actualizar
			_close_current_popup()
			open_campaigns_popup()
		else:
			print("❌ No se pudo cancelar la campaña: ", campaign.name)
		confirmation.queue_free()
	)
	
	confirmation.popup_centered()

func _close_current_popup():
	"""Cierra el popup actual de campañas"""
	var scene_children = get_tree().current_scene.get_children()
	for child in scene_children:
		if child is AcceptDialog and child.title == "🎯 GESTIÓN DE CAMPAÑAS":
			child.queue_free()
			break

# Callbacks para eventos del CampaignsManager
func _on_campaign_completed(campaign_data: Dictionary):
	"""Se llama cuando se completa una campaña"""
	print("🎯 CampaignsButton: Campaña completada - ", campaign_data.name)
	update_button_state()

func _on_campaign_started(campaign_data: Dictionary):
	"""Se llama cuando se inicia una campaña"""
	print("🎯 CampaignsButton: Campaña iniciada - ", campaign_data.name)
	update_button_state()

func _on_campaign_cancelled(campaign_data: Dictionary):
	"""Se llama cuando se cancela una campaña"""
	print("🎯 CampaignsButton: Campaña cancelada - ", campaign_data.name)
	update_button_state()
