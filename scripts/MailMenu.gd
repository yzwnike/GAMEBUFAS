extends Control

@onready var mails_container = $VBoxContainer/ScrollContainer/MailsContainer
@onready var back_button = $VBoxContainer/InfoPanel/BackButton

func _ready():
    print("MailMenu: Mostrando correos")
    
    if back_button:
        back_button.pressed.connect(_on_back_pressed)
    
    # Marcar todos los correos como leídos al abrir el menú
    mark_all_mails_as_read()
    
    update_display()

func _on_back_pressed():
    print("MailMenu: Volviendo al menú principal")
    # Marcar que venimos de la pantalla de correos
    var interactive_scene = load("res://scenes/InteractiveMenu.tscn")
    var interactive_instance = interactive_scene.instantiate()
    interactive_instance.set_meta("from_mail_menu", true)
    get_tree().root.add_child(interactive_instance)
    get_tree().current_scene.queue_free()
    get_tree().current_scene = interactive_instance

func update_display():
    print("MailMenu: Actualizando visualización...")
    
    if mails_container:
        update_mails()

func update_mails():
    print("MailMenu: Actualizando correos...")
    
    # Limpiar correos anteriores
    for child in mails_container.get_children():
        child.queue_free()
    
    var mails = MailManager.get_all_mails()
    print("MailManager devolvió ", mails.size(), " correos")
    
    if mails.is_empty():
        # Mostrar mensaje si no hay correos
        var no_mails_label = Label.new()
        no_mails_label.text = "No tienes correos nuevos"
        no_mails_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        no_mails_label.add_theme_font_size_override("font_size", 16)
        no_mails_label.add_theme_color_override("font_color", Color.GRAY)
        mails_container.add_child(no_mails_label)
        return
    
    # Usar VBoxContainer para mejor control del espaciado
    var main_container = VBoxContainer.new()
    main_container.add_theme_constant_override("separation", 25)  # Separación entre correos
    main_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    main_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
    mails_container.add_child(main_container)
    
    # Crear tarjetas de correos
    for mail in mails:
        var mail_card = create_mail_card(mail)
        main_container.add_child(mail_card)

func create_mail_card(mail):
    # Contenedor principal de la tarjeta
    var card = Control.new()
    
    # Calcular altura dinámica basada en el contenido del correo
    var base_height = 200  # Altura base para headers y botones
    var content_lines = mail.content.length() / 80  # Aproximadamente 80 caracteres por línea
    var content_height = max(100, content_lines * 18)  # 18px por línea, mínimo 100px
    var total_height = base_height + content_height
    
    card.custom_minimum_size = Vector2(700, total_height)
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    
    # Panel con fondo oscuro y bordes redondeados
    var panel = Panel.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.add_theme_constant_override("margin_left", 10)
    panel.add_theme_constant_override("margin_right", 10)
    panel.add_theme_constant_override("margin_top", 10)
    panel.add_theme_constant_override("margin_bottom", 10)

    # StyleBox
    var style_box = StyleBoxFlat.new()
    style_box.bg_color = Color(0.08, 0.08, 0.08, 1.0)
    style_box.corner_radius_top_left = 10
    style_box.corner_radius_top_right = 10
    style_box.corner_radius_bottom_left = 10
    style_box.corner_radius_bottom_right = 10
    panel.add_theme_stylebox_override("panel", style_box)
    card.add_child(panel)

    # Contenedor de contenido
    var content_container = MarginContainer.new()
    content_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    content_container.add_theme_constant_override("margin_left", 20)
    content_container.add_theme_constant_override("margin_right", 20)
    content_container.add_theme_constant_override("margin_top", 20)
    content_container.add_theme_constant_override("margin_bottom", 20)
    panel.add_child(content_container)
    
    # VBox principal para el contenido
    var vbox = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 10)
    content_container.add_child(vbox)

    # Indicador de tipo de correo y título
    var header_container = HBoxContainer.new()
    header_container.alignment = BoxContainer.ALIGNMENT_CENTER
    
    # Icono según tipo de correo
    var type_icon = Label.new()
    if mail.type == "negotiation_update":
        type_icon.text = "💼 "
        type_icon.add_theme_color_override("font_color", Color(0.3, 0.6, 0.9))
    elif mail.type == "player_complaint":
        type_icon.text = "⚠️ "
        type_icon.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3))
    else:
        type_icon.text = "📧 "
    type_icon.add_theme_font_size_override("font_size", 20)
    header_container.add_child(type_icon)
    
    # Título
    var title_label = Label.new()
    title_label.text = mail.subject
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.add_theme_font_size_override("font_size", 18)
    title_label.add_theme_color_override("font_color", Color.WHITE)
    header_container.add_child(title_label)
    
    vbox.add_child(header_container)
    
    # Remitente con mejor formato
    var sender_label = Label.new()
    var sender_text = "De: " + mail.player_name
    if mail.type == "negotiation_update":
        sender_text = "De: Departamento de Traspasos (sobre " + mail.player_name + ")"
    sender_label.text = sender_text
    sender_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sender_label.add_theme_font_size_override("font_size", 12)
    sender_label.add_theme_color_override("font_color", Color.GRAY)
    vbox.add_child(sender_label)
    
    # Separador visual
    var separator = HSeparator.new()
    separator.add_theme_constant_override("separation", 5)
    vbox.add_child(separator)
    
    # Contenedor de contenido con scroll si es necesario
    var content_scroll = ScrollContainer.new()
    content_scroll.custom_minimum_size = Vector2(0, max(100, content_height - 50))
    content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vbox.add_child(content_scroll)
    
    # Contenido
    var content_label = Label.new()
    content_label.text = mail.content
    content_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    content_label.add_theme_font_size_override("font_size", 13)
    content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    # Agregar padding interno al texto
    var content_margin = MarginContainer.new()
    content_margin.add_theme_constant_override("margin_left", 10)
    content_margin.add_theme_constant_override("margin_right", 10)
    content_margin.add_theme_constant_override("margin_top", 10)
    content_margin.add_theme_constant_override("margin_bottom", 10)
    content_margin.add_child(content_label)
    content_scroll.add_child(content_margin)

    # Botones según tipo de correo
    # Separador antes de los botones
    var button_separator = HSeparator.new()
    vbox.add_child(button_separator)
    
    # Contenedor para centrar los botones
    var button_container = HBoxContainer.new()
    button_container.alignment = BoxContainer.ALIGNMENT_CENTER
    
    if mail.type == "negotiation_update":
        var negotiation_button = Button.new()
        negotiation_button.text = "💼 Abrir Negociaciones"
        negotiation_button.custom_minimum_size = Vector2(200, 40)
        negotiation_button.add_theme_font_size_override("font_size", 14)
        negotiation_button.pressed.connect(func(): _on_open_negotiations_pressed())
        
        # Estilo del botón azul
        var button_style = StyleBoxFlat.new()
        button_style.bg_color = Color(0.2, 0.5, 0.8, 1.0)  # Azul
        button_style.corner_radius_top_left = 8
        button_style.corner_radius_top_right = 8
        button_style.corner_radius_bottom_left = 8
        button_style.corner_radius_bottom_right = 8
        negotiation_button.add_theme_stylebox_override("normal", button_style)
        
        # Estilo hover azul
        var button_style_hover = StyleBoxFlat.new()
        button_style_hover.bg_color = Color(0.3, 0.6, 0.9, 1.0)  # Azul más claro
        button_style_hover.corner_radius_top_left = 8
        button_style_hover.corner_radius_top_right = 8
        button_style_hover.corner_radius_bottom_left = 8
        button_style_hover.corner_radius_bottom_right = 8
        negotiation_button.add_theme_stylebox_override("hover", button_style_hover)
        
        button_container.add_child(negotiation_button)
    
    elif mail.type == "player_complaint":
        var confirm_button = Button.new()
        confirm_button.text = "✓ CONFIRMAR Y BORRAR"
        confirm_button.custom_minimum_size = Vector2(220, 40)
        confirm_button.add_theme_font_size_override("font_size", 14)
        confirm_button.pressed.connect(func(): _on_confirm_and_delete_pressed(mail.id))
        
        # Estilo del botón rojo
        var button_style_red = StyleBoxFlat.new()
        button_style_red.bg_color = Color(0.8, 0.3, 0.3, 1.0)  # Rojo
        button_style_red.corner_radius_top_left = 8
        button_style_red.corner_radius_top_right = 8
        button_style_red.corner_radius_bottom_left = 8
        button_style_red.corner_radius_bottom_right = 8
        confirm_button.add_theme_stylebox_override("normal", button_style_red)
        
        # Estilo hover rojo
        var button_style_red_hover = StyleBoxFlat.new()
        button_style_red_hover.bg_color = Color(0.9, 0.4, 0.4, 1.0)  # Rojo más claro
        button_style_red_hover.corner_radius_top_left = 8
        button_style_red_hover.corner_radius_top_right = 8
        button_style_red_hover.corner_radius_bottom_left = 8
        button_style_red_hover.corner_radius_bottom_right = 8
        confirm_button.add_theme_stylebox_override("hover", button_style_red_hover)
        
        button_container.add_child(confirm_button)
    
    vbox.add_child(button_container)

    return card

func _on_open_negotiations_pressed():
    print("MailMenu: Abriendo Negociaciones Activas")
    get_tree().change_scene_to_file("res://scenes/ActiveNegotiationsMarket.tscn")

func _on_confirm_and_delete_pressed(mail_id: String):
    print("MailMenu: Confirmando y borrando correo ", mail_id)
    MailManager.delete_mail(mail_id)
    update_display()

func mark_all_mails_as_read():
    print("MailMenu: Marcando todos los correos como leídos")
    var mails = MailManager.get_all_mails()
    for mail in mails:
        if not mail.is_read:
            MailManager.mark_mail_as_read(mail.id)
