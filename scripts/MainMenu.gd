extends Control

# MainMenu - Menú principal del juego

@onready var new_game_button = $MenuContainer/NewGameButton
@onready var continue_button = $MenuContainer/ContinueButton
@onready var settings_button = $MenuContainer/SettingsButton
@onready var quit_button = $MenuContainer/QuitButton
@onready var title_label = $TitleLabel

var save_exists = false

func _ready():
	print("=== MainMenu._ready() ejecutado ===")
	print("Esperando un frame para que los Autoloads se inicialicen...")
	
	# Esperar un frame para asegurar que los Autoloads se han cargado
	await get_tree().process_frame
	
	# MODO DEBUG: Verificar diferentes opciones de debug
	print("Verificando GameManager: ", GameManager)
	print("GameManager es nulo?: ", GameManager == null)
	
	if GameManager:
		print("GameManager encontrado, verificando flags...")
		print("Todos los flags actuales: ", GameManager.story_progress)
		
		# Opción 1: Debug del capítulo 2
		var load_chapter_2_flag = GameManager.get_story_flag("load_chapter_2")
		print("Flag load_chapter_2: ", load_chapter_2_flag)
		if load_chapter_2_flag:
			print("MODO DEBUG: Saltando directamente al capítulo 2...")
			transition_to_scene("res://scenes/BranchingDialogue.tscn")
			return
		
		# Opción 2: Debug del diálogo post-partido
		var post_match_flag = GameManager.get_story_flag("post_match_branch")
		print("Flag post_match_branch: ", post_match_flag)
		if post_match_flag:
			print("MODO DEBUG: Saltando directamente al diálogo post-partido...")
			transition_to_scene("res://scenes/BranchingDialogue.tscn")
			return
		
		print("Ningún flag de debug activo, mostrando menú normal...")
	else:
		print("ERROR: GameManager no está disponible")
		print("Intentando acceder directamente...")
		var gm = get_node_or_null("/root/GameManager")
		if gm:
			print("GameManager encontrado como nodo: ", gm)
		else:
			print("GameManager no encontrado ni como Autoload ni como nodo")
	
	# Verificar si existe un archivo de guardado
	save_exists = FileAccess.file_exists("user://savegame.json")
	
	# Habilitar/deshabilitar botón continuar
	continue_button.disabled = !save_exists
	
	# Conectar señales de los botones
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Configurar título
	title_label.text = "LA VELADA VISUAL NOVEL"
	
	# Animación de entrada
	play_intro_animation()

func play_intro_animation():
	# Animación suave de aparición
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 2.0)
	await tween.finished

func _on_new_game_pressed():
	# Confirmar si hay partida guardada
	if save_exists:
		show_new_game_confirmation()
	else:
		start_new_game()

func show_new_game_confirmation():
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "¿Estás seguro de que quieres empezar una nueva partida? Se perderá el progreso actual."
	dialog.title = "Nueva Partida"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(start_new_game)
	dialog.close_requested.connect(dialog.queue_free)

func start_new_game():
	# Reiniciar GameManager
	if GameManager:
		GameManager.story_progress = {}
		GameManager.team_stats = {
			"wins": 0,
			"losses": 0,
			"draws": 0,
			"goals_for": 0,
			"goals_against": 0
		}
		GameManager.team_chemistry = 50.0
	
	# Ir a la escena de personalización de personaje
	transition_to_scene("res://scenes/CharacterCustomization.tscn")

func _on_continue_pressed():
	if save_exists:
		# Cargar partida guardada
		if GameManager:
			GameManager.load_game()
		transition_to_scene("res://scenes/Chapter1Scene.tscn")

func _on_settings_pressed():
	# Mostrar menú de configuración (por implementar)
	print("Settings menu - Por implementar")

func _on_quit_pressed():
	get_tree().quit()

func transition_to_scene(scene_path):
	# Efecto de transición
	var tween = create_tween()
	
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	
	# Cambiar escena
	get_tree().change_scene_to_file(scene_path)
