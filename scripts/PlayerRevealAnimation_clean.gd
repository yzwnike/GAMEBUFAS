extends Control

var player_data = {
	"name": "",
	"ovr": 0,
	"position": "",
	"image_path": ""
}

# Control nodes
var player_panel
var player_image
var player_name
var player_ovr
var player_position
var continue_button
var audio_player

# Variables for epic FIFA-style animation
var viewport_3d
var main_camera
var environment_manager
var particle_manager
var lighting_manager
var stadium_manager
var effects_manager
var animation_manager
var reveal_capsule
var hologram_display
var card_reveal_system

# FIFA-style materials and shaders
var gold_material
var chrome_material
var glass_material
var energy_material
var hologram_material
var card_material

# Lighting systems
var main_directional_light
var stadium_flood_lights = []
var dynamic_spot_lights = []
var ambient_lights = []
var explosion_lights = []

# Particle systems
var confetti_system
var explosion_system
var energy_system
var sparkle_system
var smoke_system
var fire_system
var light_rays_system

# Stadium environment
var stadium_structure
var crowd_system
var field_system
var tunnel_system
var sky_system

# Animation sequences
var camera_sequences = []
var lighting_sequences = []
var particle_sequences = []
var reveal_sequences = []

func _ready():
	player_panel = $UI/PlayerPanel
	player_image = $UI/PlayerPanel/PlayerImage
	player_name = $UI/PlayerPanel/PlayerName
	player_ovr = $UI/PlayerPanel/PlayerOVR
	player_position = $UI/PlayerPanel/PlayerPosition
	continue_button = $UI/ContinueButton
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

	# Conectar el botÃ³n a la seÃ±al para continuar
	continue_button.connect("pressed", _on_continue_button_pressed)

	# Ocultar elementos UI al inicio
	player_panel.visible = false
	continue_button.visible = false

	# Usar el SubViewport existente
	var viewport_3d = $ViewportContainer/SubViewport
	var camera_3d = $ViewportContainer/SubViewport/Camera3D
	
	# INICIAR SECUENCIA Ã‰PICA
	start_epic_reveal_sequence(viewport_3d, camera_3d)

func create_dynamic_background():
	print("ðŸŒŒ Creando fondo dinÃ¡mico del estadio para la animaciÃ³n Ã©pica...")
	
	var sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.1, 0.1, 0.3, 1)  # Azul nocturno
	sky_material.sky_horizon_color = Color(0.2, 0.2, 0.5, 1)  # Azul oscuro
	sky.sky_material = sky_material
	environment_manager = Environment.new()
	environment_manager.sky = sky

	main_camera.environment = environment_manager

func initialize_fifa_materials():
	gold_material = StandardMaterial3D.new()
	gold_material.albedo_color = Color(1, 0.84, 0, 1)  # Dorado brillante
	gold_material.metallic = 0.9
	gold_material.roughness = 0.1
	
	chrome_material = StandardMaterial3D.new()
	chrome_material.albedo_color = Color(0.8, 0.8, 0.8, 1)  # Plateado
	chrome_material.metallic = 1.0
	chrome_material.roughness = 0.05
	
	glass_material = StandardMaterial3D.new()
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.refraction = 0.5
	glass_material.roughness = 0.05
	
	energy_material = ShaderMaterial.new()
	energy_material.shader = load("res://effects/energy_shader.shader")
	
	hologram_material = ShaderMaterial.new()
	hologram_material.shader = load("res://effects/hologram_shader.shader")
	
	card_material = StandardMaterial3D.new()
	card_material.albedo_color = Color(1, 1, 1, 1)  # Blanco bÃ¡sico

func create_stadium_background(viewport):
	print("ðŸŸï¸ Creando fondo del estadio nocturno...")
	
	var floor = MeshInstance3D.new()
	var floor_mesh = QuadMesh.new()
	floor_mesh.size = Vector2(50, 30)
	floor.mesh = floor_mesh
	floor.position = Vector3(0, 0, 0)
	var floor_material = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.1, 0.1, 0.1, 1)  # Gris oscuro
	floor.material_override = floor_material
	viewport.add_child(floor)

	# Luces del estadio
	var stadium_lights = OmniLight3D.new()
	stadium_lights.position = Vector3(0, 10, 0)
	stadium_lights.light_energy = 5.0
	viewport.add_child(stadium_lights)

func create_energy_capsule(viewport):
	"""Crear cÃ¡psula central que explota para revelar el jugador"""
	var capsule = MeshInstance3D.new()
	var capsule_mesh = CapsuleMesh.new()
	capsule_mesh.height = 4
	capsule_mesh.radius = 1
	capsule.mesh = capsule_mesh
	capsule.position = Vector3(0, 2, 0)
	var capsule_material = StandardMaterial3D.new()
	capsule_material.emission_enabled = true
	capsule_material.emission = Color(0.5, 0.5, 1, 1)
	capsule.material_override = capsule_material
	viewport.add_child(capsule)
	return capsule

func explode_capsule(viewport, capsule):
	print("ðŸ’¥ ExplosiÃ³n de la cÃ¡psula!")
	capsule.queue_free()
	# Crear efecto de explosiÃ³n
	var explosion_particles = GPUParticles3D.new()
	explosion_particles.amount = 1000
	explosion_particles.emitting = true
	explosion_particles.lifetime = 2.0
	var explosion_material = ParticleProcessMaterial.new()
	explosion_material.direction = Vector3(0, 1, 0)
	explosion_material.gravity = Vector3(0, -9.8, 0)
	explosion_material.initial_velocity_min = 5.0
	explosion_material.initial_velocity_max = 15.0
	explosion_material.scale_min = 0.5
	explosion_material.scale_max = 2.0
	# Color dorado brillante para la explosiÃ³n
	explosion_material.color = Color(1, 0.8, 0, 1)  # Dorado
	explosion_particles.process_material = explosion_material
	explosion_particles.position = Vector3(0, 2, 0)
	viewport.add_child(explosion_particles)
	
	# AÃ±adir efecto de luz brillante durante la explosiÃ³n
	var explosion_light = OmniLight3D.new()
	explosion_light.position = Vector3(0, 2, 0)
	explosion_light.light_energy = 10.0
	explosion_light.light_color = Color(1, 0.8, 0, 1)  # Dorado
	viewport.add_child(explosion_light)
	
	# Hacer que la luz se desvanezca
	var light_tween = create_tween()
	light_tween.tween_property(explosion_light, "light_energy", 0.0, 1.0)
	light_tween.tween_callback(explosion_light.queue_free)

func setup_lights(viewport):
	# Crear luces del estadio tipo FIFA
	print("ðŸ”¥ Configurando luces del estadio para la animaciÃ³n Ã©pica...")
	main_directional_light = DirectionalLight3D.new()
	main_directional_light.light_color = Color(1, 1, 0.9, 1)
	main_directional_light.light_energy = 10.0
	main_directional_light.shadow_enabled = true
	viewport.add_child(main_directional_light)
	
	for i in range(8):
		var flood_light = OmniLight3D.new()
		flood_light.position = Vector3(randf_range(-25, 25), 10, randf_range(-10, 10))
		flood_light.light_energy = 3.0
		stadium_flood_lights.append(flood_light)
		viewport.add_child(flood_light)

func setup_particles(viewport):
	# Configurar sistemas de partÃ­culas espectacularmente
	print("ðŸŽ‰ Configurando sistemas de partÃ­culas...")
	confetti_system = GPUParticles3D.new()
	confetti_system.amount = 500
	confetti_system.emitting = true
	confetti_system.lifetime = 3.0
	confetti_system.process_material = create_particle_material()
	confetti_system.position = Vector3(0, 5, 0)
	viewport.add_child(confetti_system)
	
	explosion_system = GPUParticles3D.new()
	explosion_system.amount = 1000
	explosion_system.emitting = false
	explosion_system.lifetime = 1.0
	explosion_system.process_material = create_explosion_material()
	explosion_system.position = Vector3(0, 2, 0)
	viewport.add_child(explosion_system)

func start_epic_reveal_sequence(viewport, camera):
	"""ðŸŽ¬ SECUENCIA Ã‰PICA MEJORADA - ZOOM + GIROS + EFECTOS + REVELACIÃ“N ðŸŽ¬"""
	print("ðŸŽ† Iniciando secuencia Ã©pica mejorada del estadio...")
	
	# FASE 1: Crear estadio completo
	create_spectacular_stadium(viewport)
	
	# POSICIÃ“N INICIAL DE LA CÃMARA - Vista aÃ©rea directa al centro
	camera.position = Vector3(0, 50, -100)
	camera.look_at(Vector3(0, 0, 0), Vector3.UP)
	camera.fov = 60  # Campo de visiÃ³n mÃ¡s cerrado
	
	print("ðŸŽ¬ INICIANDO SECUENCIA SIMPLIFICADA:")
	print("   â€¢ FASE 1 (0-2s): ZOOM DIRECTO hacia el centro del campo")
	print("   â€¢ FASE 2 (2-5s): GIROS sobre el campo y efectos")
	print("   â€¢ FASE 3 (5-8s): REVELACIÃ“N del jugador con imagen y botÃ³n")
	
# INICIAR SECUENCIA SIMPLIFICADA
	start_phase_1_zoom_to_center(viewport, camera)

func start_phase_1_zoom_to_center(viewport, camera):
	"""FASE 1: ZOOM DIRECTO hacia el centro del campo (0-2s)"""
	print("ðŸŽ¬ FASE 1: ZOOM DIRECTO hacia el centro del campo...")
	
	var phase1_tween = create_tween()
	
	# Configurar punto de inicio para el zoom
	var start_position = Vector3(0, 50, -100)
	var end_position = Vector3(0, 0, 0)
	
	# Animar el zoom de la cÃ¡mara hacia el centro del campo MÃS RÃPIDO
	phase1_tween.tween_property(camera, "position", end_position, 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	# CONTINUAR A FASE 2: Mostrar grid 2D con contador OVR
	phase1_tween.tween_callback(start_phase_2_ovr_grid_2d.bind(viewport, camera)).set_delay(0.0)

func start_phase_2_ovr_grid_2d(viewport, camera):
	"""FASE 2: Mostrar grid 2D (UI) con contador OVR incrementÃ¡ndose de 0 al valor real (2-5s)"""
	print("ðŸŽ¬ FASE 2: Mostrando grid 2D con contador OVR...")
	
	# Crear el grid 2D igual al del personaje pero sin botÃ³n continuar
	create_ovr_grid_2d_ui()
	
	# Mostrar el nÃºmero 0 que va subiendo al OVR del jugador
	start_ovr_counter_2d_animation()
	
	# DespuÃ©s de 3 segundos de animaciÃ³n del contador, ocultar grid y pasar a la fase 3
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.connect("timeout", finish_ovr_grid_and_continue.bind(viewport, camera))
	timer.start()

func start_phase_3_camera_spin(viewport, camera):
	"""FASE 3: Giro de cÃ¡mara 180Â° y revelaciÃ³n del jugador 3D (5-8s)"""
	print("ðŸŽ¬ FASE 3: Girando cÃ¡mara 180Â° y mostrando jugador 3D...")
	
	var phase3_tween = create_tween()
	
	# Girar la cÃ¡mara 180Â° para mostrar otra perspectiva del campo
	phase3_tween.tween_property(camera, "rotation_degrees:y", 180, 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	# AÃ±adir efectos de luz y partÃ­culas durante el giro
	create_massive_light_show(viewport)
	
	# DespuÃ©s del giro, mostrar el jugador 3D sobre el grid
	phase3_tween.tween_callback(start_phase_4_reveal_player.bind(viewport)).set_delay(0.0)

func start_phase_4_reveal_player(viewport):
	"""FASE 4: RevelaciÃ³n del modelo 3D del jugador sobre el grid (8-11s)"""
	print("ðŸŽ¬ FASE 4: Revelando modelo 3D del jugador sobre el grid...")
	
	# CREAR CONFETI Y PARTÃCULAS DE CELEBRACIÃ“N
	print("ðŸŽŠ Activando confeti de celebraciÃ³n...")
	create_celebration_confetti(viewport)
	
	# Crear modelo 3D del jugador en el centro del grid
	create_player_3d_on_grid(viewport)
	
	# DespuÃ©s de 3 segundos, mostrar la UI final
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.connect("timeout", start_reveal_animation)
	timer.start()

func start_phase_3_reveal_player(viewport):
	"""FASE 3: REVELACIÃ“N del jugador con OVR 3D primero (5-8s)"""
	print("ðŸŽ¬ FASE 3: REVELACIÃ“N con OVR 3D primero...")
	
	# CREAR CONFETI Y PARTÃCULAS DE CELEBRACIÃ“N INMEDIATAMENTE
	print("ðŸŽŠ Activando confeti de celebraciÃ³n...")
	create_celebration_confetti(viewport)
	
	# FASE 3A: Mostrar OVR 3D que sube de 0 al valor real
	start_ovr_3d_reveal(viewport)
	
	# FASE 3B: DespuÃ©s del OVR, girar y mostrar jugador 3D en campo
	var ovr_timer = Timer.new()
	add_child(ovr_timer)
	ovr_timer.wait_time = 3.0  # 3 segundos para la animaciÃ³n del OVR
	ovr_timer.one_shot = true
	ovr_timer.connect("timeout", start_player_3d_reveal.bind(viewport))
	ovr_timer.start()

func start_phase_3_lights_and_particles(viewport):
	"""FASE 3: GIROS y efectos de luz masivos (6-10s)"""
	print("ðŸŽ¬ FASE 3: GIROS y efectos de luz masivos...")
	
	var phase3_tween = create_tween()
	
	# Simular giros
	phase3_tween.tween_property(main_camera, "rotation_degrees:y", 360, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
	# AÃ±adir efectos de luz y partÃ­culas
	create_massive_light_show(viewport)

	# CONTINUAR A FASE 4
	phase3_tween.tween_callback(start_phase_4_final_explosion).set_delay(4.0)

func start_phase_4_final_explosion(viewport):
	"""FASE 4: EXPLOSIÃ“N final y revelaciÃ³n del jugador (10-15s)"""
	print("ðŸŽ¬ FASE 4: EXPLOSIÃ“N final y revelaciÃ³n del jugador...")
	
	var explosion = create_energy_capsule(viewport)
	
	# ExplosiÃ³n y revelaciÃ³n del jugador
	explode_capsule(viewport, explosion)

	# FINALIZAR ANIMACIÃ“N
	start_reveal_animation()

func create_particle_material() -> ParticleProcessMaterial:
	var material = ParticleProcessMaterial.new()
	material.gravity = Vector3(0, -1, 0)
	material.scale_min = 0.5
	material.scale_max = 2.0
	material.color = Color(1, 1, 0.5, 1)
	material.direction = Vector3(0, 1, 0)
	material.initial_velocity_min = 1.0
	material.initial_velocity_max = 3.0
	return material

func create_spectacular_stadium(viewport):
	"""Crear un estadio espectacular con iluminaciÃ³n intensa y partÃ­culas"""
	print("ðŸŒŸ Cargando Otkritie Arena...")
	
	# CREAR CIELO NOCTURNO ESPECTACULAR
	create_spectacular_sky(viewport)
	
	# CARGAR MODELO DEL ESTADIO OTKRITIE ARENA
	var stadium_path = "res://otkritie-arena/source/1.fbx"
	if ResourceLoader.exists(stadium_path):
		var stadium_scene = load(stadium_path)
		var stadium_instance = stadium_scene.instantiate()
		# Escalar y posicionar el estadio - AUMENTAR MUCHO LA ESCALA
		stadium_instance.scale = Vector3(50, 50, 50)  # Escalar 50 veces mÃ¡s grande
		stadium_instance.position = Vector3(0, -5, 0)  # Bajar un poco para que se vea bien
		viewport.add_child(stadium_instance)
		
		# APLICAR TEXTURAS AL ESTADIO
		apply_stadium_textures(stadium_instance)
		
		print("âœ… Estadio Otkritie Arena cargado exitosamente con escala x50 y texturas aplicadas")
	else:
		print("âš ï¸ No se pudo cargar el estadio, creando campo bÃ¡sico...")
		create_basic_field(viewport)

	# LUCES MASIVAS DEL ESTADIO
	create_massive_stadium_lighting(viewport)
	
	# PARTÃCULAS DE AMBIENTE
	create_ambient_particles(viewport)

func create_basic_field(viewport):
	"""Campo bÃ¡sico como respaldo"""
	# Campo de fÃºtbol
	var field = MeshInstance3D.new()
	var field_mesh = BoxMesh.new()
	field_mesh.size = Vector3(100, 0.1, 60)
	field.mesh = field_mesh
	field.position = Vector3(0, 0, 0)
	var field_material = StandardMaterial3D.new()
	field_material.albedo_color = Color(0.2, 0.8, 0.2, 1)
	field_material.emission_enabled = true
	field_material.emission = Color(0.1, 0.2, 0.1, 1)
	field.material_override = field_material
	viewport.add_child(field)

func create_massive_light_show(viewport):
	print("âœ¨ Iniciando espectÃ¡culo masivo de luces...")
	
	# MÃºltiples sistemas de partÃ­culas
	for i in range(5):
		var particles = GPUParticles3D.new()
		particles.amount = 2000
		particles.emitting = true
		particles.lifetime = 15.0
		var material = create_colorful_particle_material()
		particles.process_material = material
		particles.position = Vector3(randf_range(-20, 20), randf_range(5, 15), randf_range(-10, 10))
		viewport.add_child(particles)
	
	# Luces parpadeantes de colores
	for j in range(12):
		var spot_light = SpotLight3D.new()
		var angle = j * PI / 6
		spot_light.position = Vector3(cos(angle) * 30, 20, sin(angle) * 30)
		spot_light.look_at(Vector3(0, 0, 0), Vector3.UP)
		spot_light.light_color = Color(randf(), randf(), randf(), 1)
		spot_light.light_energy = 10.0
		spot_light.spot_range = 50
		spot_light.spot_angle = 45
		viewport.add_child(spot_light)
		
		# AnimaciÃ³n de parpadeo
		var light_tween = create_tween()
		light_tween.set_loops()
		light_tween.tween_property(spot_light, "light_energy", 15.0, 0.5)
		light_tween.tween_property(spot_light, "light_energy", 5.0, 0.5)
	
	# Luz ambiente intensa
	var ambient_light = DirectionalLight3D.new()
	ambient_light.light_color = Color(1, 1, 0.8, 1)
	ambient_light.light_energy = 3.0
	ambient_light.position = Vector3(0, 30, 0)
	viewport.add_child(ambient_light)

func create_particles_effects(viewport):
	"""Crear efectos de partÃ­culas Ã©picas"""
	print("âœ¨ Creando efectos de partÃ­culas...")
	
	# PartÃ­culas doradas (confeti)
	var particles = GPUParticles3D.new()
	particles.amount = 200
	particles.emitting = true
	particles.lifetime = 8.0
	particles.process_material = create_particle_material()
	particles.position = Vector3(0, 10, 0)
	viewport.add_child(particles)
	
	# PartÃ­culas laterales
	for side in [-8, 8]:
		var side_particles = GPUParticles3D.new()
		side_particles.amount = 100
		side_particles.emitting = true
		side_particles.lifetime = 6.0
		side_particles.process_material = create_particle_material()
		side_particles.position = Vector3(side, 5, 0)
		viewport.add_child(side_particles)

func create_lighting_effects(viewport):
	"""Crear efectos de iluminaciÃ³n Ã©picos"""
	print("ðŸ’¡ Creando iluminaciÃ³n Ã©pica...")
	
	# Luz principal dorada
	var main_light = DirectionalLight3D.new()
	main_light.position = Vector3(0, 10, 5)
	main_light.look_at(Vector3(0, 0, 0), Vector3.UP)
	main_light.light_color = Color(1, 0.9, 0.6, 1)  # Dorado
	main_light.light_energy = 2.0
	main_light.shadow_enabled = true
	viewport.add_child(main_light)
	
	# Luces de colores laterales
	var colors = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW]
	for i in range(4):
		var spot_light = SpotLight3D.new()
		var angle = i * PI / 2
		spot_light.position = Vector3(cos(angle) * 8, 6, sin(angle) * 8)
		spot_light.look_at(Vector3(0, 0, 0), Vector3.UP)
		spot_light.light_color = colors[i]
		spot_light.light_energy = 1.5
		spot_light.spot_range = 15
		spot_light.spot_angle = 30
		viewport.add_child(spot_light)

func create_explosion_material() -> ParticleProcessMaterial:
	var material = ParticleProcessMaterial.new()
	material.gravity = Vector3(0, -5, 0)
	material.scale_min = 0.2
	material.scale_max = 1.0
	material.color = Color(1, 0.8, 0, 1)  # Dorado
	material.direction = Vector3(0, 1, 0)
	material.initial_velocity_min = 5.0
	material.initial_velocity_max = 15.0
	return material

func create_colorful_particle_material() -> ParticleProcessMaterial:
	var material = ParticleProcessMaterial.new()
	material.gravity = Vector3(0, -2, 0)
	material.scale_min = 0.3
	material.scale_max = 1.5
	material.color = Color(randf(), randf(), randf(), 1)  # Colores aleatorios
	material.direction = Vector3(randf_range(-1, 1), 1, randf_range(-1, 1))
	material.initial_velocity_min = 3.0
	material.initial_velocity_max = 8.0
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	return material

func create_spectacular_sky(viewport):
	"""Crear un cielo nocturno espectacular con partÃ­culas"""
	print("ðŸŒŒ Creando cielo nocturno espectacular...")
	
	# Configurar environment con cielo brillante
	var environment = Environment.new()
	var sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	
	# Cielo nocturno brillante con gradiente
	sky_material.sky_top_color = Color(0.2, 0.1, 0.4, 1)  # PÃºrpura oscuro
	sky_material.sky_horizon_color = Color(0.8, 0.4, 0.1, 1)  # Naranja brillante
	sky_material.sky_curve = 0.3
	sky_material.ground_bottom_color = Color(0.1, 0.1, 0.2, 1)
	sky_material.ground_horizon_color = Color(0.4, 0.2, 0.1, 1)
	sky_material.ground_curve = 0.3
	
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.5
	
	# Aplicar environment a la cÃ¡mara
	if viewport.has_method("get_camera_3d"):
		var camera = viewport.get_camera_3d()
		if camera:
			camera.environment = environment
	
	# PartÃ­culas flotantes en el cielo (estrellas/luciÃ©rnagas)
	for i in range(20):
		var sky_particles = GPUParticles3D.new()
		sky_particles.amount = 500
		sky_particles.emitting = true
		sky_particles.lifetime = 20.0
		var particle_material = ParticleProcessMaterial.new()
		particle_material.gravity = Vector3(0, 0, 0)  # Sin gravedad para flotar
		particle_material.scale_min = 0.1
		particle_material.scale_max = 0.5
		particle_material.color = Color(1, 1, randf_range(0.5, 1), 1)  # Amarillo/blanco
		particle_material.direction = Vector3(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), randf_range(-0.1, 0.1))
		particle_material.initial_velocity_min = 0.5
		particle_material.initial_velocity_max = 1.5
		particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		sky_particles.process_material = particle_material
		sky_particles.position = Vector3(randf_range(-100, 100), randf_range(20, 50), randf_range(-100, 100))
		viewport.add_child(sky_particles)

func create_massive_stadium_lighting(viewport):
	"""Crear iluminaciÃ³n masiva del estadio"""
	print("ðŸ’¡ Creando iluminaciÃ³n masiva del estadio...")
	
	# Luz direccional principal sÃºper brillante
	var main_light = DirectionalLight3D.new()
	main_light.light_color = Color(1, 1, 0.9, 1)
	main_light.light_energy = 5.0  # Mucha energÃ­a
	main_light.shadow_enabled = false  # Sin sombras para mÃ¡s brillo
	main_light.position = Vector3(0, 50, 0)
	main_light.rotation_degrees = Vector3(-45, 0, 0)
	viewport.add_child(main_light)
	
	# Luces de estadio en cÃ­rculo (focos principales)
	for i in range(16):
		var angle = i * PI * 2 / 16
		var flood_light = OmniLight3D.new()
		flood_light.position = Vector3(cos(angle) * 40, 25, sin(angle) * 40)
		flood_light.light_color = Color(1, 1, 0.95, 1)
		flood_light.light_energy = 15.0  # Muy brillante
		flood_light.omni_range = 100
		viewport.add_child(flood_light)
	
	# Luces de colores parpadeantes (ambiente festivo)
	var colors = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.MAGENTA, Color.CYAN]
	for j in range(24):
		var spot_light = SpotLight3D.new()
		var angle = j * PI * 2 / 24
		spot_light.position = Vector3(cos(angle) * 60, 30, sin(angle) * 60)
		spot_light.look_at(Vector3(0, 0, 0), Vector3.UP)
		spot_light.light_color = colors[j % colors.size()]
		spot_light.light_energy = 12.0
		spot_light.spot_range = 80
		spot_light.spot_angle = 60
		viewport.add_child(spot_light)
		
		# AnimaciÃ³n de parpadeo
		var light_tween = create_tween()
		light_tween.set_loops()
		light_tween.tween_property(spot_light, "light_energy", 20.0, randf_range(0.3, 0.8))
		light_tween.tween_property(spot_light, "light_energy", 8.0, randf_range(0.3, 0.8))
	
	# Luces adicionales de relleno
	for k in range(8):
		var fill_light = OmniLight3D.new()
		fill_light.position = Vector3(randf_range(-30, 30), randf_range(10, 20), randf_range(-30, 30))
		fill_light.light_color = Color(1, 0.95, 0.9, 1)
		fill_light.light_energy = 8.0
		fill_light.omni_range = 50
		viewport.add_child(fill_light)

func create_ambient_particles(viewport):
	"""Crear partÃ­culas ambientales constantes"""
	print("âœ¨ Creando partÃ­culas ambientales...")
	
	# PartÃ­culas doradas constantes
	for i in range(10):
		var particles = GPUParticles3D.new()
		particles.amount = 1000
		particles.emitting = true
		particles.lifetime = 25.0
		var material = ParticleProcessMaterial.new()
		material.gravity = Vector3(0, -0.5, 0)  # Gravedad suave
		material.scale_min = 0.2
		material.scale_max = 1.0
		material.color = Color(1, randf_range(0.7, 1), randf_range(0.3, 0.7), 1)  # Dorado variado
		material.direction = Vector3(randf_range(-0.5, 0.5), 1, randf_range(-0.5, 0.5))
		material.initial_velocity_min = 2.0
		material.initial_velocity_max = 5.0
		material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		particles.process_material = material
		particles.position = Vector3(randf_range(-50, 50), randf_range(15, 25), randf_range(-30, 30))
		viewport.add_child(particles)

func create_celebration_confetti(viewport):
	"""Crear confeti espectacular para la revelaciÃ³n del jugador"""
	print("ðŸŽŠ Â¡ACTIVANDO CONFETI ESPECTACULAR!")
	
	# Confeti principal desde arriba - MAS VISIBLE
	for i in range(12):  # MÃ¡s sistemas de confeti
		var confetti = GPUParticles3D.new()
		confetti.amount = 1000  # MÃ¡s partÃ­culas
		confetti.emitting = true
		confetti.lifetime = 10.0  # DuraciÃ³n mÃ¡s larga
		var confetti_material = ParticleProcessMaterial.new()
		confetti_material.gravity = Vector3(0, -2.0, 0)  # CaÃ­da mÃ¡s lenta
		confetti_material.scale_min = 0.8  # MÃ¡s grandes
		confetti_material.scale_max = 2.5
		# Colores festivos y brillantes
		var colors = [
			Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, 
			Color.MAGENTA, Color.CYAN, Color.ORANGE, Color(1, 0.8, 0, 1),
			Color.WHITE, Color(1, 0.5, 0, 1), Color(0, 1, 0.5, 1), Color(0.5, 0, 1, 1)
		]
		confetti_material.color = colors[i % colors.size()]
		confetti_material.direction = Vector3(randf_range(-1.0, 1.0), 1, randf_range(-1.0, 1.0))
		confetti_material.initial_velocity_min = 5.0
		confetti_material.initial_velocity_max = 12.0
		confetti_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		confetti_material.emission_sphere_radius = 2.0
		confetti.process_material = confetti_material
		confetti.position = Vector3(randf_range(-20, 20), 25, randf_range(-20, 20))
		confetti.draw_pass_1 = QuadMesh.new()  # Usar mesh visible
		viewport.add_child(confetti)
		print("âœ¨ Confeti ", i + 1, " creado en posiciÃ³n: ", confetti.position)
	
	# ExplosiÃ³n de partÃ­culas doradas desde el centro - MÃS INTENSA
	var center_explosion = GPUParticles3D.new()
	center_explosion.amount = 1500  # MÃ¡s partÃ­culas
	center_explosion.emitting = true
	center_explosion.lifetime = 5.0
	var explosion_material = ParticleProcessMaterial.new()
	explosion_material.gravity = Vector3(0, -1.5, 0)
	explosion_material.scale_min = 1.0  # MÃ¡s grandes
	explosion_material.scale_max = 3.0
	explosion_material.color = Color(1, 0.9, 0.3, 1)  # Dorado brillante
	explosion_material.direction = Vector3(0, 1, 0)
	explosion_material.initial_velocity_min = 10.0
	explosion_material.initial_velocity_max = 20.0
	explosion_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	explosion_material.emission_sphere_radius = 1.0
	center_explosion.process_material = explosion_material
	center_explosion.position = Vector3(0, 8, 0)
	center_explosion.draw_pass_1 = SphereMesh.new()  # Usar mesh visible
	viewport.add_child(center_explosion)
	print("ðŸ’¥ ExplosiÃ³n central creada")
	
	# Luces de celebraciÃ³n parpadeantes - MÃS INTENSAS
	for j in range(10):  # MÃ¡s luces
		var celebration_light = OmniLight3D.new()
		var angle = j * PI * 2 / 10
		celebration_light.position = Vector3(cos(angle) * 12, 10, sin(angle) * 12)
		celebration_light.light_color = Color(randf(), randf(), randf(), 1)
		celebration_light.light_energy = 15.0  # MÃ¡s brillante
		celebration_light.omni_range = 25  # MÃ¡s alcance
		viewport.add_child(celebration_light)
		
		# AnimaciÃ³n de parpadeo rÃ¡pido
		var celebration_tween = create_tween()
		celebration_tween.set_loops()
		celebration_tween.tween_property(celebration_light, "light_energy", 20.0, 0.15)
		celebration_tween.tween_property(celebration_light, "light_energy", 8.0, 0.15)
	
	print("ðŸŽ‰ Â¡CONFETI ACTIVADO EXITOSAMENTE!")

func set_player_data(name, ovr, position, image, music_path = ""):
	player_data.name = name
	player_data.ovr = ovr
	player_data.position = position
	player_data.image_path = image
	
	# Asegurar que el audio_player estÃ© inicializado
	if not audio_player:
		audio_player = AudioStreamPlayer.new()
		add_child(audio_player)
	
	# Cargar y reproducir mÃºsica si estÃ¡ disponible
	if music_path != "" and ResourceLoader.exists(music_path):
		print("ðŸŽµ Cargando mÃºsica: ", music_path)
		var music = load(music_path)
		if music:
			audio_player.stream = music
			audio_player.play()
		else:
			print("âš ï¸ No se pudo cargar la mÃºsica: ", music_path)
	else:
		print("ðŸ”‡ Usando mÃºsica por defecto para este jugador: Battle! Raigo.mp3")
		var default_music_path = "res://assets/audio/Battle! Raigo.mp3"
		if ResourceLoader.exists(default_music_path):
			var default_music = load(default_music_path)
			if default_music:
				audio_player.stream = default_music
				audio_player.play()

# Empezar la animaciÃ³n
func start_reveal_animation():
	print("ðŸŽ† Iniciando revelaciÃ³n del jugador...")
	
	# Preparar datos del jugador
	if player_data.image_path != "" and ResourceLoader.exists(player_data.image_path):
		player_image.texture = load(player_data.image_path)
	else:
		print("âš ï¸ No se pudo cargar la imagen del jugador")
		
	player_name.text = player_data.name
	player_ovr.text = "OVR: " + str(player_data.ovr)
	player_position.text = player_data.position
	
	# Hacer visible el panel y aparecer con animaciÃ³n
	player_panel.visible = true
	continue_button.visible = true  # Asegurar que el botÃ³n estÃ© visible
	player_panel.modulate.a = 0
	continue_button.modulate.a = 0
	
	# Tween para aparecer elementos
	var tween = create_tween()
	tween.tween_property(player_panel, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(continue_button, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_LINEAR)

func _on_continue_button_pressed():
	# AquÃ­ se puede definir la acciÃ³n al continuar
	self.queue_free()  # Cerrar escena

func apply_stadium_textures(stadium_node: Node3D):
	"""Aplicar texturas personalizadas al modelo del estadio con orden correcto de surface material override para NUEVO JUGADOR"""
	print("ðŸŽ¨ Aplicando texturas al estadio Otkritie Arena con orden correcto para NUEVO JUGADOR...")
	
	# Cargar las texturas en el orden correcto para surface material override (0-5)
	var texture_order = [
		load("res://otkritie-arena/textures/arena_u1_v1.jpeg"),  # Surface 0
		load("res://otkritie-arena/textures/arena_u2_v1.jpeg"),  # Surface 1
		load("res://otkritie-arena/textures/arena_u3_v1.jpeg"),  # Surface 2
		load("res://otkritie-arena/textures/arena_u1_v2.jpeg"),  # Surface 3
		load("res://otkritie-arena/textures/arena_u2_v2.jpeg"),  # Surface 4
		load("res://otkritie-arena/textures/arena_u3_v2.jpeg")   # Surface 5
	]
	
	print("ðŸ“‹ Orden de texturas configurado para NUEVO JUGADOR:")
	print("   Surface 0: arena_u1_v1.jpeg")
