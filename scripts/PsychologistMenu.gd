extends Control

@onready var players_container = $VBoxContainer/ScrollContainer/PlayersContainer
@onready var back_button = $VBoxContainer/InfoPanel/BackButton

# Variables para animaciones
var transition_overlay: ColorRect

func _ready():
	print("PsychologistMenu: Mostrando menú del psicólogo")
	
	# Crear overlay de transición y hacer fade in
	create_transition_overlay()
	
	# Cambiar el fondo ColorRect por un TextureRect con salapsico.png
	setup_background()
	
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	update_display()
	
	# Iniciar fade in
	fade_in()

func setup_background():
	# Buscar el ColorRect existente
	var color_rect = $ColorRect
	if color_rect:
		# Crear un nuevo TextureRect
		var texture_rect = TextureRect.new()
		texture_rect.name = "Background"
		texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		
		# Cargar la textura del fondo salapsico
		var background_path = "res://assets/images/backgrounds/salapsico.png"
		if ResourceLoader.exists(background_path):
			texture_rect.texture = load(background_path)
			print("PsychologistMenu: Fondo salapsico cargado exitosamente")
		else:
			print("Advertencia: No se encontró el fondo salapsico en: ", background_path)
			# Mantener un color de respaldo
			texture_rect.modulate = Color(0.2, 0.3, 0.5, 1)
		
		# Obtener el índice del ColorRect para mantener el orden
		var index = color_rect.get_index()
		
		# Remover el ColorRect y añadir el TextureRect
		color_rect.queue_free()
		self.add_child(texture_rect)
		self.move_child(texture_rect, index)

func _on_back_pressed():
	print("PsychologistMenu: Volviendo al menú de entrenamiento")
	get_tree().change_scene_to_file("res://scenes/TrainingMenu.tscn")

func update_display():
	print("PsychologistMenu: Actualizando visualización...")
	
	if players_container:
		update_players()

func update_players():
	print("PsychologistMenu: Actualizando jugadores...")
	
	# Limpiar jugadores anteriores
	for child in players_container.get_children():
		child.queue_free()
	
	var players = PlayersManager.get_all_players()
	print("PlayersManager devolvió ", players.size(), " jugadores")
	
	if players.is_empty():
		var no_players_label = Label.new()
		no_players_label.text = "No hay jugadores en el equipo"
		no_players_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_players_label.add_theme_font_size_override("font_size", 16)
		no_players_label.add_theme_color_override("font_color", Color.WHITE)
		players_container.add_child(no_players_label)
		return
	
	# Usar VBoxContainer para mejor control del espaciado
	var main_container = VBoxContainer.new()
	main_container.add_theme_constant_override("separation", 15)
	main_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	players_container.add_child(main_container)
	
	# Crear tarjetas de jugadores
	for player in players:
		var player_card = create_player_card(player)
		main_container.add_child(player_card)

func create_player_card(player):
	# Contenedor principal de la tarjeta
	var card = Control.new()
	card.custom_minimum_size = Vector2(700, 80)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Panel con fondo oscuro y bordes redondeados
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_constant_override("margin_left", 10)
	panel.add_theme_constant_override("margin_right", 10)
	panel.add_theme_constant_override("margin_top", 5)
	panel.add_theme_constant_override("margin_bottom", 5)
	
	# StyleBox
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.4, 0.4, 0.4, 1.0)
	panel.add_theme_stylebox_override("panel", style_box)
	card.add_child(panel)
	
	# Contenedor horizontal
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("margin_left", 15)
	hbox.add_theme_constant_override("margin_right", 15)
	hbox.add_theme_constant_override("margin_top", 15)
	hbox.add_theme_constant_override("margin_bottom", 15)
	hbox.add_theme_constant_override("separation", 20)
	panel.add_child(hbox)
	
	# Nombre del jugador
	var name_label = Label.new()
	name_label.text = player.name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	hbox.add_child(name_label)
	
	# Posición
	var position_label = Label.new()
	position_label.text = player.position
	position_label.add_theme_font_size_override("font_size", 14)
	position_label.add_theme_color_override("font_color", Color.CYAN)
	hbox.add_child(position_label)
	
	# Moral del jugador
	var current_morale = PlayersManager.get_player_morale(player.id)
	var morale_label = Label.new()
	morale_label.text = "Moral: " + str(current_morale) + "/10"
	morale_label.add_theme_font_size_override("font_size", 14)
	
	# Color según moral
	if current_morale >= 7:
		morale_label.add_theme_color_override("font_color", Color.GREEN)
	elif current_morale >= 4:
		morale_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		morale_label.add_theme_color_override("font_color", Color.RED)
	
	hbox.add_child(morale_label)
	
	# Botón para enviar al psicólogo
	var psychologist_button = Button.new()
	psychologist_button.text = "🧠 Enviar al Psicólogo"
	psychologist_button.custom_minimum_size = Vector2(180, 35)
	psychologist_button.add_theme_font_size_override("font_size", 12)
	psychologist_button.pressed.connect(func(): _on_send_to_psychologist(player))
	
	# Estilo del botón
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.3, 0.6, 0.8, 1.0)  # Azul
	button_style.corner_radius_top_left = 6
	button_style.corner_radius_top_right = 6
	button_style.corner_radius_bottom_left = 6
	button_style.corner_radius_bottom_right = 6
	psychologist_button.add_theme_stylebox_override("normal", button_style)
	
	# Estilo hover
	var button_style_hover = StyleBoxFlat.new()
	button_style_hover.bg_color = Color(0.4, 0.7, 0.9, 1.0)  # Azul más claro
	button_style_hover.corner_radius_top_left = 6
	button_style_hover.corner_radius_top_right = 6
	button_style_hover.corner_radius_bottom_left = 6
	button_style_hover.corner_radius_bottom_right = 6
	psychologist_button.add_theme_stylebox_override("hover", button_style_hover)
	
	hbox.add_child(psychologist_button)
	
	return card

func _on_send_to_psychologist(player):
	print("PsychologistMenu: Enviando ", player.name, " al psicólogo")
	
	# Seleccionar diálogo aleatorio del psicólogo
	var psychologist_dialogues = [
		"psychologist_session_1",
		"psychologist_session_2", 
		"psychologist_session_3",
		"psychologist_session_4"
	]
	
	var random_dialogue = psychologist_dialogues[randi() % psychologist_dialogues.size()]
	print("PsychologistMenu: Iniciando diálogo ", random_dialogue)
	
	# Crear la escena de diálogo dinámica
	create_psychologist_dialogue_scene(player, random_dialogue)

func create_psychologist_dialogue_scene(player, dialogue_id):
	print("PsychologistMenu: Creando escena de diálogo para ", player.name, " con diálogo ", dialogue_id)
	
	# Guardar el diálogo seleccionado en una variable global temporal
	if not Engine.has_singleton("DialogueData"):
		# Crear un diccionario temporal global para pasar datos
		get_tree().set_meta("selected_dialogue_id", dialogue_id)
		get_tree().set_meta("selected_player_name", player.name)
	
	# Mostrar animación del cerebro antes de cambiar escena
	show_brain_animation("res://scenes/PsychologistDialogueScene.tscn")

func _on_psychologist_dialogue_finished(player):
	print("PsychologistMenu: Diálogo del psicólogo terminado para ", player.name)
	
	# Aquí se aplicaría el efecto de moral según el diálogo
	# (esto debería manejarse automáticamente por el DialogueSystem con los eventos)
	
	# Volver al menú de entrenamiento
	get_tree().change_scene_to_file("res://scenes/TrainingMenu.tscn")

# === SISTEMA DE TRANSICIONES ===

func create_transition_overlay():
	# Crear un overlay negro para las transiciones
	transition_overlay = ColorRect.new()
	transition_overlay.name = "TransitionOverlay"
	transition_overlay.color = Color.BLACK
	transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_overlay.z_index = 1000
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	self.add_child(transition_overlay)
	transition_overlay.modulate.a = 1.0  # Empezar opaco para fade in
	
	print("PsychologistMenu: Overlay de transición creado")

func fade_in(duration: float = 0.8):
	# Fade in desde negro
	if transition_overlay:
		var tween = create_tween()
		tween.tween_property(transition_overlay, "modulate:a", 0.0, duration)
		tween.tween_callback(func(): 
			if transition_overlay:
				transition_overlay.visible = false
		)
		print("PsychologistMenu: Iniciando fade in")

func show_brain_animation(scene_path: String):
	print("PsychologistMenu: Iniciando animación del cerebro")
	
	# Crear overlay de transición especial
	var brain_overlay = ColorRect.new()
	brain_overlay.name = "BrainOverlay"
	brain_overlay.color = Color(0.1, 0.0, 0.2, 1.0)  # Púrpura oscuro
	brain_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	brain_overlay.z_index = 1500
	brain_overlay.modulate.a = 0.0  # Empezar transparente
	self.add_child(brain_overlay)
	
	# Crear el cerebro como un label con emoji
	var brain_label = Label.new()
	brain_label.text = "🧠"  # Emoji de cerebro
	brain_label.add_theme_font_size_override("font_size", 150)
	brain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brain_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	brain_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	brain_label.modulate = Color(1, 1, 1, 0)  # Empezar transparente
	brain_overlay.add_child(brain_label)
	
	# Crear texto descriptivo
	var text_label = Label.new()
	text_label.text = "Accediendo a la oficina..."
	text_label.add_theme_font_size_override("font_size", 32)
	text_label.add_theme_color_override("font_color", Color.CYAN)
	text_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	text_label.add_theme_constant_override("shadow_offset_x", 3)
	text_label.add_theme_constant_override("shadow_offset_y", 3)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Posicionar debajo del cerebro
	var screen_size = get_viewport().get_visible_rect().size
	text_label.position = Vector2(0, screen_size.y * 0.7)
	text_label.size = Vector2(screen_size.x, 50)
	text_label.modulate = Color(1, 1, 1, 0)  # Empezar transparente
	brain_overlay.add_child(text_label)
	
	# Crear animación más corta
	var brain_tween = create_tween()
	
	# Fase 1: Fade in del overlay
	brain_tween.tween_property(brain_overlay, "modulate:a", 1.0, 0.3)
	
	# Fase 2: Aparecer cerebro con escala
	brain_tween.parallel().tween_property(brain_label, "modulate:a", 1.0, 0.2).set_delay(0.1)
	brain_tween.parallel().tween_property(brain_label, "scale", Vector2(1.1, 1.1), 0.2).set_delay(0.1)
	
	# Fase 3: Aparecer texto
	brain_tween.parallel().tween_property(text_label, "modulate:a", 1.0, 0.2).set_delay(0.3)
	
	# Fase 4: Cambiar texto
	brain_tween.tween_callback(func(): text_label.text = "Saludando al Dr. Chalex...").set_delay(0.8)
	
	# Fase 5: Desvanecimiento final
	brain_tween.tween_property(brain_overlay, "modulate:a", 0.0, 0.3).set_delay(1.3)
	
	# Cambiar escena al final
	brain_tween.tween_callback(func(): get_tree().change_scene_to_file(scene_path))
