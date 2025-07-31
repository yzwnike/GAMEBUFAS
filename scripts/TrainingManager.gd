extends Node

# Singleton para gestionar el estado de entrenamientos

var training_completed = false
var current_opponent = ""

func _ready():
	print("TrainingManager: Singleton inicializado")

# Verificar si se ha completado el entrenamiento para el partido actual
func has_completed_training() -> bool:
	return training_completed

# Marcar entrenamiento como completado
func complete_training():
	training_completed = true
	print("TrainingManager: Entrenamiento completado")

# Establecer el oponente actual para el entrenamiento
func set_current_opponent(opponent_name: String):
	current_opponent = opponent_name
	# Al cambiar de oponente, reiniciar el estado de entrenamiento
	training_completed = false
	print("TrainingManager: Oponente establecido: ", opponent_name)

# Obtener el oponente actual
func get_current_opponent() -> String:
	return current_opponent

# Reiniciar estado de entrenamiento (para nueva jornada)
func reset_training():
	training_completed = false
	current_opponent = ""
	print("TrainingManager: Estado de entrenamiento reiniciado")

# Simular entrenamiento (para pruebas)
func simulate_training():
	print("TrainingManager: Simulando entrenamiento...")
	training_completed = true
	print("TrainingManager: Entrenamiento simulado completado")
