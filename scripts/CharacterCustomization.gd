extends Control

# Personalización del personaje y creación del equipo

@onready var background = $Background
@onready var character_sprite = $CharacterSprite
@onready var dialogue_text = $DialogueBox/DialogueText
@onready var character_name_label = $DialogueBox/NameLabel 
@onready var name_entry = $NameEntry
@onready var choice_container = $ChoiceContainer
@onready var continue_button = $ContinueButton
@onready var confirm_name_button = $ConfirmNameButton

var player_name = ""
var character_avatar = ""
var current_dialogue_step = 0
var is_typing = false

# Personajes disponibles
var characters = {
    "yazawa": {"name": "Yazawa", "color": Color(0.2, 0.4, 0.8)},
    "albert": {"name": "Albert", "color": Color(0.8, 0.3, 0.6)},
    "aznar": {"name": "Aznar", "color": Color(0.7, 0.2, 0.2)},
    "fan": {"name": "Fan", "color": Color(0.2, 0.6, 0.3)},
    "javo": {"name": "Javo", "color": Color(0.8, 0.5, 0.2)},
    "marcos": {"name": "Marcos", "color": Color(0.4, 0.2, 0.7)}
}

# Color consistente para todos los botones de opciones
var button_base_color = Color(0.2, 0.3, 0.5)
var button_hover_color = Color(0.3, 0.4, 0.6)
var button_pressed_color = Color(0.1, 0.2, 0.4)

# Backgrounds disponibles
var backgrounds = {
    "campo": "res://assets/images/backgrounds/campo.png",
    "campovertical": "res://assets/images/backgrounds/campovertical.png"
}

# Diálogos de introducción
var introduction_dialogues = [
    {
        "character": "yazawa",
        "text": "¡Hola! Soy Yazawa, y tengo una propuesta increíble para ti.",
        "background": "campo"
    },
    {
        "character": "yazawa",
        "text": "Estoy formando un equipo de fútbol épico, y necesito a alguien como tú para ser parte de él.",
        "background": "campo"
    },
    {
        "character": "yazawa",
        "text": "Pero primero, me gustaría conocerte mejor. ¿Cómo te llamas?",
        "background": "campo",
        "action": "ask_name"
    }
]

func _ready():
    setup_scene()
    start_visual_novel()

func _input(event):
    # Permitir click para saltar texto o avanzar diálogo
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        # Solo procesar si no hay otros elementos UI visibles
        if name_entry.visible or confirm_name_button.visible or choice_container.visible:
            return
            
        if is_typing:
            # Saltar animación de escritura
            is_typing = false
        elif continue_button.visible:
            # Avanzar diálogo
            _on_continue_pressed()

func setup_scene():
    choice_container.visible = false
    name_entry.visible = false
    confirm_name_button.visible = false
    continue_button.visible = false
    dialogue_text.text = ""
    character_name_label.text = ""
    change_background("campo")
    show_character("yazawa")
    
    # Conectar señales
    continue_button.pressed.connect(_on_continue_pressed)
    confirm_name_button.pressed.connect(_on_name_confirmed)

func start_visual_novel():
    current_dialogue_step = 0
    show_next_dialogue()

func show_next_dialogue():
    if current_dialogue_step >= introduction_dialogues.size():
        return
        
    var dialogue = introduction_dialogues[current_dialogue_step]
    
    # Cambiar fondo si es necesario
    if dialogue.has("background"):
        change_background(dialogue.background)
    
    # Mostrar personaje
    if dialogue.has("character"):
        show_character(dialogue.character)
        character_name_label.text = characters[dialogue.character].name
        character_name_label.modulate = characters[dialogue.character].color
    
    # Mostrar texto con efecto de escritura
    type_text(dialogue.text)
    
    # Verificar acciones especiales
    if dialogue.has("action"):
        match dialogue.action:
            "ask_name":
                await get_tree().create_timer(2.0).timeout
                show_name_input()
                return
    
    # Mostrar botón de continuar después del texto
    await get_tree().create_timer(1.0).timeout
    continue_button.visible = true

func type_text(text: String):
    is_typing = true
    dialogue_text.text = ""
    
    for i in range(text.length()):
        if not is_typing:  # Si se canceló la animación, mostrar todo el texto
            dialogue_text.text = text
            break
        dialogue_text.text += text[i]
        await get_tree().create_timer(0.03).timeout
        
    is_typing = false

func _on_continue_pressed():
    continue_button.visible = false
    current_dialogue_step += 1
    show_next_dialogue()

func show_name_input():
    dialogue_text.text = "Por favor, escribe tu nombre:"
    name_entry.visible = true
    confirm_name_button.visible = true
    name_entry.placeholder_text = "Tu nombre aquí..."

func _on_name_confirmed():
    if name_entry.text.strip_edges() == "":
        # Si no hay nombre, mostrar mensaje
        dialogue_text.text = "¡Vamos, no seas tímido! Escribe tu nombre."
        return
        
    player_name = name_entry.text.strip_edges()
    name_entry.visible = false
    confirm_name_button.visible = false
    
    # Guardar el nombre del jugador
    if GameManager:
        GameManager.set_story_flag("player_name", player_name)
    
    show_welcome_message()

func show_welcome_message():
    var welcome_text = "¡Encantado de conocerte, " + player_name + "! Eres exactamente lo que necesitaba."
    await show_text_with_click(welcome_text)
    show_team_introduction()

func show_text_with_click(text: String):
    # Función universal para mostrar texto y esperar click del usuario
    type_text(text)
    
    # Esperar hasta que termine la animación de texto o se omita
    while is_typing:
        await get_tree().process_frame
    
    # Mostrar botón continuar
    continue_button.visible = true
    
    # Esperar hasta que el usuario haga click
    while continue_button.visible:
        await get_tree().process_frame

func show_team_introduction():
    var team_text = "Como te decía, estoy formando un equipo de fútbol increíble. ¡Y tú serás nuestro primer miembro oficial!"
    await show_text_with_click(team_text)
    show_avatar_selection_intro()

func show_avatar_selection_intro():
    change_background("campovertical")
    var avatar_text = "Ahora necesito saber cómo te ves. Tengo aquí cuatro perfiles perfectos. ¿Cuál de estos eres tú?"
    type_text(avatar_text)
    
    await get_tree().create_timer(3.0).timeout
    show_avatar_choices()

func show_avatar_choices():
    dialogue_text.text = "Elige tu avatar:"
    choice_container.visible = true
    
    # Limpiar opciones anteriores
    for child in choice_container.get_children():
        child.queue_free()
    
    # Crear un contenedor horizontal para mostrar los personajes en fila
    var avatar_container = HBoxContainer.new()
    avatar_container.alignment = BoxContainer.ALIGNMENT_CENTER
    avatar_container.add_theme_constant_override("separation", 20)
    choice_container.add_child(avatar_container)
    
# Crear botones para cada personaje
    var available_chars = ["albert", "aznar", "fan", "javo"]  # Cambié los nombres
    var char_button_names = ["1", "2", "3", "4"]  # Nombres simples para los botones
    
    for i in range(available_chars.size()):
        var char = available_chars[i]
        var button_name = char_button_names[i]
        
        var char_button_container = VBoxContainer.new()
        char_button_container.alignment = BoxContainer.ALIGNMENT_CENTER
        
        # Imagen del personaje
        var char_image = TextureRect.new()
        char_image.custom_minimum_size = Vector2(120, 150)
        char_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
        char_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        
        var character_path = "res://assets/images/characters/" + char + ".png"
        print("=== DEBUG IMAGEN ===")
        print("Personaje: ", char, " (botón: ", button_name, ")")
        print("Ruta completa: ", character_path)
        print("Existe el recurso: ", ResourceLoader.exists(character_path))
        
        if ResourceLoader.exists(character_path):
            var texture = load(character_path)
            char_image.texture = texture
            print("Textura cargada: ", texture)
            print("Ruta de la textura: ", texture.resource_path if texture else "null")
        else:
            print("ERROR: No se puede cargar la imagen: ", character_path)
            # Intentar cargar como fallback
            var fallback_path = "res://assets/images/characters/yazawa.png"
            if ResourceLoader.exists(fallback_path):
                char_image.texture = load(fallback_path)
                print("Usando imagen fallback: ", fallback_path)
        
        # Botón con el nombre simplificado (1, 2, 3, 4)
        var button = Button.new()
        button.text = button_name
        button.custom_minimum_size = Vector2(120, 50)
        
        # Estilo del botón mejorado
        var char_data = characters[char]
        var style = StyleBoxFlat.new()
        style.bg_color = char_data.color
        style.border_width_left = 3
        style.border_width_right = 3
        style.border_width_top = 3
        style.border_width_bottom = 3
        style.border_color = Color.WHITE
        style.corner_radius_top_left = 15
        style.corner_radius_top_right = 15
        style.corner_radius_bottom_left = 15
        style.corner_radius_bottom_right = 15
        
        # Estilo cuando se presiona
        var pressed_style = StyleBoxFlat.new()
        pressed_style.bg_color = char_data.color.darkened(0.3)
        pressed_style.border_width_left = 3
        pressed_style.border_width_right = 3
        pressed_style.border_width_top = 3
        pressed_style.border_width_bottom = 3
        pressed_style.border_color = Color.YELLOW
        pressed_style.corner_radius_top_left = 15
        pressed_style.corner_radius_top_right = 15
        pressed_style.corner_radius_bottom_left = 15
        pressed_style.corner_radius_bottom_right = 15
        
        # Estilo cuando pasa el mouse por encima
        var hover_style = StyleBoxFlat.new()
        hover_style.bg_color = char_data.color.lightened(0.2)
        hover_style.border_width_left = 3
        hover_style.border_width_right = 3
        hover_style.border_width_top = 3
        hover_style.border_width_bottom = 3
        hover_style.border_color = Color.WHITE
        hover_style.corner_radius_top_left = 15
        hover_style.corner_radius_top_right = 15
        hover_style.corner_radius_bottom_left = 15
        hover_style.corner_radius_bottom_right = 15
        
        button.add_theme_stylebox_override("normal", style)
        button.add_theme_stylebox_override("pressed", pressed_style)
        button.add_theme_stylebox_override("hover", hover_style)
        
        # Mejorar el texto del botón
        button.add_theme_font_size_override("font_size", 16)
        button.add_theme_color_override("font_color", Color.WHITE)
        button.add_theme_color_override("font_pressed_color", Color.WHITE)
        button.add_theme_color_override("font_hover_color", Color.WHITE)
        
        button.pressed.connect(_on_avatar_selected.bind(char))
        
        # Añadir imagen y botón al contenedor
        char_button_container.add_child(char_image)
        char_button_container.add_child(button)
        avatar_container.add_child(char_button_container)
        
        # Pequeño delay entre la aparición de botones con animación
        char_button_container.modulate.a = 0.0
        var tween = create_tween()
        tween.tween_property(char_button_container, "modulate:a", 1.0, 0.3)
        await get_tree().create_timer(0.2).timeout

func _on_avatar_selected(char_id: String):
    character_avatar = char_id
    choice_container.visible = false
    
    # Guardar selección
    if GameManager:
        GameManager.set_story_flag("player_avatar", char_id)
    
    # Mostrar personaje seleccionado
    show_character(char_id)
    character_name_label.text = characters[char_id].name
    character_name_label.modulate = characters[char_id].color
    
    var selection_text = "¡Perfecto! Así que eres " + characters[char_id].name + ". Me gusta tu estilo."
    type_text(selection_text)
    
    await get_tree().create_timer(3.0).timeout
    continue_story()

func continue_story():
    show_character("yazawa")
    character_name_label.text = "Yazawa"
    character_name_label.modulate = Color.BLUE
    
    var story_texts = [
        "Ahora que nos conocemos, déjame contarte sobre mi visión.",
        "Quiero crear el equipo de fútbol más espectacular que haya existido jamás.",
        "No solo ganaremos partidos, ¡crearemos un espectáculo que el mundo recordará!",
        "Tú, " + player_name + ", serás una pieza clave en este sueño.",
        "¿Estás listo para comenzar esta aventura épica?"
    ]
    
    for text in story_texts:
        type_text(text)
        await get_tree().create_timer(3.5).timeout
    
    show_final_choice()

func show_final_choice():
    dialogue_text.text = "¿Qué dices? ¿Te unes a mi equipo?"
    choice_container.visible = true
    
    # Limpiar opciones anteriores
    for child in choice_container.get_children():
        child.queue_free()
    
    var yes_button = create_styled_button("¡Por supuesto! ¡Vamos a hacer historia!", Vector2(400, 60), Color(0.2, 0.6, 0.3))
    yes_button.pressed.connect(_on_join_team)
    choice_container.add_child(yes_button)
    
    var maybe_button = create_styled_button("Necesito pensarlo un poco más...", Vector2(400, 60), Color(0.6, 0.5, 0.2))
    maybe_button.pressed.connect(_on_think_about_it)
    choice_container.add_child(maybe_button)

func _on_join_team():
    choice_container.visible = false
    
    # Primero la celebración
    await show_text_with_click("¡INCREÍBLE! ¡Sabía que eras la persona perfecta!")
    await show_text_with_click("Bienvenido oficialmente al equipo, " + player_name + ".")
    
    # Presentar al miembro existente
    await show_text_with_click("¡Ah! Casi se me olvida. Ven, quiero presentarte a alguien.")
    
    # Mostrar a Marcos como miembro existente
    show_character("marcos")
    character_name_label.text = "Marcos"
    character_name_label.modulate = characters["marcos"].color
    
    await show_text_with_click("Este es Marcos, mi mano derecha y el segundo miembro de nuestro equipo.")
    
    # Marcos habla
    await show_text_with_click("¡Hola " + player_name + "! Yazawa me ha hablado mucho de ti. ¡Bienvenido al equipo!")
    
    # Yazawa vuelve a hablar
    show_character("yazawa")
    character_name_label.text = "Yazawa"
    character_name_label.modulate = characters["yazawa"].color
    
    await show_text_with_click("Perfecto. Ahora somos tres, exactamente lo que necesitamos para nuestro primer desafío.")
    await show_text_with_click("He organizado una pachanga 3 contra 3 para mañana por la tarde.")
    await show_text_with_click("Será nuestro debut oficial como equipo. ¡Una oportunidad perfecta para demostrar de qué estamos hechos!")
    
    # Marcos vuelve a hablar
    show_character("marcos")
    character_name_label.text = "Marcos"
    character_name_label.modulate = characters["marcos"].color
    
    await show_text_with_click("Los rivales no serán fáciles. Son del barrio de al lado y llevan jugando juntos desde hace años.")
    await show_text_with_click("Pero con " + player_name + " en el equipo, estoy seguro de que podemos ganar.")
    
    # Yazawa cierra
    show_character("yazawa")
    character_name_label.text = "Yazawa"
    character_name_label.modulate = characters["yazawa"].color
    
    await show_text_with_click("¡Exacto! Mañana nos encontramos en el campo municipal a las 5 de la tarde.")
    await show_text_with_click("¡Será épico! Nuestro primer paso hacia la gloria del fútbol.")
    await show_text_with_click("Descansa bien esta noche, " + player_name + ". Mañana empieza nuestra leyenda.")
    
    # Guardar progreso
    if GameManager:
        GameManager.set_story_flag("joined_team", true)
        GameManager.set_story_flag("intro_completed", true)
        GameManager.set_story_flag("match_scheduled", true)
        GameManager.save_game()
    
    # Transición con mensaje final
    await show_text_with_click("¡Hasta mañana, futuro campeón!")
    transition_to_next_scene()

func _on_think_about_it():
    choice_container.visible = false
    
    var persuasion_texts = [
        "¡Vamos, " + player_name + "! Esta es la oportunidad de tu vida.",
        "Piénsalo: fama, gloria, diversión, y la oportunidad de hacer algo épico.",
        "Además, ya nos conocemos. ¡Somos un equipo perfecto!",
        "¿Qué dices ahora?"
    ]
    
    for text in persuasion_texts:
        type_text(text)
        await get_tree().create_timer(3.0).timeout
    
    # Volver a mostrar las opciones pero con diferente texto
    show_second_chance_choice()

func show_second_chance_choice():
    dialogue_text.text = "Última oportunidad. ¿Te unes?"
    choice_container.visible = true
    
    # Limpiar opciones anteriores
    for child in choice_container.get_children():
        child.queue_free()
    
    var yes_button = create_styled_button("¡Está bien, me convenciste!", Vector2(400, 60), Color(0.2, 0.6, 0.3))
    yes_button.pressed.connect(_on_join_team)
    choice_container.add_child(yes_button)
    
    var no_button = create_styled_button("Lo siento, no es para mí.", Vector2(400, 60), Color(0.6, 0.2, 0.2))
    no_button.pressed.connect(_on_reject_team)
    choice_container.add_child(no_button)

func _on_reject_team():
    choice_container.visible = false
    
    type_text("Bueno... Supongo que no todos están destinados para la grandeza. ¡Adiós!")
    
    await get_tree().create_timer(3.0).timeout
    
    # Volver al menú principal
    get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func transition_to_next_scene():
    # Efecto de transición
    var overlay = ColorRect.new()
    overlay.color = Color.BLACK
    overlay.anchor_right = 1.0
    overlay.anchor_bottom = 1.0
    overlay.modulate.a = 0.0
    add_child(overlay)
    
    var tween = create_tween()
    tween.tween_property(overlay, "modulate:a", 1.0, 1.0)
    await tween.finished
    
    # Configurar flags para el partido 3v3 del prólogo
    if GameManager:
        GameManager.set_story_flag("match_type", "3v3")
        GameManager.set_story_flag("prologue_3v3_match", true)
        GameManager.set_story_flag("rival_team", "Equipo Rival del Barrio")
    
    # Ir al simulador de fútbol para la pachanga 3vs3
    get_tree().change_scene_to_file("res://scenes/FootballSimulator.tscn")

# Función para crear botones con estilo consistente
func create_styled_button(text: String, size: Vector2, color: Color = button_base_color) -> Button:
    var button = Button.new()
    button.text = text
    button.custom_minimum_size = size
    
    # Estilo normal
    var style = StyleBoxFlat.new()
    style.bg_color = color
    style.border_width_left = 2
    style.border_width_right = 2
    style.border_width_top = 2
    style.border_width_bottom = 2
    style.border_color = Color.WHITE
    style.corner_radius_top_left = 12
    style.corner_radius_top_right = 12
    style.corner_radius_bottom_left = 12
    style.corner_radius_bottom_right = 12
    
    # Estilo hover
    var hover_style = StyleBoxFlat.new()
    hover_style.bg_color = color.lightened(0.15)
    hover_style.border_width_left = 2
    hover_style.border_width_right = 2
    hover_style.border_width_top = 2
    hover_style.border_width_bottom = 2
    hover_style.border_color = Color.YELLOW
    hover_style.corner_radius_top_left = 12
    hover_style.corner_radius_top_right = 12
    hover_style.corner_radius_bottom_left = 12
    hover_style.corner_radius_bottom_right = 12
    
    # Estilo pressed
    var pressed_style = StyleBoxFlat.new()
    pressed_style.bg_color = color.darkened(0.2)
    pressed_style.border_width_left = 2
    pressed_style.border_width_right = 2
    pressed_style.border_width_top = 2
    pressed_style.border_width_bottom = 2
    pressed_style.border_color = Color.YELLOW
    pressed_style.corner_radius_top_left = 12
    pressed_style.corner_radius_top_right = 12
    pressed_style.corner_radius_bottom_left = 12
    pressed_style.corner_radius_bottom_right = 12
    
    button.add_theme_stylebox_override("normal", style)
    button.add_theme_stylebox_override("hover", hover_style)
    button.add_theme_stylebox_override("pressed", pressed_style)
    
    # Mejorar tipografía
    button.add_theme_font_size_override("font_size", 18)
    button.add_theme_color_override("font_color", Color.WHITE)
    button.add_theme_color_override("font_pressed_color", Color.WHITE)
    button.add_theme_color_override("font_hover_color", Color.WHITE)
    
    return button

func change_background(bg_name: String):
    if backgrounds.has(bg_name):
        background.texture = load(backgrounds[bg_name])

func show_character(character_name: String):
    # Usar nombres originales de archivo para todos los personajes
    var character_path = "res://assets/images/characters/" + character_name + ".png"
    
    print("=== DEBUG MOSTRAR PERSONAJE ===")
    print("Personaje solicitado: ", character_name)
    print("Ruta de imagen: ", character_path)
    print("Existe el recurso: ", ResourceLoader.exists(character_path))
    
    if ResourceLoader.exists(character_path):
        character_sprite.texture = load(character_path)
        character_sprite.visible = true
        
        # Animación de entrada del personaje
        character_sprite.modulate.a = 0.0
        var tween = create_tween()
        tween.tween_property(character_sprite, "modulate:a", 1.0, 0.5)
        print("Imagen cargada correctamente: ", character_path)
    else:
        character_sprite.visible = false
        print("ERROR: No se encontró la imagen del personaje: ", character_path)

