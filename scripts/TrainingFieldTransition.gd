extends Control

# Referencias para la transición épica del campo de entrenamiento
var transition_overlay: ColorRect
var description_text: Label
var subtitle_text: Label
var camera_3d: Camera3D
var viewport_container: SubViewportContainer
var viewport_3d: SubViewport

func _ready():
	print("🏟️ TrainingFieldTransition: Iniciando transición épica hacia el campo de entrenamiento...")
	create_training_field_transition()

func create_training_field_transition():
	print("🚁 Creando transición de dron hacia el campo de entrenamiento...")
	
	# Crear overlay principal
	transition_overlay = ColorRect.new()
	transition_overlay.name = "TrainingFieldOverlay"
	transition_overlay.color = Color(0.3, 0.5, 0.2, 1.0)  # Verde césped
	transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_overlay.z_index = 1000
	transition_overlay.modulate.a = 0.0  # Empezar transparente
	self.add_child(transition_overlay)
	
	# Crear viewport 3D para efectos
	create_3d_training_field_effect()
	
	# Crear texto descriptivo
	description_text = Label.new()
	description_text.text = "PREPARÁNDOTE PARA EL ENTRENAMIENTO"
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
	
	# Crear subtítulo
	subtitle_text = Label.new()
	subtitle_text.text = "Visualizando estrategias y tácticas..."
	subtitle_text.add_theme_font_size_override("font_size", 24)
	subtitle_text.add_theme_color_override("font_color", Color(1, 0.8, 0.4, 1))
	subtitle_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle_text.position = Vector2(0, screen_size.y * 0.78)
	subtitle_text.size = Vector2(screen_size.x, 30)
	subtitle_text.modulate = Color(1, 1, 1, 0)  # Empezar transparente
	transition_overlay.add_child(subtitle_text)

	# Iniciar la secuencia de animación
	start_training_animation_sequence()

func create_3d_training_field_effect():
	print("⚽ Creando escena 3D para el campo de entrenamiento...")
	
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
	camera_3d.position = Vector3(0, 20, 20)  # Vista de dron
	camera_3d.look_at(Vector3(0, 0, 0), Vector3.UP)
	viewport_3d.add_child(camera_3d)

	# Crear entorno de entrenamiento 3D
	create_training_environment_3d()

	# Añadir sistema de partículas
	create_dust_particles_3d()

func create_training_environment_3d():
	print("🌿 Creando entorno del campo de entrenamiento...")

	# Crear el suelo del campo (césped verde vibrante) - MÁS GRANDE
	var field_mesh = MeshInstance3D.new()
	var field_box = BoxMesh.new()
	field_box.size = Vector3(60, 0.5, 100)  # Campo más amplio (60x100 metros)
	field_mesh.mesh = field_box
	field_mesh.position = Vector3(0, -0.25, 0)
	
	var field_material = StandardMaterial3D.new()
	field_material.albedo_color = Color(0.1, 0.8, 0.15, 1)  # Verde césped muy vibrante
	field_material.roughness = 0.6
	field_material.metallic = 0.0
	field_material.emission_enabled = true
	field_material.emission = Color(0.05, 0.3, 0.05, 1)  # Ligero brillo verde
	field_material.emission_energy = 0.2
	field_mesh.material_override = field_material
	viewport_3d.add_child(field_mesh)
	
	# Crear terreno circundante más amplio
	create_surrounding_terrain()
	
	# Crear vallas alrededor del campo
	create_field_fences()
	
	# Crear paisaje con árboles
	create_landscape_trees()
	
	# Crear líneas del campo (área central de entrenamiento)
	create_field_lines()
	
	# Crear graderías mejoradas
	create_training_stands()
	
	# Crear edificio de oficinas/vestuarios
	create_training_building()
	
	# Añadir postes de entrenamiento
	create_training_equipment()

	# Añadir luces mejoradas
	create_lighting_system()
	
func create_surrounding_terrain():
	"""Crear terreno circundante con hierba"""
	var terrain_mesh = MeshInstance3D.new()
	var terrain_box = BoxMesh.new()
	terrain_box.size = Vector3(120, 0.3, 150)
	terrain_mesh.mesh = terrain_box
	terrain_mesh.position = Vector3(0, -0.65, 0)
	
	var terrain_material = StandardMaterial3D.new()
	terrain_material.albedo_color = Color(0.2, 0.6, 0.25, 1)  # Verde hierba natural
	terrain_material.roughness = 0.9
	terrain_material.metallic = 0.0
	terrain_mesh.material_override = terrain_material
	viewport_3d.add_child(terrain_mesh)

func create_field_fences():
	"""Crear vallas alrededor del campo de entrenamiento"""
	var fence_material = StandardMaterial3D.new()
	fence_material.albedo_color = Color(0.4, 0.4, 0.4, 1)  # Gris metálico
	fence_material.metallic = 0.6
	fence_material.roughness = 0.4
	
	# Vallas laterales (izquierda y derecha)
	for side_x in [-22, 22]:
		for segment in range(7):  # 7 segmentos de valla por lado
			var fence_post = MeshInstance3D.new()
			var post_cylinder = CylinderMesh.new()
			post_cylinder.height = 3
			post_cylinder.top_radius = 0.05
			post_cylinder.bottom_radius = 0.05
			fence_post.mesh = post_cylinder
			fence_post.position = Vector3(side_x, 1.5, -30 + (segment * 10))
			fence_post.material_override = fence_material
			viewport_3d.add_child(fence_post)
			
			# Barras horizontales de la valla
			if segment < 6:
				for bar_height in [0.8, 1.5, 2.2]:
					var fence_bar = MeshInstance3D.new()
					var bar_box = BoxMesh.new()
					bar_box.size = Vector3(0.1, 0.1, 10)
					fence_bar.mesh = bar_box
					fence_bar.position = Vector3(side_x, bar_height, -25 + (segment * 10))
					fence_bar.material_override = fence_material
					viewport_3d.add_child(fence_bar)
	
	# Vallas del fondo (detrás y delante)
	for side_z in [-37, 37]:
		for segment in range(9):  # 9 segmentos de valla por lado
			var fence_post = MeshInstance3D.new()
			var post_cylinder = CylinderMesh.new()
			post_cylinder.height = 3
			post_cylinder.top_radius = 0.05
			post_cylinder.bottom_radius = 0.05
			fence_post.mesh = post_cylinder
			fence_post.position = Vector3(-20 + (segment * 5), 1.5, side_z)
			fence_post.material_override = fence_material
			viewport_3d.add_child(fence_post)
			
			# Barras horizontales
			if segment < 8:
				for bar_height in [0.8, 1.5, 2.2]:
					var fence_bar = MeshInstance3D.new()
					var bar_box = BoxMesh.new()
					bar_box.size = Vector3(5, 0.1, 0.1)
					fence_bar.mesh = bar_box
					fence_bar.position = Vector3(-17.5 + (segment * 5), bar_height, side_z)
					fence_bar.material_override = fence_material
					viewport_3d.add_child(fence_bar)

func create_landscape_trees():
	"""Crear árboles alrededor del campo para el paisaje"""
	var trunk_material = StandardMaterial3D.new()
	trunk_material.albedo_color = Color(0.4, 0.25, 0.1, 1)  # Marrón tronco
	trunk_material.roughness = 0.8
	
	var leaves_material = StandardMaterial3D.new()
	leaves_material.albedo_color = Color(0.1, 0.7, 0.2, 1)  # Verde hojas
	leaves_material.roughness = 0.7
	leaves_material.emission_enabled = true
	leaves_material.emission = Color(0.05, 0.2, 0.05, 1)
	leaves_material.emission_energy = 0.3
	
	# Posiciones de árboles alrededor del campo
	var tree_positions = [
		Vector3(-35, 0, -45), Vector3(-30, 0, -50), Vector3(-25, 0, -47),
		Vector3(25, 0, -47), Vector3(30, 0, -50), Vector3(35, 0, -45),
		Vector3(-35, 0, 45), Vector3(-30, 0, 50), Vector3(-25, 0, 47),
		Vector3(25, 0, 47), Vector3(30, 0, 50), Vector3(35, 0, 45),
		Vector3(-45, 0, -20), Vector3(-45, 0, 0), Vector3(-45, 0, 20),
		Vector3(45, 0, -20), Vector3(45, 0, 0), Vector3(45, 0, 20)
	]
	
	for pos in tree_positions:
		# Tronco del árbol
		var trunk = MeshInstance3D.new()
		var trunk_cylinder = CylinderMesh.new()
		trunk_cylinder.height = 6
		trunk_cylinder.top_radius = 0.3
		trunk_cylinder.bottom_radius = 0.4
		trunk.mesh = trunk_cylinder
		trunk.position = pos + Vector3(0, 3, 0)
		trunk.material_override = trunk_material
		viewport_3d.add_child(trunk)
		
		# Copa del árbol
		var leaves = MeshInstance3D.new()
		var leaves_sphere = SphereMesh.new()
		leaves_sphere.radius = 4
		leaves_sphere.height = 6
		leaves.mesh = leaves_sphere
		leaves.position = pos + Vector3(0, 8, 0)
		leaves.material_override = leaves_material
		viewport_3d.add_child(leaves)
	
func create_field_lines():
	"""Crear líneas del campo de fútbol realista"""
	var line_material = StandardMaterial3D.new()
	line_material.albedo_color = Color.WHITE
	line_material.emission_enabled = true
	line_material.emission = Color(0.9, 0.9, 0.9, 1)
	line_material.emission_energy = 0.4
	
	# Línea central (atraviesa todo el campo)
	var center_line = MeshInstance3D.new()
	var center_box = BoxMesh.new()
	center_box.size = Vector3(60, 0.05, 0.3)  # Línea horizontal que cruza el campo
	center_line.mesh = center_box
	center_line.position = Vector3(0, 0.26, 0)
	center_line.material_override = line_material
	viewport_3d.add_child(center_line)
	
	# Círculo central (horizontal, no vertical) - MÁS PEQUEÑO
	var center_circle = MeshInstance3D.new()
	var circle_torus = TorusMesh.new()
	circle_torus.inner_radius = 5.0  # Reducido de 9.0 a 5.0
	circle_torus.outer_radius = 5.3  # Reducido de 9.3 a 5.3
	circle_torus.rings = 64
	center_circle.mesh = circle_torus
	center_circle.position = Vector3(0, 0.26, 0)
	center_circle.rotation_degrees = Vector3(0, 0, 0)  # Horizontal (sin rotación)
	center_circle.material_override = line_material
	viewport_3d.add_child(center_circle)
	
	# Líneas laterales (banda izquierda y derecha)
	for side_x in [-30, 30]:
		var sideline = MeshInstance3D.new()
		var sideline_box = BoxMesh.new()
		sideline_box.size = Vector3(0.3, 0.05, 100)  # Líneas largas
		sideline.mesh = sideline_box
		sideline.position = Vector3(side_x, 0.26, 0)
		sideline.material_override = line_material
		viewport_3d.add_child(sideline)
	
	# Líneas de fondo (arco norte y sur)
	for side_z in [-50, 50]:
		var goalline = MeshInstance3D.new()
		var goalline_box = BoxMesh.new()
		goalline_box.size = Vector3(60, 0.05, 0.3)  # Líneas de gol
		goalline.mesh = goalline_box
		goalline.position = Vector3(0, 0.26, side_z)
		goalline.material_override = line_material
		viewport_3d.add_child(goalline)
	
	# Áreas de penalty
	for side_z in [-50, 50]:
		var penalty_direction = 1 if side_z > 0 else -1
		
		# Línea frontal del área grande
		var big_area_front = MeshInstance3D.new()
		var big_area_box = BoxMesh.new()
		big_area_box.size = Vector3(40, 0.05, 0.3)
		big_area_front.mesh = big_area_box
		big_area_front.position = Vector3(0, 0.26, side_z - (penalty_direction * 16))
		big_area_front.material_override = line_material
		viewport_3d.add_child(big_area_front)
		
		# Líneas laterales del área grande
		for area_side in [-20, 20]:
			var big_area_side = MeshInstance3D.new()
			var big_area_side_box = BoxMesh.new()
			big_area_side_box.size = Vector3(0.3, 0.05, 16)
			big_area_side.mesh = big_area_side_box
			big_area_side.position = Vector3(area_side, 0.26, side_z - (penalty_direction * 8))
			big_area_side.material_override = line_material
			viewport_3d.add_child(big_area_side)
		
		# Área pequeña (de 6 metros)
		var small_area_front = MeshInstance3D.new()
		var small_area_box = BoxMesh.new()
		small_area_box.size = Vector3(20, 0.05, 0.3)
		small_area_front.mesh = small_area_box
		small_area_front.position = Vector3(0, 0.26, side_z - (penalty_direction * 5.5))
		small_area_front.material_override = line_material
		viewport_3d.add_child(small_area_front)
		
		# Líneas laterales del área pequeña
		for small_side in [-10, 10]:
			var small_area_side = MeshInstance3D.new()
			var small_area_side_box = BoxMesh.new()
			small_area_side_box.size = Vector3(0.3, 0.05, 5.5)
			small_area_side.mesh = small_area_side_box
			small_area_side.position = Vector3(small_side, 0.26, side_z - (penalty_direction * 2.75))
			small_area_side.material_override = line_material
			viewport_3d.add_child(small_area_side)
	
	# Crear porterías
	create_goalposts()

func create_goalposts():
	"""Crear porterías en ambos extremos del campo"""
	var goalpost_material = StandardMaterial3D.new()
	goalpost_material.albedo_color = Color.WHITE
	goalpost_material.emission_enabled = true
	goalpost_material.emission = Color(0.9, 0.9, 0.9, 1)
	goalpost_material.emission_energy = 0.2
	goalpost_material.metallic = 0.1
	goalpost_material.roughness = 0.3
	
	# Crear porterías en ambos extremos
	for goal_z in [-50, 50]:
		# Postes verticales (izquierdo y derecho)
		for post_x in [-7.5, 7.5]:  # Ancho de portería: 15 metros
			var goalpost = MeshInstance3D.new()
			var post_cylinder = CylinderMesh.new()
			post_cylinder.height = 8  # Altura de portería
			post_cylinder.top_radius = 0.15
			post_cylinder.bottom_radius = 0.15
			goalpost.mesh = post_cylinder
			goalpost.position = Vector3(post_x, 4, goal_z)
			goalpost.material_override = goalpost_material
			viewport_3d.add_child(goalpost)
		
		# Travesaño horizontal
		var crossbar = MeshInstance3D.new()
		var crossbar_cylinder = CylinderMesh.new()
		crossbar_cylinder.height = 15  # Ancho de la portería
		crossbar_cylinder.top_radius = 0.15
		crossbar_cylinder.bottom_radius = 0.15
		crossbar.mesh = crossbar_cylinder
		crossbar.position = Vector3(0, 8, goal_z)
		crossbar.rotation_degrees = Vector3(0, 0, 90)  # Rotar para que sea horizontal
		crossbar.material_override = goalpost_material
		viewport_3d.add_child(crossbar)
		
		# Red de la portería (simplificada como planos semi-transparentes)
		var net_material = StandardMaterial3D.new()
		net_material.albedo_color = Color(0.9, 0.9, 0.9, 0.3)  # Blanco semi-transparente
		net_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		# Red trasera
		var net_back = MeshInstance3D.new()
		var net_back_quad = QuadMesh.new()
		net_back_quad.size = Vector2(15, 8)
		net_back.mesh = net_back_quad
		net_back.position = Vector3(0, 4, goal_z - (0.5 if goal_z > 0 else -0.5))
		net_back.material_override = net_material
		viewport_3d.add_child(net_back)
		
		# Redes laterales
		for net_side_x in [-7.5, 7.5]:
			var net_side = MeshInstance3D.new()
			var net_side_quad = QuadMesh.new()
			net_side_quad.size = Vector2(2, 8)
			net_side.mesh = net_side_quad
			net_side.position = Vector3(net_side_x, 4, goal_z - (1 if goal_z > 0 else -1))
			net_side.rotation_degrees = Vector3(0, 90, 0)
			net_side.material_override = net_material
			viewport_3d.add_child(net_side)

func create_training_stands():
	"""Crear graderías de entrenamiento más detalladas - FUERA DEL CAMPO"""
	var stand_material = StandardMaterial3D.new()
	stand_material.albedo_color = Color(0.6, 0.6, 0.7, 1)  # Gris metálico
	stand_material.metallic = 0.3
	stand_material.roughness = 0.7
	
	for side in [-40, 40]:  # Movido más lejos del campo
		# Estructura principal de las gradas
		var main_stand = MeshInstance3D.new()
		var stand_box = BoxMesh.new()
		stand_box.size = Vector3(6, 4, 25)
		main_stand.mesh = stand_box
		main_stand.position = Vector3(side, 2, 0)
		main_stand.material_override = stand_material
		viewport_3d.add_child(main_stand)
		
		# Asientos (escalones)
		for step in range(3):
			var seat_step = MeshInstance3D.new()
			var step_box = BoxMesh.new()
			step_box.size = Vector3(5.5, 0.3, 24)
			seat_step.mesh = step_box
			seat_step.position = Vector3(side + (step * 0.3 * (1 if side > 0 else -1)), 0.5 + (step * 0.8), 0)
			
			var seat_material = StandardMaterial3D.new()
			seat_material.albedo_color = Color(0.2, 0.4, 0.8, 1)  # Azul asientos
			seat_step.material_override = seat_material
			viewport_3d.add_child(seat_step)

func create_training_building():
	# Crear edificio de oficinas/vestuarios (MOVIDO ATRÁS)
	var building_material = StandardMaterial3D.new()
	building_material.albedo_color = Color(0.8, 0.7, 0.5, 1)  # Beige claro
	building_material.roughness = 0.8
	
	# Edificio principal (ahora detrás del campo)
	var main_building = MeshInstance3D.new()
	var building_box = BoxMesh.new()
	building_box.size = Vector3(12, 6, 8)
	main_building.mesh = building_box
	main_building.position = Vector3(0, 3, 60)  # Movido hacia atrás
	main_building.material_override = building_material
	viewport_3d.add_child(main_building)
	
	# Techo
	var roof = MeshInstance3D.new()
	var roof_box = BoxMesh.new()
	roof_box.size = Vector3(13, 0.5, 9)
	roof.mesh = roof_box
	roof.position = Vector3(0, 6.25, 60)  # Movido hacia atrás
	
	var roof_material = StandardMaterial3D.new()
	roof_material.albedo_color = Color(0.5, 0.2, 0.1, 1)  # Techo rojizo
	roof.material_override = roof_material
	viewport_3d.add_child(roof)
	
	# Puertas de entrada
	for door_x in [-3, 0, 3]:
		var door = MeshInstance3D.new()
		var door_box = BoxMesh.new()
		door_box.size = Vector3(1.5, 4, 0.2)
		door.mesh = door_box
		door.position = Vector3(door_x, 2, 56.1)  # Movido hacia atrás
		
		var door_material = StandardMaterial3D.new()
		door_material.albedo_color = Color(0.3, 0.2, 0.1, 1)  # Marrón oscuro
		door.material_override = door_material
		viewport_3d.add_child(door)

func create_training_equipment():
	"""Crear equipamiento de entrenamiento"""
	var equipment_material = StandardMaterial3D.new()
	equipment_material.albedo_color = Color(1, 1, 0, 1)  # Amarillo
	equipment_material.metallic = 0.1
	
	# Postes de entrenamiento
	var post_positions = [
		Vector3(-10, 0, -10), Vector3(10, 0, -10),
		Vector3(-10, 0, 10), Vector3(10, 0, 10)
	]
	
	for pos in post_positions:
		var training_post = MeshInstance3D.new()
		var post_cylinder = CylinderMesh.new()
		post_cylinder.height = 3
		post_cylinder.top_radius = 0.1
		post_cylinder.bottom_radius = 0.1
		training_post.mesh = post_cylinder
		training_post.position = pos + Vector3(0, 1.5, 0)
		training_post.material_override = equipment_material
		viewport_3d.add_child(training_post)

func create_lighting_system():
	"""Crear sistema de iluminación mejorado con cielo"""
	
	# Crear Environment con cielo azul
	var environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	
	# Crear un cielo procedural
	var sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.4, 0.7, 1.0, 1)  # Azul cielo
	sky_material.sky_horizon_color = Color(0.8, 0.9, 1.0, 1)  # Azul claro horizonte
	sky_material.ground_bottom_color = Color(0.2, 0.6, 0.3, 1)  # Verde tierra
	sky_material.ground_horizon_color = Color(0.4, 0.8, 0.5, 1)  # Verde claro horizonte
	sky_material.sun_angle_max = 30.0
	sky_material.sun_curve = 0.3
	sky.sky_material = sky_material
	environment.sky = sky
	
	# Configurar luz ambiental del cielo
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.3
	
	# Aplicar el environment a través de la cámara
	camera_3d.environment = environment
	
	# Luz solar principal
	var sunlight = DirectionalLight3D.new()
	sunlight.position = Vector3(15, 40, -10)
	sunlight.look_at(Vector3(0, 0, 0), Vector3.UP)
	sunlight.light_color = Color(1, 0.95, 0.8, 1)  # Luz solar cálida
	sunlight.light_energy = 2.5  # Aumentada para más brillo
	sunlight.shadow_enabled = true
	viewport_3d.add_child(sunlight)
	
	# Luz ambiental suave adicional
	var ambient_light = DirectionalLight3D.new()
	ambient_light.position = Vector3(-10, 30, 15)
	ambient_light.look_at(Vector3(0, 0, 0), Vector3.UP)
	ambient_light.light_color = Color(0.7, 0.8, 1, 1)  # Luz azulada suave
	ambient_light.light_energy = 1.0  # Aumentada
	viewport_3d.add_child(ambient_light)
	
	# Luz de relleno desde arriba
	var fill_light = DirectionalLight3D.new()
	fill_light.position = Vector3(0, 50, 0)
	fill_light.look_at(Vector3(0, 0, 0), Vector3.UP)
	fill_light.light_color = Color(1, 1, 1, 1)  # Luz blanca neutra
	fill_light.light_energy = 0.8
	viewport_3d.add_child(fill_light)

func create_dust_particles_3d():
	print("💨 Creando sistema de partículas de polvo...")

	var dust_particles = GPUParticles3D.new()
	dust_particles.position = Vector3(0, 0, 0)
	dust_particles.amount = 500
	dust_particles.lifetime = 2.0
	dust_particles.emitting = true

	# Configurar material de partículas
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.initial_velocity_min = 0.5
	process_material.initial_velocity_max = 1.5
	process_material.gravity = Vector3(0, -0.5, 0)
	process_material.scale_min = 0.05
	process_material.scale_max = 0.1
	process_material.color = Color(0.8, 0.7, 0.6, 0.5)
	dust_particles.process_material = process_material

	viewport_3d.add_child(dust_particles)

func start_training_animation_sequence():
	# Configurar tween para la animación
	var animation_tween = create_tween()

	# Desvanecer overlay
	animation_tween.tween_property(transition_overlay, "modulate:a", 1.0, 0.3).set_delay(0.2)

	# Animar texto descriptivo
	animation_tween.tween_property(description_text, "modulate:a", 1.0, 0.3).set_delay(0.5)
	animation_tween.tween_property(subtitle_text, "modulate:a", 1.0, 0.3).set_delay(0.8)

	# Animar movimiento de cámara (de dron a cercano) - MÁS LENTO
	animation_tween.tween_property(camera_3d, "position", Vector3(0, 5, 15), 2.5).set_delay(1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Cambiar ángulo de cámara gradualmente
	animation_tween.parallel().tween_method(update_camera_angle, Vector3(0, 0, 0), Vector3(-10, 0, 0), 2.5).set_delay(1.0)
	
	# Cambiar escena EXACTAMENTE cuando termina el movimiento de cámara
	animation_tween.tween_callback(transition_to_training_dialogue).set_delay(3.5)
	
	print("🎬 Secuencia de animación del campo de entrenamiento iniciada - duración total: 3.5s")

func create_final_fade_overlay():
	"""Crear overlay negro para transición final suave"""
	var fade_overlay = ColorRect.new()
	fade_overlay.name = "FinalFadeOverlay"
	fade_overlay.color = Color.BLACK
	fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_overlay.z_index = 3000  # Por encima de todo
	fade_overlay.modulate.a = 0.0  # Empezar transparente
	self.add_child(fade_overlay)

func start_final_fade_transition():
	"""Iniciar fade final y transición"""
	var fade_overlay = get_node_or_null("FinalFadeOverlay")
	if fade_overlay:
		var final_tween = create_tween()
		# Fade a negro
		final_tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
		# Transición al diálogo
		final_tween.tween_callback(transition_to_training_dialogue).set_delay(0.6)

func update_camera_angle(angle: Vector3):
	"""Actualiza gradualmente el ángulo de la cámara"""
	if camera_3d:
		camera_3d.rotation_degrees = angle

func transition_to_training_dialogue():
	"""Transición final hacia el diálogo de entrenamiento"""
	print("🗣️ Transicionando al diálogo de entrenamiento...")
	get_tree().change_scene_to_file("res://scenes/TrainingDialogueScene.tscn")
