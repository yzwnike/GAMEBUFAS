extends Control

# Referencias a nodos
var viewport_3d
var camera_3d
var field_overlay
var players_container
var formation_selector
var position_filter
var search_box

# Elementos 3D del campo
var field_3d_instance
var player_positions_3d = {}
var formation_positions = {}

# Controles de cámara
enum CameraMode {
	STATIC,
	ROTATING,
	FREE,
	TOP_VIEW
}
var current_camera_mode = CameraMode.STATIC

# Formaciones disponibles
var formations = {
	"4-3-3": {
		"positions": [
			{"name": "Portero", "pos": Vector3(0, 0.1, -20), "position": "PORTERO"},
			{"name": "Defensa Central Izq.", "pos": Vector3(-3, 0.1, -15), "position": "DEFENSA"},
			{"name": "Defensa Central Der.", "pos": Vector3(3, 0.1, -15), "position": "DEFENSA"},
			{"name": "Lateral Izquierdo", "pos": Vector3(-8, 0.1, -12), "position": "LATERAL"},
			{"name": "Lateral Derecho", "pos": Vector3(8, 0.1, -12), "position": "LATERAL"},
			{"name": "Mediocentro Izq.", "pos": Vector3(-4, 0.1, -5), "position": "MEDIOCENTRO"},
			{"name": "Mediocentro Der.", "pos": Vector3(4, 0.1, -5), "position": "MEDIOCENTRO"},
			{"name": "Mediocentro", "pos": Vector3(0, 0.1, -8), "position": "MEDIOCENTRO"},
			{"name": "Extremo Izquierdo", "pos": Vector3(-8, 0.1, 5), "position": "EXTREMO"},
			{"name": "Extremo Derecho", "pos": Vector3(8, 0.1, 5), "position": "EXTREMO"},
			{"name": "Delantero Centro", "pos": Vector3(0, 0.1, 15), "position": "DELANTERO"}
		]
	},
	"4-4-2": {
		"positions": [
			{"name": "Portero", "pos": Vector3(0, 0.1, -20), "position": "PORTERO"},
			{"name": "Defensa Central Izq.", "pos": Vector3(-3, 0.1, -15), "position": "DEFENSA"},
			{"name": "Defensa Central Der.", "pos": Vector3(3, 0.1, -15), "position": "DEFENSA"},
			{"name": "Lateral Izquierdo", "pos": Vector3(-8, 0.1, -12), "position": "LATERAL"},
			{"name": "Lateral Derecho", "pos": Vector3(8, 0.1, -12), "position": "LATERAL"},
			{"name": "Centrocampista Izq.", "pos": Vector3(-6, 0.1, -3), "position": "CENTROCAMPISTA"},
			{"name": "Centrocampista Der.", "pos": Vector3(6, 0.1, -3), "position": "CENTROCAMPISTA"},
			{"name": "Mediocentro Izq.", "pos": Vector3(-3, 0.1, -5), "position": "MEDIOCENTRO"},
			{"name": "Mediocentro Der.", "pos": Vector3(3, 0.1, -5), "position": "MEDIOCENTRO"},
			{"name": "Delantero Izq.", "pos": Vector3(-4, 0.1, 12), "position": "DELANTERO"},
			{"name": "Delantero Der.", "pos": Vector3(4, 0.1, 12), "position": "DELANTERO"}
		]
	}
}

# Alineación actual
var current_lineup = {}
var selected_position = null

# Manager
var players_manager

func _ready():
	# Obtener referencias
	viewport_3d = $ViewportContainer/SubViewport
	camera_3d = $ViewportContainer/SubViewport/Camera3D
	field_overlay = $UI/MainContainer/FieldContainer/Field3D/FieldOverlay
	players_container = $UI/MainContainer/PlayersPanel/ScrollContainer/PlayersContainer
	formation_selector = $UI/TopPanel/FormationSelector
	position_filter = $UI/MainContainer/PlayersPanel/FilterContainer/PositionFilter
	search_box = $UI/MainContainer/PlayersPanel/FilterContainer/SearchBox
	
	# Obtener manager
	players_manager = get_node("/root/PlayersManager")
	if players_manager == null:
		print("ERROR: No se pudo encontrar PlayersManager")
		return
	
	# Conectar señales
	setup_connections()
	
	# Configurar escena 3D
	setup_3d_scene()
	
	# Configurar formaciones
	setup_formations()
	
	# Cargar jugadores
	load_available_players()
	
	# Aplicar formación inicial
	apply_formation("4-3-3")

func setup_connections():
	"""Conectar todas las señales"""
	$UI/TopPanel/BackButton.pressed.connect(_on_back_button_pressed)
	$UI/TopPanel/SaveButton.pressed.connect(_on_save_button_pressed)
	formation_selector.item_selected.connect(_on_formation_selected)
	position_filter.item_selected.connect(_on_position_filter_changed)
	search_box.text_changed.connect(_on_search_text_changed)
	
	# Controles de cámara
	$UI/Footer/CameraControls/CameraButtons/ToggleCameraButton.pressed.connect(_on_toggle_camera_pressed)
	$UI/Footer/CameraControls/CameraButtons/ResetViewButton.pressed.connect(_on_reset_view_pressed)
	$UI/Footer/CameraControls/CameraButtons/TopViewButton.pressed.connect(_on_top_view_pressed)

func setup_3d_scene():
	"""Configurar la escena 3D del campo"""
	print("🏟️ Configurando campo 3D...")
	
	# Crear campo de fútbol 3D
	create_3d_field()
	
	# Configurar iluminación
	setup_field_lighting()
	
	# Crear ambiente
	create_field_environment()

func create_3d_field():
	"""Crear el campo de fútbol 3D"""
	# Campo principal
	var field = MeshInstance3D.new()
	var field_mesh = BoxMesh.new()
	field_mesh.size = Vector3(50, 0.2, 80)
	field.mesh = field_mesh
	field.position = Vector3(0, 0, 0)
	
	var field_material = StandardMaterial3D.new()
	field_material.albedo_color = Color(0.2, 0.8, 0.2, 1)
	field_material.emission_enabled = true
	field_material.emission = Color(0.1, 0.2, 0.1, 1)
	field.material_override = field_material
	viewport_3d.add_child(field)
	
	# Líneas del campo
	create_field_lines()
	
	# Porterías
	create_goals()

func create_field_lines():
	"""Crear las líneas del campo"""
	var line_material = StandardMaterial3D.new()
	line_material.albedo_color = Color.WHITE
	line_material.emission_enabled = true
	line_material.emission = Color(0.8, 0.8, 0.8, 1)
	
	# Línea central
	var center_line = MeshInstance3D.new()
	var center_mesh = BoxMesh.new()
	center_mesh.size = Vector3(50, 0.25, 0.3)
	center_line.mesh = center_mesh
	center_line.position = Vector3(0, 0.1, 0)
	center_line.material_override = line_material
	viewport_3d.add_child(center_line)
	
	# Círculo central
	var center_circle = MeshInstance3D.new()
	var circle_mesh = SphereMesh.new()
	circle_mesh.radius = 5
	circle_mesh.height = 0.25
	center_circle.mesh = circle_mesh
	center_circle.position = Vector3(0, 0.1, 0)
	center_circle.material_override = line_material
	viewport_3d.add_child(center_circle)
	
	# Áreas de penalti
	for z_pos in [-30, 30]:
		var penalty_area = MeshInstance3D.new()
		var penalty_mesh = BoxMesh.new()
		penalty_mesh.size = Vector3(20, 0.25, 15)
		penalty_area.mesh = penalty_mesh
		penalty_area.position = Vector3(0, 0.1, z_pos)
		
		var penalty_material = StandardMaterial3D.new()
		penalty_material.albedo_color = Color(0.3, 0.9, 0.3, 0.7)
		penalty_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		penalty_area.material_override = penalty_material
		viewport_3d.add_child(penalty_area)

func create_goals():
	"""Crear las porterías"""
	var goal_material = StandardMaterial3D.new()
	goal_material.albedo_color = Color.WHITE
	goal_material.metallic = 0.8
	goal_material.roughness = 0.2
	
	for z_pos in [-40, 40]:
		# Poste izquierdo
		var left_post = MeshInstance3D.new()
		var post_mesh = CylinderMesh.new()
		post_mesh.top_radius = 0.15
		post_mesh.bottom_radius = 0.15
		post_mesh.height = 3
		left_post.mesh = post_mesh
		left_post.position = Vector3(-3.5, 1.5, z_pos)
		left_post.material_override = goal_material
		viewport_3d.add_child(left_post)
		
		# Poste derecho
		var right_post = MeshInstance3D.new()
		right_post.mesh = post_mesh
		right_post.position = Vector3(3.5, 1.5, z_pos)
		right_post.material_override = goal_material
		viewport_3d.add_child(right_post)
		
		# Travesaño
		var crossbar = MeshInstance3D.new()
		var crossbar_mesh = CylinderMesh.new()
		crossbar_mesh.top_radius = 0.15
		crossbar_mesh.bottom_radius = 0.15
		crossbar_mesh.height = 7
		crossbar.mesh = crossbar_mesh
		crossbar.position = Vector3(0, 3, z_pos)
		crossbar.rotation_degrees = Vector3(0, 0, 90)
		crossbar.material_override = goal_material
		viewport_3d.add_child(crossbar)

func setup_field_lighting():
	"""Configurar la iluminación del campo"""
	# Luces del estadio
	for i in range(4):
		var angle = i * PI / 2
		var light = OmniLight3D.new()
		light.position = Vector3(cos(angle) * 30, 20, sin(angle) * 50)
		light.light_color = Color(1, 1, 0.95, 1)
		light.light_energy = 8.0
		light.omni_range = 60
		viewport_3d.add_child(light)

func create_field_environment():
	"""Crear el ambiente alrededor del campo"""
	# Gradería simple
	for i in range(2):
		var z_pos = -60 if i == 0 else 60
		var stand = MeshInstance3D.new()
		var stand_mesh = BoxMesh.new()
		stand_mesh.size = Vector3(60, 8, 10)
		stand.mesh = stand_mesh
		stand.position = Vector3(0, 4, z_pos)
		
		var stand_material = StandardMaterial3D.new()
		stand_material.albedo_color = Color(0.6, 0.6, 0.7, 1)
		stand.material_override = stand_material
		viewport_3d.add_child(stand)

func setup_formations():
	"""Configurar el selector de formaciones"""
	formation_selector.clear()
	for formation_name in formations.keys():
		formation_selector.add_item(formation_name)

func apply_formation(formation_name: String):
	"""Aplicar una formación específica"""
	if not formations.has(formation_name):
		return
	
	# Limpiar posiciones anteriores
	clear_field_positions()
	
	# Obtener posiciones de la formación
	var formation_data = formations[formation_name]
	formation_positions = {}
	
	# Crear marcadores de posición en el campo 3D
	for i in range(formation_data.positions.size()):
		var pos_data = formation_data.positions[i]
		create_position_marker(pos_data, i)

func create_position_marker(pos_data: Dictionary, index: int):
	"""Crear un marcador de posición en el campo 3D"""
	# Marcador 3D
	var marker = MeshInstance3D.new()
	var marker_mesh = CylinderMesh.new()
	marker_mesh.top_radius = 1.0
	marker_mesh.bottom_radius = 1.0
	marker_mesh.height = 0.3
	marker.mesh = marker_mesh
	marker.position = pos_data.pos
	
	# Material del marcador
	var marker_material = StandardMaterial3D.new()
	marker_material.albedo_color = Color(0.8, 0.3, 0.3, 0.8)
	marker_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	marker_material.emission_enabled = true
	marker_material.emission = Color(0.4, 0.1, 0.1, 1)
	marker.material_override = marker_material
	viewport_3d.add_child(marker)
	
	# Añadir área clickeable (usando Area3D)
	var area = Area3D.new()
	var collision_shape = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.height = 2.0
	shape.top_radius = 1.5
	shape.bottom_radius = 1.5
	collision_shape.shape = shape
	area.add_child(collision_shape)
	area.position = pos_data.pos
	area.input_event.connect(_on_position_clicked.bind(index))
	viewport_3d.add_child(area)
	
	# Guardar referencias
	formation_positions[index] = {
		"data": pos_data,
		"marker": marker,
		"area": area,
		"assigned_player": null
	}
	
	# Etiqueta de posición superpuesta en 2D
	create_position_label(pos_data, index)

func create_position_label(pos_data: Dictionary, index: int):
	"""Crear etiqueta 2D superpuesta para la posición"""
	var label = Label.new()
	label.text = pos_data.name
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Convertir posición 3D a 2D de la pantalla
	var screen_pos = camera_3d.unproject_position(pos_data.pos)
	label.position = screen_pos - Vector2(50, 10)
	label.size = Vector2(100, 20)
	
	field_overlay.add_child(label)

func clear_field_positions():
	"""Limpiar todas las posiciones del campo"""
	for pos_index in formation_positions.keys():
		var pos_info = formation_positions[pos_index]
		if pos_info.marker:
			pos_info.marker.queue_free()
		if pos_info.area:
			pos_info.area.queue_free()
	formation_positions.clear()
	
	# Limpiar etiquetas superpuestas
	for child in field_overlay.get_children():
		child.queue_free()

func load_available_players():
	"""Cargar jugadores disponibles en el panel lateral"""
	var all_players = players_manager.get_all_players()
	
	# Limpiar contenedor
	for child in players_container.get_children():
		child.queue_free()
	
	# Configurar filtro de posiciones
	setup_position_filter()
	
	# Crear tarjetas de jugadores
	for player_data in all_players:
		create_player_card(player_data)

func setup_position_filter():
	"""Configurar filtro de posiciones"""
	position_filter.clear()
	position_filter.add_item("Todas las posiciones")
	
	var positions = ["PORTERO", "DEFENSA", "LATERAL", "MEDIOCENTRO", "CENTROCAMPISTA", "EXTREMO", "DELANTERO"]
	for position in positions:
		position_filter.add_item(position)

func create_player_card(player_data: Dictionary):
	"""Crear tarjeta de jugador arrastrable"""
	var card = Panel.new()
	card.custom_minimum_size = Vector2(380, 80)
	
	# Estilo
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.3, 0.4, 0.9)
	style_box.corner_radius_top_left = 5
	style_box.corner_radius_top_right = 5
	style_box.corner_radius_bottom_left = 5
	style_box.corner_radius_bottom_right = 5
	card.add_theme_stylebox_override("panel", style_box)
	
	# Contenedor horizontal
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 10)
	card.add_child(hbox)
	
	# Información del jugador
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	var name_label = Label.new()
	name_label.text = player_data.name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	info_vbox.add_child(name_label)
	
	var position_label = Label.new()
	position_label.text = player_data.position + " - OVR: " + str(player_data.overall)
	position_label.add_theme_font_size_override("font_size", 12)
	position_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	info_vbox.add_child(position_label)
	
	# Botón para asignar
	var assign_button = Button.new()
	assign_button.text = "Asignar"
	assign_button.custom_minimum_size = Vector2(80, 0)
	assign_button.pressed.connect(_on_assign_player_clicked.bind(player_data))
	hbox.add_child(assign_button)
	
	players_container.add_child(card)

func _on_position_clicked(camera, event, position, normal, shape_idx, position_index):
	"""Manejar click en posición del campo"""
	if event is InputEventMouseButton and event.pressed:
		selected_position = position_index
		print("🎯 Posición seleccionada: ", formation_positions[position_index].data.name)
		
		# Resaltar posición seleccionada
		highlight_selected_position(position_index)

func highlight_selected_position(position_index: int):
	"""Resaltar la posición seleccionada"""
	# Resetear todos los marcadores
	for pos_index in formation_positions.keys():
		var marker = formation_positions[pos_index].marker
		var material = marker.material_override as StandardMaterial3D
		material.albedo_color = Color(0.8, 0.3, 0.3, 0.8)
	
	# Resaltar posición seleccionada
	if formation_positions.has(position_index):
		var marker = formation_positions[position_index].marker
		var material = marker.material_override as StandardMaterial3D
		material.albedo_color = Color(0.3, 0.8, 0.3, 0.9)

func _on_assign_player_clicked(player_data: Dictionary):
	"""Asignar jugador a la posición seleccionada"""
	if selected_position == null:
		# Crear popup para seleccionar posición
		show_position_selection_popup(player_data)
		return
	
	assign_player_to_position(player_data, selected_position)

func show_position_selection_popup(player_data: Dictionary):
	"""Mostrar popup para seleccionar posición"""
	var popup = AcceptDialog.new()
	popup.title = "Seleccionar Posición"
	popup.size = Vector2i(300, 400)
	
	var vbox = VBoxContainer.new()
	popup.add_child(vbox)
	
	var label = Label.new()
	label.text = "Selecciona una posición para " + player_data.name
	vbox.add_child(label)
	
	for pos_index in formation_positions.keys():
		var pos_data = formation_positions[pos_index].data
		var button = Button.new()
		button.text = pos_data.name
		button.pressed.connect(assign_player_to_position.bind(player_data, pos_index))
		button.pressed.connect(popup.queue_free)
		vbox.add_child(button)
	
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(popup.queue_free)

func assign_player_to_position(player_data: Dictionary, position_index: int):
	"""Asignar jugador a una posición específica"""
	if not formation_positions.has(position_index):
		return
	
	# Asignar jugador
	formation_positions[position_index].assigned_player = player_data
	current_lineup[position_index] = player_data
	
	# Actualizar marcador visual
	var marker = formation_positions[position_index].marker
	var material = marker.material_override as StandardMaterial3D
	material.albedo_color = Color(0.3, 0.3, 0.8, 0.9)
	
	# Crear etiqueta con nombre del jugador
	update_position_label(position_index)
	
	print("✅ Jugador asignado: ", player_data.name, " → ", formation_positions[position_index].data.name)
	selected_position = null

func update_position_label(position_index: int):
	"""Actualizar etiqueta de posición con nombre del jugador"""
	var pos_data = formation_positions[position_index].data
	var player_data = formation_positions[position_index].assigned_player
	
	# Buscar y actualizar etiqueta existente
	for child in field_overlay.get_children():
		if child is Label:
			var screen_pos = camera_3d.unproject_position(pos_data.pos)
			if abs(child.position.x - (screen_pos.x - 50)) < 10:
				if player_data:
					child.text = player_data.name
					child.add_theme_color_override("font_color", Color.CYAN)
				else:
					child.text = pos_data.name
					child.add_theme_color_override("font_color", Color.WHITE)
				break

# Métodos de cámara
func _on_toggle_camera_pressed():
	"""Alternar rotación de cámara"""
	match current_camera_mode:
		CameraMode.STATIC:
			current_camera_mode = CameraMode.ROTATING
			start_camera_rotation()
			$UI/Footer/CameraControls/CameraButtons/ToggleCameraButton.text = "Parar Rotación"
		CameraMode.ROTATING:
			current_camera_mode = CameraMode.STATIC
			$UI/Footer/CameraControls/CameraButtons/ToggleCameraButton.text = "Rotar Cámara"

func start_camera_rotation():
	"""Iniciar rotación de cámara"""
	var rotation_tween = create_tween()
	rotation_tween.set_loops()
	rotation_tween.tween_method(rotate_camera_around_field, 0.0, 360.0, 20.0)

func rotate_camera_around_field(angle_degrees: float):
	"""Rotar cámara alrededor del campo"""
	if current_camera_mode != CameraMode.ROTATING:
		return
	
	var angle_rad = deg_to_rad(angle_degrees)
	var radius = 25.0
	var height = 15.0
	
	camera_3d.position = Vector3(cos(angle_rad) * radius, height, sin(angle_rad) * radius)
	camera_3d.look_at(Vector3.ZERO, Vector3.UP)
	
	# Actualizar etiquetas superpuestas
	update_overlay_labels()

func update_overlay_labels():
	"""Actualizar posiciones de etiquetas superpuestas"""
	for pos_index in formation_positions.keys():
		var pos_data = formation_positions[pos_index].data
		var screen_pos = camera_3d.unproject_position(pos_data.pos)
		
		# Buscar etiqueta correspondiente
		for child in field_overlay.get_children():
			if child is Label and abs(child.position.x - (screen_pos.x - 50)) < 100:
				child.position = screen_pos - Vector2(50, 10)

func _on_reset_view_pressed():
	"""Resetear vista de cámara"""
	current_camera_mode = CameraMode.STATIC
	var reset_tween = create_tween()
	reset_tween.parallel().tween_property(camera_3d, "position", Vector3(0, 15, 25), 1.0)
	reset_tween.parallel().tween_property(camera_3d, "rotation_degrees", Vector3(-30, 0, 0), 1.0)
	$UI/Footer/CameraControls/CameraButtons/ToggleCameraButton.text = "Rotar Cámara"

func _on_top_view_pressed():
	"""Vista cenital del campo"""
	current_camera_mode = CameraMode.TOP_VIEW
	var top_tween = create_tween()
	top_tween.parallel().tween_property(camera_3d, "position", Vector3(0, 50, 0), 1.0)
	top_tween.parallel().tween_property(camera_3d, "rotation_degrees", Vector3(-90, 0, 0), 1.0)

# Otros métodos
func _on_formation_selected(index: int):
	"""Cambiar formación"""
	var formation_name = formation_selector.get_item_text(index)
	apply_formation(formation_name)

func _on_position_filter_changed(index: int):
	"""Filtrar jugadores por posición"""
	# Implementar filtrado
	pass

func _on_search_text_changed(new_text: String):
	"""Buscar jugadores por nombre"""
	# Implementar búsqueda
	pass

func _on_save_button_pressed():
	"""Guardar alineación"""
	print("💾 Guardando alineación...")
	# Implementar guardado
	
func _on_back_button_pressed():
	"""Volver atrás"""
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
