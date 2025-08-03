extends Control

var player_data = {
	"name": "",
	"ovr": 0,
	"position": "",
	"image_path": ""
}

# Nodos UI
var player_panel
var player_image
var player_name_label
var player_ovr_label
var player_position_label
var continue_button
var audio_player

# Nodos 3D
var viewport_3d
var camera_3d
var stadium_node
var ovr_text_3d
var player_model_3d

func _ready():
	# Configurar nodos UI
	setup_ui()
	
	# Configurar viewport 3D
	viewport_3d = $ViewportContainer/SubViewport
	camera_3d = $ViewportContainer/SubViewport/Camera3D
	
	# Iniciar la animación épica simplificada
	start_gacha_animation()

func setup_ui():
	"""Configurar elementos de UI"""
	player_panel = $UI/PlayerPanel
	player_image = $UI/PlayerPanel/PlayerImage
	player_name_label = $UI/PlayerPanel/PlayerName
	player_ovr_label = $UI/PlayerPanel/PlayerOVR
	player_position_label = $UI/PlayerPanel/PlayerPosition
	continue_button = $UI/ContinueButton
	
	# Audio
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	# Conectar botón
	continue_button.connect("pressed", _on_continue_button_pressed)
	
	# Ocultar UI al inicio
	player_panel.visible = false
	continue_button.visible = false

func start_gacha_animation():
	"""🎬 ANIMACIÓN PRINCIPAL DEL GACHAPÓN"""
	print("🎆 Iniciando animación del gachapón...")
	
	# FASE 1: Crear estadio y configurar cámara inicial
	setup_stadium()
	setup_initial_camera()
	
	# FASE 2: Zoom hacia el centro del campo (2 segundos)
	await zoom_to_field_center()
	
	# FASE 3: Mostrar OVR 3D que sube de 0 al valor real (3 segundos)
	await show_ovr_countdown()
	
	# FASE 4: Girar cámara y mostrar grid 3D con jugador (3 segundos)
	await show_player_grid_3d()
	
	# FASE 5: Mostrar UI final
	show_final_ui()

func setup_stadium():
	"""Configurar el estadio básico"""
	print("🏟️ Configurando estadio...")
	
	# Crear campo básico
	var field = MeshInstance3D.new()
	var field_mesh = PlaneMesh.new()
	field_mesh.size = Vector2(50, 30)
	field.mesh = field_mesh
	field.position = Vector3(0, 0, 0)
	
	var field_material = StandardMaterial3D.new()
	field_material.albedo_color = Color(0.2, 0.8, 0.2, 1)  # Verde césped
	field_material.emission_enabled = true
	field_material.emission = Color(0.1, 0.3, 0.1, 1)
	field.material_override = field_material
	
	viewport_3d.add_child(field)
	stadium_node = field
	
	# Iluminación básica
	var main_light = DirectionalLight3D.new()
	main_light.light_energy = 3.0
	main_light.position = Vector3(0, 20, 10)
	main_light.rotation_degrees = Vector3(-45, 0, 0)
	viewport_3d.add_child(main_light)
	
	# Algunas luces ambientales
	for i in range(4):
		var light = OmniLight3D.new()
		var angle = i * PI / 2
		light.position = Vector3(cos(angle) * 30, 15, sin(angle) * 30)
		light.light_energy = 5.0
		light.light_color = Color(1, 1, 0.9, 1)
		viewport_3d.add_child(light)

func setup_initial_camera():
	"""Configurar posición inicial de la cámara"""
	camera_3d.position = Vector3(0, 50, -80)
	camera_3d.look_at(Vector3(0, 0, 0), Vector3.UP)
	camera_3d.fov = 60

func zoom_to_field_center():
"""FASE 2: Zoom hacia el centro del campo"""
print("🎬 FASE 2: Zoom hacia el centro del campo...")

var tween = create_tween()
var target_position = Vector3(0, 8, -15)

tween.tween_property(camera_3d, "position", target_position, 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

await tween.finished

# Mostrar el grid 2D con el contador de OVR
await show_ovr_grid_2d()

func show_ovr_grid_2d():
	"""FASE 2.5: Mostrar grid 2D con SOLO contador OVR (sin datos del jugador)"""
	print("🖼️ FASE 2.5: Mostrando grid 2D con solo contador OVR...")
	print("🔍 DEBUG: Datos del jugador - OVR:", player_data.ovr, "Nombre:", player_data.name)
	
	# Verificar que los nodos existen
	if not player_panel:
		print("❌ ERROR: player_panel es null!")
		return
	if not player_ovr_label:
		print("❌ ERROR: player_ovr_label es null!")
		return
	
	print("✅ Nodos UI encontrados correctamente")
	
	# Limpiar el panel - solo mostrar el número
	player_image.texture = null  # Sin imagen
	player_name_label.text = ""  # Sin nombre
	player_position_label.text = ""  # Sin posición
	player_ovr_label.text = "0"  # Solo el número, sin "OVR:"
	
	# Hacer el texto del OVR más grande y centrado
	player_ovr_label.add_theme_font_size_override("font_size", 72)
	player_ovr_label.add_theme_color_override("font_color", Color.YELLOW)
	
	print("🖼️ Configurando grid solo con contador OVR target: ", player_data.ovr)
	print("🔍 DEBUG: Panel position:", player_panel.position, "size:", player_panel.size)
	print("🔍 DEBUG: OVR label text:", player_ovr_label.text)
	
	# Mostrar el panel con animación de entrada
	player_panel.visible = true
	continue_button.visible = false
	player_panel.modulate.a = 1.0  # Hacer visible inmediatamente para debug
	
	print("🔍 DEBUG: Panel visible:", player_panel.visible, "modulate:", player_panel.modulate.a)
	
	# Esperar un momento para que se vea
	await get_tree().create_timer(1.0).timeout
	
	# Verificar si realmente está visible
	print("🔍 DEBUG: Después de 1s - Panel visible:", player_panel.visible, "modulate:", player_panel.modulate.a)
	
	print("🖼️ Panel visible, iniciando contador OVR...")
	
	# Animar el contador de OVR de 0 al valor real
	var target_ovr = player_data.ovr
	if target_ovr <= 0:
		print("❌ ERROR: OVR del jugador es 0 o negativo:", target_ovr)
		target_ovr = 75  # Valor por defecto para testing
	
	var count_duration = 2.5
	var delay_per_increment = count_duration / max(target_ovr, 1)  # Evitar división por 0
	
	print("🔍 DEBUG: Iniciando contador de 0 a", target_ovr, "con delay:", delay_per_increment)
	
	for i in range(target_ovr + 1):
		player_ovr_label.text = str(i)  # Solo el número
		print("🔢 Contador OVR: ", i, "- Texto actual:", player_ovr_label.text)
		
		# Efecto de pulse en el texto
		var pulse_tween = create_tween()
		pulse_tween.tween_property(player_ovr_label, "scale", Vector2(1.5, 1.5), 0.1)
		pulse_tween.tween_property(player_ovr_label, "scale", Vector2(1.0, 1.0), 0.1)
		
		# Solo esperar si no es el último número
		if i < target_ovr:
			await get_tree().create_timer(delay_per_increment).timeout
	
	print("🎉 Contador OVR completado en: ", target_ovr)
	
	# Esperar un momento para mostrar el resultado final
	await get_tree().create_timer(1.0).timeout
	
	# Ocultar el panel con animación
	var hide_tween = create_tween()
	hide_tween.tween_property(player_panel, "modulate:a", 0.0, 0.5)
	await hide_tween.finished
	player_panel.visible = false
	print("🖼️ Panel oculto, continuando con giro y grid 3D...")

func show_ovr_countdown():
	"""FASE 3: Mostrar OVR 3D que sube de 0 al valor real"""
	print("🔥 FASE 3: Mostrando contador OVR 3D...")
	
	# Crear texto 3D para el OVR
	ovr_text_3d = Label3D.new()
	ovr_text_3d.text = "0"
	ovr_text_3d.position = Vector3(0, 6, 0)
	ovr_text_3d.pixel_size = 0.02
	ovr_text_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ovr_text_3d.font_size = 200
	
	# Material dorado brillante
	var text_material = StandardMaterial3D.new()
	text_material.emission_enabled = true
	text_material.emission = Color(1, 0.8, 0, 1)
	text_material.albedo_color = Color(1, 1, 0, 1)
	ovr_text_3d.material_override = text_material
	
	viewport_3d.add_child(ovr_text_3d)
	
	# Partículas doradas alrededor del número
	create_ovr_particles()
	
	# Animar el contador de 0 al OVR real
	var target_ovr = player_data.ovr
	var count_duration = 2.5
	
	for i in range(target_ovr + 1):
		ovr_text_3d.text = str(i)
		
		# Efecto de pulse
		var pulse_tween = create_tween()
		pulse_tween.tween_property(ovr_text_3d, "scale", Vector3(1.3, 1.3, 1.3), 0.05)
		pulse_tween.tween_property(ovr_text_3d, "scale", Vector3(1.0, 1.0, 1.0), 0.05)
		
		await get_tree().create_timer(count_duration / target_ovr).timeout
	
	# Esperar un momento después del conteo
	await get_tree().create_timer(0.5).timeout

func create_ovr_particles():
	"""Crear partículas doradas alrededor del OVR"""
	var particles = GPUParticles3D.new()
	particles.amount = 300
	particles.emitting = true
	particles.lifetime = 4.0
	particles.position = Vector3(0, 6, 0)
	
	var material = ParticleProcessMaterial.new()
	material.gravity = Vector3(0, 2, 0)
	material.scale_min = 0.3
	material.scale_max = 0.8
	material.color = Color(1, 0.8, 0, 1)
	material.direction = Vector3(0, 1, 0)
	material.initial_velocity_min = 3.0
	material.initial_velocity_max = 8.0
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 2.0
	
	particles.process_material = material
	viewport_3d.add_child(particles)

func show_player_grid_3d():
	"""FASE 4: Girar cámara y mostrar grid 3D con jugador"""
	print("🎬 FASE 4: Girando cámara y mostrando grid 3D...")
	
	# Ocultar el texto del OVR
	if ovr_text_3d:
		ovr_text_3d.queue_free()
	
	# Girar la cámara hacia otra parte del campo
	var tween = create_tween()
	tween.parallel().tween_property(camera_3d, "rotation_degrees:y", 180, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(camera_3d, "position", Vector3(15, 12, 10), 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	await tween.finished
	
	# Crear el grid 3D
	create_3d_grid()
	
	# Crear modelo 3D del jugador
	create_3d_player_model()
	
	# Esperar un momento para apreciar el grid
	await get_tree().create_timer(2.0).timeout

func create_3d_grid():
	"""Crear grid 3D visible en el campo"""
	print("📏 Creando grid 3D...")
	
	var grid_color = Color(1, 1, 1, 0.8)  # Blanco semi-transparente
	var line_thickness = 0.05
	
	# Líneas verticales
	for i in range(11):
		var x = -25 + i * 5
		create_grid_line(Vector3(x, 0.2, -15), Vector3(x, 0.2, 15), line_thickness, grid_color)
	
	# Líneas horizontales
	for j in range(7):
		var z = -15 + j * 5
		create_grid_line(Vector3(-25, 0.2, z), Vector3(25, 0.2, z), line_thickness, grid_color)
	
	# Líneas de altura (verticales hacia arriba)
	for i in range(6):  # Menos líneas para no saturar
		for j in range(4):
			var x = -20 + i * 8
			var z = -10 + j * 7
			create_grid_line(Vector3(x, 0, z), Vector3(x, 10, z), line_thickness * 0.7, grid_color)

func create_grid_line(start_pos: Vector3, end_pos: Vector3, thickness: float, color: Color):
	"""Crear una línea individual del grid"""
	var line = MeshInstance3D.new()
	var line_mesh = BoxMesh.new()
	
	var distance = start_pos.distance_to(end_pos)
	line_mesh.size = Vector3(thickness, thickness, distance)
	line.mesh = line_mesh
	
	# Posicionar y orientar la línea
	line.position = (start_pos + end_pos) / 2
	line.look_at(end_pos, Vector3.UP)
	
	# Material brillante
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.5
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line.material_override = material
	
	viewport_3d.add_child(line)

func create_3d_player_model():
	"""Crear modelo 3D del jugador en el grid"""
	print("👤 Creando modelo 3D del jugador...")
	
	# Crear cuerpo del jugador
	var player_body = MeshInstance3D.new()
	var body_mesh = CapsuleMesh.new()
	body_mesh.height = 2.0
	body_mesh.radius = 0.4
	player_body.mesh = body_mesh
	player_body.position = Vector3(10, 1, 0)
	
	# Material del jugador según posición
	var player_material = StandardMaterial3D.new()
	match player_data.position:
		"Portero":
			player_material.albedo_color = Color.GREEN
		"Defensa", "Lateral":
			player_material.albedo_color = Color.BLUE
		"Centrocampista", "Mediocentro":
			player_material.albedo_color = Color.YELLOW
		_:  # Delantero
			player_material.albedo_color = Color.RED
	
	player_material.emission_enabled = true
	player_material.emission = player_material.albedo_color * 0.4
	player_body.material_override = player_material
	
	viewport_3d.add_child(player_body)
	player_model_3d = player_body
	
	# Agregar imagen del jugador flotando encima
	if player_data.image_path != "" and ResourceLoader.exists(player_data.image_path):
		create_floating_player_image(player_body)
	
	# Partículas alrededor del jugador
	create_player_particles(player_body)
	
	# Animación de entrada
	animate_player_entrance(player_body)

func create_floating_player_image(player_body: MeshInstance3D):
	"""Crear imagen flotante del jugador"""
	var image_plane = MeshInstance3D.new()
	var plane_mesh = QuadMesh.new()
	plane_mesh.size = Vector2(2.0, 2.5)
	image_plane.mesh = plane_mesh
	image_plane.position = Vector3(0, 3, 0)
	
	var image_material = StandardMaterial3D.new()
	image_material.albedo_texture = load(player_data.image_path)
	image_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	image_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	image_plane.material_override = image_material
	
	player_body.add_child(image_plane)
	
	# Rotación suave
	var rotation_tween = create_tween()
	rotation_tween.set_loops()
	rotation_tween.tween_property(image_plane, "rotation_degrees:y", 360, 6.0)

func create_player_particles(player_body: MeshInstance3D):
	"""Crear partículas alrededor del jugador"""
	var particles = GPUParticles3D.new()
	particles.amount = 150
	particles.emitting = true
	particles.lifetime = 6.0
	particles.position = Vector3(0, 1, 0)
	
	var material = ParticleProcessMaterial.new()
	material.gravity = Vector3(0, 1, 0)
	material.scale_min = 0.2
	material.scale_max = 0.6
	material.color = Color(1, 1, 1, 0.7)
	material.direction = Vector3(0, 1, 0)
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 5.0
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 1.0
	
	particles.process_material = material
	player_body.add_child(particles)

func animate_player_entrance(player_body: MeshInstance3D):
	"""Animar la entrada del jugador"""
	# Empezar pequeño y desde arriba
	player_body.scale = Vector3(0.1, 0.1, 0.1)
	player_body.position.y = 15
	
	var entrance_tween = create_tween()
	entrance_tween.parallel().tween_property(player_body, "scale", Vector3(1, 1, 1), 1.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	entrance_tween.parallel().tween_property(player_body, "position:y", 1, 1.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	# Rotación de celebración
	entrance_tween.tween_property(player_body, "rotation_degrees:y", 720, 1.0)

func show_final_ui():
	"""FASE 5: Mostrar UI final con información del jugador"""
	print("🎬 FASE 5: Mostrando UI final...")
	
	# Configurar datos del jugador en la UI
	if player_data.image_path != "" and ResourceLoader.exists(player_data.image_path):
		player_image.texture = load(player_data.image_path)
	
	player_name_label.text = player_data.name
	player_ovr_label.text = "OVR: " + str(player_data.ovr)
	player_position_label.text = player_data.position
	
	# Mostrar panel con animación
	player_panel.visible = true
	continue_button.visible = true
	player_panel.modulate.a = 0
	continue_button.modulate.a = 0
	
	var ui_tween = create_tween()
	ui_tween.tween_property(player_panel, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	ui_tween.tween_property(continue_button, "modulate:a", 1.0, 0.5)

func set_player_data(name: String, ovr: int, position: String, image_path: String, music_path: String = ""):
	"""Configurar datos del jugador"""
	player_data.name = name
	player_data.ovr = ovr
	player_data.position = position
	player_data.image_path = image_path
	
	print("🔍 DEBUG: Datos del jugador configurados:")
	print("   - Nombre:", name)
	print("   - OVR:", ovr)
	print("   - Posición:", position)
	print("   - Imagen:", image_path)
	print("   - Música:", music_path)
	
	# Cargar y reproducir música si está disponible
	if music_path != "" and ResourceLoader.exists(music_path):
		print("🎵 Cargando música: ", music_path)
		var music = load(music_path)
		if music:
			audio_player.stream = music
			audio_player.play()

func _on_continue_button_pressed():
	"""Continuar después de la revelación"""
	queue_free()
