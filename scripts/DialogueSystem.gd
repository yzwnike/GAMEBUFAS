extends Control

# Sistema de diálogos estilo Doki Doki Literature Club
# Inspirado en La Velada del Año

@onready var character_name_label = $DialogueBox/NameLabel
@onready var dialogue_text = $DialogueBox/DialogueText
@onready var background = $Background
@onready var character_sprite = $CharacterSprite
@onready var continue_indicator = $DialogueBox/ContinueIndicator
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
	"campovertical": "res://assets/images/backgrounds/campovertical.png"
}

signal dialogue_finished
signal choice_made(choice_id)

var simple_dialogue_panel
var simple_name_label
var simple_text_label
var simple_continue_label

func _ready():
	print("DialogueSystem: _ready() iniciado")
	
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
	
	print("DialogueSystem: _ready() completado")

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
	if backgrounds.has(bg_name):
		background.texture = load(backgrounds[bg_name])

func show_character(character_name):
	# Verificar si es un jugador dinámico
	var char_data = characters.get(character_name, {})
	if char_data.has("image"):
		# Es un jugador de la plantilla
		var character_path = char_data.image
		if ResourceLoader.exists(character_path):
			character_sprite.texture = load(character_path)
			character_sprite.visible = true
		else:
			hide_character()
			print("Advertencia: No se encontró la imagen del jugador: ", character_name, " en ", character_path)
	else:
		# Mapear nombres de personajes fijos a archivos específicos
		var character_files = {
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

func apply_effect(effect_name):
	print("Aplicando efecto: ", effect_name)
	# Efectos simplificados para Godot 4 - por implementar

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
