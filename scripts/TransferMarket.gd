extends Control

var players_container
var money_label
var back_button

func _ready():
	print("TransferMarket: ¡Mercado de traspasos iniciado!")
	
	# Buscar nodos con la nueva estructura
	players_container = get_node_or_null("VBoxContainer/ScrollContainer/PlayersContainer")
	money_label = get_node_or_null("VBoxContainer/InfoPanel/MoneyLabel")
	back_button = get_node_or_null("VBoxContainer/InfoPanel/BackButton")
	
	print("players_container: ", players_container)
	print("money_label: ", money_label)
	print("back_button: ", back_button)
	
	# Conectar botón de volver
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
		print("TransferMarket: Botón 'Volver' conectado")
	
	# Actualizar display
	update_display()
	
	print("TransferMarket: Inicialización completada")

func _on_back_pressed():
	print("TransferMarket: Volviendo al menú del barrio")
	get_tree().change_scene_to_file("res://scenes/NeighborhoodMenu.tscn")

func update_display():
	print("TransferMarket: Actualizando visualización...")
	
	if money_label:
		var current_money = GameManager.get_money()
		money_label.text = "Dinero: €%s" % current_money
		print("TransferMarket: Dinero actualizado: €", current_money)
	
	if players_container and TransferMarketManager:
		update_players()

func update_players():
	print("TransferMarket: Actualizando jugadores...")
	
	# Cambiar el container a GridContainer si no lo es ya
	if not players_container is GridContainer:
		# Crear nuevo GridContainer
		var grid_container = GridContainer.new()
		grid_container.columns = 4  # 4 cartas por fila
		grid_container.add_theme_constant_override("h_separation", 20)
		grid_container.add_theme_constant_override("v_separation", 20)
		
		# Reemplazar el container actual
		var parent = players_container.get_parent()
		var old_container = players_container
		parent.remove_child(old_container)
		parent.add_child(grid_container)
		players_container = grid_container
		old_container.queue_free()
	
	# Limpiar jugadores anteriores
	for child in players_container.get_children():
		child.queue_free()
	
	# Obtener jugadores disponibles
	var players = TransferMarketManager.get_available_players()
	print("TransferMarketManager devolvió ", players.size(), " jugadores")
	
	if players.is_empty():
		# Mostrar mensaje si no hay jugadores
		var no_players_label = Label.new()
		no_players_label.text = "Cargando jugadores..."
		no_players_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		players_container.add_child(no_players_label)
		return
	
	# Crear tarjetas de jugadores
	for player in players:
		var player_card = create_player_card(player)
		players_container.add_child(player_card)
		print("TransferMarket: Añadida tarjeta para ", player.name)

func create_player_card(player):
	var card = Control.new()
	card.custom_minimum_size = Vector2(200, 280)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Panel de fondo
	var panel = Panel.new()
	panel.size = card.custom_minimum_size
	
	# Estilo del panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.3, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color.GOLD
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	card.add_child(panel)
	
	# VBox para organizar contenido
	var vbox = VBoxContainer.new()
	vbox.size = panel.size
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	# Imagen del jugador
	var image_container = ColorRect.new()
	image_container.custom_minimum_size = Vector2(120, 120)
	image_container.color = Color(0.3, 0.3, 0.3)
	image_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	image_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vbox.add_child(image_container)
	
	# Cargar imagen real del jugador si existe
	if player.has("image") and player.image != "":
		var texture = load(player.image)
		if texture:
			var image_rect = TextureRect.new()
			image_rect.texture = texture
			image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			image_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			# Forzar el tamaño del TextureRect al contenedor
			image_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			image_container.add_child(image_rect)
			# Cambiar color de fondo para que la imagen sea visible
			image_container.color = Color.TRANSPARENT
	
	# Nombre
	var name_label = Label.new()
	name_label.text = player.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)
	
	# Posición del jugador
	var position_label = Label.new()
	position_label.text = player.position if player.has("position") else "N/A"
	position_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	position_label.add_theme_font_size_override("font_size", 12)
	position_label.add_theme_color_override("font_color", Color.CYAN)
	vbox.add_child(position_label)
	
	# Overall
	var overall_label = Label.new()
	overall_label.text = "OVR: " + str(player.overall)
	overall_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overall_label.add_theme_font_size_override("font_size", 14)
	overall_label.add_theme_color_override("font_color", Color.YELLOW)
	vbox.add_child(overall_label)
	
	# Precio
	var price_label = Label.new()
	price_label.text = "€" + str(player.market_value)
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 14)
	price_label.add_theme_color_override("font_color", Color.GREEN)
	vbox.add_child(price_label)
	
	# Botón negociar
	var negotiate_btn = Button.new()
	negotiate_btn.text = "NEGOCIAR"
	negotiate_btn.custom_minimum_size = Vector2(120, 35)
	negotiate_btn.add_theme_font_size_override("font_size", 12)
	negotiate_btn.pressed.connect(func(): start_negotiation(player))
	vbox.add_child(negotiate_btn)
	
	return card

func start_negotiation(player):
	print("TransferMarket: Iniciando negociación con ", player.name)
	
	# Crear diálogo de negociación
	var dialog = AcceptDialog.new()
	dialog.title = "Negociar con " + player.name
	dialog.size = Vector2(400, 200)
	
	var vbox = VBoxContainer.new()
	
	# Info del jugador
	var info = Label.new()
	info.text = "%s\nOverall: %s\nPrecio: €%s" % [player.name, player.overall, player.market_value]
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info)
	
	vbox.add_child(HSeparator.new())
	
	# Input para oferta
	var offer_label = Label.new()
	offer_label.text = "Tu oferta (€):"
	vbox.add_child(offer_label)
	
	var offer_input = LineEdit.new()
	offer_input.text = str(player.market_value)
	vbox.add_child(offer_input)
	
	# Botón enviar
	var send_btn = Button.new()
	send_btn.text = "Enviar Oferta"
	send_btn.pressed.connect(func(): send_offer(player, int(offer_input.text), dialog))
	vbox.add_child(send_btn)
	
	dialog.add_child(vbox)
	add_child(dialog)
	dialog.popup_centered()

func send_offer(player, offer_amount, dialog):
	print("TransferMarket: Enviando oferta de €", offer_amount, " por ", player.name)
	
	# Verificar dinero
	var current_money = GameManager.get_money()
	if offer_amount > current_money:
		show_message("No tienes suficiente dinero. Tienes €%s, necesitas €%s" % [current_money, offer_amount])
		dialog.queue_free()
		return
	
	# Usar TransferMarketManager para procesar la oferta
	var result = TransferMarketManager.start_negotiation(player.id, offer_amount)
	
	if result.success:
		if result.immediate_response:
			show_message(result.response.message)
		else:
			show_message(result.message)
	else:
		show_message("Error: " + result.message)
	
	dialog.queue_free()

func show_message(text):
	var popup = AcceptDialog.new()
	popup.dialog_text = text
	popup.title = "Resultado"
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(func(): popup.queue_free())
