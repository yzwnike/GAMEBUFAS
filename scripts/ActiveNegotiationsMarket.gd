extends Control

var negotiations_container
var money_label
var back_button

func _ready():
	print("ActiveNegotiationsMarket: ¡Negociaciones activas iniciadas!")
	
	# Buscar nodos exactamente igual que TransferablePlayersMarket
	negotiations_container = get_node_or_null("VBoxContainer/ScrollContainer/NegotiationsContainer")
	money_label = get_node_or_null("VBoxContainer/InfoPanel/MoneyLabel")
	back_button = get_node_or_null("VBoxContainer/InfoPanel/BackButton")
	
	print("negotiations_container: ", negotiations_container)
	print("money_label: ", money_label)
	print("back_button: ", back_button)
	
	# Conectar botón de volver exactamente igual
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
		print("ActiveNegotiationsMarket: Botón 'Volver' conectado")
	
	# Actualizar display exactamente igual
	update_display()
	
	print("ActiveNegotiationsMarket: Inicialización completada")

func _on_back_pressed():
	print("ActiveNegotiationsMarket: Volviendo al menú principal del mercado")
	get_tree().change_scene_to_file("res://scenes/TransferMarketMenu.tscn")

func update_display():
	print("ActiveNegotiationsMarket: Actualizando visualización...")
	
	if money_label:
		var current_money = GameManager.get_money()
		money_label.text = "Dinero: €%s" % current_money
		print("ActiveNegotiationsMarket: Dinero actualizado: €", current_money)
	
	if negotiations_container and TransferMarketManager:
		update_negotiations()

func update_negotiations():
	print("ActiveNegotiationsMarket: Actualizando negociaciones...")
	
	# Limpiar negociaciones anteriores
	for child in negotiations_container.get_children():
		child.queue_free()
	
	# Obtener negociaciones activas
	var negotiations = TransferMarketManager.get_active_negotiations()
	print("TransferMarketManager devolvió ", negotiations.size(), " negociaciones")
	
	# Debug: mostrar todas las negociaciones
	for i in range(negotiations.size()):
		var neg = negotiations[i]
		print("Negociación ", i, ": ", neg.player_name, " - Estado: ", neg.internal_status, " - Puede interactuar: ", neg.can_interact)
	
	if negotiations.is_empty():
		# Mostrar mensaje si no hay negociaciones
		var no_negotiations_label = Label.new()
		no_negotiations_label.text = "No tienes negociaciones activas"
		no_negotiations_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_negotiations_label.add_theme_font_size_override("font_size", 16)
		no_negotiations_label.add_theme_color_override("font_color", Color.GRAY)
		negotiations_container.add_child(no_negotiations_label)
		return
	
	# Usar VBoxContainer en lugar de GridContainer para mejor control del scroll
	var main_container = VBoxContainer.new()
	main_container.add_theme_constant_override("separation", 30)  # Más separación entre tarjetas
	main_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	negotiations_container.add_child(main_container)
	
	# Crear tarjetas de negociaciones
	for negotiation in negotiations:
		var negotiation_card = create_negotiation_card(negotiation)
		main_container.add_child(negotiation_card)
		print("ActiveNegotiationsMarket: Añadida tarjeta para ", negotiation.player_name)

func create_negotiation_card(negotiation):
	# Contenedor principal de la tarjeta estilo web
	var card = Control.new()
	card.custom_minimum_size = Vector2(600, 250)  # Tamaño mínimo base
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Ajustar altura dinámicamente según el contenido
	var base_height = 180  # Altura base para info del jugador
	var email_height = 0
	var buttons_height = 50  # Espacio para botones
	
	if negotiation.has("agent_response") and negotiation.agent_response != null:
		# Calcular altura necesaria para el correo
		var response = negotiation.agent_response
		var email_text = generate_agent_email(response, negotiation.player_name)
		var estimated_lines = email_text.length() / 60  # Aproximadamente 60 caracteres por línea
		email_height = max(150, estimated_lines * 15 + 80)  # 15px por línea + encabezado
		
		# Altura extra para contraofertas (tienen más botones)
		if response.status == "counter_offer":
			buttons_height = 80
	
	var total_height = base_height + email_height + buttons_height + 60  # +60 para márgenes y padding
	card.custom_minimum_size.y = max(250, total_height)  # Mínimo 250px
	
	# Panel con fondo oscuro y bordes redondeados
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_constant_override("margin_left", 20)
	panel.add_theme_constant_override("margin_right", 20)
	panel.add_theme_constant_override("margin_top", 15)
	panel.add_theme_constant_override("margin_bottom", 15)
	
	# Crear StyleBox con fondo negro sólido
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.08, 0.08, 0.08, 1.0)  # Negro casi sólido
	style_box.corner_radius_top_left = 15
	style_box.corner_radius_top_right = 15
	style_box.corner_radius_bottom_left = 15
	style_box.corner_radius_bottom_right = 15
	style_box.border_width_left = 3
	style_box.border_width_right = 3
	style_box.border_width_top = 3
	style_box.border_width_bottom = 3
	style_box.border_color = Color(0.4, 0.4, 0.4, 1.0)  # Borde gris visible
	style_box.shadow_color = Color(0, 0, 0, 0.5)
	style_box.shadow_size = 5
	style_box.shadow_offset = Vector2(2, 2)
	panel.add_theme_stylebox_override("panel", style_box)
	card.add_child(panel)
	
	# Contenedor de contenido con márgenes
	var content_container = MarginContainer.new()
	content_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_container.add_theme_constant_override("margin_left", 25)
	content_container.add_theme_constant_override("margin_right", 25)
	content_container.add_theme_constant_override("margin_top", 20)
	content_container.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(content_container)
	
	# VBox principal para el contenido
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	content_container.add_child(vbox)
	
	var name_label = Label.new()
	name_label.text = negotiation.player_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_label)
	
	var offer_label = Label.new()
	offer_label.text = "Tu oferta: €%s" % negotiation.current_offer
	offer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(offer_label)
	
	# Mostrar estado de la negociación
	var status_label = Label.new()
	status_label.text = negotiation.status
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 12)
	
	# Colorear según el estado
	match negotiation.internal_status:
		"pending_initial_response", "pending_counter_response":
			status_label.add_theme_color_override("font_color", Color.ORANGE)
		"response_received":
			status_label.add_theme_color_override("font_color", Color.GREEN)
		"completed":
			status_label.add_theme_color_override("font_color", Color.GRAY)
	
	vbox.add_child(status_label)
	
	# Mostrar días desde la última acción
	if negotiation.has("days_since_action") and negotiation.days_since_action > 0:
		var days_label = Label.new()
		days_label.text = "Hace %d día(s)" % negotiation.days_since_action
		days_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		days_label.add_theme_font_size_override("font_size", 10)
		days_label.add_theme_color_override("font_color", Color.GRAY)
		vbox.add_child(days_label)
	
	# Mostrar respuesta del agente si existe
	if negotiation.has("agent_response") and negotiation.agent_response != null:
		var response = negotiation.agent_response
		var response_label = Label.new()
		
		if response.status == "counter_offer":
			response_label.text = "Contraoferta del agente: €%s" % response.counter_offer
			response_label.add_theme_color_override("font_color", Color.ORANGE)
		elif response.status == "accepted":
			response_label.text = "¡Oferta ACEPTADA!"
			response_label.add_theme_color_override("font_color", Color.GREEN)
		elif response.status == "rejected":
			response_label.text = "Oferta RECHAZADA"
			response_label.add_theme_color_override("font_color", Color.RED)
		
		response_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		response_label.add_theme_font_size_override("font_size", 14)
		vbox.add_child(response_label)
		
		# Mostrar mensaje del agente estilo correo electrónico
		var email_container = VBoxContainer.new()
		
		# Encabezado del correo
		var header_label = Label.new()
		header_label.text = "De: Representante de " + negotiation.player_name
		header_label.add_theme_font_size_override("font_size", 10)
		header_label.add_theme_color_override("font_color", Color.GRAY)
		header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		email_container.add_child(header_label)
		
		# Mensaje principal
		var message_label = Label.new()
		message_label.text = generate_agent_email(response, negotiation.player_name)
		message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		message_label.add_theme_font_size_override("font_size", 11)
		message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		# Permitir que el texto se ajuste dinámicamente sin restricciones fijas
		email_container.add_child(message_label)
		
		vbox.add_child(email_container)
	
	# Solo mostrar botones de acción si se puede interactuar
	if negotiation.has("can_interact") and negotiation.can_interact:
		create_action_buttons(vbox, negotiation)
	elif negotiation.has("internal_status"):
		# Mostrar mensaje de estado para negociaciones pendientes
		var pending_label = Label.new()
		match negotiation.internal_status:
			"pending_initial_response":
				pending_label.text = "⏳ Esperando respuesta del representante..."
			"pending_counter_response":
				pending_label.text = "⏳ Esperando respuesta a tu contraoferta..."
			_:
				pending_label.text = "⏳ Procesando..."
		
		pending_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pending_label.add_theme_font_size_override("font_size", 12)
		pending_label.add_theme_color_override("font_color", Color.YELLOW)
		vbox.add_child(pending_label)
	
	return card

func create_action_buttons(vbox: VBoxContainer, negotiation):
	var actions_container = HBoxContainer.new()
	actions_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Si hay una respuesta del agente
	if negotiation.has("agent_response") and negotiation.agent_response != null:
		var response = negotiation.agent_response
		
		if response.status == "counter_offer":
			# Botones para manejar contraoferta
			var accept_counter_btn = Button.new()
			accept_counter_btn.text = "Aceptar €%s" % response.counter_offer
			accept_counter_btn.pressed.connect(func(): accept_counter_offer(negotiation))
			actions_container.add_child(accept_counter_btn)
			
			var new_counter_btn = Button.new()
			new_counter_btn.text = "Nueva contraoferta"
			new_counter_btn.pressed.connect(func(): make_counter_offer(negotiation))
			actions_container.add_child(new_counter_btn)
			
			var reject_btn = Button.new()
			reject_btn.text = "Rechazar"
			reject_btn.pressed.connect(func(): reject_negotiation(negotiation))
			actions_container.add_child(reject_btn)
			
		elif response.status == "accepted":
			# Botón para finalizar la transferencia
			var finalize_btn = Button.new()
			finalize_btn.text = "Finalizar transferencia"
			finalize_btn.pressed.connect(func(): accept_negotiation(negotiation))
			finalize_btn.add_theme_color_override("font_color", Color.WHITE)
			actions_container.add_child(finalize_btn)
			
			# Botón para rechazar la oferta aceptada
			var reject_btn = Button.new()
			reject_btn.text = "Rechazar"
			reject_btn.pressed.connect(func(): reject_negotiation(negotiation))
			reject_btn.add_theme_color_override("font_color", Color.RED)
			actions_container.add_child(reject_btn)
			
		elif response.status == "rejected":
			# Botón para confirmar el rechazo y cerrar la negociación
			var confirm_btn = Button.new()
			confirm_btn.text = "Entendido - Cerrar negociación"
			confirm_btn.pressed.connect(func(): dismiss_negotiation(negotiation))
			confirm_btn.add_theme_color_override("font_color", Color.WHITE)
			actions_container.add_child(confirm_btn)
	else:
		# Botones básicos para negociaciones sin respuesta específica
		var accept_btn = Button.new()
		accept_btn.text = "Aceptar oferta"
		accept_btn.pressed.connect(func(): accept_negotiation(negotiation))
		actions_container.add_child(accept_btn)
		
		var counter_btn = Button.new()
		counter_btn.text = "Contraoferta"
		counter_btn.pressed.connect(func(): make_counter_offer(negotiation))
		actions_container.add_child(counter_btn)
		
		var reject_btn = Button.new()
		reject_btn.text = "Rechazar"
		reject_btn.pressed.connect(func(): reject_negotiation(negotiation))
		actions_container.add_child(reject_btn)
	
	vbox.add_child(actions_container)


func accept_negotiation(negotiation):
	print("ActiveNegotiationsMarket: Aceptando negociación para ", negotiation.player_name)
	var result = TransferMarketManager.accept_deal(negotiation.id)
	if not result.success:
		show_error(result.message)
	else:
		update_display()

func make_counter_offer(negotiation):
	print("ActiveNegotiationsMarket: Contraofertando negociación para ", negotiation.player_name)
	
	# Calcular rangos de precio para la contraoferta
	var min_price = negotiation.current_offer
	var max_price = 0
	
	if negotiation.has("agent_response") and negotiation.agent_response != null:
		if negotiation.agent_response.has("counter_offer"):
			max_price = negotiation.agent_response.counter_offer
		else:
			# Si no hay contraoferta, usar precio actual + 50%
			max_price = min_price * 1.5
	else:
		# Si no hay respuesta del agente, usar el precio actual como máximo
		max_price = min_price * 1.5  # 50% más como máximo
	
	var input_dialog = AcceptDialog.new()
	input_dialog.title = "Contraoferta para " + negotiation.player_name
	
	var vbox = VBoxContainer.new()
	var instruction_label = Label.new()
	instruction_label.text = "Rango permitido: €%s - €%s" % [min_price, max_price]
	instruction_label.add_theme_font_size_override("font_size", 10)
	instruction_label.add_theme_color_override("font_color", Color.GRAY)
	vbox.add_child(instruction_label)
	
	var hbox = HBoxContainer.new()
	var label = Label.new()
	label.text = "Nueva oferta (€):"
	hbox.add_child(label)
	var line_edit = LineEdit.new()
	line_edit.placeholder_text = "Entre %s y %s" % [min_price, max_price]
	hbox.add_child(line_edit)
	vbox.add_child(hbox)
	
	input_dialog.add_child(vbox)
	add_child(input_dialog)
	input_dialog.popup_centered()
	input_dialog.confirmed.connect(func():
		var new_offer = int(line_edit.text)
		
		# Validar rango
		if new_offer < min_price or new_offer > max_price:
			show_error("La oferta debe estar entre €%s y €%s" % [min_price, max_price])
			input_dialog.queue_free()
			return
		
		# Procesar contraoferta inmediatamente
		var response = TransferMarketManager.make_counter_offer(negotiation.id, new_offer)
		if not response.success:
			show_error(response.message)
		else:
			show_message(response.message)
			update_display()  # Actualizar la UI inmediatamente
		
		input_dialog.queue_free()
	)

# Función removida - ahora procesamos contraofertas inmediatamente

func accept_counter_offer(negotiation):
	print("ActiveNegotiationsMarket: Aceptando contraoferta para ", negotiation.player_name)
	var result = TransferMarketManager.accept_counter_offer(negotiation.id)
	if not result.success:
		show_error(result.message)
	else:
		show_message(result.message)
		update_display()

func reject_negotiation(negotiation):
	print("ActiveNegotiationsMarket: Rechazando negociación para ", negotiation.player_name)
	var result = TransferMarketManager.reject_counter_offer(negotiation.id)
	if not result.success:
		show_error(result.message)
	else:
		update_display()

func dismiss_negotiation(negotiation):
	print("ActiveNegotiationsMarket: Cerrando negociación rechazada para ", negotiation.player_name)
	# Marcar la negociación como completada para que desaparezca
	var result = TransferMarketManager.complete_negotiation(negotiation.id)
	if not result.success:
		show_error(result.message)
	else:
		show_message("Negociación cerrada.")
		update_display()

func show_message(text):
	var popup = AcceptDialog.new()
	popup.dialog_text = text
	popup.title = "Información"
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(func(): popup.queue_free())

func show_error(message):
	var error_dialog = AcceptDialog.new()
	error_dialog.dialog_text = message
	error_dialog.title = "Error"
	add_child(error_dialog)
	error_dialog.popup_centered()
	error_dialog.confirmed.connect(func(): error_dialog.queue_free())

func generate_agent_email(response, player_name):
	var email_text = ""
	
	if response.status == "counter_offer":
		email_text = "Estimado director deportivo,\n\n"
		email_text += "Hemos recibido su oferta por nuestro jugador " + player_name + ". "
		email_text += "Después de consultarlo con el jugador y el cuerpo técnico, "
		email_text += "consideramos que la propuesta actual no refleja el verdadero valor del jugador.\n\n"
		email_text += "Por tanto, nos complace presentarle una contraoferta de €" + str(response.counter_offer) + ". "
		email_text += "Creemos que esta cifra es más acorde con las cualidades y potencial de " + player_name + ".\n\n"
		email_text += "Esperamos su respuesta y quedamos a la espera de poder cerrar esta operación.\n\n"
		email_text += "Saludos cordiales,\nRepresentante de " + player_name
		
	elif response.status == "accepted":
		email_text = "Estimado director deportivo,\n\n"
		email_text += "¡Excelentes noticias! Hemos aceptado su oferta por " + player_name + ". "
		email_text += "Tanto el jugador como nosotros estamos muy emocionados por esta oportunidad.\n\n"
		email_text += "" + player_name + " está ansioso por unirse a su proyecto deportivo y "
		email_text += "contribuir al éxito del equipo. Procederemos con los trámites necesarios de inmediato.\n\n"
		email_text += "Gracias por su profesionalidad en esta negociación.\n\n"
		email_text += "Saludos cordiales,\nRepresentante de " + player_name
		
	elif response.status == "rejected":
		email_text = "Estimado director deportivo,\n\n"
		email_text += "Lamentamos informarle que, tras una cuidadosa consideración, "
		email_text += "hemos decidido rechazar su oferta por " + player_name + ".\n\n"
		email_text += "La propuesta económica presentada está muy por debajo de nuestras expectativas "
		email_text += "y no refleja el valor de mercado actual del jugador. "
		email_text += "En estas circunstancias, preferimos que " + player_name + " continúe en su club actual.\n\n"
		email_text += "Agradecemos su interés, pero damos por finalizada esta negociación.\n\n"
		email_text += "Saludos,\nRepresentante de " + player_name
	
	return email_text

# Función para manejar la tecla ESC (volver atrás)
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		print("ActiveNegotiationsMarket: ESC presionado - volviendo al menú")
		_on_back_pressed()

