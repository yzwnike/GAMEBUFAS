extends Control

# Sistema de diálogos estilo Doki Doki Literature Club
# Inspirado en La Velada del Año

@onready var character_name_label = get_node_or_null("DialogueBox/NameLabel") # Fallback para TrainingDialogueScene
@onready var dialogue_text = get_node_or_null("DialogueBox/DialogueText") # Fallback para TrainingDialogueScene
@onready var background = get_node_or_null("Background") # Se inicializa correctamente en _ready()
@onready var character_sprite = $CharacterSprite
@onready var continue_indicator = get_node_or_null("DialogueBox/ContinueIndicator") # Fallback para TrainingDialogueScene
@onready var choice_container = $ChoiceContainer

var current_dialogue = []
var current_index = 0
var is_typing = false
var typing_speed = 0.05
var selected_players = []
var auto_advance = false
var showing_choices = false

# Personajes disponibles
var characters = {
	"narrator": {"name": "", "color": Color.WHITE},
	"Yazawa": {"name": "Yazawa", "color": Color.BLUE},
	"Usuario": {"name": "Tú", "color": Color.GREEN},
	"psicologo": {"name": "Dr. Martínez", "color": Color.PURPLE},
	"grefg": {"name": "TheGrefg", "color": Color.MAGENTA},
	"westcol": {"name": "Westcol", "color": Color.ORANGE},
	"perxitaa": {"name": "Perxitaa", "color": Color.CYAN},
	"viruzz": {"name": "Viruzz", "color": Color.RED},
	"tomas": {"name": "Tomás", "color": Color.GREEN},
	"rivaldios": {"name": "Rivaldios", "color": Color.YELLOW},
	"peereira": {"name": "Peereira", "color": Color.PINK},
	"alana": {"name": "Alana", "color": Color.MAGENTA},
	"arigeli": {"name": "Arigeli", "color": Color.GREEN},
	"andoni": {"name": "Andoni", "color": Color.CYAN}
}

# Backgrounds disponibles
var backgrounds = {
	"campo": "res://assets/images/backgrounds/campo.png",
	"vestuario": "res://assets/images/backgrounds/vestuario.png",
	"entrenamiento": "res://assets/images/backgrounds/entrenamiento.png",
	"campovertical": "res://assets/images/backgrounds/campovertical.png",
	"salapsico": "res://assets/images/backgrounds/salapsico.png",
	"ofipsico": "res://assets/images/backgrounds/ofipsico.png",
	"partido": "res://assets/images/backgrounds/partido.png"
}

signal dialogue_finished
signal choice_made(choice_id)

var simple_dialogue_panel
var simple_name_label
var simple_text_label
var simple_continue_label

func _ready():
	print("DialogueSystem: _ready() iniciado")
	
	# Inicializar background correctamente
	if not background:
		background = get_node_or_null("../Background")
	
	# Crear overlay de transición
	create_transition_overlay()
	
	# Conectar señal de fin de diálogo
	dialogue_finished.connect(_on_dialogue_finished)
	
	# Cargar fondo por defecto inmediatamente
	if background and background is TextureRect:
		background.texture = load("res://assets/images/backgrounds/ofipsico.png")
		print("DialogueSystem: Fondo ofipsico cargado por defecto")
	
	# Verificar que todos los nodos estén disponibles
	print("DialogueSystem: Verificando nodos...")
	print("  - continue_indicator: ", continue_indicator)
	print("  - choice_container: ", choice_container)
	print("  - dialogue_text: ", dialogue_text)
	print("  - character_name_label: ", character_name_label)
	print("  - background: ", background)
	print("  - character_sprite: ", character_sprite)
	
	if continue_indicator:
		continue_indicator.visible = false
	if choice_container:
		choice_container.visible = false
	if dialogue_text:
		dialogue_text.text = ""
	
	# Iniciar transición de entrada
	fade_in()
	
	# Verificar si hay un salto a línea específica configurado
	if get_tree().has_meta("jump_to_specific_line") and get_tree().get_meta("jump_to_specific_line"):
		var file_path = get_tree().get_meta("dialogue_file_path")
		var target_index = get_tree().get_meta("target_line_index")
		print("DialogueSystem: Salto a línea específica detectado: ", file_path, " índice ", target_index)
		
		# Limpiar los meta datos
		get_tree().remove_meta("jump_to_specific_line")
		get_tree().remove_meta("dialogue_file_path")
		get_tree().remove_meta("target_line_index")
		
		# Cargar el diálogo y saltar a la línea específica
		load_dialogue_and_jump_to_line(file_path, target_index)
		
	# Verificar si hay un diálogo guardado para cargar (sistema de psicólogo)
	elif get_tree().has_meta("selected_dialogue_id"):
		var dialogue_id = get_tree().get_meta("selected_dialogue_id")
		var player_name = get_tree().get_meta("selected_player_name")
		print("DialogueSystem: Diálogo guardado encontrado: ", dialogue_id, " para jugador: ", player_name)
		
		# Limpiar los meta datos
		get_tree().remove_meta("selected_dialogue_id")
		get_tree().remove_meta("selected_player_name")
		
		# Cargar el diálogo desde el archivo JSON
		load_dialogue_from_file(dialogue_id, player_name)
	
	print("DialogueSystem: _ready() completado")

func _on_dialogue_finished():
	print("DialogueSystem: Diálogo terminado completamente")
	# Esperar un frame para asegurar que todo se procese
	await get_tree().process_frame
	
	# Solo mostrar grid de moral si es un diálogo del psicólogo
	if is_psychologist_dialogue():
		print("DialogueSystem: Es un diálogo del psicólogo, mostrando grid de moral")
		show_morale_grid()
	else:
		print("DialogueSystem: No es un diálogo del psicólogo, regresando al menú de entrenamiento")
		fade_out_and_change_scene("res://scenes/TrainingMenu.tscn")

func show_morale_grid():
	print("DialogueSystem: Mostrando grid de moral")
	
	# Ocultar el sistema de diálogo actual
	if simple_dialogue_panel:
		simple_dialogue_panel.visible = false
	
	# Ocultar el personaje
	hide_character()
	
	# Crear overlay para el grid de moral que ocupe toda la pantalla
	var moral_overlay = ColorRect.new()
	moral_overlay.name = "MoralOverlay"
	moral_overlay.color = Color(0.0, 0.0, 0.2, 0.9)  # Fondo azul oscuro semi-transparente
	moral_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	moral_overlay.z_index = 2000  # Por encima de todo
	self.add_child(moral_overlay)
	
	# Crear contenedor principal centrado
	var main_container = VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	main_container.add_theme_constant_override("separation", 40)
	moral_overlay.add_child(main_container)
	
	# Calcular la moral ganada desde el diálogo
	var morale_gained = calculate_morale_gained()
	
	# Título principal
	var title_label = Label.new()
	title_label.text = "🧠 SESIÓN COMPLETADA 🧠"
	title_label.add_theme_font_size_override("font_size", 56)
	title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.1))  # Amarillo brillante
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title_label.add_theme_constant_override("shadow_offset_x", 3)
	title_label.add_theme_constant_override("shadow_offset_y", 3)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(title_label)
	
	# Panel para la información de moral
	var moral_panel = Panel.new()
	moral_panel.custom_minimum_size = Vector2(600, 200)
	
	# Estilo del panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.3, 0.95)  # Azul oscuro
	panel_style.border_width_left = 4
	panel_style.border_width_right = 4
	panel_style.border_width_top = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color(0.9, 0.9, 0.1)  # Borde amarillo
	panel_style.corner_radius_top_left = 20
	panel_style.corner_radius_top_right = 20
	panel_style.corner_radius_bottom_left = 20
	panel_style.corner_radius_bottom_right = 20
	moral_panel.add_theme_stylebox_override("panel", panel_style)
	main_container.add_child(moral_panel)
	
	# Contenedor para el contenido del panel
	var panel_content = VBoxContainer.new()
	panel_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_content.add_theme_constant_override("margin_left", 30)
	panel_content.add_theme_constant_override("margin_right", 30)
	panel_content.add_theme_constant_override("margin_top", 30)
	panel_content.add_theme_constant_override("margin_bottom", 30)
	panel_content.add_theme_constant_override("separation", 20)
	moral_panel.add_child(panel_content)
	
	# Obtener nombre del jugador actual
	var player_name = ""
	if get_tree().has_meta("current_player_name"):
		player_name = get_tree().get_meta("current_player_name")
	
	# Label del jugador
	var player_label = Label.new()
	player_label.text = "Jugador: " + player_name
	player_label.add_theme_font_size_override("font_size", 24)
	player_label.add_theme_color_override("font_color", Color.WHITE)
	player_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel_content.add_child(player_label)
	
	# Label de moral ganada
	var moral_label = Label.new()
	if morale_gained > 0:
		moral_label.text = "¡Has ganado +" + str(morale_gained) + " puntos de Moral!"
		moral_label.add_theme_color_override("font_color", Color.GREEN)
	elif morale_gained == 0:
		moral_label.text = "Reflexión profunda completada"
		moral_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		moral_label.text = "Moral: " + str(morale_gained)
		moral_label.add_theme_color_override("font_color", Color.WHITE)
	
	moral_label.add_theme_font_size_override("font_size", 32)
	moral_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	moral_label.add_theme_constant_override("shadow_offset_x", 2)
	moral_label.add_theme_constant_override("shadow_offset_y", 2)
	moral_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel_content.add_child(moral_label)
	
	# Instrucciones para continuar
	var continue_label = Label.new()
	continue_label.text = "✨ HAZ CLIC PARA CONTINUAR ✨"
	continue_label.add_theme_font_size_override("font_size", 24)
	continue_label.add_theme_color_override("font_color", Color(0.1, 0.9, 0.9))  # Cian brillante
	continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(continue_label)
	
	# Añadir efecto de parpadeo al texto de continuar
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(continue_label, "modulate:a", 0.3, 0.8)
	tween.tween_property(continue_label, "modulate:a", 1.0, 0.8)
	
	# Conectar clic en todo el overlay para finalizar
	moral_overlay.gui_input.connect(_on_morale_grid_clicked)
	
	print("DialogueSystem: Grid de moral creado exitosamente")

func calculate_morale_gained() -> int:
	# Buscar en el diálogo actual cuánta moral se ganó
	var total_morale = 0
	for line in current_dialogue:
		if line.has("effect") and line.effect.has("type") and line.effect.type == "morale_boost":
			total_morale += line.effect.get("amount", 0)
	return total_morale

func _on_morale_grid_clicked(event):
	if event is InputEventMouseButton and event.pressed:
		print("DialogueSystem: Clic en grid de moral, finalizando sesión")
		fade_out_and_change_scene("res://scenes/TrainingMenu.tscn")

func _input(event):
	if event.is_action_pressed("ui_accept"):
		print("DialogueSystem: ESPACIO presionado - is_typing: ", is_typing, ", current_index: ", current_index, ", dialogue_size: ", current_dialogue.size(), ", showing_choices: ", showing_choices)
		if is_typing:
			# Saltar animación de escritura
			print("DialogueSystem: Saltando animación de escritura")
			complete_current_text()
		elif current_index < current_dialogue.size() and not showing_choices:
			# Avanzar al siguiente diálogo
			print("DialogueSystem: Avanzando diálogo")
			advance_dialogue()
		elif current_index >= current_dialogue.size():
			# Finalizar diálogo solo si realmente se acabó
			print("DialogueSystem: Finalizando diálogo - índice fuera de rango")
			emit_signal("dialogue_finished")
		else:
			print("DialogueSystem: ESPACIO ignorado - mostrando opciones o condición no cumplida")
	
	# Función para saltar todo el diálogo con la tecla F
	if event.is_action_pressed("ui_skip") or (event is InputEventKey and event.keycode == KEY_F and event.pressed):
		if not showing_choices:
			print("DialogueSystem: SALTANDO TODO EL DIÁLOGO con tecla F")
			skip_entire_dialogue()
		else:
			print("DialogueSystem: No se puede saltar diálogo mientras se muestran opciones")

func load_dialogue(dialogue_data):
	print("DialogueSystem: load_dialogue llamado")
	print("DialogueSystem: dialogue_data recibido: ", dialogue_data)
	current_dialogue = dialogue_data
	current_index = 0
	
	# Crear un sistema de diálogo simple y visible
	create_simple_dialogue_ui()
	
	print("DialogueSystem: current_dialogue.size(): ", current_dialogue.size())
	if current_dialogue.size() > 0:
		print("DialogueSystem: Llamando show_dialogue_line()")
		show_dialogue_line()
	else:
		print("ERROR: dialogue_data está vacío")

func create_simple_dialogue_ui():
	print("DialogueSystem: Creando UI simple de diálogo...")
	
	# Obtener tamaño de pantalla para posicionar en la parte inferior
	var screen_size = get_viewport().get_visible_rect().size
	
	# Crear panel principal - más grande y en la parte inferior
	simple_dialogue_panel = Panel.new()
	simple_dialogue_panel.size = Vector2(screen_size.x - 100, 250)  # Más ancho y alto
	simple_dialogue_panel.position = Vector2(50, screen_size.y - 300)  # En la parte inferior
	
	# Estilo del panel más llamativo
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.2, 0.95)  # Azul oscuro semi-transparente
	panel_style.border_width_left = 5
	panel_style.border_width_right = 5
	panel_style.border_width_top = 5
	panel_style.border_width_bottom = 5
	panel_style.border_color = Color(0.9, 0.9, 0.1)  # Borde amarillo brillante
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.corner_radius_bottom_right = 15
	# Añadir sombra
	panel_style.shadow_color = Color(0, 0, 0, 0.6)
	panel_style.shadow_size = 10
	panel_style.shadow_offset = Vector2(5, 5)
	simple_dialogue_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Añadir panel al nodo raíz
	self.add_child(simple_dialogue_panel)
	
	# Crear label para el nombre - más grande y llamativo
	simple_name_label = Label.new()
	simple_name_label.position = Vector2(30, 15)
	simple_name_label.size = Vector2(400, 50)
	simple_name_label.add_theme_font_size_override("font_size", 28)  # Mucho más grande
	simple_name_label.add_theme_color_override("font_color", Color(1, 0.9, 0.1))  # Amarillo brillante
	# Añadir efecto de sombra al texto del nombre
	simple_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	simple_name_label.add_theme_constant_override("shadow_offset_x", 2)
	simple_name_label.add_theme_constant_override("shadow_offset_y", 2)
	simple_dialogue_panel.add_child(simple_name_label)
	
	# Crear label para el texto - mucho más grande
	simple_text_label = Label.new()
	simple_text_label.position = Vector2(30, 75)
	simple_text_label.size = Vector2(simple_dialogue_panel.size.x - 60, 130)
	simple_text_label.add_theme_font_size_override("font_size", 22)  # Mucho más grande
	simple_text_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))  # Blanco casi puro
	# Añadir sombra al texto
	simple_text_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	simple_text_label.add_theme_constant_override("shadow_offset_x", 1)
	simple_text_label.add_theme_constant_override("shadow_offset_y", 1)
	simple_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	simple_text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	simple_dialogue_panel.add_child(simple_text_label)
	
	# Crear label para continuar - más llamativo
	simple_continue_label = Label.new()
	simple_continue_label.position = Vector2(simple_dialogue_panel.size.x - 280, 210)
	simple_continue_label.size = Vector2(250, 35)
	simple_continue_label.text = "⚡ ESPACIO para continuar ⚡"
	simple_continue_label.add_theme_font_size_override("font_size", 16)  # Más grande
	simple_continue_label.add_theme_color_override("font_color", Color(0.1, 0.9, 0.9))  # Cian brillante
	# Añadir parpadeo al indicador de continuar
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(simple_continue_label, "modulate:a", 0.3, 0.8)
	tween.tween_property(simple_continue_label, "modulate:a", 1.0, 0.8)
	simple_dialogue_panel.add_child(simple_continue_label)
	
	print("DialogueSystem: UI simple mejorada creada exitosamente")

func show_dialogue_line():
	print("DialogueSystem: show_dialogue_line() - current_index: ", current_index)
	if current_index >= current_dialogue.size():
		print("DialogueSystem: Diálogo terminado")
		emit_signal("dialogue_finished")
		return
		
	var line = current_dialogue[current_index]
	print("DialogueSystem: Línea actual: ", line)
	
	# Cambiar fondo si es necesario
	if line.has("background"):
		print("DialogueSystem: Cambiando fondo a: ", line.background)
		change_background(line.background)
	
	# Mostrar personaje y nombre en el sistema simple
	if line.has("character"):
		var character_id = line.character
		print("DialogueSystem: Mostrando personaje: ", character_id)
		
		# Obtener datos del personaje (incluyendo jugadores aleatorios)
		var char_data = characters.get(character_id, {"name": character_id, "color": Color.WHITE})
		
		# Actualizar el sistema simple de UI
		if simple_name_label:
			simple_name_label.text = char_data.name
			simple_name_label.modulate = char_data.color
			print("DialogueSystem: Nombre actualizado a: ", char_data.name)
		
		# IMPORTANTE: Mostrar la imagen del personaje
		show_character(character_id)
		
		# También actualizar el sistema original por compatibilidad
		if character_name_label:
			character_name_label.text = char_data.name
			character_name_label.modulate = char_data.color
	else:
		if simple_name_label:
			simple_name_label.text = ""
		if character_name_label:
			character_name_label.text = ""
	
	# Mostrar opciones si las hay
	if line.has("choices"):
		show_choices(line.choices)
		return
	
	# Efectos especiales
	if line.has("effect"):
		apply_effect(line.effect)
	
	# Mostrar texto con efecto de escritura progresiva
	var text_to_show = line.text
	print("DialogueSystem: Mostrando texto: ", text_to_show)
	
	# Usar el efecto de escritura progresiva
	type_text_simple(text_to_show)

func type_text_simple(text):
	is_typing = true
	if simple_continue_label:
		simple_continue_label.visible = false
	if simple_text_label:
		simple_text_label.text = ""
	
	# Animación de escritura caracter por caracter en el sistema simple
	for i in range(text.length()):
		if simple_text_label:
			simple_text_label.text += text[i]
		await get_tree().create_timer(typing_speed).timeout
		
		# Verificar si se canceló la animación
		if not is_typing:
			if simple_text_label:
				simple_text_label.text = text
			break
	
	is_typing = false
	if simple_continue_label:
		simple_continue_label.visible = true

func complete_current_text():
	is_typing = false

func advance_dialogue():
	current_index += 1
	show_dialogue_line()

func change_background(bg_name):
	if backgrounds.has(bg_name) and background:
		# Si el background es un ColorRect, convertirlo a TextureRect
		if background is ColorRect:
			print("DialogueSystem: Convirtiendo ColorRect a TextureRect para mostrar imagen")
			# Crear un nuevo TextureRect
			var texture_rect = TextureRect.new()
			texture_rect.name = "Background"
			texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			texture_rect.texture = load(backgrounds[bg_name])
			
			# Obtener el padre del ColorRect actual
			var parent = background.get_parent()
			var index = background.get_index()
			
			# Remover el ColorRect y añadir el TextureRect en su lugar
			background.queue_free()
			parent.add_child(texture_rect)
			parent.move_child(texture_rect, index)
			
			# Actualizar la referencia
			background = texture_rect
		else:
			# Si ya es un TextureRect, simplemente cambiar la textura
			background.texture = load(backgrounds[bg_name])
		
		print("DialogueSystem: Fondo cambiado a: ", bg_name)

func show_character(character_name):
	# Configurar el tamaño del CharacterSprite para que sea más grande
	if character_sprite:
		# Hacer el sprite más grande y mejor posicionado
		var screen_size = get_viewport().get_visible_rect().size
		character_sprite.custom_minimum_size = Vector2(400, 600)  # Tamaño mínimo más grande
		character_sprite.size = Vector2(400, 600)  # Tamaño fijo más grande
		character_sprite.position = Vector2(screen_size.x - 450, screen_size.y - 650)  # Posición en la esquina derecha
		character_sprite.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
		character_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Verificar si es un jugador dinámico
	var char_data = characters.get(character_name, {})
	if char_data.has("image"):
		# Es un jugador de la plantilla
		var character_path = char_data.image
		if ResourceLoader.exists(character_path):
			character_sprite.texture = load(character_path)
			character_sprite.visible = true
			print("DialogueSystem: Imagen del jugador cargada: ", character_name)
		else:
			hide_character()
			print("Advertencia: No se encontró la imagen del jugador: ", character_name, " en ", character_path)
	else:
		# Mapear nombres de personajes fijos a archivos específicos
		var character_files = {
			"psicologo": "psicologo.png",
			"grefg": "grefg.png",
			"westcol": "westcol.png", 
			"perxitaa": "perxitaa.png",
			"viruzz": "viruz.png",  # Nota: el archivo se llama viruz sin la segunda z
			"tomas": "tomas.png",
			"rivaldios": "rivaldios.png"
		}
		
		var filename = character_files.get(character_name, character_name + ".png")
		var character_path = "res://assets/images/characters/" + filename
		
		if ResourceLoader.exists(character_path):
			character_sprite.texture = load(character_path)
			character_sprite.visible = true
			print("DialogueSystem: Imagen del personaje cargada: ", character_name)
		else:
			hide_character()
			print("Advertencia: No se encontró la imagen del personaje: ", character_name, " en ", character_path)

func hide_character():
	character_sprite.visible = false

func show_choices(choices):
	showing_choices = true
	choice_container.visible = true
	
	# Limpiar opciones anteriores
	for child in choice_container.get_children():
		child.queue_free()
	
	# Crear botones para cada opción
	for i in range(choices.size()):
		var choice = choices[i]
		var button = Button.new()
		button.text = choice.text
		button.connect("pressed", _on_choice_selected.bind(choice.id))
		choice_container.add_child(button)

func _on_choice_selected(choice_id):
	choice_container.visible = false
	
	# Obtener el texto de la opción seleccionada
	var selected_text = ""
	var line = current_dialogue[current_index]
	if line.has("choices"):
		for choice in line.choices:
			if choice.id == choice_id:
				selected_text = choice.text
				break
	
	# Crear línea de diálogo temporal del Usuario
	if selected_text != "":
		# Mostrar al Usuario hablando
		var user_char_data = characters.get("Usuario", {"name": "Usuario", "color": Color.GREEN})
		if simple_name_label:
			simple_name_label.text = user_char_data.name
			simple_name_label.modulate = user_char_data.color
		
		# IMPORTANTE: Mostrar imagen del Usuario (ocultar otras imágenes)
		show_character("Usuario")
		
		# Mostrar el texto seleccionado con efecto de escritura
		type_text_simple(selected_text)
		
		# Esperar a que termine la escritura completamente
		while is_typing:
			await get_tree().process_frame
		
		# Esperar un momento extra para que se lea
		await get_tree().create_timer(1.5).timeout
	
	print("DialogueSystem: Opción seleccionada: ", choice_id, ", continuando diálogo...")
	showing_choices = false
	emit_signal("choice_made", choice_id)
	advance_dialogue()

func apply_effect(effect_data):
	print("DialogueSystem: Aplicando efecto: ", effect_data)
	
	if typeof(effect_data) == TYPE_DICTIONARY:
		var effect_type = effect_data.get("type", "")
		var amount = effect_data.get("amount", 0)
		var message = effect_data.get("message", "")
		
		if effect_type == "morale_boost":
			# Obtener el nombre del jugador actual desde los metadatos
			var player_name = ""
			if get_tree().has_meta("current_player_name"):
				player_name = get_tree().get_meta("current_player_name")
			else:
				# Si no hay metadatos, buscar en el diálogo actual
				for line in current_dialogue:
					if line.has("character") and line.character != "psicologo":
						player_name = line.character
						break
			
			if player_name != "" and player_name != "psicologo":
				# Buscar al jugador en PlayersManager
				var all_players = PlayersManager.get_all_players()
				for player in all_players:
					if player.name == player_name:
						# Obtener moral actual para mostrar el cambio
						var old_morale = PlayersManager.get_player_morale(player.id)
						
						# Aplicar el boost de moral usando la función correcta
						if amount > 0:
							PlayersManager.boost_morale(player.id, amount)
						else:
							# Si el amount es 0 o negativo, no aplicar ningún boost
							print("DialogueSystem: No se aplica boost de moral (amount = ", amount, ")")
						
						# Obtener la nueva moral para mostrar el cambio
						var new_morale = PlayersManager.get_player_morale(player.id)
						
						# Mostrar mensaje procesado con el nombre del jugador
						var processed_message = message.replace("{player_name}", player_name)
						print("DialogueSystem: ", processed_message)
						print("DialogueSystem: Moral cambió de ", old_morale, " a ", new_morale)
						
						# Crear un popup temporal para mostrar el efecto
						show_effect_notification(processed_message)
						break
			else:
				print("DialogueSystem: No se pudo determinar el jugador para aplicar el efecto")
	else:
		print("DialogueSystem: Efecto en formato desconocido: ", effect_data)

func show_effect_notification(message: String):
	# Crear una notificación temporal del efecto
	var notification = Label.new()
	notification.text = message
	notification.add_theme_font_size_override("font_size", 20)
	notification.add_theme_color_override("font_color", Color.YELLOW)
	notification.add_theme_color_override("font_shadow_color", Color.BLACK)
	notification.add_theme_constant_override("shadow_offset_x", 2)
	notification.add_theme_constant_override("shadow_offset_y", 2)
	notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Posicionar en el centro superior de la pantalla
	var screen_size = get_viewport().get_visible_rect().size
	notification.position = Vector2(screen_size.x / 2 - 200, 50)
	notification.size = Vector2(400, 50)
	
	self.add_child(notification)
	
	# Animar la notificación
	var tween = create_tween()
	tween.tween_property(notification, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.0)
	tween.tween_property(notification, "modulate:a", 0.0, 0.5)
	tween.tween_callback(notification.queue_free)

func select_random_players():
	var players_manager = get_node("/root/PlayersManager")
	if players_manager == null:
		print("ERROR: No se pudo encontrar PlayersManager")
		return
	
	var all_players = players_manager.get_all_players()
	# Filtrar para excluir jugadores que no deben aparecer como aleatorios
	var filtered_players = []
	for player in all_players:
		# Excluir "Usuario" y "Yazawa" de la selección aleatoria
		if player.name != "Usuario" and player.name != "Yazawa":
			filtered_players.append(player)
	
	filtered_players.shuffle()
	selected_players = filtered_players.slice(0, min(5, filtered_players.size()))
	
	# Registrar jugadores seleccionados y añadirlos al diccionario de personajes
	for i in range(selected_players.size()):
		var player_key = "jugador" + str(i + 1)
		characters[player_key] = {
			"name": selected_players[i].name,
			"color": get_player_color(i),
			"image": selected_players[i].image
		}
		print("Jugador ", i+1, ": ", selected_players[i].name, " (", selected_players[i].position, ")")

func get_player_color(index: int) -> Color:
	# Colores distintivos para cada jugador
	var colors = [Color.CYAN, Color.ORANGE, Color.GREEN, Color.MAGENTA, Color.YELLOW]
	return colors[index % colors.size()]

func load_dialogue_from_file(dialogue_id, player_name):
	print("DialogueSystem: Cargando diálogo ", dialogue_id, " para jugador ", player_name)
	
	# Guardar el nombre del jugador actual para usar en efectos
	get_tree().set_meta("current_player_name", player_name)
	
	# Cargar el archivo JSON de diálogos del psicólogo
	var file_path = "res://data/psychologist_dialogues.json"
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if not file:
		print("ERROR: No se pudo abrir el archivo ", file_path)
		return
	
	var text = file.get_as_text()
	file.close()
	
	# Parsear JSON
	var json = JSON.new()
	var parse_result = json.parse(text)
	
	if parse_result != OK:
		print("ERROR: Error al parsear JSON: ", json.get_error_message())
		return
	
	var dialogue_data = json.data
	
	# Verificar que existe el diálogo solicitado
	if not dialogue_data.has(dialogue_id):
		print("ERROR: No se encontró el diálogo ", dialogue_id)
		return
	
	# Obtener el diálogo específico
	var raw_dialogue = dialogue_data[dialogue_id]
	
	# Reemplazar placeholders {player_name} con el nombre real del jugador
	var processed_dialogue = []
	for line in raw_dialogue:
		var processed_line = {}
		
		# Copiar todas las propiedades de la línea original
		for key in line.keys():
			if key == "text" or key == "character":
				# Reemplazar placeholders en texto y personaje
				processed_line[key] = line[key].replace("{player_name}", player_name)
			else:
				# Copiar otras propiedades tal como están
				processed_line[key] = line[key]
		
		processed_dialogue.append(processed_line)
	
	print("DialogueSystem: Diálogo procesado exitosamente")
	
	# Cargar el diálogo procesado
	load_dialogue(processed_dialogue)

func skip_entire_dialogue():
	# Detener cualquier animación de escritura en curso
	complete_current_text()
	
	# Buscar la última línea que no tenga opciones para evitar saltarse decisiones importantes
	var target_index = current_dialogue.size() - 1
	for i in range(current_index, current_dialogue.size()):
		if current_dialogue[i].has("choices"):
			# Si encontramos opciones, pararse justo antes
			target_index = i
			break
	
	# Ir al índice objetivo
	current_index = target_index
	
	# Mostrar la línea objetivo o finalizar si llegamos al final
	if current_index < current_dialogue.size():
		show_dialogue_line()
	else:
		emit_signal("dialogue_finished")
	
	print("DialogueSystem: Diálogo saltado hasta el índice: ", current_index)

# === FUNCIONES DE DETECCIÓN ===

func is_psychologist_dialogue() -> bool:
	"""Determina si el diálogo actual es del psicólogo"""
	
	# Método 1: Verificar si hay un jugador guardado en los metadatos (indica sesión psicólogo)
	if get_tree().has_meta("current_player_name"):
		var player_name = get_tree().get_meta("current_player_name")
		if player_name != "" and player_name != null:
			print("DialogueSystem: Detectado diálogo del psicólogo (jugador: ", player_name, ")")
			return true
	
	# Método 2: Verificar si hay efectos de moral en el diálogo
	for line in current_dialogue:
		if line.has("effect") and line.effect.has("type") and line.effect.type == "morale_boost":
			print("DialogueSystem: Detectado diálogo del psicólogo (efecto de moral encontrado)")
			return true
	
	# Método 3: Verificar si aparece el personaje 'psicologo' en el diálogo
	for line in current_dialogue:
		if line.has("character") and line.character == "psicologo":
			print("DialogueSystem: Detectado diálogo del psicólogo (personaje psicólogo encontrado)")
			return true
	
	# Método 4: Verificar si el fondo es de la oficina del psicólogo
	for line in current_dialogue:
		if line.has("background") and (line.background == "ofipsico" or line.background == "salapsico"):
			print("DialogueSystem: Detectado diálogo del psicólogo (fondo psicólogo encontrado)")
			return true
	
	print("DialogueSystem: No es un diálogo del psicólogo")
	return false

# === SISTEMA DE TRANSICIONES ===

var transition_overlay: ColorRect

func create_transition_overlay():
	# Crear un overlay negro para las transiciones
	transition_overlay = ColorRect.new()
	transition_overlay.name = "TransitionOverlay"
	transition_overlay.color = Color.BLACK
	transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_overlay.z_index = 1000  # Asegurar que esté por encima de todo
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # No bloquear input
	
	# Añadir al nodo raíz de la escena
	get_tree().current_scene.add_child(transition_overlay)
	
	print("DialogueSystem: Overlay de transición creado")

func fade_in(duration: float = 0.8):
	# Fade in desde negro
	if transition_overlay:
		transition_overlay.modulate.a = 1.0  # Empezar opaco
		var tween = create_tween()
		tween.tween_property(transition_overlay, "modulate:a", 0.0, duration)
		tween.tween_callback(func(): 
			if transition_overlay:
				transition_overlay.visible = false
		)
		print("DialogueSystem: Iniciando fade in")

func fade_out(duration: float = 0.5):
	# Fade out a negro
	if transition_overlay:
		transition_overlay.visible = true
		transition_overlay.modulate.a = 0.0  # Empezar transparente
		var tween = create_tween()
		tween.tween_property(transition_overlay, "modulate:a", 1.0, duration)
		print("DialogueSystem: Iniciando fade out")
		return tween

func fade_out_and_change_scene(scene_path: String, duration: float = 0.5):
	# Fade out y cambiar escena
	print("DialogueSystem: Fade out y cambio a escena: ", scene_path)
	var tween = fade_out(duration)
	if tween:
		await tween.finished
	get_tree().change_scene_to_file(scene_path)

# === FUNCIÓN PARA SALTAR A LÍNEA ESPECÍFICA ===

func load_dialogue_and_jump_to_line(file_path: String, target_line_index: int):
	"""Carga un diálogo desde un archivo JSON y salta directamente a una línea específica"""
	print("DialogueSystem: Cargando diálogo desde ", file_path, " y saltando al índice ", target_line_index)
	
	# Cargar el archivo JSON
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if not file:
		print("ERROR: No se pudo abrir el archivo ", file_path)
		return
	
	var text = file.get_as_text()
	file.close()
	
	# Parsear JSON
	var json = JSON.new()
	var parse_result = json.parse(text)
	
	if parse_result != OK:
		print("ERROR: Error al parsear JSON: ", json.get_error_message())
		return
	
	var dialogue_data = json.data
	
	# Verificar que el índice objetivo está dentro del rango
	if target_line_index < 0 or target_line_index >= dialogue_data.size():
		print("ERROR: Índice de línea fuera de rango: ", target_line_index, " (máximo: ", dialogue_data.size() - 1, ")")
		return
	
	# Cargar el diálogo completo
	current_dialogue = dialogue_data
	current_index = target_line_index  # Saltar directamente al índice objetivo
	
	# Crear un sistema de diálogo simple y visible
	create_simple_dialogue_ui()
	
	print("DialogueSystem: Saltando directamente al índice ", target_line_index, " de ", current_dialogue.size(), " líneas")
	
	# Mostrar la línea objetivo directamente
	if current_dialogue.size() > 0:
		show_dialogue_line()
	else:
		print("ERROR: dialogue_data está vacío")
