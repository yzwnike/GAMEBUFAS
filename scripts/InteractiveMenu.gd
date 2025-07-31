extends Control

@onready var hover_info_panel = $UILayer/HoverInfo
@onready var info_label = $UILayer/HoverInfo/InfoLabel
@onready var day_label = $UILayer/DayContainer/DayLabel
@onready var title_container = $UILayer/TitleContainer
@onready var day_container = $UILayer/DayContainer
@onready var background = $Background

# Variables para animaciones
var hover_tween: Tween
var entry_tween: Tween
var transition_tween: Tween
var area_buttons = {}
var original_positions = {}
var original_scales = {}
var original_background_position: Vector2
var original_background_scale: Vector2
var is_transitioning = false

# Variables para controlar estados de transición
var is_first_time = true
var last_selected_area = ""
var returning_from_submenu = false

func _ready():
	print("InteractiveMenu: Inicializando menú interactivo...")
	
	# Verificar que todos los nodos existen
	var estadio_area = $ClickableAreas/EstadioArea
	var campo_area = $ClickableAreas/CampoArea
	var barrio_area = $ClickableAreas/BarrioArea
	
	if not estadio_area or not campo_area or not barrio_area:
		print("ERROR: No se pudieron encontrar todas las áreas clickables")
		return
	
	print("InteractiveMenu: Conectando señales...")
	
	# Conectar señales de hover
	estadio_area.mouse_entered.connect(func(): _on_area_hovered("estadio"))
	estadio_area.mouse_exited.connect(self._on_area_exited)
	
	campo_area.mouse_entered.connect(func(): _on_area_hovered("campo"))
	campo_area.mouse_exited.connect(self._on_area_exited)
	
	barrio_area.mouse_entered.connect(func(): _on_area_hovered("barrio"))
	barrio_area.mouse_exited.connect(self._on_area_exited)
	
	# Conectar señales de clic
	estadio_area.pressed.connect(func(): _on_area_clicked("estadio"))
	campo_area.pressed.connect(func(): _on_area_clicked("campo"))
	barrio_area.pressed.connect(func(): _on_area_clicked("barrio"))
	
	# Actualizar visualización del día
	update_day_display()
	
	# Conectar a la señal de cambio de día
	if DayManager.has_signal("day_advanced"):
		DayManager.day_advanced.connect(_on_day_advanced)
	if DayManager.has_signal("day_changed"):
		DayManager.day_changed.connect(update_day_display)
	
	# Guardar botones de área y posiciones originales
	area_buttons["estadio"] = estadio_area
	area_buttons["campo"] = campo_area
	area_buttons["barrio"] = barrio_area
	
	for area_name in area_buttons:
		original_positions[area_name] = area_buttons[area_name].position
	
	# Guardar posición y escala originales del fondo
	original_background_position = background.position
	original_background_scale = background.scale
	
	# Crear shader material para el fondo (comentado temporalmente)
	# setup_background_shader()
	
	# Solo hacer la animación completa la primera vez
	# Las siguientes veces (cuando volvemos de submenús) usaremos start_return_transition()
	if is_first_time:
		start_entrance_animation()
	else:
		# Aparecer directamente en modo normal sin animación
		setup_normal_state()
	
	print("InteractiveMenu: Menú interactivo listo")

func _input(event):
	# CHEAT: Pulsar D para probar la transición de día
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_D:
			test_day_transition()

func test_day_transition():
	print("🌅 CHEAT: Probando transición de día...")
	DayManager.advance_day_with_origin("training")

func _on_area_hovered(area_name):
	hover_info_panel.visible = true
	
	match area_name:
		"estadio":
			info_label.text = "Torneo Tiki-Taka: Compite en el torneo de fútbol 7 y demuestra quién es el mejor equipo."
		"campo":
			info_label.text = "Campo de Entrenamiento: Mejora tus habilidades y las de tu equipo."
		"barrio":
			info_label.text = "El Barrio: Fichajes, enciclopedia de jugadores y tienda de suplementos."

func _on_area_exited():
	hover_info_panel.visible = false

func _on_area_clicked(area_name):
	if is_transitioning:
		return
	
	print("InteractiveMenu: Área clickeada: ", area_name)
	
	# Determinar la escena de destino
	var target_scene = ""
	match area_name:
		"estadio":
			print("Accediendo al Torneo Tiki-Taka...")
			target_scene = "res://scenes/TournamentMenu.tscn"
		"campo":
			print("Accediendo al Campo de Entrenamiento...")
			target_scene = "res://scenes/TrainingMenu.tscn"
		"barrio":
			print("Accediendo al Barrio...")
			target_scene = "res://scenes/NeighborhoodMenu.tscn"
	
	# Iniciar transición con zoom
	start_zoom_transition(area_name, target_scene)

# Animación de entrada inicial del menú
func start_entrance_animation():
	entry_tween = get_tree().create_tween()
	
	# Animar la entrada con fade in solamente (más simple y estable)
	for area_name in area_buttons:
		var button = area_buttons[area_name]
		button.modulate = Color(1, 1, 1, 0)  # Empezar invisible
		entry_tween.parallel().tween_property(button, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Animar el título principal
	title_container.modulate = Color(1, 1, 1, 0)  # Comienza invisible
	entry_tween.tween_property(title_container, "modulate:a", 1, 1.0)
	
	# Animar el fondo para efectos visuales iniciales
	background.modulate = Color(1, 1, 1, 0)
	entry_tween.tween_property(background, "modulate:a", 1, 2.0)

# Configuración de shader de fondo
func setup_background_shader():
	# Intentar cargar el shader, pero no fallar si no existe
	var shader_path = "res://shaders/background.gdshader"
	if ResourceLoader.exists(shader_path):
		background.material = ShaderMaterial.new()
		var shader = load(shader_path)
		background.material.shader = shader
		print("InteractiveMenu: Shader de fondo cargado correctamente")
	else:
		print("InteractiveMenu: Shader de fondo no encontrado, continuando sin efectos")

# Actualizar visualización del día actual
func update_day_display():
	var current_day = DayManager.get_current_day()
	day_label.text = "Día %d" % current_day

func _on_day_advanced(new_day: int):
	print("🌅 InteractiveMenu: Día avanzado a ", new_day, ", actualizando UI...")
	update_day_display()

# Configurar estado normal sin animación
func setup_normal_state():
	# Establecer el estado del fondo y elementos UI al estado inicial sin animaciones
	self.modulate.a = 1.0
	background.scale = original_background_scale
	background.position = original_background_position
	
	# Restaurar visibilidad de los botones y elementos UI
	for area_name in area_buttons:
		var button = area_buttons[area_name]
		button.modulate.a = 1.0
	
	title_container.modulate.a = 1.0
	day_container.modulate.a = 1.0

# Transición de retorno desde un submenú (tras hacer zoom en un área)
func start_return_transition():
	# Configurar estado inicial: aparecer con el zoom del área donde estuvimos
	# Usar exactamente los mismos valores que en el zoom de ida
	var zoom_offsets = {
		"estadio": Vector2(0, -600),      # Torneo - mismos valores que zoom de ida
		"campo": Vector2(-1400, -1300),  # Entrenamiento - mismos valores que zoom de ida
		"barrio": Vector2(-2800, -900)   # Barrio - mismos valores que zoom de ida
	}
	
	var area_zoom_offset = zoom_offsets.get(last_selected_area, Vector2.ZERO)
	
	background.scale = Vector2(2.5, 2.5)
	background.position = original_background_position + area_zoom_offset
	
	# Crear tween de recuperación para retornar al estado inicial
	transition_tween = get_tree().create_tween()
	transition_tween.set_parallel(true)
	
	# Restaurar fondo a su estado original
	transition_tween.tween_property(background, "scale", original_background_scale, 0.8).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	transition_tween.tween_property(background, "position", original_background_position, 0.8).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	# Fade in de los botones y elementos UI
	for area_name in area_buttons:
		var button = area_buttons[area_name]
		button.modulate.a = 0.0
		transition_tween.tween_property(button, "modulate:a", 1.0, 0.6).set_delay(0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Fade in de elementos UI
	title_container.modulate.a = 0.0
	day_container.modulate.a = 0.0
	transition_tween.tween_property(title_container, "modulate:a", 1.0, 0.6).set_delay(0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	transition_tween.tween_property(day_container, "modulate:a", 1.0, 0.6).set_delay(0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# Transición con zoom al hacer clic en un área
func start_zoom_transition(area_name: String, target_scene: String):
	is_transitioning = true
	
	# Guardar el área seleccionada para cuando volvamos
	last_selected_area = area_name
	is_first_time = false  # Ya no es la primera vez
	
	# Ocultar panel de información
	hover_info_panel.visible = false
	
	# Obtener el botón del área seleccionada para calcular posición
	var selected_button = area_buttons[area_name]
	
	# Crear el tween de transición
	transition_tween = get_tree().create_tween()
	transition_tween.set_parallel(true)
	
	# Definir posiciones de zoom basadas en las ubicaciones visuales en la imagen de fondo
	# Para hacer zoom al centro de la imagen, necesitamos mover el fondo hacia arriba-izquierda
	var zoom_offsets = {
		"estadio": Vector2(0, -600),    # Torneo - izquierda, ligeramente abajo
		"campo": Vector2(-1400, -1300),    # Entrenamiento - centro de la imagen (mover fondo para centrar)
		"barrio": Vector2(-2800, -900)     # Barrio - derecha, ligeramente abajo
	}
	
	# Obtener el offset de zoom para el área seleccionada
	var zoom_offset = zoom_offsets.get(area_name, Vector2.ZERO)
	
	# Calcular la posición objetivo del fondo
	var background_target_pos = original_background_position + zoom_offset
	
	# Fase 1: Zoom del fondo hacia el área seleccionada
	# Escalar el fondo (zoom in)
	transition_tween.tween_property(background, "scale", Vector2(2.5, 2.5), 0.8).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	
	# Mover el fondo para mostrar el área visual correcta
	transition_tween.tween_property(background, "position", background_target_pos, 0.8).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	
	# Fade out de todos los botones
	for button_name in area_buttons:
		transition_tween.tween_property(area_buttons[button_name], "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Fade out de elementos UI
	transition_tween.tween_property(title_container, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	transition_tween.tween_property(day_container, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Fase 2: Fade out de toda la pantalla después del zoom
	transition_tween.tween_property(self, "modulate:a", 0.0, 0.4).set_delay(0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Cambiar a la escena de destino cuando termine la animación
	transition_tween.tween_callback(func(): get_tree().change_scene_to_file(target_scene)).set_delay(1.0)
	
	print("InteractiveMenu: Iniciando transición con zoom del fondo hacia ", area_name)


