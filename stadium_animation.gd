extends Control

# Variables para la animación del estadio
var stadium_overlay: ColorRect
var camera_3d: Camera3D
var viewport_container: SubViewportContainer
var viewport_3d: SubViewport

func _ready():
	print("🏟️ Iniciando animación del estadio...")
	
	# Conectar el botón si existe (para debug/testing)
	var go_button = get_node_or_null("UILayer/GoToStadiumButton")
	if go_button:
		go_button.pressed.connect(_on_go_to_stadium_pressed)
		go_button.visible = false  # Ocultar durante la animación
	
	create_stadium_scene()

func create_stadium_scene():
	# Crear overlay simple y visible
	stadium_overlay = ColorRect.new()
	stadium_overlay.name = "StadiumOverlay"
	stadium_overlay.color = Color(0.1, 0.5, 0.1, 1.0)  # Verde estadio
	stadium_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stadium_overlay.z_index = 1000
	self.add_child(stadium_overlay)
	
	# Crear un label de texto para mostrar la animación
	var stadium_label = Label.new()
	stadium_label.text = "🏟️ ESTADIO - ANIMACIÓN EN CURSO..."
	stadium_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stadium_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stadium_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stadium_label.add_theme_font_size_override("font_size", 48)
	stadium_label.add_theme_color_override("font_color", Color.WHITE)
	stadium_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	stadium_label.add_theme_constant_override("shadow_offset_x", 2)
	stadium_label.add_theme_constant_override("shadow_offset_y", 2)
	stadium_overlay.add_child(stadium_label)

	# Crear viewport 3D (opcional, para efectos visuales)
	create_3d_stadium_effect()

	# Iniciar la secuencia de animación
	start_stadium_animation_sequence()

func create_3d_stadium_effect():
	viewport_container = SubViewportContainer.new()
	viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_container.stretch = true
	stadium_overlay.add_child(viewport_container)

	viewport_3d = SubViewport.new()
	viewport_3d.size = Vector2i(1920, 1080)
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(viewport_3d)

	# Crear cámara 3D
	camera_3d = Camera3D.new()
	camera_3d.position = Vector3(0, 100, 200)  # Vista inicial más lejana
	camera_3d.look_at(Vector3(0, 0, 0), Vector3.UP)
	viewport_3d.add_child(camera_3d)

	# Crear campo y graderías
	create_stadium_field()
	create_stadium_stands()

func create_stadium_field():
	# Crear el campo de fútbol
	var field_mesh = MeshInstance3D.new()
	var field_box = BoxMesh.new()
	field_box.size = Vector3(100, 1, 150)  # Estadio más grande
	field_mesh.mesh = field_box
	field_mesh.position = Vector3(0, 0, 0)

	var field_material = StandardMaterial3D.new()
	field_material.albedo_color = Color(0.1, 0.7, 0.1, 1)  # Verde césped
	field_mesh.material_override = field_material
	viewport_3d.add_child(field_mesh)

	# Añadir porterías, líneas, etc.

func create_stadium_stands():
	# Crear graderías alrededor del estadio
	var stand_material = StandardMaterial3D.new()
	stand_material.albedo_color = Color(0.6, 0.6, 0.7, 1)  # Gris metálico

	for stand_side in [-120, 120]:  # Graderías a ambos lados
		for level in range(3):  # Múltiples niveles de graderías
			var stand = MeshInstance3D.new()
			var stand_box = BoxMesh.new()
			stand_box.size = Vector3(20, 10, 80)  # Tamaño de cada sección
			stand.mesh = stand_box
			stand.position = Vector3(stand_side, level * 10, 0)
			stand.material_override = stand_material
			viewport_3d.add_child(stand)

			# Añadir detalles a las graderías

func start_stadium_animation_sequence():
	print("🎬 Iniciando secuencia de animación del estadio")
	print("🔍 Debug: stadium_overlay creado: ", stadium_overlay != null)
	print("🔍 Debug: camera_3d creado: ", camera_3d != null)
	
	# Hacer el overlay visible inmediatamente para debug
	stadium_overlay.modulate.a = 1.0
	stadium_overlay.color = Color(0.1, 0.3, 0.1, 1.0)  # Verde más visible
	
	# Crear animación
	var animation_tween = create_tween()
	
	# Esperar un momento para que se vea la escena
	animation_tween.tween_interval(2.0)
	
	# Cambio de color del overlay durante la animación
	animation_tween.tween_property(stadium_overlay, "color", Color(0.2, 0.8, 0.2, 1.0), 2.0).set_trans(Tween.TRANS_SINE)
	
	# Movimiento de cámara épico
	animation_tween.parallel().tween_property(camera_3d, "position", Vector3(0, 20, 50), 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Rotación suave de la cámara
	animation_tween.parallel().tween_method(rotate_camera, 0.0, 360.0, 3.0).set_trans(Tween.TRANS_SINE)
	
	# Al finalizar la animación, ir al partido
	animation_tween.tween_callback(transition_to_match)
	
	print("🎬 Animación configurada, duración total: ~8 segundos")

func rotate_camera(degrees: float):
	if camera_3d:
		camera_3d.rotation_degrees.y = degrees * 0.1  # Rotación suave

func transition_to_match():
	print("🏟️ Animación del estadio completada, transicionando al partido...")
	
	# Buscar la escena de partido disponible
	if ResourceLoader.exists("res://scenes/MatchDialogueScene.tscn"):
		print("🎯 Cargando MatchDialogueScene.tscn")
		get_tree().change_scene_to_file("res://scenes/MatchDialogueScene.tscn")
	elif ResourceLoader.exists("res://scenes/TrainingDialogueScene.tscn"):
		print("🎯 Cargando TrainingDialogueScene.tscn como fallback")
		get_tree().change_scene_to_file("res://scenes/TrainingDialogueScene.tscn")
	else:
		print("⚠️ No se encontró escena de partido, simulando directamente")
		simulate_and_return_to_tournament()

func simulate_and_return_to_tournament():
	# Simular partido rápido y volver al torneo
	print("🎲 Simulando partido...")
	
	# Obtener datos del partido
	var lineup_data = LineupManager.get_saved_lineup()
	var player_ids = []
	if lineup_data != null:
		for pos_name in lineup_data.players:
			var player_info = lineup_data.players[pos_name]
			player_ids.append(player_info.id)
	
	# Generar resultado aleatorio
	var home_goals = randi() % 4
	var away_goals = randi() % 4
	print("📊 Resultado: ", home_goals, "-", away_goals)
	
	# Actualizar datos del juego
	PlayersManager.update_stamina_after_match(player_ids)
	LeagueManager.complete_match(home_goals, away_goals)
	TrainingManager.reset_training_after_match()
	DayManager.advance_day()
	
	# Volver al torneo
	get_tree().change_scene_to_file("res://scenes/TournamentMenu.tscn")

func _on_go_to_stadium_pressed():
	print("🎯 Botón IR AL CAMPO presionado (debug/testing)")
	transition_to_match()
