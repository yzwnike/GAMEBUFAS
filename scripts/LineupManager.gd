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
	# Convertir el diccionario de posiciones a una lista simple de jugadores
	current_lineup = {}
	var player_count = 0
	for position_key in players_dict.keys():
		var player = players_dict[position_key]
		if player != null:
			player_count += 1
			current_lineup["player_" + str(player_count)] = player
	
	lineup_saved = true
	print("LineupManager: Alineación guardada - Formación: ", formation, ", Jugadores: ", player_count)
	# Debug: mostrar qué jugadores se guardaron
	for key in current_lineup.keys():
		var player = current_lineup[key]
		print("  Guardado: ", player.name, " (", player.get("position", "Sin posición"), ")")

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
