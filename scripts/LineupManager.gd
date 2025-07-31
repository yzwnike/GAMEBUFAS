extends Node

# Singleton para gestionar el estado de alineaciones sin persistencia automática

var current_lineup = {}
var current_formation = ""
var lineup_saved = false

func _ready():
	print("LineupManager: Singleton inicializado")

# Guardar alineación en memoria (no persistente)
func save_lineup(formation: String, players_dict: Dictionary):
	current_formation = formation
	current_lineup = players_dict.duplicate(true)
	lineup_saved = true
	print("LineupManager: Alineación guardada - Formación: ", formation, ", Jugadores: ", players_dict.size())

# Obtener alineación actual
func get_saved_lineup():
	if not lineup_saved or current_lineup.is_empty():
		print("LineupManager: No hay alineación guardada")
		return null
	
	return {
		"formation": current_formation,
		"players": current_lineup.duplicate(true)
	}

# Verificar si hay una alineación válida
func has_valid_lineup() -> bool:
	if not lineup_saved or current_lineup.is_empty():
		return false
	
	# Verificar que tengamos exactamente 7 jugadores
	var player_count = current_lineup.size()
	print("LineupManager: Verificando alineación - Jugadores: ", player_count)
	return player_count == 7

# Limpiar alineación (para testing o nuevo juego)
func clear_lineup():
	current_lineup.clear()
	current_formation = ""
	lineup_saved = false
	print("LineupManager: Alineación limpiada")

# Obtener información de la alineación para debug
func get_lineup_info() -> String:
	if not lineup_saved:
		return "No hay alineación guardada"
	
	var info = "Formación: %s\nJugadores (%d):\n" % [current_formation, current_lineup.size()]
	for position in current_lineup:
		var player = current_lineup[position]
		info += "- %s: %s\n" % [position, player.get("name", "Desconocido")]
	
	return info
