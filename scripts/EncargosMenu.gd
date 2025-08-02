extends Control

# Interfaz del menú de Encargos
# Muestra los 8 encargos de la temporada actual en un grid 4x2

# Referencias a nodos UI
var title_label: Label
var subtitle_label: Label
var encargos_grid: GridContainer
var back_button: Button
var temporada_label: Label
var progreso_label: Label
var background: ColorRect

# Popup para detalles del encargo
var detail_popup: AcceptDialog
var detail_title: Label
var detail_description: Label
var detail_reward: Label
var detail_progress: Label
var accept_button: Button

# Variables de control
var encargo_seleccionado: EncargosManager.Encargo
var encargo_cards: Array[Control] = []

func _ready():
	print("EncargosMenu: Inicializando menú de encargos...")
	
	# Inicializar referencias a nodos
	init_node_references()
	
	# Configurar estilos
	setup_styles()
	
	# Crear el grid de encargos
	create_encargos_grid()
	
	# Crear popup de detalles
	create_detail_popup()
	
	# Conectar botones
	connect_buttons()
	
	# Cargar encargos desde el manager
	load_encargos()
	
	print("EncargosMenu: Menú listo")

func init_node_references():
	"""Inicializa referencias a nodos de la interfaz"""
	title_label = get_node_or_null("MarginContainer/VBoxContainer/TitleLabel")
	subtitle_label = get_node_or_null("MarginContainer/VBoxContainer/SubtitleLabel")
	encargos_grid = get_node_or_null("MarginContainer/VBoxContainer/EncargosContainer/EncargosGrid")
	back_button = get_node_or_null("MarginContainer/VBoxContainer/BackButton")
	temporada_label = get_node_or_null("MarginContainer/VBoxContainer/InfoContainer/TemporadaLabel")
	progreso_label = get_node_or_null("MarginContainer/VBoxContainer/InfoContainer/ProgresoLabel")
	background = get_node_or_null("Background")
	
	# Si no existen los nodos, crearlos
	if not title_label:
		create_ui_structure()

func create_ui_structure():
	"""Crea la estructura básica de la UI si no existe"""
	print("EncargosMenu: Creando estructura de UI...")
	
	# Fondo
	background = ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.1, 0.15, 0.25, 1.0)
	add_child(background)
	
	# Container principal
	var main_margin = MarginContainer.new()
	main_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_margin.add_theme_constant_override("margin_left", 50)
	main_margin.add_theme_constant_override("margin_right", 50)
	main_margin.add_theme_constant_override("margin_top", 30)
	main_margin.add_theme_constant_override("margin_bottom", 30)
	add_child(main_margin)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 20)
	main_margin.add_child(main_vbox)
	
	# Título
	title_label = Label.new()
	title_label.text = "ENCARGOS DE LA TEMPORADA"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title_label)
	
	# Subtítulo
	subtitle_label = Label.new()
	subtitle_label.text = "Completa estas misiones para obtener recompensas"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(subtitle_label)
	
	# Container de info (temporada y progreso)
	var info_container = HBoxContainer.new()
	info_container.add_theme_constant_override("separation", 50)
	main_vbox.add_child(info_container)
	
	temporada_label = Label.new()
	temporada_label.text = "TEMPORADA 1"
	info_container.add_child(temporada_label)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_container.add_child(spacer)
	
	progreso_label = Label.new()
	progreso_label.text = "COMPLETADOS: 0/8"
	info_container.add_child(progreso_label)
	
	# Container de encargos
	var encargos_container = VBoxContainer.new()
	encargos_container.add_theme_constant_override("separation", 10)
	main_vbox.add_child(encargos_container)
	
	var encargos_title = Label.new()
	encargos_title.text = "ENCARGOS DISPONIBLES"
	encargos_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	encargos_container.add_child(encargos_title)
	
	# Grid de encargos (4x2)
	encargos_grid = GridContainer.new()
	encargos_grid.columns = 4
	encargos_grid.add_theme_constant_override("h_separation", 15)
	encargos_grid.add_theme_constant_override("v_separation", 15)
	encargos_container.add_child(encargos_grid)
	
	# Botón volver
	back_button = Button.new()
	back_button.text = "VOLVER A LA OFICINA"
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_vbox.add_child(back_button)

func setup_styles():
	"""Configura los estilos visuales"""
	if title_label:
		var title_settings = LabelSettings.new()
		title_settings.font_size = 48
		title_settings.font_color = Color.WHITE
		title_settings.outline_size = 3
		title_settings.outline_color = Color.BLACK
		title_label.label_settings = title_settings
	
	if subtitle_label:
		var subtitle_settings = LabelSettings.new()
		subtitle_settings.font_size = 20
		subtitle_settings.font_color = Color(1, 0.9, 0.7, 1)
		subtitle_settings.outline_size = 2
		subtitle_settings.outline_color = Color.BLACK
		subtitle_label.label_settings = subtitle_settings
	
	if temporada_label:
		var temp_settings = LabelSettings.new()
		temp_settings.font_size = 24
		temp_settings.font_color = Color.CYAN
		temp_settings.outline_size = 2
		temp_settings.outline_color = Color.BLACK
		temporada_label.label_settings = temp_settings
	
	if progreso_label:
		var prog_settings = LabelSettings.new()
		prog_settings.font_size = 24
		prog_settings.font_color = Color.YELLOW
		prog_settings.outline_size = 2
		prog_settings.outline_color = Color.BLACK
		progreso_label.label_settings = prog_settings
	
	if back_button:
		back_button.add_theme_font_size_override("font_size", 18)

func create_encargos_grid():
	"""Crea el grid de encargos (8 cartas en 4x2)"""
	if not encargos_grid:
		return
	
	# Limpiar grid existente
	for child in encargos_grid.get_children():
		child.queue_free()
	encargo_cards.clear()
	
	# Crear 8 cartas de encargo
	for i in range(8):
		var card = create_encargo_card(i)
		encargos_grid.add_child(card)
		encargo_cards.append(card)

func create_encargo_card(index: int) -> Control:
	"""Crea una carta individual de encargo"""
	var card = Panel.new()
	card.custom_minimum_size = Vector2(250, 120)
	
	# Estilo del panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.25, 0.35, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color.WHITE
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	card.add_theme_stylebox_override("panel", style)
	
	# Container de contenido
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	card.add_child(vbox)
	
	# Margin interno
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	vbox.add_child(margin)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(content_vbox)
	
	# Título del encargo
	var title = Label.new()
	title.text = "Encargo " + str(index + 1)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color.WHITE)
	content_vbox.add_child(title)
	
	# Descripción corta
	var description = Label.new()
	description.text = "Descripción del encargo..."
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.add_theme_font_size_override("font_size", 12)
	description.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_vbox.add_child(description)
	
	# Estado del encargo
	var status = Label.new()
	status.text = "DISPONIBLE"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 10)
	status.add_theme_color_override("font_color", Color.GRAY)
	content_vbox.add_child(status)
	
	# Hacer la carta clickeable
	var button = Button.new()
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.flat = true
	button.pressed.connect(func(): _on_encargo_card_clicked(index))
	card.add_child(button)
	
	# Guardar referencias en la carta
	card.set_meta("title_label", title)
	card.set_meta("description_label", description)
	card.set_meta("status_label", status)
	card.set_meta("button", button)
	card.set_meta("index", index)
	
	return card

func create_detail_popup():
	"""Crea el popup de detalles del encargo"""
	detail_popup = AcceptDialog.new()
	detail_popup.title = "Detalles del Encargo"
	detail_popup.size = Vector2(500, 400)
	detail_popup.unresizable = false
	add_child(detail_popup)
	
	# Container principal del popup
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	detail_popup.add_child(vbox)
	
	# Título del encargo
	detail_title = Label.new()
	detail_title.add_theme_font_size_override("font_size", 24)
	detail_title.add_theme_color_override("font_color", Color.WHITE)
	detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(detail_title)
	
	# Descripción detallada
	detail_description = Label.new()
	detail_description.add_theme_font_size_override("font_size", 14)
	detail_description.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_description.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	vbox.add_child(detail_description)
	
	# Recompensa
	detail_reward = Label.new()
	detail_reward.add_theme_font_size_override("font_size", 16)
	detail_reward.add_theme_color_override("font_color", Color.YELLOW)
	detail_reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(detail_reward)
	
	# Progreso
	detail_progress = Label.new()
	detail_progress.add_theme_font_size_override("font_size", 14)
	detail_progress.add_theme_color_override("font_color", Color.CYAN)
	detail_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(detail_progress)
	
	# Botón aceptar/continuar encargo
	accept_button = Button.new()
	accept_button.text = "ACEPTAR ENCARGO"
	accept_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	accept_button.pressed.connect(_on_accept_encargo_pressed)
	vbox.add_child(accept_button)

func connect_buttons():
	"""Conecta las señales de los botones"""
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)

func load_encargos():
	"""Carga los encargos desde el EncargosManager"""
	if not EncargosManager:
		print("ERROR: EncargosManager no encontrado")
		return
	
	var encargos = EncargosManager.get_encargos_temporada()
	
	# Actualizar información de temporada
	if temporada_label:
		temporada_label.text = "TEMPORADA " + str(EncargosManager.temporada_actual)
	
	# Actualizar progreso
	if progreso_label:
		var completados = EncargosManager.get_encargos_completados()
		progreso_label.text = "COMPLETADOS: " + str(completados) + "/8"
	
	# Actualizar cartas de encargo
	for i in range(min(encargos.size(), encargo_cards.size())):
		update_encargo_card(encargo_cards[i], encargos[i])

func update_encargo_card(card: Control, encargo: EncargosManager.Encargo):
	"""Actualiza una carta de encargo con los datos del encargo"""
	var title_label = card.get_meta("title_label") as Label
	var description_label = card.get_meta("description_label") as Label
	var status_label = card.get_meta("status_label") as Label
	
	if title_label:
		title_label.text = encargo.titulo
	
	if description_label:
		description_label.text = encargo.descripcion
	
	if status_label:
		match encargo.estado:
			EncargosManager.EncargoState.DISPONIBLE:
				status_label.text = "DISPONIBLE"
				status_label.add_theme_color_override("font_color", Color.WHITE)
				# Estilo normal
				var style = card.get_theme_stylebox("panel") as StyleBoxFlat
				if style:
					style.bg_color = Color(0.2, 0.25, 0.35, 0.9)
					style.border_color = Color.WHITE
			
			EncargosManager.EncargoState.EN_CURSO:
				status_label.text = "EN CURSO"
				status_label.add_theme_color_override("font_color", Color.YELLOW)
				# Estilo en curso
				var style = card.get_theme_stylebox("panel") as StyleBoxFlat
				if style:
					style.bg_color = Color(0.3, 0.3, 0.2, 0.9)
					style.border_color = Color.YELLOW
			
			EncargosManager.EncargoState.COMPLETADO:
				status_label.text = "¡COMPLETADO!"
				status_label.add_theme_color_override("font_color", Color.GREEN)
				# Estilo completado
				var style = StyleBoxFlat.new()
				style.bg_color = Color(0.2, 0.4, 0.2, 0.9)
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

func _on_encargo_card_clicked(index: int):
	"""Se llama cuando se hace clic en una carta de encargo"""
	if not EncargosManager:
		return
	
	var encargos = EncargosManager.get_encargos_temporada()
	if index < 0 or index >= encargos.size():
		return
	
	encargo_seleccionado = encargos[index]
	show_encargo_details(encargo_seleccionado)

func show_encargo_details(encargo: EncargosManager.Encargo):
	"""Muestra los detalles del encargo en el popup"""
	if not detail_popup:
		return
	
	# Actualizar título
	if detail_title:
		detail_title.text = encargo.titulo
	
	# Actualizar descripción
	if detail_description:
		detail_description.text = encargo.descripcion_detallada
	
	# Actualizar recompensa
	if detail_reward:
		var reward_text = "RECOMPENSA: "
		var rewards = []
		
		if encargo.recompensa.has("dinero"):
			rewards.append(str(encargo.recompensa["dinero"]) + " monedas")
		
		if encargo.recompensa.has("fama"):
			rewards.append(str(encargo.recompensa["fama"]) + " puntos de fama")
		
		reward_text += " | ".join(rewards)
		detail_reward.text = reward_text
	
	# Actualizar progreso
	if detail_progress:
		if encargo.progreso_objetivo > 1:
			detail_progress.text = "PROGRESO: " + str(encargo.progreso_actual) + "/" + str(encargo.progreso_objetivo)
			detail_progress.visible = true
		else:
			detail_progress.visible = false
	
	# Actualizar botón
	if accept_button:
		match encargo.estado:
			EncargosManager.EncargoState.DISPONIBLE:
				accept_button.text = "ACEPTAR ENCARGO"
				accept_button.disabled = false
			EncargosManager.EncargoState.EN_CURSO:
				accept_button.text = "EN CURSO..."
				accept_button.disabled = true
			EncargosManager.EncargoState.COMPLETADO:
				accept_button.text = "¡COMPLETADO!"
				accept_button.disabled = true
	
	# Mostrar popup
	detail_popup.popup_centered()

func _on_accept_encargo_pressed():
	"""Se llama cuando se acepta un encargo"""
	if not encargo_seleccionado:
		return
	
	if encargo_seleccionado.estado == EncargosManager.EncargoState.DISPONIBLE:
		# Cambiar estado a EN_CURSO
		encargo_seleccionado.estado = EncargosManager.EncargoState.EN_CURSO
		print("EncargosMenu: Encargo aceptado - ", encargo_seleccionado.titulo)
		
		# Actualizar la interfaz
		load_encargos()
		
		# Cerrar popup
		detail_popup.hide()

func _on_back_button_pressed():
	"""Vuelve al menú de la oficina de Yazawa"""
	print("EncargosMenu: Volviendo a la oficina...")
	get_tree().change_scene_to_file("res://scenes/YazawaOfficeMenu.tscn")

# Manejar tecla ESC para volver
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if detail_popup and detail_popup.visible:
			detail_popup.hide()
		else:
			_on_back_button_pressed()
