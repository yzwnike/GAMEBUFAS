extends "res://scripts/DialogueSystem.gd"

# Chapter1Scene - Maneja específicamente el primer capítulo

var dialogue_loader

func _ready():
	# Llamar al _ready del padre
	._ready()
	
	# Crear el loader de diálogos
	dialogue_loader = preload("res://scripts/DialogueLoader.gd").new()
	add_child(dialogue_loader)
	
	# Conectar señales
	connect("dialogue_finished", self, "_on_dialogue_finished")
	connect("choice_made", self, "_on_choice_made")
	
	# Cargar y comenzar el primer capítulo
	start_chapter()

func start_chapter():
	# Cargar datos del capítulo 1
	var chapter_data = dialogue_loader.get_chapter_dialogue(1)
	
	if chapter_data and chapter_data.has("dialogue"):
		# Actualizar backgrounds disponibles con las rutas correctas
		backgrounds["campo"] = "res://assets/images/backgrounds/campo.png"
		backgrounds["campovertical"] = "res://assets/images/backgrounds/campovertical.png"
		
		# Cargar el diálogo
		load_dialogue(chapter_data.dialogue)
	else:
		print("Error: No se pudo cargar el capítulo 1")
		# Diálogo de fallback
		var fallback_dialogue = [
			{
				"character": "narrator",
				"text": "¡Bienvenido a La Velada Visual Novel!",
				"background": "campo"
			},
			{
				"character": "grefg", 
				"text": "¡Este es solo el comienzo de una gran aventura!"
			}
		]
		load_dialogue(fallback_dialogue)

func show_character(character_name):
	var character_path = "res://assets/images/characters/" + character_name + ".webp"
	if ResourceLoader.exists(character_path):
		character_sprite.texture = load(character_path)
		character_sprite.visible = true
		
		# Animación de entrada del personaje
		var tween = Tween.new()
		add_child(tween)
		character_sprite.modulate.a = 0.0
		tween.interpolate_property(character_sprite, "modulate:a", 0.0, 1.0, 0.5)
		tween.start()
		yield(tween, "tween_completed")
		tween.queue_free()
	else:
		hide_character()
		print("Advertencia: No se encontró la imagen del personaje: ", character_name)

func _on_dialogue_finished():
	print("Capítulo 1 completado!")
	# Guardar progreso
	if GameManager:
		GameManager.set_story_flag("chapter1_completed", true)
		GameManager.save_game()
	
	# Transición al siguiente capítulo o menú de gestión de equipo
	transition_to_next_scene()

func _on_choice_made(choice_id):
	print("Elección hecha: ", choice_id)
	
	# Manejar las decisiones específicas del capítulo 1
	match choice_id:
		"strategy_focus":
			if GameManager:
				GameManager.set_story_flag("team_strategy", "tactical")
				GameManager.team_chemistry += 5
			print("Enfoque táctico seleccionado")
			
		"chemistry_focus":
			if GameManager:
				GameManager.set_story_flag("team_strategy", "chemistry")
				GameManager.team_chemistry += 10
			print("Enfoque en química del equipo seleccionado")
			
		"attack_focus":
			if GameManager:
				GameManager.set_story_flag("team_strategy", "attack")
				GameManager.team_chemistry += 3
			print("Enfoque ofensivo seleccionado")

func transition_to_next_scene():
	# Efecto de transición
	var tween = Tween.new()
	add_child(tween)
	
	# Fade out
	tween.interpolate_property(self, "modulate:a", 1.0, 0.0, 1.0)
	tween.start()
	yield(tween, "tween_completed")
	
	# Por ahora volvemos al menú principal
	# En el futuro esto llevará a la gestión de equipo o próximo capítulo
	get_tree().change_scene("res://scenes/MainMenu.tscn")
	
	tween.queue_free()
