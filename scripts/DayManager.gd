extends Node

# Singleton para manejar el sistema de días
signal day_advanced(new_day: int)
signal day_transition_finished

var current_day: int = 1
var day_transition_scene: PackedScene
var day_transition_instance: Control

# Sistema de origen para saber de dónde viene la transición
var transition_origin: String = ""  # "training", "tournament", o ""

func _ready():
	print("DayManager: Inicializando sistema de días...")
	print("DayManager: Día actual: ", current_day)
	
	# Cargar la escena de transición
	day_transition_scene = preload("res://scenes/DayTransition.tscn")

func get_current_day() -> int:
	return current_day

func advance_day():
	advance_day_with_origin("")

func advance_day_with_origin(origin: String):
	transition_origin = origin
	var old_day = current_day
	current_day += 1
	print("DayManager: Avanzando al día ", current_day, " desde origen: ", origin)
	
	# Mostrar transición visual
	show_day_transition(old_day, current_day)
	
	# Esperar a que termine la transición antes de continuar
	await day_transition_finished
	
	# Notificar a otros sistemas
	day_advanced.emit(current_day)
	
	# Notificar al TransferMarketManager
	if TransferMarketManager:
		TransferMarketManager.advance_day()
	
	# NO reiniciar el estado de entrenamiento aquí automáticamente
	# El entrenamiento solo se reinicia después de jugar un partido
	# if TrainingManager:
	# 	TrainingManager.reset_training()
	
	# Redirigir al InteractiveMenu con zoom según el origen
	redirect_to_interactive_menu()

func show_day_transition(from_day: int, to_day: int):
	print("🌅 DayManager: Iniciando transición visual del día ", from_day, " al día ", to_day)
	
	# Crear instancia de la transición si no existe
	if not day_transition_instance:
		day_transition_instance = day_transition_scene.instantiate()
		
		# Conectar señal de finalización
		day_transition_instance.transition_finished.connect(_on_transition_finished)
		
		# Añadir como hijo del árbol principal
		get_tree().root.add_child(day_transition_instance)
		
		# Asegurar que esté en el frente
		day_transition_instance.z_index = 1000
	
	# Iniciar la transición
	day_transition_instance.show_day_transition(from_day, to_day)

func _on_transition_finished():
	print("🌅 DayManager: Transición visual completada")
	
	# Limpiar la instancia
	if day_transition_instance:
		day_transition_instance.queue_free()
		day_transition_instance = null
	
	# Emitir señal de finalización
	day_transition_finished.emit()

func redirect_to_interactive_menu():
	print("🎅 DayManager: Redirigiendo al InteractiveMenu con origen: ", transition_origin)
	
	# Crear una instancia del InteractiveMenu
	var interactive_scene = load("res://scenes/InteractiveMenu.tscn")
	var interactive_instance = interactive_scene.instantiate()
	
	# Configurar el área de zoom según el origen
	var zoom_area = ""
	match transition_origin:
		"training":
			zoom_area = "campo"
			print("🏃 DayManager: Configurando zoom desde campo de entrenamiento")
		"tournament":
			zoom_area = "estadio"
			print("🏆 DayManager: Configurando zoom desde estadio")
		_:
			zoom_area = ""
			print("🌅 DayManager: Sin zoom especial, aparición normal")
	
	# Configurar el InteractiveMenu para que sepa de dónde viene
	if zoom_area != "":
		interactive_instance.returning_from_submenu = true
		interactive_instance.last_selected_area = zoom_area
		interactive_instance.is_first_time = false
	
	# Cambiar a la escena
	get_tree().change_scene_to_packed(interactive_scene)
	
	# Resetear el origen para próximas transiciones
	transition_origin = ""

func get_day_text() -> String:
	return "Día %d de la aventura" % current_day
