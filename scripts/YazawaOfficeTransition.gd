extends Control

# Referencias a nodos
@onready var president_icon = $CenterContainer/VBoxContainer/PresidentIcon
@onready var loading_text = $CenterContainer/VBoxContainer/LoadingText
@onready var sub_text = $CenterContainer/VBoxContainer/SubText
@onready var progress_bar = $CenterContainer/VBoxContainer/ProgressBar
@onready var status_text = $CenterContainer/VBoxContainer/StatusText
@onready var background = $Background
@onready var gold_particles = $ParticleLayer/GoldParticles
@onready var viewport_3d = $ViewportContainer/3DViewport
@onready var camera_3d = $ViewportContainer/3DViewport/Camera3D
@onready var crown_3d = $ViewportContainer/3DViewport/PresidentialCrown
@onready var building_3d = $ViewportContainer/3DViewport/OfficeBuilding
@onready var audio_player = $AudioStreamPlayer

# Variables de animación
var transition_tween: Tween
var progress_tween: Tween
var camera_tween: Tween
var rotation_tween: Tween

# Fases de carga
var loading_phases = [
	{"text": "Verificando credenciales presidenciales...", "progress": 15},
	{"text": "Encendiendo luces de la oficina ejecutiva...", "progress": 30},
	{"text": "Preparando sillón de cuero premium...", "progress": 45},
	{"text": "Activando sistema de seguridad VIP...", "progress": 60},
	{"text": "Cargando documentos confidenciales...", "progress": 75},
	{"text": "Puliendo trofeos y medallas...", "progress": 90},
	{"text": "¡Bienvenido, Presidente Yazawa!", "progress": 100}
]

var current_phase = 0

func _ready():
	print("🏛️ YazawaOfficeTransition: Iniciando transición épica...")
	
	# Debug - verificar que todos los nodos existan
	debug_check_nodes()
	
	# Configurar estilos iniciales
	setup_initial_styles()
	
	# Crear objetos 3D
	create_3d_objects()
	
	# Iniciar partículas doradas
	gold_particles.emitting = true
	
	# Comenzar la secuencia épica
	start_epic_sequence()

func setup_initial_styles():
	"""Configura los estilos iniciales súper impactantes"""
	
	# Icono del presidente - SÚPER GRANDE
	president_icon.add_theme_font_size_override("font_size", 200)
	president_icon.add_theme_color_override("font_color", Color.GOLD)
	president_icon.modulate = Color(1, 1, 1, 0)  # Empezar invisible
	
	# Texto de carga principal
	loading_text.add_theme_font_size_override("font_size", 42)
	loading_text.add_theme_color_override("font_color", Color.WHITE)
	loading_text.add_theme_color_override("font_shadow_color", Color.BLACK)
	loading_text.add_theme_constant_override("shadow_offset_x", 4)
	loading_text.add_theme_constant_override("shadow_offset_y", 4)
	loading_text.modulate = Color(1, 1, 1, 0)
	
	# Subtexto elegante
	sub_text.add_theme_font_size_override("font_size", 24)
	sub_text.add_theme_color_override("font_color", Color(1, 0.8, 0.4, 1))
	sub_text.modulate = Color(1, 1, 1, 0)
	
	# Barra de progreso dorada
	var progress_style = StyleBoxFlat.new()
	progress_style.bg_color = Color(0.2, 0.15, 0.1, 0.8)
	progress_style.corner_radius_top_left = 10
	progress_style.corner_radius_top_right = 10
	progress_style.corner_radius_bottom_left = 10
	progress_style.corner_radius_bottom_right = 10
	progress_style.border_width_left = 2
	progress_style.border_width_right = 2
	progress_style.border_width_top = 2
	progress_style.border_width_bottom = 2
	progress_style.border_color = Color.GOLD
	progress_bar.add_theme_stylebox_override("background", progress_style)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color.GOLD
	fill_style.corner_radius_top_left = 8
	fill_style.corner_radius_top_right = 8
	fill_style.corner_radius_bottom_left = 8
	fill_style.corner_radius_bottom_right = 8
	progress_bar.add_theme_stylebox_override("fill", fill_style)
	
	# Texto de estado
	status_text.add_theme_font_size_override("font_size", 18)
	status_text.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	status_text.modulate = Color(1, 1, 1, 0)

func create_3d_objects():
	"""Crea objetos 3D impresionantes"""
	
	# Crear corona presidencial 3D
	var crown_mesh = SphereMesh.new()
	crown_mesh.radius = 1.5
	crown_mesh.height = 2.0
	crown_3d.mesh = crown_mesh
	
	# Material dorado brillante para la corona
	var crown_material = StandardMaterial3D.new()
	crown_material.albedo_color = Color.GOLD
	crown_material.metallic = 0.8
	crown_material.roughness = 0.2
	crown_material.emission_enabled = true
	crown_material.emission = Color(1, 0.8, 0.2, 1)
	crown_material.emission_energy = 0.5
	crown_3d.material_override = crown_material
	
	# Crear edificio de oficina
	var building_mesh = BoxMesh.new()
	building_mesh.size = Vector3(4, 6, 2)
	building_3d.mesh = building_mesh
	
	# Material del edificio
	var building_material = StandardMaterial3D.new()
	building_material.albedo_color = Color(0.3, 0.2, 0.15, 1)
	building_material.metallic = 0.3
	building_material.roughness = 0.7
	building_3d.material_override = building_material
	
	# Posición inicial de la cámara (muy lejos)
	camera_3d.position = Vector3(0, 10, 20)
	camera_3d.look_at(Vector3.ZERO, Vector3.UP)

func start_epic_sequence():
	"""Inicia la secuencia épica completa"""
	
	transition_tween = create_tween()
	transition_tween.set_parallel(true)
	
	# Fase 1: Aparición dramática del fondo
	transition_tween.tween_property(background, "modulate:a", 1.0, 1.0)
	
	# Fase 2: Aparición de la corona 3D con zoom cinematográfico
	transition_tween.tween_callback(start_3d_camera_sequence).set_delay(0.5)
	
	# Fase 3: Aparición del icono presidencial
	transition_tween.tween_property(president_icon, "modulate:a", 1.0, 0.8).set_delay(1.0)
	transition_tween.tween_property(president_icon, "scale", Vector2(1.2, 1.2), 0.4).set_delay(1.0)
	transition_tween.tween_property(president_icon, "scale", Vector2(1.0, 1.0), 0.4).set_delay(1.4)
	
	# Fase 4: Textos principales con efecto de escritura
	transition_tween.tween_callback(animate_text_appearance).set_delay(1.8)
	
	# Fase 5: Inicio de la barra de progreso
	transition_tween.tween_callback(start_loading_sequence).set_delay(2.5)
	
	# Fase 6: Rotación continua de elementos 3D
	start_continuous_3d_rotation()

func start_3d_camera_sequence():
	"""Secuencia cinematográfica de la cámara 3D"""
	
	camera_tween = create_tween()
	camera_tween.set_parallel(true)
	
	# Zoom dramático hacia la corona
	camera_tween.tween_property(camera_3d, "position", Vector3(0, 2, 8), 2.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	# Movimiento orbital alrededor de la corona
	camera_tween.tween_method(orbit_camera_around_crown, 0.0, 360.0, 4.0).set_delay(1.0)

func orbit_camera_around_crown(angle_degrees: float):
	"""Hace que la cámara orbite alrededor de la corona"""
	var angle_rad = deg_to_rad(angle_degrees)
	var radius = 8.0
	var height = 2.0
	
	var x = cos(angle_rad) * radius
	var z = sin(angle_rad) * radius
	
	camera_3d.position = Vector3(x, height, z)
	camera_3d.look_at(Vector3(0, 1, 0), Vector3.UP)

func start_continuous_3d_rotation():
	"""Rotación continua de objetos 3D"""
	
	rotation_tween = create_tween()
	rotation_tween.set_loops()
	
	# Rotación lenta y majestuosa de la corona
	rotation_tween.tween_method(rotate_crown, 0.0, 360.0, 3.0)

func rotate_crown(angle_degrees: float):
	"""Rota la corona presidencial"""
	crown_3d.rotation_degrees = Vector3(0, angle_degrees, 0)

func animate_text_appearance():
	"""Anima la aparición de los textos principales"""
	
	var text_tween = create_tween()
	text_tween.set_parallel(true)
	
	# Texto principal con efecto de máquina de escribir
	text_tween.tween_property(loading_text, "modulate:a", 1.0, 0.6)
	text_tween.tween_property(loading_text, "scale", Vector2(1.1, 1.1), 0.3)
	text_tween.tween_property(loading_text, "scale", Vector2(1.0, 1.0), 0.3).set_delay(0.3)
	
	# Subtexto con delay
	text_tween.tween_property(sub_text, "modulate:a", 1.0, 0.8).set_delay(0.4)
	
	# Texto de estado
	text_tween.tween_property(status_text, "modulate:a", 1.0, 0.6).set_delay(0.8)

func start_loading_sequence():
	"""Inicia la secuencia de carga con múltiples fases"""
	
	current_phase = 0
	progress_loading_phase()

func progress_loading_phase():
	"""Progresa a la siguiente fase de carga"""
	
	if current_phase >= loading_phases.size():
		finish_transition()
		return
	
	var phase = loading_phases[current_phase]
	
	# Actualizar texto de estado con efecto de parpadeo
	var status_tween = create_tween()
	status_tween.tween_property(status_text, "modulate:a", 0.3, 0.1)
	status_tween.tween_callback(func(): status_text.text = phase.text)
	status_tween.tween_property(status_text, "modulate:a", 1.0, 0.1)
	
	# Animar barra de progreso
	progress_tween = create_tween()
	progress_tween.tween_property(progress_bar, "value", phase.progress, 0.8).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	# Efectos especiales según la fase
	match current_phase:
		0:  # Verificando credenciales
			president_icon.text = "🔐"
		1:  # Encendiendo luces
			president_icon.text = "💡"
			flash_background_effect()
		2:  # Preparando sillón
			president_icon.text = "🪑"
		3:  # Sistema de seguridad
			president_icon.text = "🛡️"
		4:  # Documentos confidenciales
			president_icon.text = "📋"
		5:  # Puliendo trofeos
			president_icon.text = "🏆"
			intensify_particles()
		6:  # ¡Bienvenido!
			president_icon.text = "👑"
			final_fanfare_effect()
	
	# Programar siguiente fase
	current_phase += 1
	get_tree().create_timer(1.2).timeout.connect(progress_loading_phase)

func flash_background_effect():
	"""Efecto de flash de luz para simular luces encendiéndose"""
	var flash_tween = create_tween()
	flash_tween.tween_property(background, "color", Color(0.3, 0.2, 0.1, 1), 0.2)
	flash_tween.tween_property(background, "color", Color(0.15, 0.1, 0.05, 1), 0.3)

func intensify_particles():
	"""Intensifica las partículas doradas"""
	gold_particles.amount = 200
	gold_particles.initial_velocity_max = 100.0

func final_fanfare_effect():
	"""Efecto final épico antes de cambiar de escena"""
	var fanfare_tween = create_tween()
	fanfare_tween.set_parallel(true)
	
	# Zoom final del icono presidencial
	fanfare_tween.tween_property(president_icon, "scale", Vector2(1.5, 1.5), 0.5)
	fanfare_tween.tween_property(president_icon, "modulate", Color.WHITE, 0.5)
	
	# Partículas al máximo
	gold_particles.amount = 300
	gold_particles.initial_velocity_max = 150.0
	
	# Pulso de luz en el fondo
	fanfare_tween.tween_property(background, "color", Color(0.4, 0.3, 0.2, 1), 0.3)
	fanfare_tween.tween_property(background, "color", Color(0.15, 0.1, 0.05, 1), 0.7)
	
	# Efecto de respiración en todos los textos
	fanfare_tween.tween_property(loading_text, "scale", Vector2(1.1, 1.1), 0.4)
	fanfare_tween.tween_property(loading_text, "scale", Vector2(1.0, 1.0), 0.4).set_delay(0.4)

func finish_transition():
	"""Completa la transición y cambia a la oficina"""
	
	print("🏛️ YazawaOfficeTransition: Transición completada, accediendo a la oficina...")
	
	# Efecto de fade out final
	var final_tween = create_tween()
	final_tween.set_parallel(true)
	
	# Fade out de todos los elementos
	final_tween.tween_property(self, "modulate:a", 0.0, 1.0)
	
	# Cambiar a la oficina después del fade out
	final_tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/YazawaOfficeMenu.tscn")).set_delay(1.0)

func debug_check_nodes():
	"""Función de debug para verificar que todos los nodos existan"""
	print("🔍 Debug - Verificando nodos:")
	print("  President Icon: ", president_icon != null)
	print("  Loading Text: ", loading_text != null)
	print("  Sub Text: ", sub_text != null)
	print("  Progress Bar: ", progress_bar != null)
	print("  Status Text: ", status_text != null)
	print("  Background: ", background != null)
	print("  Gold Particles: ", gold_particles != null)
	print("  Viewport 3D: ", viewport_3d != null)
	print("  Camera 3D: ", camera_3d != null)
	print("  Crown 3D: ", crown_3d != null)
	print("  Building 3D: ", building_3d != null)
	print("  Audio Player: ", audio_player != null)
	
	if not president_icon or not loading_text or not progress_bar:
		print("❌ ERROR: Faltan nodos críticos para la transición")
		return false
	else:
		print("✅ Todos los nodos críticos están presentes")
		return true

func _input(event):
	"""Permite saltar la transición presionando cualquier tecla"""
	if event.is_pressed() and not event.is_echo():
		print("🏛️ YazawaOfficeTransition: Saltando transición...")
		finish_transition()
