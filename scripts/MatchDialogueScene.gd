extends Control

# Escena de partido con diálogos dinámicos
# Carga jugadores aleatorios y ejecuta la novela visual

var dialogue_system

var current_opponent = ""

func _ready():
	print("MatchDialogueScene: INICIO DE _ready()")
	
	# Esperar un frame para asegurar que todo esté cargado
	await get_tree().process_frame
	
	# Configurar el diálogo directamente sin tantas verificaciones
	setup_dialogue_directly()

func setup_dialogue_directly():
	# Inicializar dialogue_system
	dialogue_system = get_node_or_null("DialogueSystem")
	print("MatchDialogueScene: Buscando DialogueSystem... encontrado: ", dialogue_system != null)
	
	# Obtener el oponente actual del TrainingManager
	current_opponent = TrainingManager.get_current_opponent()
	print("MatchDialogueScene: Oponente actual: ", current_opponent)
	
	# Mapear nombres de equipos a archivos de diálogo
	var dialogue_files = {
		"Deportivo Magadios": "res://data/match_dialogues/vs_deportivo_magadios.json",
		"Patrulla Canina": "res://data/match_dialogues/vs_patrulla_canina.json",
		"Reyes de Jalisco": "res://data/match_dialogues/vs_reyes_jalisco.json",
		"Inter de Panzones": "res://data/match_dialogues/vs_inter_panzones.json",
		"Chocolateros FC": "res://data/match_dialogues/vs_chocolateros_fc.json",
		"Fantasy FC": "res://data/match_dialogues/vs_fantasy_fc.json",
		"Picacachorras FC": "res://data/match_dialogues/vs_picacachorras_fc.json"
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
			print("MatchDialogueScene: Diálogo cargado exitosamente")
		else:
			print("ERROR: Error al parsear archivo JSON")

	# Verificar métodos disponibles en dialogue_system
	if dialogue_system:
		print("MatchDialogueScene: dialogue_system encontrado. Tipo: ", dialogue_system.get_class())
		print("MatchDialogueScene: Script asignado: ", dialogue_system.get_script())
		
		# Verificar si tiene el script correcto
		var script_path = dialogue_system.get_script().resource_path if dialogue_system.get_script() else "NONE"
		print("MatchDialogueScene: Script path: ", script_path)
		
		# Si no tiene script, intentar asignarlo manualmente
		if not dialogue_system.get_script():
			print("MatchDialogueScene: Intentando cargar script manualmente...")
			var dialogue_script = load("res://scripts/DialogueSystem.gd")
			dialogue_system.set_script(dialogue_script)
			print("MatchDialogueScene: Script asignado manualmente")
		
		# Forzar inicialización del DialogueSystem
		print("MatchDialogueScene: Forzando inicialización del DialogueSystem...")
		if dialogue_system.has_method("_ready"):
			dialogue_system._ready()
			print("MatchDialogueScene: _ready() del DialogueSystem ejecutado")
		
		# Esperar un frame para que se complete la inicialización
		await get_tree().process_frame
		
		# Ahora intentar usar el método load_dialogue
		if dialogue_system.has_method("load_dialogue"):
			print("MatchDialogueScene: Método load_dialogue encontrado, iniciando diálogo...")
			
			# IMPORTANTE: Seleccionar jugadores aleatorios ANTES de cargar el diálogo
			print("MatchDialogueScene: Seleccionando jugadores aleatorios...")
			if dialogue_system.has_method("select_random_players"):
				dialogue_system.select_random_players()
				print("MatchDialogueScene: Jugadores aleatorios seleccionados exitosamente")
			else:
				print("ERROR: No se pudo encontrar el método select_random_players")
			
			# Conectar señal de fin de diálogo
			print("MatchDialogueScene: Conectando señal dialogue_finished...")
			if dialogue_system.has_signal("dialogue_finished"):
				dialogue_system.dialogue_finished.connect(_on_dialogue_finished)
				print("MatchDialogueScene: Señal conectada exitosamente")
			else:
				print("ERROR: Señal dialogue_finished no encontrada")
			
			# Cargar el diálogo
			print("MatchDialogueScene: Cargando diálogo con ", dialogue_data.size(), " líneas...")
			dialogue_system.load_dialogue(dialogue_data)
			print("MatchDialogueScene: Diálogo iniciado exitosamente")
		else:
			print("ERROR: Método load_dialogue aún no disponible después de _ready()")
	else:
		print("ERROR: dialogue_system no está disponible")

func _on_dialogue_finished():
	print("MatchDialogueScene: Diálogo terminado, iniciando simulador de partido...")
	
	# Generar automáticamente una alineación válida para eventos dinámicos
	generate_automatic_lineup()
	
	# Configurar el tipo de partido y el rival para el simulador
	GameManager.set_story_flag("match_type", "dynamic")
	GameManager.set_story_flag("rival_team", current_opponent)
	
	# Ir al simulador dinámico en lugar del simulador normal
	get_tree().change_scene_to_file("res://scenes/DynamicFootballSimulator.tscn")

func generate_automatic_lineup():
	print("MatchDialogueScene: Generando alineación automática...")
	
	# Obtener todos los jugadores disponibles
	if not PlayersManager:
		print("ERROR: PlayersManager no disponible")
		return
	
	var all_players = PlayersManager.get_all_players()
	if all_players.size() < 7:
		print("ERROR: No hay suficientes jugadores (", all_players.size(), ") para formar una alineación")
		return
	
	# Crear una alineación automática con los primeros 7 jugadores
	var lineup_players = {}
	var positions = ["GK", "DEF1", "DEF2", "DEF3", "MID1", "MID2", "ATT1"]
	
	for i in range(min(7, all_players.size())):
		var player = all_players[i]
		var position_key = positions[i]
		
		# Crear una copia de los datos del jugador
		lineup_players[position_key] = {
			"id": player.id,
			"name": player.name,
			"position": player.position,
			"overall": player.overall,
			# Añadir todas las estadísticas necesarias para el simulador
			"shooting": player.get("shooting", 50),
			"heading": player.get("heading", 50),
			"short_pass": player.get("short_pass", 50),
			"long_pass": player.get("long_pass", 50),
			"dribbling": player.get("dribbling", 50),
			"speed": player.get("speed", 50),
			"marking": player.get("marking", 50),
			"tackling": player.get("tackling", 50),
			"reflexes": player.get("reflexes", 50),
			"positioning": player.get("positioning", 50),
			"concentration": player.get("concentration", 50)
		}
		
		print("MatchDialogueScene: Jugador agregado a alineación - ", player.name, " (", player.position, ")")
	
	# Guardar la alineación en LineupManager
	if LineupManager:
		LineupManager.save_lineup("3-2-1", lineup_players)
		print("MatchDialogueScene: Alineación automática guardada exitosamente")
	else:
		print("ERROR: LineupManager no disponible")

# Función para manejar las teclas ESC y F (saltar diálogo)
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_dialogue_finished()
	
	# Saltar diálogo con la tecla F
	if event.is_action_pressed("ui_skip") or (event is InputEventKey and event.keycode == KEY_F and event.pressed):
		if dialogue_system and dialogue_system.has_method("skip_entire_dialogue"):
			print("MatchDialogueScene: SALTANDO TODO EL DIÁLOGO con tecla F")
			dialogue_system.skip_entire_dialogue()
		else:
			# Si no hay método de salto, finalizar directamente
			print("MatchDialogueScene: Finalizando diálogo directamente (sin método skip)")
			_on_dialogue_finished()

# DEBUG: Función para mostrar la estructura de nodos
func _print_node_structure(node: Node, depth: int):
	var indent = ""
	for i in range(depth):
		indent += "  "
	print(indent + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		_print_node_structure(child, depth + 1)
