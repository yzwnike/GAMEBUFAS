extends Control

# Referencias para la transición épica del estadio
var transition_overlay: ColorRect
var description_text: Label
var camera_3d: Camera3D
var viewport_container: SubViewportContainer
var viewport_3d: SubViewport

func _ready():
    print("🏟️ StadiumTransition: Iniciando la transición épica hacia el estadio...")
    create_stadium_transition()

func create_stadium_transition():
    print("🚁 Creando transición de dron hacia el estadio...")
    
    # Crear overlay principal
    transition_overlay = ColorRect.new()
    transition_overlay.name = "StadiumOverlay"
    transition_overlay.color = Color(0.2, 0.3, 0.5, 1.0)  # Azul noche
    transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    transition_overlay.z_index = 1000
    transition_overlay.modulate.a = 0.0  # Empezar transparente
    self.add_child(transition_overlay)
    
    # Crear viewport 3D para efectos
    create_3d_stadium_effect()
    
    # Crear texto descriptivo
    description_text = Label.new()
    description_text.text = "PREPARÁNDOTE PARA EL PARTIDO"
    description_text.add_theme_font_size_override("font_size", 48)
    description_text.add_theme_color_override("font_color", Color.WHITE)
    description_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    description_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    
    # Posicionar en la parte inferior
    var screen_size = get_viewport().get_visible_rect().size
    description_text.position = Vector2(0, screen_size.y * 0.7)
    description_text.size = Vector2(screen_size.x, 60)
    description_text.modulate = Color(1, 1, 1, 0)  # Empezar transparente
    transition_overlay.add_child(description_text)

    # Iniciar la secuencia de animación
    start_stadium_animation_sequence()

func create_3d_stadium_effect():
    print("⚽ Creando escena 3D del estadio...")
    
    viewport_container = SubViewportContainer.new()
    viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    viewport_container.stretch = true
    transition_overlay.add_child(viewport_container)
    
    viewport_3d = SubViewport.new()
    viewport_3d.size = Vector2i(1920, 1080)
    viewport_3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    viewport_container.add_child(viewport_3d)

    # Crear cámara 3D
    camera_3d = Camera3D.new()
    camera_3d.position = Vector3(0, 40, 40)  # Vista amplia de estadio
    camera_3d.look_at(Vector3(0, 0, 0), Vector3.UP)
    viewport_3d.add_child(camera_3d)

    # Añadir luces del estadio
    create_stadium_lights()

func create_stadium_lights():
    """Crear sistema de iluminación del estadio"""
    var stadium_lights = DirectionalLight3D.new()
    stadium_lights.position = Vector3(-50, 50, 0)
    stadium_lights.look_at(Vector3(0, 0, 0), Vector3.UP)
    stadium_lights.light_energy = 5.0
    viewport_3d.add_child(stadium_lights)

func start_stadium_animation_sequence():
    # Configurar tween para la animación
    var animation_tween = create_tween()

    # Desvanecer overlay
    animation_tween.tween_property(transition_overlay, "modulate:a", 1.0, 0.3).set_delay(0.2)

    # Animar texto descriptivo
    animation_tween.tween_property(description_text, "modulate:a", 1.0, 0.3).set_delay(0.5)

    # Animar movimiento de cámara
    animation_tween.tween_property(camera_3d, "position", Vector3(0, 10, 15), 2.5).set_delay(1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    
    # Cambiar ángulo de cámara gradualmente
    animation_tween.parallel().tween_method(update_camera_angle, Vector3(0, 0, 0), Vector3(-10, 0, 0), 2.5).set_delay(1.0)

    # Switch scene exactly when camera movement ends
    animation_tween.tween_callback(transition_to_stadium_scene).set_delay(3.5)

func update_camera_angle(angle: Vector3):
    """Actualiza gradualmente el ángulo de la cámara"""
    if camera_3d:
        camera_3d.rotation_degrees = angle

func transition_to_stadium_scene():
    """Transición final hacia la escena del estadio"""
    print("⚽ Transicionando a la escena del estadio...")
    get_tree().change_scene_to_file("res://stadium_scene.tscn")

