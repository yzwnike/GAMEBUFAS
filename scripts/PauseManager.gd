extends Control

# PauseManager - Sistema global de pausa con menú de ajustes
signal game_paused
signal game_resumed

var is_game_paused = false
var pause_menu_scene = null
var current_pause_menu = null

func _ready():
	print("PauseManager: Inicializando sistema de pausa...")
	
	# Configurar el proceso en modo pausa
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Cargar la escena del menú de pausa
	pause_menu_scene = preload("res://scenes/PauseMenu.tscn")

func _unhandled_input(event):
	# Detectar la tecla Escape
	if event.is_action_pressed("ui_pause"):
		toggle_pause()

func toggle_pause():
	if is_game_paused:
		resume_game()
	else:
		pause_game()

func pause_game():
	if is_game_paused:
		return
	
	print("PauseManager: Pausando el juego...")
	is_game_paused = true
	
	# Pausar el árbol de escena
	get_tree().paused = true
	
	# Crear y mostrar el menú de pausa
	show_pause_menu()
	
	# Emitir señal
	game_paused.emit()

func resume_game():
	if not is_game_paused:
		return
	
	print("PauseManager: Reanudando el juego...")
	is_game_paused = false
	
	# Reanudar el árbol de escena
	get_tree().paused = false
	
	# Ocultar el menú de pausa
	hide_pause_menu()
	
	# Emitir señal
	game_resumed.emit()

func show_pause_menu():
	if current_pause_menu:
		return
	
	# Instanciar el menú de pausa
	current_pause_menu = pause_menu_scene.instantiate()
	current_pause_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Conectar señales del menú
	current_pause_menu.resume_requested.connect(resume_game)
	current_pause_menu.main_menu_requested.connect(_on_main_menu_requested)
	
	# Añadir a la escena en una capa alta
	get_tree().current_scene.add_child(current_pause_menu)

func hide_pause_menu():
	if current_pause_menu:
		current_pause_menu.queue_free()
		current_pause_menu = null

func _on_main_menu_requested():
	# Primero reanudar el juego
	is_game_paused = false
	get_tree().paused = false
	
	# Limpiar el menú de pausa
	hide_pause_menu()
	
	# Ir al menú principal
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func is_paused() -> bool:
	return is_game_paused
