extends Node

# Singleton para gestionar el estado de entrenamientos

signal training_completed
signal training_status_changed

var training_completed_status = false
var current_opponent = ""
var current_match_day = -1  # Para trackear para qué jornada es el entrenamiento

func _ready():
	print("TrainingManager: Singleton inicializado")

# Verificar si se ha completado el entrenamiento para el partido actual
func has_completed_training() -> bool:
	return training_completed_status

# Marcar entrenamiento como completado
func complete_training():
	training_completed_status = true
	print("TrainingManager: Entrenamiento completado")
	training_completed.emit()
	training_status_changed.emit()

# Establecer el oponente actual para el entrenamiento
func set_current_opponent(opponent_name: String, match_day: int = -1):
	# Solo reiniciar si es un oponente/jornada diferente
	if current_opponent != opponent_name or (match_day != -1 and current_match_day != match_day):
		current_opponent = opponent_name
		current_match_day = match_day
		training_completed_status = false
		print("TrainingManager: Oponente establecido: ", opponent_name, " (Jornada: ", match_day, ")")
	else:
		print("TrainingManager: Mismo oponente y jornada, manteniendo estado actual")

# Obtener el oponente actual
func get_current_opponent() -> String:
	return current_opponent

# Reiniciar estado de entrenamiento solo cuando se juega el partido
func reset_training_after_match():
	training_completed_status = false
	current_opponent = ""
	current_match_day = -1
	print("TrainingManager: Estado de entrenamiento reiniciado después del partido")

# Función antigua mantenida para compatibilidad pero sin resetear automáticamente
func reset_training():
	print("TrainingManager: reset_training() llamado pero no se resetea automáticamente")

# Verificar si es día de partido (días pares)
func is_match_day() -> bool:
	var current_day = DayManager.get_current_day()
	return current_day % 2 == 0

# Verificar si se puede entrenar
func can_train() -> bool:
	# No se puede entrenar en día de partido o si ya se completó
	return not is_match_day() and not training_completed_status

# Simular entrenamiento (para pruebas)
func simulate_training():
	print("TrainingManager: Simulando entrenamiento...")
	training_completed_status = true
	print("TrainingManager: Entrenamiento simulado completado")
