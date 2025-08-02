extends Control

# Transición visual para el cambio de día

var old_day: int
var new_day: int

# Elementos UI
var transition_container: Control
var day_label: Label
var sun_sprite: Control
var background: ColorRect
var particles_container: Control

# Colores y configuración
var day_colors = [
	Color(1.0, 0.9, 0.4, 1.0),  # Amarillo dorado
	Color(1.0, 0.7, 0.3, 1.0),  # Naranja claro
	Color(0.9, 0.6, 0.8, 1.0),  # Rosa suave
	Color(0.7, 0.9, 1.0, 1.0),  # Azul cielo
	Color(0.8, 1.0, 0.6, 1.0),  # Verde claro
]

func _ready():
	# Configurar el control para pantalla completa
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# BLOQUEAR INPUTS DURANTE LA TRANSICIÓN
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP  # Interceptar todos los clics
	
	# Crear la transición
	setup_transition()

func show_day_transition(from_day: int, to_day: int):
	old_day = from_day
	new_day = to_day
	
	print("🌅 DayTransition: Iniciando transición del día ", from_day, " al día ", to_day)
	
	# Hacer visible y activar bloqueo de inputs
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP  # Bloquear clics
	print("🚫 DayTransition: Inputs bloqueados durante la transición")
	
	start_transition_animation()

func setup_transition():
	# Fondo completamente opaco
	background = ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.1, 0.1, 0.2, 1.0)  # Azul oscuro inicial OPACO
	add_child(background)
	
	# Container principal
	transition_container = Control.new()
	transition_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(transition_container)
	
	# Sol animado
	sun_sprite = create_sun_sprite()
	transition_container.add_child(sun_sprite)
	
	# Label del día
	day_label = Label.new()
	day_label.add_theme_font_size_override("font_size", 64)
	day_label.add_theme_color_override("font_color", Color.WHITE)
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	day_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	day_label.text = "DÍA 1"
	transition_container.add_child(day_label)
	
	# Container para partículas
	particles_container = Control.new()
	particles_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_container.add_child(particles_container)
	
	# Inicialmente invisible
	visible = false

func create_sun_sprite() -> Control:
	var sun_container = Control.new()
	sun_container.size = Vector2(150, 150)
	
	# Círculo del sol
	var sun_circle = ColorRect.new()
	sun_circle.size = Vector2(120, 120)
	sun_circle.position = Vector2(15, 15)
	sun_circle.color = Color(1.0, 0.9, 0.3, 1.0)
	sun_container.add_child(sun_circle)
	
	# Añadir rayos del sol
	for i in range(8):
		var ray = ColorRect.new()
		ray.size = Vector2(40, 6)
		ray.color = Color(1.0, 0.8, 0.2, 0.8)
		ray.position = Vector2(55, 72)  # Centro del sol
		ray.pivot_offset = Vector2(0, 3)  # Centro del rayo
		ray.rotation = i * PI / 4  # 8 rayos a 45 grados
		sun_container.add_child(ray)
	
	# Posición inicial del sol (fuera de pantalla, izquierda)
	sun_container.position = Vector2(-200, get_viewport().get_visible_rect().size.y / 2 - 75)
	
	return sun_container

func start_transition_animation():
	# Configurar texto inicial - MOSTRAR DIRECTAMENTE EL NUEVO DÍA
	var day_color = day_colors[(new_day - 1) % day_colors.size()]
	day_label.text = "DÍA " + str(new_day)  # DIRECTAMENTE EL NUEVO DÍA
	day_label.add_theme_color_override("font_color", day_color)
	day_label.modulate = Color.TRANSPARENT
	
	var screen_size = get_viewport().get_visible_rect().size
	var tween = create_tween()
	tween.set_parallel(true)  # Permitir múltiples animaciones en paralelo
	
	# FASE 1: Fade in del fondo y aparición del NUEVO DÍA (0.3s)
	tween.tween_property(background, "color", Color(0.2, 0.3, 0.5, 1.0), 0.3)
	tween.tween_property(day_label, "modulate", Color.WHITE, 0.3)
	
	# FASE 2: Sol atraviesa la pantalla (1.2s) - empieza después de 0.2s
	tween.tween_property(sun_sprite, "position", Vector2(screen_size.x + 200, screen_size.y / 2 - 75), 1.2).set_delay(0.2)
	
	# Rotación del sol mientras se mueve
	tween.tween_property(sun_sprite, "rotation", PI * 2, 1.2).set_delay(0.2)
	
	# FASE 3: Cambio de color del fondo según el NUEVO día (0.6s) - empieza a los 0.6s
	var gradient_color = day_color
	gradient_color.a = 1.0  # MANTENER COMPLETAMENTE OPACO
	tween.tween_property(background, "color", gradient_color, 0.6).set_delay(0.6)
	
	# Cambiar el texto del día a azul para mejor contraste con el fondo colorido
	tween.tween_property(day_label, "modulate", Color(0.2, 0.3, 0.8, 1.0), 0.6).set_delay(0.6)
	
	# FASE 4: Crear partículas/estrellas (0.5s) - empieza a los 1.2s
	await get_tree().create_timer(1.2).timeout
	create_sparkle_particles()
	
	# FASE 5: Fade out más rápido (0.4s) - empieza a los 1.8s
	await get_tree().create_timer(0.8).timeout
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.4)
	
	# Cleanup y señal de finalización
	await get_tree().create_timer(0.4).timeout
	finish_transition()

func create_sparkle_particles():
	var screen_size = get_viewport().get_visible_rect().size
	
	# Crear partículas de brillos
	for i in range(15):
		var particle = create_sparkle()
		particle.position = Vector2(
			randf_range(0, screen_size.x),
			randf_range(0, screen_size.y)
		)
		particles_container.add_child(particle)
		
		# Animar cada partícula
		animate_sparkle(particle)

func create_sparkle() -> Control:
	var sparkle = Label.new()
	var sparkle_chars = ["✨", "⭐", "🌟", "💫"]
	sparkle.text = sparkle_chars[randi() % sparkle_chars.size()]
	sparkle.add_theme_font_size_override("font_size", randi_range(20, 40))
	sparkle.modulate = Color.TRANSPARENT
	return sparkle

func animate_sparkle(sparkle: Control):
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade in
	tween.tween_property(sparkle, "modulate", Color.WHITE, 0.3)
	
	# Escala pulsante
	tween.tween_property(sparkle, "scale", Vector2(1.5, 1.5), 0.5)
	tween.tween_property(sparkle, "scale", Vector2(1.0, 1.0), 0.5).set_delay(0.5)
	
	# Fade out
	tween.tween_property(sparkle, "modulate", Color.TRANSPARENT, 0.4).set_delay(0.8)
	
	# Cleanup
	tween.tween_callback(sparkle.queue_free).set_delay(1.2)

func finish_transition():
	print("🌅 DayTransition: Transición completada")
	
	# Limpiar partículas restantes
	for child in particles_container.get_children():
		child.queue_free()
	
	# DESBLOQUEAR INPUTS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	print("✅ DayTransition: Inputs desbloqueados")
	
	# Ocultar y resetear
	visible = false
	modulate = Color.WHITE
	
	# Señal de finalización si hay algún listener
	if has_signal("transition_finished"):
		emit_signal("transition_finished")

# Función para interceptar TODOS los inputs durante la transición
func _input(event):
	# Si la transición está activa (visible), bloquear TODOS los inputs
	if visible:
		get_viewport().set_input_as_handled()
		if event is InputEventMouseButton:
			print("🚫 DayTransition: Clic bloqueado durante la transición")
		elif event is InputEventKey:
			print("🚫 DayTransition: Tecla bloqueada durante la transición")
		return  # No procesar más el input

# Función para interceptar inputs en la GUI
func _gui_input(event):
	# Si la transición está activa, bloquear todos los inputs GUI
	if visible:
		accept_event()  # Marcar el evento como manejado
		if event is InputEventMouseButton:
			print("🚫 DayTransition: GUI clic bloqueado")

# Señal para notificar cuando la transición termina
signal transition_finished
