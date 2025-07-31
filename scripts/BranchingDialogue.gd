extends Control

# BranchingDialogue - Sistema de novela visual con ramificación de historia

@onready var background = $Background
@onready var character_sprite = $CharacterSprite
@onready var dialogue_box = $DialogueBox
@onready var name_label = $DialogueBox/NameLabel
@onready var dialogue_text = $DialogueBox/DialogueText
@onready var continue_indicator = $DialogueBox/ContinueIndicator
@onready var choice_container = $ChoiceContainer

var current_dialogue = []
var current_index = 0
var is_typing = false
var story_flags = {}

# Personajes disponibles
var characters = {
	"narrator": {"name": "", "color": Color.WHITE},
	"pablo": {"name": "Pablo", "color": Color.CYAN},
	"mario": {"name": "Mario", "color": Color.GREEN},
	"javo": {"name": "Javo", "color": Color.ORANGE},
	"perma": {"name": "Perma", "color": Color.MAGENTA},
	"yazawa": {"name": "Yazawa", "color": Color.YELLOW},
	"rival_1": {"name": "Rival Presumido", "color": Color.RED},
	"rival_2": {"name": "Rival Goloso", "color": Color.MAGENTA},
	"rival_3": {"name": "Rival Calculador", "color": Color.CYAN},
	"desconocido_1": {"name": "???", "color": Color.PURPLE},
	"fan": {"name": "Fan Entusiasta", "color": Color.GOLD}
}

# Backgrounds disponibles
var backgrounds = {
	"campo": "res://assets/images/backgrounds/campo.png",
	"campovertical": "res://assets/images/backgrounds/campovertical.png"
}

func _ready():
	setup_scene()
	load_story()

func setup_scene():
	continue_indicator.visible = false
	choice_container.visible = false
	dialogue_text.text = ""
	
	# Configurar fondo inicial
	change_background("campo")

func load_story():
	# Verificar si tenemos un diálogo post-partido pendiente
	var post_match_branch = GameManager.get_story_flag("post_match_branch")
	if post_match_branch:
		print("=== Cargando diálogo post-partido (rama: ", post_match_branch, ") ===")
		var loaded_dialogue = GameManager.load_post_match_dialogue()
		if loaded_dialogue.size() > 0:
			current_dialogue = loaded_dialogue
			print("Diálogo post-partido cargado con ", loaded_dialogue.size(), " líneas")
		else:
			print("ERROR: No se pudo cargar el diálogo post-partido, usando historia por defecto.")
			load_static_story()
	else:
		# Cargar capítulo 2 si está marcado
		if GameManager.get_story_flag("load_chapter_2"):
			print("=== Cargando Capítulo 2 ===")
			GameManager.load_chapter_dialogue(2)
			current_dialogue = GameManager.get_current_dialogue_data()
		else:
			load_static_story()

	current_index = 0
	show_dialogue_line()

func load_static_story():
	# Historia principal con ramificaciones
	current_dialogue = [
		{
			"character": "narrator",
			"text": "En el centro de entrenamiento de La Velada, tres amigos se preparan para el gran evento...",
			"background": "campo"
		},
		{
			"character": "pablo",
			"text": "¡Chicos! ¿Habéis visto el sorteo? ¡Nos toca enfrentarnos en diferentes combates!"
		},
		{
			"character": "mario",
			"text": "Sí, lo he visto. Va a ser intenso. Llevamos meses entrenando juntos y ahora..."
		},
		{
			"character": "javo",
			"text": "Tranquilos, hermanos. Pase lo que pase, seguiremos siendo amigos. ¡Pero en el ring daré todo!"
		},
		{
			"character": "narrator",
			"text": "De repente, surge una discusión sobre la estrategia a seguir...",
			"background": "campovertical"
		},
		{
			"character": "pablo",
			"text": "Creo que deberíamos ayudarnos mutuamente en los entrenamientos hasta el final.",
			"choices": [
				{
					"text": "Mario: 'Estoy de acuerdo, mantengamos el equipo unido.'",
					"id": "unity_path"
				},
				{
					"text": "Mario: 'No, cada uno debe entrenar por su cuenta ahora.'",
					"id": "rivalry_path"
				},
				{
					"text": "Mario: 'Propongo que hagamos una competencia amistosa.'",
					"id": "competition_path"
				}
			]
		}
	]
	
	current_index = 0
	show_dialogue_line()

func _input(event):
	if event.is_action_pressed("ui_accept"):
		if choice_container.visible:
			return  # Las opciones manejan sus propios clics
		
		if is_typing:
			complete_current_text()
		elif current_index < current_dialogue.size() - 1:
			advance_dialogue()
		else:
			finish_dialogue()

func show_dialogue_line():
	if current_index >= current_dialogue.size():
		finish_dialogue()
		return
	
	var line = current_dialogue[current_index]
	
	# Cambiar fondo si es necesario
	if line.has("background"):
		change_background(line.background)
	
	# Configurar personaje
	if line.has("character"):
		show_character(line.character)
		var char_data = characters.get(line.character, {"name": line.character, "color": Color.WHITE})
		name_label.text = char_data.name
		name_label.modulate = char_data.color
	else:
		hide_character()
		name_label.text = ""
	
	# Mostrar opciones si las hay
	if line.has("choices"):
		show_choices(line.choices)
		type_text(line.text)
		return
	
	# Verificar si hay una transición especial
	if line.has("transition_to"):
		type_text(line.text)
		# Esperar a que termine de escribir el texto
		await get_tree().create_timer(2.0).timeout
		handle_special_transition(line.transition_to)
		return
	
	# Mostrar texto con animación
	type_text(line.text)

func show_character(character_name):
	# Lista de personajes que no tienen imagen
	var no_image_characters = ["narrator", "desconocido_1"]
	
	if character_name in no_image_characters:
		hide_character()
		return
	
	var character_path = "res://assets/images/characters/" + character_name + ".png"
	
	if ResourceLoader.exists(character_path):
		character_sprite.texture = load(character_path)
		character_sprite.visible = true
		
		# Animación de entrada
		character_sprite.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(character_sprite, "modulate:a", 1.0, 0.5)
	else:
		hide_character()
		print("Advertencia: No se encontró la imagen del personaje: ", character_name)

func hide_character():
	character_sprite.visible = false

func change_background(bg_name):
	if backgrounds.has(bg_name):
		background.texture = load(backgrounds[bg_name])

func type_text(text):
	is_typing = true
	continue_indicator.visible = false
	dialogue_text.text = ""
	
	# Animación de escritura caracter por caracter
	for i in range(text.length()):
		if not is_typing:  # Si se canceló la animación
			dialogue_text.text = text
			break
		
		dialogue_text.text += text[i]
		await get_tree().create_timer(0.03).timeout
	
	is_typing = false
	if not choice_container.visible:
		continue_indicator.visible = true

func complete_current_text():
	is_typing = false

func advance_dialogue():
	current_index += 1
	show_dialogue_line()

func show_choices(choices):
	choice_container.visible = true
	continue_indicator.visible = false
	
	# Limpiar opciones anteriores
	for child in choice_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame  # Esperar un frame para que se eliminen
	
	# Crear botones para cada opción
	for choice in choices:
		var button = Button.new()
		button.text = choice.text
		button.custom_minimum_size = Vector2(400, 50)
		button.pressed.connect(_on_choice_selected.bind(choice.id))
		choice_container.add_child(button)

func _on_choice_selected(choice_id):
	choice_container.visible = false
	story_flags[choice_id] = true
	
	print("Elección seleccionada: ", choice_id)
	
	# Cargar la continuación basada en la elección
	load_story_branch(choice_id)

func load_story_branch(choice_id):
	var branch_dialogue = []
	
	match choice_id:
		"unity_path":
			branch_dialogue = [
				{
					"character": "mario",
					"text": "Tienes razón, Pablo. Somos un equipo y así seguiremos hasta el final.",
					"background": "campo"
				},
				{
					"character": "javo",
					"text": "¡Esa es la actitud! Entrenaremos juntos y que gane el mejor en el ring."
				},
				{
					"character": "pablo",
					"text": "Perfecto. Propongo que cada día uno de nosotros dirija el entrenamiento."
				},
				{
					"character": "narrator",
					"text": "Los tres amigos decidieron mantener su amistad por encima de la competencia."
				},
				{
					"character": "mario",
					"text": "Pase lo que pase en La Velada, esto no cambiará nuestra amistad."
				},
				{
					"character": "narrator",
					"text": "FINAL: CAMINO DE LA UNIDAD - Su amistad se fortaleció y todos dieron lo mejor en el evento."
				}
			]
		
		"rivalry_path":
			branch_dialogue = [
				{
					"character": "mario",
					"text": "Lo siento chicos, pero creo que es hora de que cada uno vaya por su cuenta.",
					"background": "campovertical"
				},
				{
					"character": "pablo",
					"text": "¿En serio, Mario? Después de todo lo que hemos pasado juntos..."
				},
				{
					"character": "javo",
					"text": "Si esa es tu decisión, la respeto. Pero yo seguiré siendo vuestro amigo."
				},
				{
					"character": "mario",
					"text": "No es personal. Solo creo que necesito concentrarme al máximo."
				},
				{
					"character": "narrator",
					"text": "La tensión creció entre los amigos. Cada uno siguió su propio camino."
				},
				{
					"character": "pablo",
					"text": "Nos vemos en el ring, Mario. Que gane el mejor."
				},
				{
					"character": "narrator",
					"text": "FINAL: CAMINO DE LA RIVALIDAD - La competencia los separó, pero los hizo más fuertes individualmente."
				}
			]
		
		"competition_path":
			branch_dialogue = [
				{
					"character": "mario",
					"text": "¿Qué tal si hacemos nuestra propia mini-velada? ¡Una competencia amistosa!",
					"background": "campo"
				},
				{
					"character": "javo",
					"text": "¡Me encanta la idea! Podemos hacer diferentes pruebas cada día."
				},
				{
					"character": "pablo",
					"text": "Genial. Fuerza, resistencia, técnica... ¡El que gane más pruebas es el campeón!"
				},
				{
					"character": "narrator",
					"text": "Los tres organizaron su propia competencia preparatoria."
				},
				{
					"character": "mario",
					"text": "Esto nos ayudará a mejorar y mantener el ambiente divertido."
				},
				{
					"character": "javo",
					"text": "¡Y el ganador invita a los otros dos a cenar!"
				},
				{
					"character": "narrator",
					"text": "FINAL: CAMINO DE LA COMPETENCIA - Encontraron el equilibrio perfecto entre amistad y competición."
				}
			]
	
	# Añadir el nuevo diálogo al final
	current_dialogue.append_array(branch_dialogue)
	advance_dialogue()

func load_chapter(chapter_number):
	print("Cargando capítulo ", chapter_number)
	GameManager.load_chapter_dialogue(chapter_number)
	current_dialogue = GameManager.get_current_dialogue_data()
	current_index = 0
	show_dialogue_line()

func finish_dialogue():
	print("Diálogo completado.")
	
	# Si venimos de un post-partido, cargamos el capítulo 2
	if GameManager.get_story_flag("post_match_branch") != null:
		print("Secuencia post-partido finalizada. Cargando capítulo 2...")
		GameManager.set_story_flag("post_match_branch", null) # Limpiar flag
		GameManager.set_story_flag("load_chapter_2", true) # Marcar que vamos a cargar el capítulo 2
		load_chapter(2)
		return
	
	# Si acabamos de terminar el capítulo 2, ir al partido 7vs7
	if GameManager.get_story_flag("load_chapter_2"):
		print("Capítulo 2 completado. Iniciando partido 7vs7...")
		GameManager.set_story_flag("load_chapter_2", false) # Limpiar flag
		handle_special_transition("match_7v7")
		return

	# Si no, volvemos al menú principal
	print("Volviendo al menú principal...")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func handle_special_transition(transition_type: String):
	print("Manejando transición especial: ", transition_type)
	
	match transition_type:
		"match_6v6":
			# Configurar el simulador para 6 vs 6
			GameManager.set_story_flag("match_type", "6v6")
			GameManager.set_story_flag("chapter_2_6v6", true)
			
		"match_7v7":
			# Configurar el simulador para 7 vs 7
			print("Configurando partido 7v7...")
			GameManager.set_story_flag("match_type", "7v7")
			GameManager.set_story_flag("rival_team", "Equipo Misterioso")
			GameManager.set_story_flag("chapter_2_7v7", true)
			
			# Transición al simulador de fútbol
			var tween = create_tween()
			tween.tween_property(self, "modulate:a", 0.0, 1.0)
			await tween.finished
			get_tree().change_scene_to_file("res://scenes/FootballSimulator.tscn")
			return
			
		"prologue_end":
			# Transición épica al fin del prólogo
			print("¡Fin del prólogo! Transicionando a la escena épica...")
			GameManager.set_story_flag("prologue_completed", true)
			
			# Transición con fade
			var tween = create_tween()
			tween.tween_property(self, "modulate:a", 0.0, 1.0)
			await tween.finished
			get_tree().change_scene_to_file("res://scenes/PrologueEnd.tscn")
			return
			
		_:
			print("Transición desconocida: ", transition_type)
			# Volver al menú principal como fallback
			var tween = create_tween()
			tween.tween_property(self, "modulate:a", 0.0, 1.0)
			await tween.finished
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
