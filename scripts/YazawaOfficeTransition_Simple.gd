extends Control

# Referencias para la transición épica presidencial
var transition_overlay: ColorRect
var president_crown: Label
var yazawa_portrait: TextureRect
var description_text: Label
var subtitle_text: Label
var gold_particles: CPUParticles2D
var crown_rotation_tween: Tween
var main_tween: Tween

# Efectos 3D
var crown_3d: MeshInstance3D
var camera_3d: Camera3D
var viewport_container: SubViewportContainer
var viewport_3d: SubViewport

func _ready():
	print("👑 YazawaOfficeTransition: Iniciando transición épica presidencial...")
	
	# Crear la transición inmediatamente
	create_epic_presidential_transition()

func create_epic_presidential_transition():
	print("🏛️ Creando transición épica presidencial...")
	
	# Crear overlay principal con color marrón presidencial
	transition_overlay = ColorRect.new()
	transition_overlay.name = "PresidentialOverlay"
	transition_overlay.color = Color(0.4, 0.25, 0.1, 1.0)  # Marrón elegante
	transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_overlay.z_index = 2000
	transition_overlay.modulate.a = 0.0  # Empezar transparente
	self.add_child(transition_overlay)
	
	# Crear viewport 3D para efectos épicos
	create_3d_crown_effect()
	
	# Crear corona presidencial gigante
	president_crown = Label.new()
	president_crown.text = "👑"  # Corona presidencial
	president_crown.add_theme_font_size_override("font_size", 200)
	president_crown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	president_crown.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	president_crown.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	president_crown.modulate = Color(1, 1, 1, 0)  # Empezar transparente
	transition_overlay.add_child(president_crown)
	
	# Crear retrato de Yazawa (intentar cargar la imagen)
	yazawa_portrait = TextureRect.new()
	yazawa_portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	yazawa_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	yazawa_portrait.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	yazawa_portrait.size = Vector2(300, 300)
	yazawa_portrait.position = Vector2(-150, -250)  # Centrado arriba
	yazawa_portrait.modulate = Color(1, 1, 1, 0)  # Empezar transparente
	
	# Intentar cargar imagen de Yazawa
	var yazawa_image_path = "res://assets/images/characters/yazawa.png"
	if ResourceLoader.exists(yazawa_image_path):
		yazawa_portrait.texture = load(yazawa_image_path)
		print("👑 Imagen de Yazawa cargada exitosamente")
	else:
		print("⚠️ No se encontró imagen de Yazawa, usando corona por defecto")
		yazawa_portrait.queue_free()
		yazawa_portrait = null
	
	if yazawa_portrait:
		transition_overlay.add_child(yazawa_portrait)
	
	# Crear texto descriptivo principal
	description_text = Label.new()
	description_text.text = "ACCEDIENDO AL DESPACHO PRESIDENCIAL"
	description_text.add_theme_font_size_override("font_size", 48)
	description_text.add_theme_color_override("font_color", Color.GOLD)
	description_text.add_theme_color_override("font_shadow_color", Color.BLACK)
	description_text.add_theme_constant_override("shadow_offset_x", 4)
	description_text.add_theme_constant_override("shadow_offset_y", 4)
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
	subtitle_text.text = "Preparando el salón más exclusivo del club..."
	subtitle_text.add_theme_font_size_override("font_size", 24)
	subtitle_text.add_theme_color_override("font_color", Color(1, 0.8, 0.4, 1))
	subtitle_text.add_theme_color_override("font_shadow_color", Color.BLACK)
	subtitle_text.add_theme_constant_override("shadow_offset_x", 2)
	subtitle_text.add_theme_constant_override("shadow_offset_y", 2)
	subtitle_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle_text.position = Vector2(0, screen_size.y * 0.78)
	subtitle_text.size = Vector2(screen_size.x, 30)
	subtitle_text.modulate = Color(1, 1, 1, 0)  # Empezar transparente
	transition_overlay.add_child(subtitle_text)
	
	# Crear partículas doradas épicas
	create_epic_particles()
	
	# Iniciar la secuencia de animación épica
	start_epic_animation_sequence()

func create_3d_crown_effect():
	print("🎥 Creando escena 3D cinematográfica de entrada a la oficina...")
	
	# Crear viewport 3D para efectos espectaculares
	viewport_container = SubViewportContainer.new()
	viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_container.stretch = true
	transition_overlay.add_child(viewport_container)
	
	viewport_3d = SubViewport.new()
	viewport_3d.size = Vector2i(1920, 1080)
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(viewport_3d)
	
	# Crear cámara 3D para movimiento cinematográfico
	camera_3d = Camera3D.new()
	# Empezar FUERA de la oficina (como si estuviéramos en el pasillo)
	camera_3d.position = Vector3(0, 1.7, 15)  # Altura de persona, lejos de la puerta
	camera_3d.look_at(Vector3(0, 1.7, 0), Vector3.UP)  # Mirar hacia la oficina
	viewport_3d.add_child(camera_3d)
	

  # Crear entorno de oficina 3D
	create_office_environment_3d()
	
	# Crear corona presidencial flotante en el centro
	create_floating_crown_3d()
	
	# Crear partículas 3D épicas
	create_3d_particles_system()
	
	# Iniciar movimiento cinematográfico de entrada
	start_cinematic_camera_movement()

func create_office_environment_3d():
	print("🏢 Creando entorno 3D de oficina presidencial...")
	
	# Crear el SUELO de la oficina
	var floor_mesh = MeshInstance3D.new()
	var floor_box = BoxMesh.new()
	floor_box.size = Vector3(12, 0.2, 10)
	floor_mesh.mesh = floor_box
	floor_mesh.position = Vector3(0, -1, 0)
	
	var floor_material = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.4, 0.2, 0.1, 1)  # Marrón elegante
	floor_material.metallic = 0.2
	floor_material.roughness = 0.8
	floor_mesh.material_override = floor_material
	viewport_3d.add_child(floor_mesh)
	
	# Crear PAREDES de la oficina
	# Pared trasera
	var back_wall = MeshInstance3D.new()
	var back_wall_box = BoxMesh.new()
	back_wall_box.size = Vector3(12, 6, 0.3)
	back_wall.mesh = back_wall_box
	back_wall.position = Vector3(0, 2, -5)
	
	var wall_material = StandardMaterial3D.new()
	wall_material.albedo_color = Color(0.3, 0.2, 0.15, 1)
	wall_material.roughness = 0.9
	back_wall.material_override = wall_material
	viewport_3d.add_child(back_wall)
	
	# Paredes laterales
	for side in [-1, 1]:
		var side_wall = MeshInstance3D.new()
		var side_wall_box = BoxMesh.new()
		side_wall_box.size = Vector3(0.3, 6, 10)
		side_wall.mesh = side_wall_box
		side_wall.position = Vector3(side * 6, 2, 0)
		side_wall.material_override = wall_material
		viewport_3d.add_child(side_wall)
	
	# PARED FRONTAL con abertura para la puerta
	# Pared frontal izquierda (desde pared lateral izquierda hasta inicio de puerta)
	var front_wall_left = MeshInstance3D.new()
	var front_wall_left_box = BoxMesh.new()
	front_wall_left_box.size = Vector3(4.5, 6, 0.3)  # Desde X=-6 hasta X=-1.5
	front_wall_left.mesh = front_wall_left_box
	front_wall_left.position = Vector3(-3.75, 2, 5)  # Centro entre -6 y -1.5
	front_wall_left.material_override = wall_material
	viewport_3d.add_child(front_wall_left)
	
	# Pared frontal derecha (desde final de puerta hasta pared lateral derecha)
	var front_wall_right = MeshInstance3D.new()
	var front_wall_right_box = BoxMesh.new()
	front_wall_right_box.size = Vector3(4.5, 6, 0.3)  # Desde X=1.5 hasta X=6
	front_wall_right.mesh = front_wall_right_box
	front_wall_right.position = Vector3(3.75, 2, 5)  # Centro entre 1.5 y 6
	front_wall_right.material_override = wall_material
	viewport_3d.add_child(front_wall_right)
	
	# PUERTA de entrada que se abre cinematográficamente
	var office_door = MeshInstance3D.new()
	var door_box = BoxMesh.new()
	door_box.size = Vector3(3, 6, 0.15)  # Puerta de 3 unidades de ancho
	office_door.mesh = door_box
	office_door.position = Vector3(-1.5, 1, 5.1)  # Bisagra en el lado izquierdo, ligeramente hacia afuera
	office_door.rotation_degrees = Vector3(0, 0, 0)  # Empezar cerrada
	
	var door_material = StandardMaterial3D.new()
	door_material.albedo_color = Color(0.5, 0.3, 0.1, 1)  # Madera elegante
	door_material.roughness = 0.8
	door_material.metallic = 0.1
	office_door.material_override = door_material
	viewport_3d.add_child(office_door)
	
	# MARCOS DE PUERTA para mayor realismo
	# Marco superior
	var door_frame_top = MeshInstance3D.new()
	var door_frame_top_box = BoxMesh.new()
	door_frame_top_box.size = Vector3(3.2, 0.3, 0.4)  # Ligeramente más ancho que la puerta
	door_frame_top.mesh = door_frame_top_box
	door_frame_top.position = Vector3(0, 4.15, 5.2)  # Encima de la abertura de la puerta
	
	var frame_material = StandardMaterial3D.new()
	frame_material.albedo_color = Color(0.4, 0.25, 0.08, 1)  # Madera más oscura para el marco
	frame_material.roughness = 0.7
	frame_material.metallic = 0.1
	door_frame_top.material_override = frame_material
	viewport_3d.add_child(door_frame_top)
	
	# Marcos laterales de la puerta
	for side_pos in [-1.6, 1.6]:  # Posiciones izquierda y derecha del marco
		var door_frame_side = MeshInstance3D.new()
		var door_frame_side_box = BoxMesh.new()
		door_frame_side_box.size = Vector3(0.2, 6, 0.4)
		door_frame_side.mesh = door_frame_side_box
		door_frame_side.position = Vector3(side_pos, 1, 5.2)  # A los lados de la puerta
		door_frame_side.material_override = frame_material
		viewport_3d.add_child(door_frame_side)
	
	# Animar apertura dramática de la puerta - INMEDIATAMENTE
	var door_opening_tween = create_tween()
	door_opening_tween.tween_property(office_door, "rotation_degrees", Vector3(0, -90, 0), 1.0).set_delay(0.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	print("🚪 Puerta y paredes frontales creadas - habitación cerrada con entrada dramática")
	
	
	# Crear ESCRITORIO presidencial
	var desk = MeshInstance3D.new()
	var desk_box = BoxMesh.new()
	desk_box.size = Vector3(4, 0.2, 2)
	desk.mesh = desk_box
	desk.position = Vector3(0, 0.1, -2)
	
	var desk_material = StandardMaterial3D.new()
	desk_material.albedo_color = Color(0.6, 0.4, 0.2, 1)  # Madera elegante
	desk_material.metallic = 0.1
	desk_material.roughness = 0.7
	desk.material_override = desk_material
	viewport_3d.add_child(desk)
	
	# SILLA PRESIDENCIAL REMOVIDA para no tapar la corona flotante
	
	# SILLAS DE VISITAS frente al escritorio (disposición de oficina ejecutiva)
	var visitor_chair_positions = [
		Vector3(-1.5, 0.4, -0.5),  # Silla izquierda frente al escritorio
		Vector3(1.5, 0.4, -0.5),   # Silla derecha frente al escritorio
		Vector3(-2.8, 0.4, 1),     # Silla lateral izquierda
		Vector3(2.8, 0.4, 1)       # Silla lateral derecha
	]
	
	for i in range(visitor_chair_positions.size()):
		var visitor_chair = MeshInstance3D.new()
		var visitor_cylinder = CylinderMesh.new()
		visitor_cylinder.height = 1.6
		visitor_cylinder.top_radius = 0.5
		visitor_cylinder.bottom_radius = 0.6
		visitor_chair.mesh = visitor_cylinder
		visitor_chair.position = visitor_chair_positions[i]
		
		# Rotar las sillas laterales hacia el escritorio
		if i >= 2:  # Sillas laterales
			if i == 2:  # Silla lateral izquierda
				visitor_chair.rotation_degrees = Vector3(0, 30, 0)
			else:  # Silla lateral derecha
				visitor_chair.rotation_degrees = Vector3(0, -30, 0)
		
		var visitor_chair_material = StandardMaterial3D.new()
		visitor_chair_material.albedo_color = Color(0.25, 0.15, 0.08, 1)  # Cuero marrón claro
		visitor_chair_material.metallic = 0.2
		visitor_chair_material.roughness = 0.7
		visitor_chair.material_override = visitor_chair_material
		viewport_3d.add_child(visitor_chair)
		
		# Añadir respaldos a las sillas de visitas
		var visitor_backrest = MeshInstance3D.new()
		var visitor_backrest_box = BoxMesh.new()
		visitor_backrest_box.size = Vector3(0.9, 1.8, 0.2)
		visitor_backrest.mesh = visitor_backrest_box
		
		# Posicionar respaldo según la silla
		var backrest_offset = Vector3(0, 1.5, 0.4)
		if i >= 2:  # Sillas laterales
			if i == 2:  # Silla lateral izquierda
				backrest_offset = Vector3(0.3, 1.5, 0.2)
				visitor_backrest.rotation_degrees = Vector3(0, 30, 0)
			else:  # Silla lateral derecha
				backrest_offset = Vector3(-0.3, 1.5, 0.2)
				visitor_backrest.rotation_degrees = Vector3(0, -30, 0)
		
		visitor_backrest.position = visitor_chair_positions[i] + backrest_offset
		visitor_backrest.material_override = visitor_chair_material
		viewport_3d.add_child(visitor_backrest)
	
	print("🪑 Sillas de despacho añadidas: 1 silla presidencial + 4 sillas de visitas")
	
	# Añadir LUCES ambientales
	var ambient_light = DirectionalLight3D.new()
	ambient_light.position = Vector3(3, 4, 3)
	ambient_light.look_at(Vector3(0, 0, 0), Vector3.UP)
	ambient_light.light_energy = 1.5
	ambient_light.light_color = Color(1, 0.9, 0.7, 1)  # Luz cálida
	viewport_3d.add_child(ambient_light)
	
	# Luz dorada para el ambiente presidencial
	var golden_light = DirectionalLight3D.new()
	golden_light.position = Vector3(-3, 4, 2)
	golden_light.look_at(Vector3(0, 0, 0), Vector3.UP)
	golden_light.light_energy = 1.0
	golden_light.light_color = Color.GOLD
	viewport_3d.add_child(golden_light)

func create_floating_crown_3d():
	print("👑 Creando corona presidencial flotante...")
	
	# Crear corona 3D épica flotando sobre el escritorio
	crown_3d = MeshInstance3D.new()
	var crown_mesh = SphereMesh.new()
	crown_mesh.radius = 0.8
	crown_mesh.height = 1.2
	crown_3d.mesh = crown_mesh
	crown_3d.position = Vector3(0, 3, -2)  # Flotando sobre el escritorio
	
	# Material dorado brillante con emisiones
	var crown_material = StandardMaterial3D.new()
	crown_material.albedo_color = Color.GOLD
	crown_material.metallic = 0.95
	crown_material.roughness = 0.05
	crown_material.emission_enabled = true
	crown_material.emission = Color(1, 0.8, 0.2, 1)
	crown_material.emission_energy = 2.0
	crown_3d.material_override = crown_material
	
	viewport_3d.add_child(crown_3d)
	
	# Crear gemas en la corona (esferas pequeñas)
	for i in range(6):
		var gem = MeshInstance3D.new()
		var gem_sphere = SphereMesh.new()
		gem_sphere.radius = 0.1
		gem.mesh = gem_sphere
		
		var angle = (i * PI * 2) / 6
		gem.position = Vector3(cos(angle) * 0.9, 3.2, -2 + sin(angle) * 0.9)
		
		var gem_material = StandardMaterial3D.new()
		gem_material.albedo_color = Color(0.8, 0.2, 0.9, 1)  # Gemas moradas
		gem_material.emission_enabled = true
		gem_material.emission = Color(0.8, 0.2, 0.9, 1)
		gem_material.emission_energy = 1.5
		gem.material_override = gem_material
		
		viewport_3d.add_child(gem)
	
	# Iniciar rotación y flotación de la corona
	start_3d_crown_rotation()
	start_crown_floating_effect()

func create_3d_particles_system():
	print("✨ Creando sistema de partículas 3D masivo...")
	
	# Partículas doradas cayendo desde el techo
	var particles_3d = GPUParticles3D.new()
	particles_3d.position = Vector3(0, 5, 0)
	particles_3d.amount = 1000
	particles_3d.lifetime = 5.0
	particles_3d.emitting = true
	
	# Configuración del material de partículas
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, -1, 0)
	process_material.initial_velocity_min = 2.0
	process_material.initial_velocity_max = 5.0
	process_material.gravity = Vector3(0, -9.8, 0)
	process_material.scale_min = 0.1
	process_material.scale_max = 0.3
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(8, 1, 6)
	
	particles_3d.process_material = process_material
	
	# Material visual dorado
	var particle_material = StandardMaterial3D.new()
	particle_material.albedo_color = Color.GOLD
	particle_material.emission_enabled = true
	particle_material.emission = Color.GOLD
	particle_material.emission_energy = 2.0
	particles_3d.material_override = particle_material
	
	viewport_3d.add_child(particles_3d)

func create_epic_particles():
	# Crear partículas doradas épicas
	gold_particles = CPUParticles2D.new()
	gold_particles.position = Vector2(960, 540)  # Centro de la pantalla
	gold_particles.amount = 300
	gold_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	gold_particles.emission_sphere_radius = 400.0
	gold_particles.direction = Vector2(0, -1)
	gold_particles.initial_velocity_min = 50.0
	gold_particles.initial_velocity_max = 150.0
	gold_particles.gravity = Vector2(0, 20)
	gold_particles.scale_amount_min = 0.3
	gold_particles.scale_amount_max = 2.0
	
	# Crear gradiente dorado
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray([Color.GOLD, Color(1, 0.6, 0.1, 1), Color(0.8, 0.4, 0.1, 0.5)])
	gold_particles.color_ramp = gradient
	
	gold_particles.emitting = true
	transition_overlay.add_child(gold_particles)

func start_3d_crown_rotation():
	if crown_3d:
		crown_rotation_tween = create_tween()
		crown_rotation_tween.set_loops()
		crown_rotation_tween.tween_method(rotate_3d_crown, 0.0, 360.0, 3.0)

func rotate_3d_crown(angle_degrees: float):
	if crown_3d:
		crown_3d.rotation_degrees = Vector3(15, angle_degrees, 5)

func start_epic_animation_sequence():
	print("🎬 Iniciando transición cinematográfica de 3 segundos...")
	
	main_tween = create_tween()
	main_tween.set_parallel(true)
	
	# DURACIÓN TOTAL: 3 SEGUNDOS
	
	# Fase 1: Fade in instantáneo (0.1s)
	main_tween.tween_property(transition_overlay, "modulate:a", 1.0, 0.1)
	
	# Fase 2: Texto aparece rápido (0.2s, delay 0.1s)
	main_tween.tween_property(description_text, "modulate:a", 1.0, 0.2).set_delay(0.1)
	main_tween.tween_property(description_text, "scale", Vector2(1.05, 1.05), 0.1).set_delay(0.1)
	main_tween.tween_property(description_text, "scale", Vector2(1.0, 1.0), 0.1).set_delay(0.2)
	
	# Fase 3: Retrato de Yazawa entrada (0.7s, delay 0.3s)
	if yazawa_portrait:
		# Entrada desde la izquierda
		yazawa_portrait.position.x -= 400  # Empezar fuera de pantalla
		yazawa_portrait.modulate = Color(0.3, 0.3, 0.3, 0.8)  # Oscuro como sombra
		
		main_tween.tween_property(yazawa_portrait, "modulate:a", 1.0, 0.4).set_delay(0.3)
		main_tween.tween_property(yazawa_portrait, "position:x", yazawa_portrait.position.x + 400, 0.7).set_delay(0.3).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		main_tween.tween_property(yazawa_portrait, "modulate", Color(1, 1, 1, 1), 0.5).set_delay(0.5)  # Iluminación gradual
	
	# Fase 4: Efectos de partículas de apertura de puerta (1.0s)
	main_tween.tween_callback(func(): create_door_opening_particles()).set_delay(1.0)
	
	# Fase 5: Fade out limpio y elegante hacia negro (2.5-3.0s)
	var black_fade = ColorRect.new()
	black_fade.color = Color(0, 0, 0, 0)
	black_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black_fade.z_index = 3000  # Por encima de todo
	self.add_child(black_fade)
	
	main_tween.tween_property(black_fade, "color:a", 1.0, 0.5).set_delay(2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	main_tween.tween_callback(func(): go_to_office()).set_delay(3.0)

func change_text_phase_1():
	if description_text:
		description_text.text = "VERIFICANDO CREDENCIALES PRESIDENCIALES"
	if subtitle_text:
		subtitle_text.text = "Activando protocolo de seguridad VIP..."

func change_text_phase_2():
	if description_text:
		description_text.text = "PREPARANDO SALÓN EJECUTIVO"
	if subtitle_text:
		subtitle_text.text = "Puliendo trofeos y ajustando el sillón de cuero..."

func change_text_final():
	if description_text:
		description_text.text = "¡BIENVENIDO, PRESIDENTE YAZAWA!"
	if subtitle_text:
		subtitle_text.text = "Su despacho está listo para la grandeza..."
	
	# Efectos finales épicos
	if president_crown:
		var final_tween = create_tween()
		final_tween.tween_property(president_crown, "scale", Vector2(1.3, 1.3), 0.5)
		final_tween.tween_property(president_crown, "modulate", Color(2, 2, 2, 1), 0.5)
	
	# GRAN FINAL: Intensificar todos los efectos de partículas
	enhance_particle_effects()
	
	# Intensificar partículas 2D base
	if gold_particles:
		gold_particles.amount = 500
		gold_particles.initial_velocity_max = 200.0

func start_yazawa_epic_effects():
	"""Efectos épicos continuos para el retrato de Yazawa"""
	if yazawa_portrait:
		print("🎆 Iniciando efectos épicos de Yazawa...")
		
		# EFECTO 1: Respiración suave
		var breathing_tween = create_tween()
		breathing_tween.set_loops()
		breathing_tween.tween_property(yazawa_portrait, "scale", Vector2(1.02, 1.02), 1.5)
		breathing_tween.tween_property(yazawa_portrait, "scale", Vector2(0.98, 0.98), 1.5)
		
		# EFECTO 2: Flotación vertical sutil
		var original_y = yazawa_portrait.position.y
		var floating_tween = create_tween()
		floating_tween.set_loops()
		floating_tween.tween_property(yazawa_portrait, "position:y", original_y - 5, 2.5).set_trans(Tween.TRANS_SINE)
		floating_tween.tween_property(yazawa_portrait, "position:y", original_y + 5, 2.5).set_trans(Tween.TRANS_SINE)
		
		# EFECTO 3: Pulso de brillo dorado
		var glow_tween = create_tween()
		glow_tween.set_loops()
		glow_tween.tween_property(yazawa_portrait, "modulate", Color(1.2, 1.1, 1.0, 1), 1.0)
		glow_tween.tween_property(yazawa_portrait, "modulate", Color(1.0, 1.0, 1.0, 1), 1.0)
		
		# EFECTO 4: Rotación muy sutil
		var subtle_rotation_tween = create_tween()
		subtle_rotation_tween.set_loops()
		subtle_rotation_tween.tween_property(yazawa_portrait, "rotation", deg_to_rad(2), 3.0)
		subtle_rotation_tween.tween_property(yazawa_portrait, "rotation", deg_to_rad(-2), 3.0)
		
		print("✨ Efectos épicos de Yazawa activados: respiración, flotación, brillo y rotación")

func start_cinematic_camera_movement():
	print("🎥 Iniciando movimiento cinematográfico de cámara - esperando apertura de puerta...")
	
	if camera_3d:
		var camera_tween = create_tween()
		camera_tween.set_parallel(true)
		
		# FASE 1: Permanecer fuera viendo la puerta cerrada (0-1s)
		# La cámara permanece en su posición inicial
		
		# FASE 2: Entrada después de que se abra la puerta (1-3s) - No tan cerca
		camera_tween.tween_property(camera_3d, "position", Vector3(0, 1.7, 4), 2.0).set_delay(1.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		
		print("🎬 Movimiento cinematográfico sincronizado: espera 1s, luego entrada en 2s")

func camera_dramatic_pan(angle_degrees: float):
	"""Mueve la cámara en un arco dramático alrededor de la oficina"""
	if camera_3d:
		var angle_rad = deg_to_rad(angle_degrees)
		var radius = 4.0
		var height = 1.8
		
		var x = cos(angle_rad) * radius
		var z = 3 + sin(angle_rad) * radius
		
		camera_3d.position = Vector3(x, height, z)
		# Siempre mirar hacia la corona flotante
		camera_3d.look_at(Vector3(0, 3, -2), Vector3.UP)

func start_crown_floating_effect():
	"""Efecto de flotación suave para la corona 3D"""
	if crown_3d:
		var floating_tween = create_tween()
		floating_tween.set_loops()
		
		# Movimiento vertical suave de flotación
		floating_tween.tween_property(crown_3d, "position:y", 3.3, 2.0).set_trans(Tween.TRANS_SINE)
		floating_tween.tween_property(crown_3d, "position:y", 2.7, 2.0).set_trans(Tween.TRANS_SINE)
		
		print("🌊 Efecto de flotación de corona activado")

func create_magical_dust_particles():
	"""Crea partículas mágicas alrededor de la corona"""
	print("✨ Creando polvo mágico alrededor de la corona...")
	
	# Partículas mágicas orbitando la corona
	var magic_particles = GPUParticles3D.new()
	magic_particles.position = Vector3(0, 3, -2)  # Misma posición que la corona
	magic_particles.amount = 200
	magic_particles.lifetime = 3.0
	magic_particles.emitting = true
	
	# Configuración orbital de partículas
	var magic_process_material = ParticleProcessMaterial.new()
	magic_process_material.direction = Vector3(0, 0, 0)
	magic_process_material.initial_velocity_min = 0.5
	magic_process_material.initial_velocity_max = 2.0
	magic_process_material.gravity = Vector3(0, 0, 0)  # Sin gravedad para efecto mágico
	magic_process_material.scale_min = 0.05
	magic_process_material.scale_max = 0.15
	magic_process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	magic_process_material.emission_sphere_radius = 1.5
	
	magic_particles.process_material = magic_process_material
	
	# Material mágico brillante
	var magic_material = StandardMaterial3D.new()
	magic_material.albedo_color = Color(1, 0.8, 1, 0.8)  # Rosa mágico
	magic_material.emission_enabled = true
	magic_material.emission = Color(1, 0.8, 1, 1)
	magic_material.emission_energy = 3.0
	magic_particles.material_override = magic_material
	
	viewport_3d.add_child(magic_particles)

func create_door_opening_particles():
	"""Crea efectos de partículas espectaculares al abrir la puerta"""
	print("🚪✨ Creando efectos de apertura de puerta épicos...")
	
	# Partículas de polvo dorado cayendo como si la puerta hubiera sido abierta
	var door_particles = CPUParticles2D.new()
	door_particles.position = Vector2(100, 300)  # Desde donde aparece Yazawa
	door_particles.amount = 150
	door_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	door_particles.emission_rect_extents = Vector2(50, 200)
	door_particles.direction = Vector2(1, 0.3)  # Hacia la derecha y ligeramente abajo
	door_particles.initial_velocity_min = 80.0
	door_particles.initial_velocity_max = 150.0
	door_particles.gravity = Vector2(0, 50)
	door_particles.scale_amount_min = 0.5
	door_particles.scale_amount_max = 2.5
	door_particles.lifetime = 3.0
	
	# Gradiente dorado brillante
	var door_gradient = Gradient.new()
	door_gradient.colors = PackedColorArray([Color(1, 1, 0.7, 1), Color.GOLD, Color(0.9, 0.5, 0.1, 0.3)])
	door_particles.color_ramp = door_gradient
	
	door_particles.emitting = true
	transition_overlay.add_child(door_particles)
	
	# Crear flash dorado de apertura
	var flash_effect = ColorRect.new()
	flash_effect.color = Color(1, 1, 0.8, 0)
	flash_effect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_overlay.add_child(flash_effect)
	
	# Animar el flash
	var flash_tween = create_tween()
	flash_tween.tween_property(flash_effect, "color:a", 0.4, 0.1)
	flash_tween.tween_property(flash_effect, "color:a", 0.0, 0.3)
	
	print("💫 Efectos de apertura de puerta creados")

func enhance_particle_effects():
	"""Mejora los efectos de partículas durante momentos clave"""
	print("🎆 Intensificando efectos de partículas...")
	
	# Intensificar partículas 2D
	if gold_particles:
		gold_particles.amount = 800
		gold_particles.initial_velocity_max = 200.0
		gold_particles.scale_amount_max = 3.0
	
	# Crear polvo mágico adicional
	create_magical_dust_particles()

func go_to_office():
	print("👑 Transición épica completada - Accediendo a la oficina de Yazawa...")
	get_tree().change_scene_to_file("res://scenes/YazawaOfficeMenu.tscn")

func _input(event):
	if event.is_pressed() and not event.is_echo():
		print("⏭️ Saltando transición épica...")
		go_to_office()
