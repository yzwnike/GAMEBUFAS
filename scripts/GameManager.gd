extends Node

# GameManager - Controlador principal del juego
# Maneja las transiciones entre la novela visual y la simulación de fútbol

signal money_updated(new_amount: int)
signal tickets_updated(new_amount: int)
signal inventory_updated()

var current_scene_path = ""
var previous_scene_path = ""

# Sistema de dinero e inventario
var money: int = 22000  # Dinero inicial + 20k para testing
var tickets_bufas: int = 3  # Tickets Bufas iniciales para debug
var inventory: Dictionary = {} # {item_id: quantity}

# Estados del juego
enum GameState {
	MAIN_MENU,
	VISUAL_NOVEL,
	TEAM_MANAGEMENT,
	MATCH_SIMULATION,
	PAUSE_MENU
}

var current_state = GameState.MAIN_MENU

# Variables de progreso del juego
var story_progress = {}
var team_stats = {
	"wins": 0,
	"losses": 0,
	"draws": 0,
	"goals_for": 0,
	"goals_against": 0
}

# Configuración del equipo FC Bufas
var team_formation = "4-3-3"
var starting_eleven = []
var team_chemistry = 50.0

# Sistema de guardado
var save_file_path = "user://savegame.json"

# Sistema de diálogos dinámicos
var current_dialogue_data = []

signal scene_changed
signal game_state_changed

func _ready():
	print("=== GameManager._ready() ejecutado ===")
	# MODO DEBUG: Puedes cambiar estas configuraciones para probar diferentes partes del juego
	
	# OPCIÓN 1: Debug del partido 3vs3 (comentar las otras opciones)
	# set_story_flag("chapter1_completed", true)
	# set_story_flag("ready_for_3v3_match", true)
	# set_story_flag("rival_team", "perma pablo javo")
	
	# OPCIÓN 2: Debug directo al capítulo 2 + partido 7vs7
	# set_story_flag("chapter1_completed", true)
	# set_story_flag("load_chapter_2", true) # Ir directamente al capítulo 2
	# OPCIÓN 3: Debug del último diálogo del prólogo (ACTIVO)
	print("Configurando flags de debug para diálogo post-partido 7vs7...")
	set_story_flag("chapter1_completed", true)
	set_story_flag("chapter_2_7v7", true)
	set_story_flag("post_match_branch", "win_7v7") # Puedes cambiar a "loss_7v7" si quieres ver la rama de derrota
	print("Flag post_match_branch configurado a: ", get_story_flag("post_match_branch"))
	
	# Cargar progreso del juego si existe
	# load_game()  # Comentado para debug
	
	# Conectar señales (si es necesario)
	# get_tree().tree_changed.connect(_on_tree_changed)

func change_scene(scene_path):
	previous_scene_path = current_scene_path
	current_scene_path = scene_path
	
	# Efecto de transición
	transition_to_scene(scene_path)

func transition_to_scene(scene_path):
	# Crear efecto de fade out/in
	var transition = create_transition_overlay()
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(transition, "modulate:a", 1.0, 0.5)
	await tween.finished
	
	# Cambiar escena
	get_tree().change_scene_to_file(scene_path)
	
	# La transición de fade in se manejará en la nueva escena
	emit_signal("scene_changed")

func create_transition_overlay():
	var overlay = ColorRect.new()
	overlay.color = Color.BLACK
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.modulate.a = 0.0
	get_tree().current_scene.add_child(overlay)
	return overlay

func set_game_state(new_state):
	current_state = new_state
	emit_signal("game_state_changed", new_state)

# Sistema de guardado y carga
func save_game():
	var save_data = {
		"story_progress": story_progress,
		"team_stats": team_stats,
		"team_formation": team_formation,
		"starting_eleven": starting_eleven,
		"team_chemistry": team_chemistry,
		"current_scene": current_scene_path
	}
	
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Juego guardado correctamente")
	else:
		print("Error al guardar el juego")

func load_game():
	var file = FileAccess.open(save_file_path, FileAccess.READ)
	if file:
		var save_data_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(save_data_text)
		if parse_result == OK:
			var save_data = json.data
			story_progress = save_data.get("story_progress", {})
			team_stats = save_data.get("team_stats", team_stats)
			team_formation = save_data.get("team_formation", "4-3-3")
			starting_eleven = save_data.get("starting_eleven", [])
			team_chemistry = save_data.get("team_chemistry", 50.0)
			print("Juego cargado correctamente")
		else:
			print("Error al parsear el archivo de guardado")
	else:
		print("No se encontró archivo de guardado previo")

# Funciones para el progreso de la historia
func set_story_flag(flag_name, value):
	story_progress[flag_name] = value

func get_story_flag(flag_name, default_value = false):
	return story_progress.get(flag_name, default_value)

# Funciones para estadísticas del equipo
func add_match_result(goals_for, goals_against):
	team_stats.goals_for += goals_for
	team_stats.goals_against += goals_against
	
	if goals_for > goals_against:
		team_stats.wins += 1
	elif goals_for < goals_against:
		team_stats.losses += 1
	else:
		team_stats.draws += 1
	
	# Guardar automáticamente después de cada partido
	save_game()

func get_win_percentage():
	var total_matches = team_stats.wins + team_stats.losses + team_stats.draws
	if total_matches == 0:
		return 0.0
	return float(team_stats.wins) / float(total_matches) * 100.0

# Funciones para la gestión del equipo
func set_formation(formation):
	team_formation = formation
	# Recalcular química del equipo basado en la formación
	calculate_team_chemistry()

func calculate_team_chemistry():
	# Lógica básica para calcular la química del equipo
	# Se puede expandir con más factores
	team_chemistry = 50.0  # Base
	
	# Bonus por partidos ganados
	team_chemistry += min(team_stats.wins * 2, 30)
	
	# Penalty por partidos perdidos
	team_chemistry -= min(team_stats.losses * 1, 20)
	
	# Mantener entre 0 y 100
	team_chemistry = clamp(team_chemistry, 0.0, 100.0)

func _on_tree_changed():
	# Función llamada cuando cambia la estructura del árbol de nodos
	pass

# Funciones para diálogos dinámicos
func load_post_match_dialogue():
	var branch = get_story_flag("post_match_branch", "loss")
	var dialogue_file_path = "res://data/post_match_dialogue.json"
	
	var file = FileAccess.open(dialogue_file_path, FileAccess.READ)
	if not file:
		print("Error: No se pudo cargar el archivo de diálogo post-partido")
		return []
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("Error al parsear el JSON de diálogo post-partido")
		return []
	
	var dialogue_data = json.data
	var branch_key = branch + "_branch"
	
	if dialogue_data.has(branch_key):
		current_dialogue_data = dialogue_data[branch_key]
		print("Diálogo post-partido cargado: rama ", branch)
		return current_dialogue_data
	else:
		print("Error: No se encontró la rama de diálogo ", branch_key)
		return []

func get_current_dialogue_data():
	return current_dialogue_data

func clear_dialogue_data():
	current_dialogue_data = []

func load_chapter_dialogue(chapter_number: int):
	var dialogue_file_path = "res://data/chapter" + str(chapter_number) + "_dialogue.json"
	
	var file = FileAccess.open(dialogue_file_path, FileAccess.READ)
	if not file:
		print("Error: No se pudo cargar el archivo de diálogo del capítulo ", chapter_number)
		return []
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("Error al parsear el JSON del capítulo ", chapter_number)
		return []
	
	var dialogue_data = json.data
	
	if dialogue_data.has("dialogue"):
		current_dialogue_data = dialogue_data["dialogue"]
		print("Capítulo ", chapter_number, " cargado: ", dialogue_data.get("title", "Sin título"))
		return current_dialogue_data
	else:
		print("Error: No se encontró diálogo en el capítulo ", chapter_number)
		return []

func quit_game():
	save_game()
	get_tree().quit()

# Funciones de tickets Bufas
func get_tickets_bufas() -> int:
	return tickets_bufas

func add_tickets_bufas(amount: int):
	tickets_bufas += amount
	tickets_updated.emit(tickets_bufas)
	print("GameManager: Tickets Bufas actualizados - ", tickets_bufas)

func spend_tickets_bufas(amount: int) -> bool:
	if tickets_bufas >= amount:
		tickets_bufas -= amount
		tickets_updated.emit(tickets_bufas)
		print("GameManager: Tickets Bufas gastados - ", amount, ". Tickets Bufas restantes: ", tickets_bufas)
		return true
	else:
		print("GameManager: No hay suficientes Tickets Bufas para gastar ", amount)
		return false

func can_afford_tickets(amount: int) -> bool:
	return tickets_bufas >= amount

# Funciones de dinero e inventario
func get_money() -> int:
	return money

func add_money(amount: int):
	money += amount
	money_updated.emit(money)
	print("GameManager: Dinero actualizado - ", money)

func spend_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		money_updated.emit(money)
		print("GameManager: Dinero gastado - ", amount, ". Dinero restante: ", money)
		return true
	else:
		print("GameManager: No hay suficiente dinero para gastar ", amount)
		return false

func can_afford(amount: int) -> bool:
	return money >= amount

func get_inventory() -> Dictionary:
	return inventory

func add_item_to_inventory(item_id: String, quantity: int):
	if inventory.has(item_id):
		inventory[item_id] += quantity
	else:
		inventory[item_id] = quantity
	
	inventory_updated.emit()
	print("GameManager: Inventario actualizado - ", inventory)
