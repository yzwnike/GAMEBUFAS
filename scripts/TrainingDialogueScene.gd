extends Control

# Escena de entrenamiento con diálogos dinámicos
# Carga jugadores aleatorios y ejecuta la novela visual

var dialogue_system

var current_opponent = ""

func _ready():
	print("TrainingDialogueScene: INICIO DE _ready()")
	
	# Esperar un frame para asegurar que todo esté cargado
	await get_tree().process_frame
	
	# Configurar el diálogo directamente sin tantas verificaciones
	setup_dialogue_directly()

func setup_dialogue_directly():
	# Inicializar dialogue_system
	dialogue_system = get_node_or_null("DialogueSystem")
	print("TrainingDialogueScene: Buscando DialogueSystem... encontrado: ", dialogue_system != null)
	
	# Obtener el oponente actual del TrainingManager
	current_opponent = TrainingManager.get_current_opponent()
	print("TrainingDialogueScene: Oponente actual: ", current_opponent)
	
	# Mapear nombres de equipos a archivos de diálogo
	var dialogue_files = {
		"Deportivo Magadios": "res://data/training_dialogues/vs_deportivo_magadios.json"
	}
	
	var dialogue_file = dialogue_files.get(current_opponent, "")
	if dialogue_file == "":
		print("ERROR: No se encontró diálogo para el oponente: ", current_opponent)
		return

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
			print("TrainingDialogueScene: Diálogo cargado exitosamente")
		else:
			print("ERROR: Error al parsear archivo JSON")

	# Verificar métodos disponibles en dialogue_system
	if dialogue_system:
		print("TrainingDialogueScene: dialogue_system encontrado. Tipo: ", dialogue_system.get_class())
		print("TrainingDialogueScene: Script asignado: ", dialogue_system.get_script())
		
		# Verificar si tiene el script correcto
		var script_path = dialogue_system.get_script().resource_path if dialogue_system.get_script() else "NONE"
		print("TrainingDialogueScene: Script path: ", script_path)
		
		# Si no tiene script, intentar asignarlo manualmente
		if not dialogue_system.get_script():
			print("TrainingDialogueScene: Intentando cargar script manualmente...")
			var dialogue_script = load("res://scripts/DialogueSystem.gd")
			dialogue_system.set_script(dialogue_script)
			print("TrainingDialogueScene: Script asignado manualmente")
		
		# Forzar inicialización del DialogueSystem
		print("TrainingDialogueScene: Forzando inicialización del DialogueSystem...")
		if dialogue_system.has_method("_ready"):
			dialogue_system._ready()
			print("TrainingDialogueScene: _ready() del DialogueSystem ejecutado")
		
		# Esperar un frame para que se complete la inicialización
		await get_tree().process_frame
		
		# Ahora intentar usar el método load_dialogue
		if dialogue_system.has_method("load_dialogue"):
			print("TrainingDialogueScene: Método load_dialogue encontrado, iniciando diálogo...")
			
			# IMPORTANTE: Seleccionar jugadores aleatorios ANTES de cargar el diálogo
			print("TrainingDialogueScene: Seleccionando jugadores aleatorios...")
			if dialogue_system.has_method("select_random_players"):
				dialogue_system.select_random_players()
				print("TrainingDialogueScene: Jugadores aleatorios seleccionados exitosamente")
			else:
				print("ERROR: No se pudo encontrar el método select_random_players")
			
			# Conectar señal de fin de diálogo
			print("TrainingDialogueScene: Conectando señal dialogue_finished...")
			if dialogue_system.has_signal("dialogue_finished"):
				dialogue_system.dialogue_finished.connect(_on_dialogue_finished)
				print("TrainingDialogueScene: Señal conectada exitosamente")
			else:
				print("ERROR: Señal dialogue_finished no encontrada")
			
			# Cargar el diálogo
			print("TrainingDialogueScene: Cargando diálogo con ", dialogue_data.size(), " líneas...")
			dialogue_system.load_dialogue(dialogue_data)
			print("TrainingDialogueScene: Diálogo iniciado exitosamente")
		else:
			print("ERROR: Método load_dialogue aún no disponible después de _ready()")
	else:
		print("ERROR: dialogue_system no está disponible")

func _on_dialogue_finished():
	print("TrainingDialogueScene: Diálogo terminado, iniciando minijuego de marcaje...")
	
	# Ir al minijuego de marcaje en lugar de completar directamente
	get_tree().change_scene_to_file("res://scenes/MarkingMiniGame.tscn")

# Función para manejar la tecla ESC (saltar diálogo)
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_dialogue_finished()

# DEBUG: Función para mostrar la estructura de nodos
func _print_node_structure(node: Node, depth: int):
	var indent = ""
	for i in range(depth):
		indent += "  "
	print(indent + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		_print_node_structure(child, depth + 1)
