extends Node

# Singleton para manejar el sistema de días
signal day_advanced(new_day: int)

var current_day: int = 1

func _ready():
	print("DayManager: Inicializando sistema de días...")
	print("DayManager: Día actual: ", current_day)

func get_current_day() -> int:
	return current_day

func advance_day():
	current_day += 1
	print("DayManager: Avanzando al día ", current_day)
	
	# Notificar a otros sistemas
	day_advanced.emit(current_day)
	
	# Notificar al TransferMarketManager
	if TransferMarketManager:
		TransferMarketManager.advance_day()

func get_day_text() -> String:
	return "Día %d de la aventura" % current_day
