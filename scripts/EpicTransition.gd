extends Control

# Replicar una animación épica similar a la de entrenamiento
func create_epic_training_end_transition():
    print("🎉 Iniciando transición épica hacia el final del diálogo de entrenamiento...")
    
    # Crear overlay de transición
    var transition_overlay = ColorRect.new()
    transition_overlay.name = "EpicTransitionOverlay"
    transition_overlay.color = Color(0, 0, 0, 1)  # Negro
    transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    transition_overlay.z_index = 1000
    transition_overlay.modulate.a = 0.0  # Empezar transparente
    add_child(transition_overlay)

    # Crear texto descriptivo
    var description_text = Label.new()
    description_text.text = "FINALIZA EL ENTRENAMIENTO"
    description_text.add_theme_font_size_override("font_size", 48)
    description_text.add_theme_color_override("font_color", Color.WHITE)
    description_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    description_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    description_text.position = Vector2(0, get_viewport().get_visible_rect().size.y * 0.5)
    description_text.size = Vector2(get_viewport().get_visible_rect().size.x, 60)
    description_text.modulate = Color(1, 1, 1, 0)  # Empezar transparente
    transition_overlay.add_child(description_text)

    # Iniciar la secuencia de animación
    start_epic_animation_sequence(transition_overlay, description_text)

# Secuencia de animación épica
func start_epic_animation_sequence(transition_overlay, description_text):
    var animation_tween = get_tree().create_tween()

    # Desvanecer overlay
    animation_tween.tween_property(transition_overlay, "modulate:a", 1.0, 0.5).set_delay(0.2)

    # Animar texto descriptivo
    animation_tween.tween_property(description_text, "modulate:a", 1.0, 0.5).set_delay(0.7)

    # Transición a la escena de diálogo al finalizar la animación
    animation_tween.tween_callback(func() {
        get_tree().change_scene_to_file("res://scenes/TrainingDialogueScene.tscn")
    }).set_delay(1.5)
    
    print("🎬 Animación épica completada, transicionando al diálogo...")

