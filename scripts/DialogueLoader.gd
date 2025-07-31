extends Node

# DialogueLoader - Carga diálogos desde archivos JSON

func load_dialogue_from_file(file_path):
	var file = File.new()
	if file.open(file_path, File.READ) != OK:
		print("Error: No se pudo abrir el archivo ", file_path)
		return null
	
	var text = file.get_as_text()
	file.close()
	
	var json_parse_result = JSON.parse(text)
	if json_parse_result.error != OK:
		print("Error al parsear JSON en línea ", json_parse_result.error_line, ": ", json_parse_result.error_string)
		return null
	
	return json_parse_result.result

func get_chapter_dialogue(chapter_number):
	var file_path = "res://data/chapter" + str(chapter_number) + "_dialogue.json"
	return load_dialogue_from_file(file_path)

# Funciones para manejar branching narrativo
func get_dialogue_branch(base_dialogue, choice_id):
	# Buscar ramas específicas basadas en las decisiones del jugador
	var branch_file = "res://data/branches/" + choice_id + "_dialogue.json"
	var branch_data = load_dialogue_from_file(branch_file)
	
	if branch_data:
		return branch_data.dialogue
	else:
		# Si no hay rama específica, continúa con el diálogo principal
		return base_dialogue

func preload_dialogue_resources():
	# Precargar recursos comunes para mejorar rendimiento
	var common_backgrounds = [
		"res://assets/images/backgrounds/campo.webp",
		"res://assets/images/backgrounds/vestuario.webp"
	]
	
	var common_characters = [
		"res://assets/images/characters/grefg.webp",
		"res://assets/images/characters/westcol.webp",
		"res://assets/images/characters/perxitaa.webp"
	]
	
	# Precargar texturas para evitar stuttering
	for bg_path in common_backgrounds:
		if ResourceLoader.exists(bg_path):
			ResourceLoader.load(bg_path)
	
	for char_path in common_characters:
		if ResourceLoader.exists(char_path):
			ResourceLoader.load(char_path)
