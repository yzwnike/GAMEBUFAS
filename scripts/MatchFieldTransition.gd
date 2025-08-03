extends Control

# Referencias para la transición épica del estadio
var transition_overlay: ColorRect
var description_text: Label
var subtitle_text: Label
var camera_3d: Camera3D
var viewport_container: SubViewportContainer
var viewport_3d: SubViewport

# Variables para datos del partido
var current_jornada: int = 1
var rival_team: String = "EQUIPO RIVAL"
var match_data: Dictionary = {}

func _ready():
	print("🏟️ MatchFieldTransition: Iniciando transición épica hacia el ESTADIO...")
	# Cargar datos del partido si existen
	load_match_data()
	create_stadium_transition()

# Función para configurar los datos del partido desde otras escenas
func set_match_data(jornada: int, rival: String, additional_data: Dictionary = {}):
	"""Configura los datos del partido para mostrar en la transición"""
	current_jornada = jornada
	rival_team = rival
	match_data = additional_data
	print("📊 Datos del partido configurados: Jornada ", jornada, " vs ", rival)

func load_match_data():
	"""Cargar datos del partido desde LeagueManager (igual que PreMatchMenu)"""
	# Verificar que LeagueManager esté disponible
	if not has_node("/root/LeagueManager"):
		print("ERROR MatchFieldTransition: LeagueManager no encontrado, usando datos por defecto")
		current_jornada = 1
		rival_team = "EQUIPO RIVAL"
		return
	
	# Obtener el siguiente partido (igual que en PreMatchMenu)
	var match = LeagueManager.get_next_match()
	if match == null:
		print("WARNING MatchFieldTransition: No hay partido siguiente disponible")
		current_jornada = 1
		rival_team = "EQUIPO RIVAL"
		return
	
	# Establecer jornada
	current_jornada = match.match_day
	
	# Determinar quién es el rival de FC Bufas (igual que en PreMatchMenu)
	var opponent_id = ""
	if match.home_team == "fc_bufas":
		opponent_id = match.away_team
	else:
		opponent_id = match.home_team
	
	# Obtener nombre del equipo rival
	var opponent_team = LeagueManager.get_team_by_id(opponent_id)
	if opponent_team:
		rival_team = opponent_team.name
		print("📊 MatchFieldTransition: Datos cargados - Jornada ", current_jornada, " vs ", rival_team)
	else:
		print("WARNING MatchFieldTransition: Equipo oponente no encontrado: ", opponent_id)
		rival_team = "EQUIPO RIVAL"

func create_stadium_transition():
	print("🚁 Creando transición de dron hacia el ESTADIO ÉPICO...")
	
	# Crear overlay principal
	transition_overlay = $TrainingFieldOverlay
	transition_overlay.modulate.a = 0.0  # Empezar transparente
	transition_overlay.color = Color(0.1, 0.2, 0.4, 1.0)  # Azul noche de estadio
	
	# Crear viewport 3D para efectos
	create_3d_stadium_effect()
	
	# Texto descriptivo
	description_text = $TrainingFieldOverlay/DescriptionText
	description_text.modulate = Color(1, 1, 1, 0)  # Empezar transparente
	description_text.text = "BIENVENIDOS AL ESTADIO BUFAS"

	# Subtítulo
	subtitle_text = $TrainingFieldOverlay/SubtitleText
	subtitle_text.modulate = Color(1, 1, 1, 0)  # Empezar transparente
	subtitle_text.text = "INICIANDO PARTIDO: JORNADA " + str(current_jornada) + ", " + rival_team

	# Iniciar la secuencia de animación
	start_stadium_animation_sequence()

func create_3d_stadium_effect():
	print("🏟️ Creando ESTADIO ÉPICO 3D tipo Santiago Bernabéu...")
	
	# Verificar y crear estructura de nodos 3D si no existe
	viewport_container = get_node_or_null("TrainingFieldOverlay/ViewportContainer")
	if not viewport_container:
		print("ERROR: ViewportContainer no encontrado")
		return
	
	viewport_3d = viewport_container.get_child(0) if viewport_container.get_child_count() > 0 else null
	if not viewport_3d:
		print("ERROR: SubViewport no encontrado, creando uno nuevo...")
		viewport_3d = SubViewport.new()
		viewport_3d.size = Vector2i(1920, 1080)
		viewport_3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		viewport_container.add_child(viewport_3d)
	
	camera_3d = viewport_3d.get_child(0) if viewport_3d.get_child_count() > 0 else null
	if not camera_3d:
		print("ERROR: Camera3D no encontrada, creando una nueva...")
		camera_3d = Camera3D.new()
		viewport_3d.add_child(camera_3d)
	
	camera_3d.position = Vector3(0, 120, 180)  # Vista de dron muy alta
	camera_3d.look_at(Vector3(0, 0, 0), Vector3.UP)
	
	# Crear el estadio completo
	create_epic_stadium_environment()
	
	# Crear sistema de iluminación nocturna
	create_stadium_lighting_system()
	
	# Crear efectos de partículas y atmósfera
	create_stadium_atmosphere_effects()

func create_epic_stadium_environment():
	"""Cargar el estadio Otkritie Arena para la transición"""
	print("🌟 Cargando Otkritie Arena...")
	
	# CARGAR MODELO DEL ESTADIO OTKRITIE ARENA
	var stadium_path = "res://otkritie-arena/source/1.fbx"
	if ResourceLoader.exists(stadium_path):
		var stadium_scene = load(stadium_path)
		var stadium_instance = stadium_scene.instantiate()
		# Escalar y posicionar el estadio - AUMENTAR MUCHO LA ESCALA
		stadium_instance.scale = Vector3(100, 100, 100)  # Escalar 100 veces más grande
		stadium_instance.position = Vector3(0, -10, 0)  # Bajar un poco para que se vea bien
		viewport_3d.add_child(stadium_instance)
		
		# PRIMERO: Inspeccionar estructura del modelo
		print_stadium_structure(stadium_instance)
		
		# APLICAR TEXTURAS AL ESTADIO
		apply_stadium_textures(stadium_instance)
		
		print("✅ Estadio Otkritie Arena cargado exitosamente con escala x100 y texturas aplicadas")
	else:
		print("⚠️ No se pudo cargar el estadio, utilizando representación de respaldo...")
		create_professional_football_field()

func create_professional_football_field():
	"""Crear campo de fútbol profesional de 105x68 metros"""
	print("⚽ Creando campo profesional de fútbol...")
	
	# Campo principal (105x68 metros - medidas FIFA)
	var field_mesh = MeshInstance3D.new()
	var field_box = BoxMesh.new()
	field_box.size = Vector3(105, 0.5, 68)  # Campo profesional
	field_mesh.mesh = field_box
	field_mesh.position = Vector3(0, -0.25, 0)
	
	var field_material = StandardMaterial3D.new()
	field_material.albedo_color = Color(0.1, 0.8, 0.15, 1)  # Verde césped natural
	field_material.roughness = 0.4
	field_material.metallic = 0.0
	field_material.emission_enabled = false  # Sin emisión en ambiente diurno
	field_mesh.material_override = field_material
	viewport_3d.add_child(field_mesh)
	
	# Crear líneas del campo profesional
	create_professional_field_lines()
	
	# Crear porterías profesionales
	create_professional_goalposts()

func create_professional_field_lines():
	"""Crear todas las líneas de un campo profesional"""
	var line_material = StandardMaterial3D.new()
	line_material.albedo_color = Color.WHITE
	line_material.emission_enabled = false  # Sin emisión en día
	
	# Línea central
	var center_line = MeshInstance3D.new()
	var center_box = BoxMesh.new()
	center_box.size = Vector3(105, 0.1, 0.12)
	center_line.mesh = center_box
	center_line.position = Vector3(0, 0.3, 0)
	center_line.material_override = line_material
	viewport_3d.add_child(center_line)
	
	# Círculo central
	var center_circle = MeshInstance3D.new()
	var circle_torus = TorusMesh.new()
	circle_torus.inner_radius = 9.15  # Medidas FIFA
	circle_torus.outer_radius = 9.27
	circle_torus.rings = 64
	center_circle.mesh = circle_torus
	center_circle.position = Vector3(0, 0.3, 0)
	center_circle.material_override = line_material
	viewport_3d.add_child(center_circle)
	
	# Líneas laterales y de fondo
	for side_x in [-52.5, 52.5]:  # 105m / 2
		var sideline = MeshInstance3D.new()
		var sideline_box = BoxMesh.new()
		sideline_box.size = Vector3(0.12, 0.1, 68)
		sideline.mesh = sideline_box
		sideline.position = Vector3(side_x, 0.3, 0)
		sideline.material_override = line_material
		viewport_3d.add_child(sideline)
	
	for side_z in [-34, 34]:  # 68m / 2
		var goalline = MeshInstance3D.new()
		var goalline_box = BoxMesh.new()
		goalline_box.size = Vector3(105, 0.1, 0.12)
		goalline.mesh = goalline_box
		goalline.position = Vector3(0, 0.3, side_z)
		goalline.material_override = line_material
		viewport_3d.add_child(goalline)
	
	# Áreas de penalty y otras marcas FIFA
	create_fifa_penalty_areas(line_material)

func create_fifa_penalty_areas(line_material):
	"""Crear áreas de penalty según estándares FIFA"""
	for side_z in [-34, 34]:
		var penalty_direction = 1 if side_z > 0 else -1
		
		# Área grande (40.3m x 16.5m)
		var big_area_front = MeshInstance3D.new()
		var big_area_box = BoxMesh.new()
		big_area_box.size = Vector3(40.3, 0.1, 0.12)
		big_area_front.mesh = big_area_box
		big_area_front.position = Vector3(0, 0.3, side_z - (penalty_direction * 16.5))
		big_area_front.material_override = line_material
		viewport_3d.add_child(big_area_front)
		
		# Líneas laterales del área grande
		for area_side in [-20.15, 20.15]:
			var big_area_side = MeshInstance3D.new()
			var big_area_side_box = BoxMesh.new()
			big_area_side_box.size = Vector3(0.12, 0.1, 16.5)
			big_area_side.mesh = big_area_side_box
			big_area_side.position = Vector3(area_side, 0.3, side_z - (penalty_direction * 8.25))
			big_area_side.material_override = line_material
			viewport_3d.add_child(big_area_side)
		
		# Área pequeña (18.3m x 5.5m)
		var small_area_front = MeshInstance3D.new()
		var small_area_box = BoxMesh.new()
		small_area_box.size = Vector3(18.3, 0.1, 0.12)
		small_area_front.mesh = small_area_box
		small_area_front.position = Vector3(0, 0.3, side_z - (penalty_direction * 5.5))
		small_area_front.material_override = line_material
		viewport_3d.add_child(small_area_front)
		
		# Líneas laterales del área pequeña
		for small_side in [-9.15, 9.15]:
			var small_area_side = MeshInstance3D.new()
			var small_area_side_box = BoxMesh.new()
			small_area_side_box.size = Vector3(0.12, 0.1, 5.5)
			small_area_side.mesh = small_area_side_box
			small_area_side.position = Vector3(small_side, 0.3, side_z - (penalty_direction * 2.75))
			small_area_side.material_override = line_material
			viewport_3d.add_child(small_area_side)

func create_professional_goalposts():
	"""Crear porterías profesionales (7.32m x 2.44m)"""
	var goalpost_material = StandardMaterial3D.new()
	goalpost_material.albedo_color = Color.WHITE
	goalpost_material.emission_enabled = true
	goalpost_material.emission = Color(1, 1, 1, 1)
	goalpost_material.emission_energy = 0.4
	goalpost_material.metallic = 0.2
	goalpost_material.roughness = 0.3
	
	for goal_z in [-34, 34]:
		# Postes verticales
		for post_x in [-3.66, 3.66]:  # 7.32m / 2
			var goalpost = MeshInstance3D.new()
			var post_cylinder = CylinderMesh.new()
			post_cylinder.height = 2.44
			post_cylinder.top_radius = 0.06
			post_cylinder.bottom_radius = 0.06
			goalpost.mesh = post_cylinder
			goalpost.position = Vector3(post_x, 1.22, goal_z)
			goalpost.material_override = goalpost_material
			viewport_3d.add_child(goalpost)
		
		# Travesaño horizontal
		var crossbar = MeshInstance3D.new()
		var crossbar_cylinder = CylinderMesh.new()
		crossbar_cylinder.height = 7.32
		crossbar_cylinder.top_radius = 0.06
		crossbar_cylinder.bottom_radius = 0.06
		crossbar.mesh = crossbar_cylinder
		crossbar.position = Vector3(0, 2.44, goal_z)
		crossbar.rotation_degrees = Vector3(0, 0, 90)
		crossbar.material_override = goalpost_material
		viewport_3d.add_child(crossbar)
		
		# Red de la portería
		create_goal_net(goal_z)

func create_goal_net(goal_z):
	"""Crear red de la portería"""
	var net_material = StandardMaterial3D.new()
	net_material.albedo_color = Color(0.95, 0.95, 0.95, 0.4)
	net_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	# Red trasera
	var net_back = MeshInstance3D.new()
	var net_back_quad = QuadMesh.new()
	net_back_quad.size = Vector2(7.32, 2.44)
	net_back.mesh = net_back_quad
	net_back.position = Vector3(0, 1.22, goal_z - (0.5 if goal_z > 0 else -0.5))
	net_back.material_override = net_material
	viewport_3d.add_child(net_back)
	
	# Redes laterales
	for net_side_x in [-3.66, 3.66]:
		var net_side = MeshInstance3D.new()
		var net_side_quad = QuadMesh.new()
		net_side_quad.size = Vector2(2, 2.44)
		net_side.mesh = net_side_quad
		net_side.position = Vector3(net_side_x, 1.22, goal_z - (1 if goal_z > 0 else -1))
		net_side.rotation_degrees = Vector3(0, 90, 0)
		net_side.material_override = net_material
		viewport_3d.add_child(net_side)

func create_massive_stadium_stands():
	"""Crear gradas gigantescas de 4 niveles tipo Santiago Bernabéu"""
	print("🏟️ Construyendo gradas gigantescas de 4 niveles...")
	
	var stand_material = StandardMaterial3D.new()
	stand_material.albedo_color = Color(0.85, 0.85, 0.9, 1)  # Gris claro moderno
	stand_material.metallic = 0.1
	stand_material.roughness = 0.8
	
	# Crear 4 gradas (Norte, Sur, Este, Oeste)
	var stand_positions = [
		{"pos": Vector3(0, 0, -60), "size": Vector3(140, 60, 20), "name": "Norte"},
		{"pos": Vector3(0, 0, 60), "size": Vector3(140, 60, 20), "name": "Sur"},
		{"pos": Vector3(-75, 0, 0), "size": Vector3(20, 55, 100), "name": "Oeste"},
		{"pos": Vector3(75, 0, 0), "size": Vector3(20, 55, 100), "name": "Este"}
	]
	
	for stand_data in stand_positions:
		create_multi_level_stand(stand_data.pos, stand_data.size, stand_data.name, stand_material)

func create_multi_level_stand(base_pos: Vector3, base_size: Vector3, stand_name: String, material):
	"""Crear grada de múltiples niveles"""
	print("🏟️ Construyendo grada ", stand_name, "...")
	
	# Crear 4 niveles de gradas
	for level in range(4):
		var level_height = 12 + (level * 15)  # Cada nivel más alto
		var level_depth = base_size.z - (level * 2)  # Cada nivel más estrecho
		var level_width = base_size.x - (level * 5)  # Cada nivel más estrecho lateralmente
		
		# Estructura principal del nivel
		var level_structure = MeshInstance3D.new()
		var structure_box = BoxMesh.new()
		structure_box.size = Vector3(level_width, 12, level_depth)
		level_structure.mesh = structure_box
		level_structure.position = base_pos + Vector3(0, level_height, 0)
		level_structure.material_override = material
		viewport_3d.add_child(level_structure)
		
		# Crear asientos en escalones
		create_stadium_seating(base_pos + Vector3(0, level_height + 6, 0), level_width, level_depth, level)

func create_stadium_seating(base_pos: Vector3, width: float, depth: float, level: int):
	"""Crear asientos en las gradas"""
	var seat_colors = [
		Color(0.2, 0.4, 0.8, 1),  # Azul - Nivel 1
		Color(0.8, 0.2, 0.2, 1),  # Rojo - Nivel 2  
		Color(0.2, 0.8, 0.2, 1),  # Verde - Nivel 3
		Color(0.8, 0.8, 0.2, 1)   # Amarillo - Nivel 4 (VIP)
	]
	
	var seat_material = StandardMaterial3D.new()
	seat_material.albedo_color = seat_colors[level]
	seat_material.emission_enabled = true
	seat_material.emission = seat_colors[level] * 0.2
	seat_material.emission_energy = 0.3
	
	# Crear filas de asientos
	var rows = 8
	for row in range(rows):
		var seat_row = MeshInstance3D.new()
		var row_box = BoxMesh.new()
		row_box.size = Vector3(width * 0.9, 0.4, 1.2)
		seat_row.mesh = row_box
		seat_row.position = base_pos + Vector3(0, -2 + (row * 0.8), -depth/2 + (row * 1.5))
		seat_row.material_override = seat_material
		viewport_3d.add_child(seat_row)

func create_stadium_roof_structure():
	"""Crear techo y estructura exterior moderna"""
	print("🏯 Construyendo techo y estructura moderna...")
	
	var roof_material = StandardMaterial3D.new()
	roof_material.albedo_color = Color(0.9, 0.9, 0.9, 0.8)
	roof_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	roof_material.metallic = 0.7
	roof_material.roughness = 0.2
	
	# Techo principal curvado
	var main_roof = MeshInstance3D.new()
	var roof_sphere = SphereMesh.new()
	roof_sphere.radius = 90
	roof_sphere.height = 40
	main_roof.mesh = roof_sphere
	main_roof.position = Vector3(0, 85, 0)
	main_roof.scale = Vector3(1.8, 0.4, 1.2)  # Aplanar y estirar
	main_roof.material_override = roof_material
	viewport_3d.add_child(main_roof)
	
	# Estructura de soporte
	create_support_pillars()

func create_support_pillars():
	"""Crear pilares de soporte del estadio"""
	var pillar_material = StandardMaterial3D.new()
	pillar_material.albedo_color = Color(0.6, 0.6, 0.7, 1)
	pillar_material.metallic = 0.8
	pillar_material.roughness = 0.3
	
	var pillar_positions = [
		Vector3(-80, 0, -65), Vector3(80, 0, -65),
		Vector3(-80, 0, 65), Vector3(80, 0, 65),
		Vector3(-90, 0, 0), Vector3(90, 0, 0)
	]
	
	for pos in pillar_positions:
		var pillar = MeshInstance3D.new()
		var pillar_cylinder = CylinderMesh.new()
		pillar_cylinder.height = 90
		pillar_cylinder.top_radius = 1.5
		pillar_cylinder.bottom_radius = 2.5
		pillar.mesh = pillar_cylinder
		pillar.position = pos + Vector3(0, 45, 0)
		pillar.material_override = pillar_material
		viewport_3d.add_child(pillar)

func create_stadium_facilities():
	"""Crear túneles, áreas VIP y otras instalaciones"""
	print("🏢 Construyendo instalaciones del estadio...")
	
	# Túfel de jugadores
	create_player_tunnel()
	
	# Palcos VIP
	create_vip_boxes()
	
	# Zona técnica
	create_technical_area()

func create_player_tunnel():
	"""Crear túfel de entrada de jugadores"""
	var tunnel_material = StandardMaterial3D.new()
	tunnel_material.albedo_color = Color(0.3, 0.3, 0.4, 1)
	tunnel_material.metallic = 0.1
	
	var tunnel = MeshInstance3D.new()
	var tunnel_box = BoxMesh.new()
	tunnel_box.size = Vector3(8, 4, 15)
	tunnel.mesh = tunnel_box
	tunnel.position = Vector3(0, 2, -42)
	tunnel.material_override = tunnel_material
	viewport_3d.add_child(tunnel)

func create_vip_boxes():
	"""Crear palcos VIP"""
	var vip_material = StandardMaterial3D.new()
	vip_material.albedo_color = Color(0.8, 0.7, 0.2, 1)  # Dorado
	vip_material.metallic = 0.9
	vip_material.roughness = 0.1
	vip_material.emission_enabled = true
	vip_material.emission = Color(0.8, 0.7, 0.2, 1) * 0.3
	vip_material.emission_energy = 0.5
	
	# Palcos en ambos lados
	for side_x in [-60, 60]:
		for box_z in [-20, 0, 20]:
			var vip_box = MeshInstance3D.new()
			var box_mesh = BoxMesh.new()
			box_mesh.size = Vector3(8, 4, 12)
			vip_box.mesh = box_mesh
			vip_box.position = Vector3(side_x, 25, box_z)
			vip_box.material_override = vip_material
			viewport_3d.add_child(vip_box)

func create_technical_area():
	"""Crear zona técnica y banquillos"""
	var bench_material = StandardMaterial3D.new()
	bench_material.albedo_color = Color(0.4, 0.4, 0.4, 1)
	
	# Banquillos de ambos equipos
	for side_z in [-25, 25]:
		var bench = MeshInstance3D.new()
		var bench_box = BoxMesh.new()
		bench_box.size = Vector3(15, 1, 3)
		bench.mesh = bench_box
		bench.position = Vector3(-40, 0.5, side_z)
		bench.material_override = bench_material
		viewport_3d.add_child(bench)

func create_modern_stadium_elements():
	"""Crear pantallas gigantes y elementos modernos"""
	print("📺 Instalando pantallas gigantes y tecnología...")
	
	# Pantallas gigantes en las esquinas
	create_giant_screens()
	
	# Sistema de megafonía
	create_sound_system()

func create_giant_screens():
	"""Crear pantallas gigantes en las esquinas del estadio"""
	var screen_material = StandardMaterial3D.new()
	screen_material.albedo_color = Color(0.1, 0.1, 0.2, 1)
	screen_material.emission_enabled = true
	screen_material.emission = Color(0.2, 0.4, 0.8, 1)
	screen_material.emission_energy = 2.0
	
	var screen_positions = [
		Vector3(-60, 40, -45), Vector3(60, 40, -45),
		Vector3(-60, 40, 45), Vector3(60, 40, 45)
	]
	
	for pos in screen_positions:
		var screen = MeshInstance3D.new()
		var screen_quad = QuadMesh.new()
		screen_quad.size = Vector2(20, 12)
		screen.mesh = screen_quad
		screen.position = pos
		screen.material_override = screen_material
		viewport_3d.add_child(screen)

func create_sound_system():
	"""Crear sistema de megafonía"""
	var speaker_material = StandardMaterial3D.new()
	speaker_material.albedo_color = Color(0.2, 0.2, 0.2, 1)
	speaker_material.metallic = 0.8
	
	# Altavoces en el techo
	for x in range(-3, 4):
		for z in range(-2, 3):
			var speaker = MeshInstance3D.new()
			var speaker_cylinder = CylinderMesh.new()
			speaker_cylinder.height = 2
			speaker_cylinder.top_radius = 0.8
			speaker_cylinder.bottom_radius = 0.8
			speaker.mesh = speaker_cylinder
			speaker.position = Vector3(x * 20, 70, z * 15)
			speaker.material_override = speaker_material
			viewport_3d.add_child(speaker)

func create_stadium_lighting_system():
	"""Crear sistema de iluminación diurna con cielo azul"""
	print("☀️ Configurando iluminación diurna y paisaje natural...")
	
	# Crear Environment diurno
	var environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	
	# Cielo azul diurno
	var sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.4, 0.7, 1.0, 1)  # Azul cielo brillante
	sky_material.sky_horizon_color = Color(0.7, 0.85, 1.0, 1)  # Azul claro horizonte
	sky_material.ground_bottom_color = Color(0.3, 0.6, 0.3, 1)  # Verde césped
	sky_material.ground_horizon_color = Color(0.5, 0.8, 0.5, 1)  # Verde claro
	sky_material.sun_angle_max = 60.0  # Sol alto (mediodía)
	sky_material.sun_curve = 0.3  # Suavizar transición del sol
	sky.sky_material = sky_material
	environment.sky = sky
	
	# Iluminación ambiental natural
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.8  # Luz ambiental natural
	
	# Sol como luz direccional principal
	var sun_light = DirectionalLight3D.new()
	sun_light.position = Vector3(30, 100, 40)  # Posición del sol
	sun_light.look_at(Vector3(0, 0, 0), Vector3.UP)
	sun_light.light_color = Color(1.0, 0.95, 0.8, 1)  # Luz solar cálida
	sun_light.light_energy = 1.2  # Energía solar natural
	sun_light.shadow_enabled = true  # Sombras realistas
	viewport_3d.add_child(sun_light)
	
	camera_3d.environment = environment
	
	# Crear paisaje natural alrededor del estadio
	create_natural_landscape()

func create_natural_landscape():
	"""Crear paisaje natural con árboles alrededor del estadio"""
	print("🌳 Generando paisaje natural...")
	
	# Añadir algunos árboles alrededor del estadio (lejos para que no molesten)
	for i in range(8):
		var tree = MeshInstance3D.new()
		var tree_mesh = CylinderMesh.new()
		tree_mesh.height = 12
		tree_mesh.top_radius = 0.8
		tree_mesh.bottom_radius = 1.5
		tree.mesh = tree_mesh
		# Colocar árboles lejos del estadio
		tree.position = Vector3(randf_range(-150, 150), 6, randf_range(-150, 150))
		
		# Tronco marrón
		var trunk_material = StandardMaterial3D.new()
		trunk_material.albedo_color = Color(0.4, 0.2, 0.1, 1)  # Marrón
		tree.material_override = trunk_material
		
		var leaves = MeshInstance3D.new()
		var leaves_mesh = SphereMesh.new()
		leaves_mesh.radius = 4
		leaves.mesh = leaves_mesh
		leaves.position = Vector3(0, 8, 0)
		leaves.material_override = StandardMaterial3D.new()
		leaves.material_override.albedo_color = Color(0.2, 0.7, 0.2, 1)  # Verde hojas
		tree.add_child(leaves)
		viewport_3d.add_child(tree)
	
	# QUITAR EL CÉSPED PROBLEMÁTICO - Solo ambiente diurno natural

func create_field_perimeter_lights():
	"""Crear iluminación perimetral del campo"""
	# Luces perimetrales alrededor del campo
	for x in range(-10, 11):
		for z_side in [-1, 1]:
			var perimeter_light = SpotLight3D.new()
			perimeter_light.position = Vector3(x * 10, 5, z_side * 40)
			perimeter_light.look_at(Vector3(0, 0, 0), Vector3.UP)
			perimeter_light.light_color = Color(0.9, 1, 0.9, 1)
			perimeter_light.light_energy = 2.0
			perimeter_light.spot_range = 50
			perimeter_light.spot_angle = 45
			viewport_3d.add_child(perimeter_light)

func create_stadium_atmosphere_effects():
	"""Crear efectos de atmósfera y partículas"""
	print("✨ Creando efectos atmosféricos del estadio...")
	
	# Partículas de humo y ambiente
	create_stadium_smoke_effects()
	
	# Efectos de luces de colores
	create_stadium_color_effects()

func create_stadium_smoke_effects():
	"""Crear efectos de humo y neblina"""
	var smoke_particles = GPUParticles3D.new()
	smoke_particles.position = Vector3(0, 10, 0)
	smoke_particles.amount = 1000
	smoke_particles.lifetime = 5.0
	smoke_particles.emitting = true
	
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.initial_velocity_min = 0.5
	process_material.initial_velocity_max = 2.0
	process_material.gravity = Vector3(0, -0.2, 0)
	process_material.scale_min = 0.5
	process_material.scale_max = 2.0
	process_material.color = Color(0.8, 0.8, 0.9, 0.3)
	smoke_particles.process_material = process_material
	
	viewport_3d.add_child(smoke_particles)

func create_stadium_color_effects():
	"""Crear efectos atmosféricos diurnos"""
	# En ambiente diurno no necesitamos luces de colores artificiales
	print("☀️ Ambiente diurno - sin luces artificiales de colores")

func start_stadium_animation_sequence():
	"""Secuencia de animación épica cinematográfica del estadio para PARTIDO"""
	print("🎬 Iniciando secuencia cinematográfica para PARTIDO...")
	
	# CONFIGURACIÓN INICIAL: Cámara más cerca del campo
	camera_3d.position = Vector3(0, 60, 80)  # Más cerca que antes
	camera_3d.look_at(Vector3(0, 0, 0), Vector3.UP)
	camera_3d.fov = 65  # Campo de visión moderado
	
	print("🎬 SECUENCIA CINEMATOGRÁFICA DE PARTIDO (8 segundos):")
	print("   • FASE 1 (0-2s): Mostrar overlay y textos")
	print("   • FASE 2 (2-5s): ROTACIÓN orbital alrededor del campo")
	print("   • FASE 3 (5-7s): ENTRADA desde arriba hacia el centro")
	print("   • FASE 4 (7-8s): FADE OUT y transición al diálogo")
	
	# INICIAR FASE 1: Mostrar textos
	start_phase_1_show_texts()

func start_phase_1_show_texts():
	"""FASE 1: Mostrar overlay y textos (0-2s)"""
	print("🎬 FASE 1: Mostrando overlay y textos...")
	
	var phase1_tween = create_tween()
	
	# Mostrar overlay gradualmente
	phase1_tween.tween_property(transition_overlay, "modulate:a", 0.8, 0.5)
	
	# Mostrar texto principal
	phase1_tween.tween_property(description_text, "modulate:a", 1.0, 0.8).set_delay(0.3)
	
	# Mostrar subtítulo
	phase1_tween.tween_property(subtitle_text, "modulate:a", 1.0, 0.8).set_delay(0.8)
	
	# CONTINUAR A FASE 2
	phase1_tween.tween_callback(start_phase_2_rotation).set_delay(2.0)

func start_phase_2_rotation():
	"""FASE 2: ROTACIÓN orbital alrededor del campo (2-5s)"""
	print("🎬 FASE 2: Iniciando rotación orbital alrededor del campo...")
	
	var phase2_tween = create_tween()
	
	# Calcular posición inicial y final para rotación
	var rotation_radius = 100.0
	var rotation_height = 60.0
	var start_angle = 0.0
	var end_angle = PI * 1.5  # 270 grados de rotación
	
	# Animar rotación usando tween_method
	phase2_tween.tween_method(update_camera_orbital_position, start_angle, end_angle, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# CONTINUAR A FASE 3
	phase2_tween.tween_callback(start_phase_3_dive).set_delay(3.0)

func update_camera_orbital_position(angle: float):
	"""Actualizar posición de cámara en órbita"""
	var rotation_radius = 100.0
	var rotation_height = 60.0
	
	var new_x = cos(angle) * rotation_radius
	var new_z = sin(angle) * rotation_radius + 80  # Offset hacia atrás
	
	camera_3d.position = Vector3(new_x, rotation_height, new_z)
	camera_3d.look_at(Vector3(0, 0, 0), Vector3.UP)

func start_phase_3_dive():
	"""FASE 3: ENTRADA desde arriba hacia el centro (5-7s)"""
	print("🎬 FASE 3: Entrada dramática desde arriba...")
	
	var phase3_tween = create_tween()
	
	# Mover cámara hacia arriba primero
	var high_position = Vector3(0, 120, 60)
	var final_position = Vector3(0, 8, 15)  # Cerca del centro del campo
	
	# Subir rápidamente
	phase3_tween.tween_property(camera_3d, "position", high_position, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Descender dramáticamente hacia el centro
	phase3_tween.tween_property(camera_3d, "position", final_position, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	# Ajustar el ángulo para vista más dramática
	phase3_tween.parallel().tween_method(update_camera_angle, Vector3(0, 0, 0), Vector3(-10, 0, 0), 2.0)
	
	# CONTINUAR A FASE 4
	phase3_tween.tween_callback(start_phase_4_fade).set_delay(2.0)

func start_phase_4_fade():
	"""FASE 4: FADE OUT y transición al diálogo (7-8s)"""
	print("🎬 FASE 4: Fade out y transición al diálogo...")
	
	var phase4_tween = create_tween()
	
	# Fade out gradual de todos los elementos
	phase4_tween.tween_property(description_text, "modulate:a", 0.0, 0.5)
	phase4_tween.parallel().tween_property(subtitle_text, "modulate:a", 0.0, 0.5)
	
	# Fade out del overlay
	phase4_tween.tween_property(transition_overlay, "modulate:a", 0.0, 0.8).set_delay(0.3)
	
	# TRANSICIÓN FINAL
	phase4_tween.tween_callback(transition_to_match_scene).set_delay(1.0)

func update_camera_angle(angle: Vector3):
	"""Actualiza gradualmente el ángulo de la cámara"""
	if camera_3d:
		camera_3d.rotation_degrees = angle

func transition_to_match_scene():
	"""Transición final hacia el partido"""
	print("⚽ Transicionando al partido en el ESTADIO ÉPICO...")
	transition_overlay.visible = false  # Ocultar overlay para evitar superposición
	get_tree().change_scene_to_file("res://stadium_scene.tscn")

func apply_stadium_textures(stadium_node: Node3D):
	"""Aplicar texturas personalizadas al modelo del estadio con orden correcto de surface material override"""
	print("🎨 Aplicando texturas al estadio Otkritie Arena con orden correcto...")
	
	# Cargar las texturas en el orden correcto para surface material override (0-5)
	var texture_order = [
		load("res://otkritie-arena/textures/arena_u1_v1.jpeg"),  # Surface 0
		load("res://otkritie-arena/textures/arena_u2_v1.jpeg"),  # Surface 1
		load("res://otkritie-arena/textures/arena_u3_v1.jpeg"),  # Surface 2
		load("res://otkritie-arena/textures/arena_u1_v2.jpeg"),  # Surface 3
		load("res://otkritie-arena/textures/arena_u2_v2.jpeg"),  # Surface 4
		load("res://otkritie-arena/textures/arena_u3_v2.jpeg")   # Surface 5
	]
	
	print("📋 Orden de texturas configurado:")
	print("   Surface 0: arena_u1_v1.jpeg")
	print("   Surface 1: arena_u2_v1.jpeg")
	print("   Surface 2: arena_u3_v1.jpeg")
	print("   Surface 3: arena_u1_v2.jpeg")
	print("   Surface 4: arena_u2_v2.jpeg")
	print("   Surface 5: arena_u3_v2.jpeg")
	
	# Aplicar texturas con el orden correcto
	_apply_textures_with_surface_override(stadium_node, texture_order)

func _apply_textures_with_surface_override(node: Node3D, texture_order: Array):
	"""Aplicar texturas usando el orden correcto en las superficies"""
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		if mesh_instance.mesh != null:
			var surface_count = mesh_instance.mesh.get_surface_count()
			print("🎨 Aplicando texturas a ", mesh_instance.name, " con ", surface_count, " superficies")
			for i in range(min(texture_order.size(), surface_count)):
				if texture_order[i] != null:
					var material = StandardMaterial3D.new()
					material.albedo_texture = texture_order[i]
					material.albedo_color = Color(1, 1, 1, 1)  # Color base blanco
					material.roughness = 0.7
					material.metallic = 0.1
					mesh_instance.set_surface_override_material(i, material)
					print("   Surface ", i, ": ", texture_order[i].resource_path)

	# Recurre a los hijos
	for child in node.get_children():
		_apply_textures_with_surface_override(child, texture_order)

func _apply_textures_recursive(node: Node, textures: Dictionary):
	"""Aplicar texturas recursivamente a todos los MeshInstance3D"""
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		var node_name = mesh_instance.name.to_lower()
		
		# RESPETAR TEXTURAS ORIGINALES - No sobrescribir si ya tiene material
		if mesh_instance.material_override != null:
			print("✅ Respetando textura original de: ", mesh_instance.name)
			return  # NO sobrescribir texturas existentes
		
		# Solo aplicar material si NO tiene uno
		var material = StandardMaterial3D.new()
		
		# Lógica inteligente para aplicar texturas
		if is_field_surface(node_name):
			# CAMPO DE FÚtBOL - Verde césped
			material.albedo_color = Color(0.15, 0.7, 0.2, 1)  # Verde césped natural
			material.roughness = 0.8
			material.metallic = 0.0
			print("🌱 Material de césped aplicado a: ", mesh_instance.name)
		elif is_stadium_structure(node_name):
			# ESTRUCTURAS DEL ESTADIO - USAR SIEMPRE arena_u1_v1.jpeg
			if textures.has("arena_u1_v1"):
				material.albedo_texture = textures["arena_u1_v1"]
				material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)  # BLANCO PURO - sin tinte
				material.roughness = 0.5
				material.metallic = 0.0  # Sin metalálico
				material.emission_enabled = false  # Sin emisión
				material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
				print("🏟️ Textura arena_u1_v1 aplicada a: ", mesh_instance.name)
			else:
				# Fallback si no se encuentra la textura
				material.albedo_color = Color(0.8, 0.8, 0.85, 1)  # Gris claro
				material.roughness = 0.7
				material.metallic = 0.1
				print("⚠️ No se encontró arena_u1_v1, usando color por defecto para: ", mesh_instance.name)
		else:
			# OTROS ELEMENTOS - USAR SIEMPRE arena_u1_v1.jpeg TAMBIÉN
			if textures.has("arena_u1_v1"):
				material.albedo_texture = textures["arena_u1_v1"]
				material.albedo_color = Color(1, 1, 1, 1)
				material.roughness = 0.7
				material.metallic = 0.1
				print("🎨 Textura arena_u1_v1 aplicada a OTROS: ", mesh_instance.name)
			else:
				# Fallback si no se encuentra la textura
				material.albedo_color = Color(0.7, 0.7, 0.7, 1)  # Gris
				material.roughness = 0.7
				material.metallic = 0.1
				print("⚠️ No se encontró arena_u1_v1 para OTROS: ", mesh_instance.name)
		
		# Aplicar el material
		mesh_instance.material_override = material
	
	# Continuar con los nodos hijos
	for child in node.get_children():
		_apply_textures_recursive(child, textures)

func is_field_surface(node_name: String) -> bool:
	"""Determinar si un nodo es superficie de campo de fútbol"""
	var field_keywords = ["field", "grass", "ground", "pitch", "cesped", "campo", "superficie"]
	for keyword in field_keywords:
		if keyword in node_name:
			return true
	return false

func is_stadium_structure(node_name: String) -> bool:
	"""Determinar si un nodo es estructura del estadio"""
	var structure_keywords = ["stand", "seat", "tribune", "roof", "wall", "structure", "building", "grada", "asiento", "techo", "pared"]
	for keyword in structure_keywords:
		if keyword in node_name:
			return true
	return false

func print_stadium_structure(node: Node, depth: int = 0):
	"""Imprimir la estructura completa del modelo del estadio para debug"""
	var indent = ""
	for i in range(depth):
		indent += "  "
	
	var node_info = str(node.name) + " (" + str(node.get_class()) + ")"
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		node_info += " - MESH"
		
		# Información detallada de materiales
		var mesh = mesh_instance.mesh
		if mesh:
			for surface_idx in range(mesh.get_surface_count()):
				var material = mesh_instance.get_surface_override_material(surface_idx)
				if not material:
					material = mesh.surface_get_material(surface_idx)
				
				if material:
					print("🎨 MATERIAL ", surface_idx, ": ", material.resource_name if material.resource_name != "" else "Sin nombre")
					if material is StandardMaterial3D:
						var std_mat = material as StandardMaterial3D
						if std_mat.albedo_texture:
							print("   📄 TEXTURA: ", std_mat.albedo_texture.resource_path)
						else:
							print("   🎨 COLOR: ", std_mat.albedo_color)
	
	print("🔍 ESTRUCTURA: ", indent, node_info)
	
	# Recurrir a los hijos
	for child in node.get_children():
		print_stadium_structure(child, depth + 1)

