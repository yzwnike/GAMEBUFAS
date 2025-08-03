extends Control

# Escena de diálogo post-entrenamiento con diálogos dinámicos
# Carga jugadores aleatorios y ejecuta la novela visual

var dialogue_system

func _ready():
	print("PostTrainingDialogueScene: INICIO DE _ready()")
	
	# Esperar un frame para asegurar que todo esté cargado
	await get_tree().process_frame
	
	# Configurar el diálogo directamente sin tantas verificaciones
	setup_dialogue_directly()

func setup_dialogue_directly():
	# Inicializar dialogue_system
	dialogue_system = get_node_or_null("DialogueSystem")
	print("PostTrainingDialogueScene: Buscando DialogueSystem... encontrado: ", dialogue_system != null)
	
	# Cargar el archivo de diálogo post-entrenamiento específico del rival actual
	var dialogue_file = get_post_training_dialogue_path()
	print("PostTrainingDialogueScene: Cargando diálogo post-entrenamiento: ", dialogue_file)

	# Cargar y parsear el archivo JSON
	var dialogue_data = []
	var file = FileAccess.open(dialogue_file, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			dialogue_data = json.data
			print("PostTrainingDialogueScene: Diálogo cargado exitosamente")
		else:
			print("ERROR: Error al parsear archivo JSON")

	# Verificar métodos disponibles en dialogue_system
	if dialogue_system:
		print("PostTrainingDialogueScene: dialogue_system encontrado. Tipo: ", dialogue_system.get_class())
		print("PostTrainingDialogueScene: Script asignado: ", dialogue_system.get_script())
		
		# Verificar si tiene el script correcto
		var script_path = dialogue_system.get_script().resource_path if dialogue_system.get_script() else "NONE"
		print("PostTrainingDialogueScene: Script path: ", script_path)
		
		# Si no tiene script, intentar asignarlo manualmente
		if not dialogue_system.get_script():
			print("PostTrainingDialogueScene: Intentando cargar script manualmente...")
			var dialogue_script = load("res://scripts/DialogueSystem.gd")
			dialogue_system.set_script(dialogue_script)
			print("PostTrainingDialogueScene: Script asignado manualmente")
		
		# Forzar inicialización del DialogueSystem
		print("PostTrainingDialogueScene: Forzando inicialización del DialogueSystem...")
		if dialogue_system.has_method("_ready"):
			dialogue_system._ready()
			print("PostTrainingDialogueScene: _ready() del DialogueSystem ejecutado")
		
		# Esperar un frame para que se complete la inicialización
		await get_tree().process_frame
		
		# Ahora intentar usar el método load_dialogue
		if dialogue_system.has_method("load_dialogue"):
			print("PostTrainingDialogueScene: Método load_dialogue encontrado, iniciando diálogo...")
			
			# IMPORTANTE: Seleccionar jugadores aleatorios ANTES de cargar el diálogo
			print("PostTrainingDialogueScene: Seleccionando jugadores aleatorios...")
			if dialogue_system.has_method("select_random_players"):
				dialogue_system.select_random_players()
				print("PostTrainingDialogueScene: Jugadores aleatorios seleccionados exitosamente")
			else:
				print("ERROR: No se pudo encontrar el método select_random_players")
			
			# Conectar señal de fin de diálogo
			print("PostTrainingDialogueScene: Conectando señal dialogue_finished...")
			if dialogue_system.has_signal("dialogue_finished"):
				dialogue_system.dialogue_finished.connect(_on_dialogue_finished)
				print("PostTrainingDialogueScene: Señal conectada exitosamente")
			else:
				print("ERROR: Señal dialogue_finished no encontrada")
			
			# Cargar el diálogo
			print("PostTrainingDialogueScene: Cargando diálogo con ", dialogue_data.size(), " líneas...")
			dialogue_system.load_dialogue(dialogue_data)
			print("PostTrainingDialogueScene: Diálogo iniciado exitosamente")
		else:
			print("ERROR: Método load_dialogue aún no disponible después de _ready()")
	else:
		print("ERROR: dialogue_system no está disponible")

func _on_dialogue_finished():
	print("PostTrainingDialogueScene: Diálogo terminado, completando entrenamiento...")
	
	# Completar el entrenamiento y otorgar experiencia
	complete_training_success()
	
	# La transición de día se encargará de la redirección al InteractiveMenu

func complete_training_success():
	print("PostTrainingDialogueScene: Completando entrenamiento con éxito...")
	
	# Otorgar experiencia a los jugadores
	var players_manager = get_node("/root/PlayersManager")
	if players_manager != null:
		players_manager.add_experience_after_training()
		print("¡Entrenamiento completado! Todos los jugadores ganaron 2 puntos de experiencia.")
	
	# Marcar el entrenamiento como completado
	if TrainingManager:
		TrainingManager.complete_training()
		print("PostTrainingDialogueScene: Entrenamiento marcado como completado")
	
	# Avanzar el día después de completar el entrenamiento con origen training
	if DayManager:
		DayManager.advance_day_with_origin("training")
		print("PostTrainingDialogueScene: Día avanzado después del entrenamiento")

# Función para manejar la tecla ESC (saltar diálogo)
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_dialogue_finished()

# Función para obtener la ruta del diálogo post-entrenamiento del rival actual
func get_post_training_dialogue_path() -> String:
	if RivalTeamsManager:
		var post_training_path = RivalTeamsManager.get_post_training_dialogue_path()
		if post_training_path != "" and ResourceLoader.exists(post_training_path):
			print("PostTrainingDialogueScene: Usando diálogo específico del rival: ", post_training_path)
			return post_training_path
	
	# Fallback al diálogo genérico si no existe el específico
	var fallback_path = "res://data/training_dialogues/post_training_dialogue.json"
	print("PostTrainingDialogueScene: Usando diálogo genérico como fallback: ", fallback_path)
	return fallback_path

# DEBUG: Función para mostrar la estructura de nodos
func _print_node_structure(node: Node, depth: int):
	var indent = ""
	for i in range(depth):
		indent += "  "
	print(indent + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		_print_node_structure(child, depth + 1)
