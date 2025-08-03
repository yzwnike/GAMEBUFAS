extends Control

# Referencias a nodos
var viewport_3d
var camera_3d
var ui_container

# Grids de jugadores
var left_grid
var center_grid
var right_grid

# Controles de cámara
var camera_rotation_speed = 1.0
var camera_zoom_speed = 5.0
var is_camera_rotating = false
var camera_target_position = Vector3(0, 10, 15)
var camera_target_rotation = Vector3(-30, 0, 0)

# Estados de cámara
enum CameraMode {
	STATIC,
	ROTATING,
	FREE
}
var current_camera_mode = CameraMode.STATIC

# Manager de jugadores
var players_manager

func _ready():
	# Obtener referencias
	viewport_3d = $ViewportContainer/SubViewport
	camera_3d = $ViewportContainer/SubViewport/Camera3D
	ui_container = $UI
	
	# Grids
	left_grid = $UI/GridsContainer/LeftGrid/ScrollContainer/PlayersGrid
	center_grid = $UI/GridsContainer/CenterGrid/ScrollContainer/PlayersGrid
	right_grid = $UI/GridsContainer/RightGrid/ScrollContainer/PlayersGrid
	
	# Obtener manager de jugadores
	players_manager = get_node("/root/PlayersManager")
	if players_manager == null:
		print("ERROR: No se pudo encontrar PlayersManager")
		return
	
	# Conectar botones
	$UI/Footer/ButtonsContainer/BackButton.pressed.connect(_on_back_button_pressed)
	$UI/Footer/ButtonsContainer/ToggleCameraButton.pressed.connect(_on_toggle_camera_pressed)
	$UI/Footer/ButtonsContainer/ResetViewButton.pressed.connect(_on_reset_view_pressed)
	
	# Configurar escena 3D
	setup_3d_scene()
	
	# Cargar jugadores en los grids
	load_players_into_grids()
	
	# Iniciar rotación automática suave
	start_camera_rotation()

func setup_3d_scene():
	"""Configurar la escena 3D de fondo"""
	print("🏟️ Configurando escena 3D para vista de plantilla...")
	
	# Crear ambiente
	create_stadium_environment()
	
	# Configurar luces
	setup_lighting()
	
	# Partículas ambientales
	create_ambient_particles()

func create_stadium_environment():
	"""Crear el ambiente del estadio como fondo"""
	# Cargar estadio si existe
	var stadium_path = "res://otkritie-arena/source/1.fbx"
	if ResourceLoader.exists(stadium_path):
		var stadium_scene = load(stadium_path)
		var stadium_instance = stadium_scene.instantiate()
		stadium_instance.scale = Vector3(30, 30, 30)
		stadium_instance.position = Vector3(0, -5, 0)
		viewport_3d.add_child(stadium_instance)
		print("✅ Estadio cargado como fondo")
	else:
		# Crear campo básico
		create_basic_field()

func create_basic_field():
	"""Crear campo básico como respaldo"""
	var field = MeshInstance3D.new()
	var field_mesh = BoxMesh.new()
	field_mesh.size = Vector3(50, 0.1, 30)
	field.mesh = field_mesh
	field.position = Vector3(0, 0, 0)
	
	var field_material = StandardMaterial3D.new()
	field_material.albedo_color = Color(0.2, 0.8, 0.2, 1)
	field_material.emission_enabled = true
	field_material.emission = Color(0.1, 0.2, 0.1, 1)
	field.material_override = field_material
	viewport_3d.add_child(field)

func setup_lighting():
	"""Configurar iluminación del estadio"""
	# Luces del estadio en círculo
	for i in range(8):
		var angle = i * PI * 2 / 8
		var light = OmniLight3D.new()
		light.position = Vector3(cos(angle) * 25, 15, sin(angle) * 25)
		light.light_color = Color(1, 1, 0.95, 1)
		light.light_energy = 5.0
		light.omni_range = 40
		viewport_3d.add_child(light)

func create_ambient_particles():
	"""Crear partículas ambientales sutiles"""
	var particles = GPUParticles3D.new()
	particles.amount = 200
	particles.emitting = true
	particles.lifetime = 10.0
	
	var material = ParticleProcessMaterial.new()
	material.gravity = Vector3(0, -0.2, 0)
	material.scale_min = 0.1
	material.scale_max = 0.3
	material.color = Color(1, 1, 0.8, 0.5)
	material.direction = Vector3(0, 1, 0)
	material.initial_velocity_min = 0.5
	material.initial_velocity_max = 1.5
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	
	particles.process_material = material
	particles.position = Vector3(0, 8, 0)
	viewport_3d.add_child(particles)

func load_players_into_grids():
	"""Cargar jugadores en los grids según su posición"""
	var all_players = players_manager.get_all_players()
	
	# Limpiar grids
	clear_grid(left_grid)
	clear_grid(center_grid)
	clear_grid(right_grid)
	
	# Clasificar jugadores por posición
	for player_data in all_players:
		var position = player_data.position.to_upper()
		var player_card = create_player_card(player_data)
		
		if position in ["DELANTERO", "EXTREMO", "MEDIAPUNTA"]:
			left_grid.add_child(player_card)
		elif position in ["CENTROCAMPISTA", "MEDIOCENTRO", "LATERAL"]:
			center_grid.add_child(player_card)
		elif position in ["DEFENSA", "CENTRAL", "PORTERO"]:
			right_grid.add_child(player_card)
		else:
			# Por defecto al centro
			center_grid.add_child(player_card)

func clear_grid(grid_container):
	"""Limpiar un contenedor grid"""
	for child in grid_container.get_children():
		child.queue_free()

func create_player_card(player_data: Dictionary) -> Control:
	"""Crear una tarjeta de jugador para el grid"""
	var card = Panel.new()
	card.custom_minimum_size = Vector2(180, 120)
	
	# Estilo de la tarjeta
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.3, 0.4, 0.9)
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.6, 0.8, 1.0, 1)
	card.add_theme_stylebox_override("panel", style_box)
	
	# Contenedor vertical
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	card.add_child(vbox)
	
	# Nombre del jugador
	var name_label = Label.new()
	name_label.text = player_data.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(name_label)
	
	# Posición
	var position_label = Label.new()
	position_label.text = player_data.position
	position_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	position_label.add_theme_font_size_override("font_size", 12)
	position_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	vbox.add_child(position_label)
	
	# Overall
	var ovr_label = Label.new()
	ovr_label.text = "OVR: " + str(player_data.overall)
	ovr_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ovr_label.add_theme_font_size_override("font_size", 14)
	ovr_label.add_theme_color_override("font_color", Color.YELLOW)
	vbox.add_child(ovr_label)
	
	# Estadísticas básicas
	var stats_container = HBoxContainer.new()
	stats_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(stats_container)
	
	var stats = ["ATK: " + str(player_data.attack), "DEF: " + str(player_data.defense), "VEL: " + str(player_data.speed)]
	for stat in stats:
		var stat_label = Label.new()
		stat_label.text = stat
		stat_label.add_theme_font_size_override("font_size", 10)
		stat_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
		stats_container.add_child(stat_label)
	
	# Hacer la tarjeta clickeable
	var button = Button.new()
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.flat = true
	button.pressed.connect(_on_player_card_clicked.bind(player_data))
	card.add_child(button)
	
	return card

func start_camera_rotation():
	"""Iniciar rotación automática de la cámara"""
	current_camera_mode = CameraMode.ROTATING
	var rotation_tween = create_tween()
	rotation_tween.set_loops()
	rotation_tween.tween_method(rotate_camera_around_center, 0.0, 360.0, 30.0)

func rotate_camera_around_center(angle_degrees: float):
	"""Rotar la cámara alrededor del centro"""
	if current_camera_mode != CameraMode.ROTATING:
		return
	
	var angle_rad = deg_to_rad(angle_degrees)
	var radius = 15.0
	var height = 10.0
	
	var new_position = Vector3(
		cos(angle_rad) * radius,
		height,
		sin(angle_rad) * radius
	)
	
	camera_3d.position = new_position
	camera_3d.look_at(Vector3.ZERO, Vector3.UP)

func _input(event):
	"""Manejar input para control manual de cámara"""
	if current_camera_mode == CameraMode.FREE:
		if event is InputEventMouseMotion and Input.is_action_pressed("ui_select"):
			# Rotar cámara con mouse
			var sensitivity = 0.005
			var yaw = -event.relative.x * sensitivity
			var pitch = -event.relative.y * sensitivity
			
			camera_3d.rotate_y(yaw)
			camera_3d.rotate_object_local(Vector3(1, 0, 0), pitch)
		
		elif event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				# Zoom in
				var forward = -camera_3d.global_transform.basis.z
				camera_3d.global_position += forward * camera_zoom_speed
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				# Zoom out
				var forward = -camera_3d.global_transform.basis.z
				camera_3d.global_position -= forward * camera_zoom_speed

func _on_toggle_camera_pressed():
	"""Alternar entre modos de cámara"""
	match current_camera_mode:
		CameraMode.STATIC:
			current_camera_mode = CameraMode.ROTATING
			start_camera_rotation()
			$UI/Footer/ButtonsContainer/ToggleCameraButton.text = "Cámara Libre"
		CameraMode.ROTATING:
			current_camera_mode = CameraMode.FREE
			$UI/Footer/ButtonsContainer/ToggleCameraButton.text = "Cámara Estática"
		CameraMode.FREE:
			current_camera_mode = CameraMode.STATIC
			_on_reset_view_pressed()
			$UI/Footer/ButtonsContainer/ToggleCameraButton.text = "Alternar Cámara"

func _on_reset_view_pressed():
	"""Resetear vista de cámara a la posición inicial"""
	current_camera_mode = CameraMode.STATIC
	
	var reset_tween = create_tween()
	reset_tween.parallel().tween_property(camera_3d, "position", Vector3(0, 10, 15), 1.0)
	reset_tween.parallel().tween_property(camera_3d, "rotation_degrees", Vector3(-30, 0, 0), 1.0)
	
	$UI/Footer/ButtonsContainer/ToggleCameraButton.text = "Alternar Cámara"

func _on_back_button_pressed():
	"""Volver al menú anterior"""
	# Aquí puedes implementar la navegación hacia atrás
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_player_card_clicked(player_data: Dictionary):
	"""Manejar click en tarjeta de jugador"""
	print("🎮 Jugador seleccionado: ", player_data.name)
	
	# Crear popup con información detallada del jugador
	var popup = AcceptDialog.new()
	popup.title = "Información del Jugador"
	popup.size = Vector2i(400, 300)
	
	var vbox = VBoxContainer.new()
	popup.add_child(vbox)
	
	# Información detallada
	var info_lines = [
		"Nombre: " + player_data.name,
		"Posición: " + player_data.position,
		"Overall: " + str(player_data.overall),
		"Ataque: " + str(player_data.attack),
		"Defensa: " + str(player_data.defense),
		"Velocidad: " + str(player_data.speed),
		"Resistencia: " + str(player_data.stamina),
		"Habilidad: " + str(player_data.skill)
	]
	
	for line in info_lines:
		var label = Label.new()
		label.text = line
		label.add_theme_font_size_override("font_size", 14)
		vbox.add_child(label)
	
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(popup.queue_free)
