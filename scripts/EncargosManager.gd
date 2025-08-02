extends Node

# Manager singleton para el sistema de Encargos
# Gestiona la creación, seguimiento y verificación de encargos del jugador

signal encargo_completado(encargo_id: String, recompensa: Dictionary)
signal encargo_fallido(encargo_id: String)

# Estados de los encargos
enum EncargoState {
	DISPONIBLE,
	EN_CURSO,
	COMPLETADO,
	FALLADO
}

# Tipos de condiciones
enum ConditionType {
	GANAR_PARTIDO,
	GOLEADA, # Ganar por X goles de diferencia
	PORTERIA_CERO, # No recibir goles
	JUGADOR_GOLES, # Un jugador específico debe marcar X goles
	USAR_JUGADOR, # Usar un jugador específico todo el partido
	FICHAR_JUGADOR, # Fichar jugador de cierto país/posición
	RACHA_VICTORIAS # Mantener X victorias seguidas
}

# Estructura de un encargo
class Encargo:
	var id: String
	var titulo: String
	var descripcion: String
	var descripcion_detallada: String
	var condicion_tipo: ConditionType
	var condicion_parametros: Dictionary
	var estado: EncargoState
	var recompensa: Dictionary
	var temporada_creacion: int
	var progreso_actual: int = 0
	var progreso_objetivo: int = 1
	
	func _init(data: Dictionary):
		id = data.get("id", "")
		titulo = data.get("titulo", "")
		descripcion = data.get("descripcion", "")
		descripcion_detallada = data.get("descripcion_detallada", "")
		condicion_tipo = data.get("condicion_tipo", ConditionType.GANAR_PARTIDO)
		condicion_parametros = data.get("condicion_parametros", {})
		estado = EncargoState.DISPONIBLE
		recompensa = data.get("recompensa", {})
		temporada_creacion = data.get("temporada", 1)
		progreso_objetivo = data.get("progreso_objetivo", 1)

# Datos de los encargos actuales
var encargos_temporada: Array[Encargo] = []
var temporada_actual: int = 1

# Plantillas de encargos que se generan aleatoriamente
var plantillas_encargos = [
	{
		"id": "goleada_3",
		"titulo": "¡Victoria Aplastante!",
		"descripcion": "Gana un partido por 3+ goles",
		"descripcion_detallada": "El club necesita una demostración de poder. Derrota al próximo rival por una diferencia de al menos 3 goles para demostrar la superioridad de tu equipo.",
		"condicion_tipo": ConditionType.GOLEADA,
		"condicion_parametros": {"diferencia_minima": 3},
		"recompensa": {"dinero": 50000, "fama": 15},
		"progreso_objetivo": 1
	},
	{
		"id": "porteria_cero",
		"titulo": "Fortaleza Inexpugnable",
		"descripcion": "No recibir goles en un partido",
		"descripcion_detallada": "La hinchada ha perdido confianza en la defensa. Necesitas demostrar que tu equipo puede mantener la portería a cero durante todo un encuentro.",
		"condicion_tipo": ConditionType.PORTERIA_CERO,
		"condicion_parametros": {},
		"recompensa": {"dinero": 30000, "fama": 10},
		"progreso_objetivo": 1
	},
	{
		"id": "jugador_2_goles",
		"titulo": "Estrella del Partido",
		"descripcion": "Un jugador debe marcar 2+ goles",
		"descripcion_detallada": "Los aficionados quieren ver espectáculo. Consigue que uno de tus jugadores se convierta en el héroe del partido marcando al menos 2 goles.",
		"condicion_tipo": ConditionType.JUGADOR_GOLES,
		"condicion_parametros": {"goles_minimos": 2},
		"recompensa": {"dinero": 40000, "fama": 12},
		"progreso_objetivo": 1
	},
	{
		"id": "racha_3_victorias",
		"titulo": "Racha Victoriosa",
		"descripcion": "Gana 3 partidos seguidos",
		"descripcion_detallada": "El momentum es clave en el fútbol. Demuestra la consistencia de tu equipo ganando 3 partidos consecutivos sin perder ninguno.",
		"condicion_tipo": ConditionType.RACHA_VICTORIAS,
		"condicion_parametros": {"victorias_consecutivas": 3},
		"recompensa": {"dinero": 80000, "fama": 25},
		"progreso_objetivo": 3
	},
	{
		"id": "usar_delantero",
		"titulo": "Confianza Total",
		"descripcion": "Usa un delantero todo el partido",
		"descripcion_detallada": "Los medios critican tu rotación constante. Demuestra que confías en tus jugadores manteniendo al mismo delantero en el campo durante todo el encuentro.",
		"condicion_tipo": ConditionType.USAR_JUGADOR,
		"condicion_parametros": {"posicion": "Delantero"},
		"recompensa": {"dinero": 25000, "fama": 8},
		"progreso_objetivo": 1
	},
	{
		"id": "goleada_5",
		"titulo": "Exhibición Total",
		"descripcion": "Gana un partido por 5+ goles",
		"descripcion_detallada": "Los rivales han subestimado tu equipo. Es hora de dar una lección inolvidable ganando por una diferencia de al menos 5 goles.",
		"condicion_tipo": ConditionType.GOLEADA,
		"condicion_parametros": {"diferencia_minima": 5},
		"recompensa": {"dinero": 100000, "fama": 30},
		"progreso_objetivo": 1
	},
	{
		"id": "sin_goles_2_partidos",
		"titulo": "Muro Impenetrable",
		"descripcion": "No recibir goles en 2 partidos",
		"descripcion_detallada": "La defensa necesita demostrar su valía. Mantén la portería a cero durante 2 partidos consecutivos para silenciar a los críticos.",
		"condicion_tipo": ConditionType.PORTERIA_CERO,
		"condicion_parametros": {},
		"recompensa": {"dinero": 60000, "fama": 20},
		"progreso_objetivo": 2
	},
	{
		"id": "hat_trick",
		"titulo": "Hat-Trick Legendario",
		"descripcion": "Un jugador debe marcar 3+ goles",
		"descripcion_detallada": "Los aficionados sueñan con momentos mágicos. Consigue que uno de tus atacantes haga historia marcando un hat-trick o más en un solo partido.",
		"condicion_tipo": ConditionType.JUGADOR_GOLES,
		"condicion_parametros": {"goles_minimos": 3},
		"recompensa": {"dinero": 70000, "fama": 25},
		"progreso_objetivo": 1
	}
]

func _ready():
	print("EncargosManager: Inicializando sistema de encargos...")
	
	# Conectar señales del GameManager para revisar condiciones
	if GameManager:
		if GameManager.has_signal("match_completed"):
			GameManager.match_completed.connect(_on_match_completed)
		if GameManager.has_signal("season_ended"):
			GameManager.season_ended.connect(_on_season_ended)
	
	# Inicializar encargos para la temporada actual si no existen
	if encargos_temporada.is_empty():
		generar_encargos_temporada()
	
	print("EncargosManager: Sistema listo")

func generar_encargos_temporada():
	"""Genera 8 encargos aleatorios para la temporada actual"""
	print("EncargosManager: Generando encargos para temporada ", temporada_actual)
	
	encargos_temporada.clear()
	
	# Seleccionar 8 plantillas aleatorias (sin repetir)
	var plantillas_disponibles = plantillas_encargos.duplicate()
	
	for i in range(8):
		if plantillas_disponibles.is_empty():
			break
			
		var indice_aleatorio = randi() % plantillas_disponibles.size()
		var plantilla = plantillas_disponibles[indice_aleatorio]
		plantillas_disponibles.remove_at(indice_aleatorio)
		
		# Crear encargo con ID único para esta temporada
		var datos_encargo = plantilla.duplicate(true)
		datos_encargo["id"] = plantilla["id"] + "_t" + str(temporada_actual)
		datos_encargo["temporada"] = temporada_actual
		
		var nuevo_encargo = Encargo.new(datos_encargo)
		encargos_temporada.append(nuevo_encargo)
	
	print("EncargosManager: ", encargos_temporada.size(), " encargos generados")

func get_encargos_temporada() -> Array[Encargo]:
	"""Devuelve todos los encargos de la temporada actual"""
	return encargos_temporada

func get_encargo_by_id(id: String) -> Encargo:
	"""Busca un encargo por su ID"""
	for encargo in encargos_temporada:
		if encargo.id == id:
			return encargo
	return null

func _on_match_completed(resultado: Dictionary):
	"""Se llama cuando termina un partido para revisar condiciones"""
	print("EncargosManager: Revisando encargos tras partido completado")
	
	for encargo in encargos_temporada:
		if encargo.estado == EncargoState.EN_CURSO:
			verificar_condicion_encargo(encargo, resultado)

func verificar_condicion_encargo(encargo: Encargo, resultado_partido: Dictionary):
	"""Verifica si se cumplió la condición de un encargo específico"""
	print("EncargosManager: Verificando encargo: ", encargo.titulo)
	
	var cumplido = false
	
	match encargo.condicion_tipo:
		ConditionType.GOLEADA:
			var diferencia_minima = encargo.condicion_parametros.get("diferencia_minima", 3)
			var goles_jugador = resultado_partido.get("goles_jugador", 0)
			var goles_rival = resultado_partido.get("goles_rival", 0)
			var diferencia = goles_jugador - goles_rival
			
			if resultado_partido.get("victoria", false) and diferencia >= diferencia_minima:
				cumplido = true
				print("EncargosManager: ¡Goleada conseguida! Diferencia: ", diferencia)
		
		ConditionType.PORTERIA_CERO:
			if resultado_partido.get("goles_rival", 1) == 0:
				encargo.progreso_actual += 1
				print("EncargosManager: Portería a cero. Progreso: ", encargo.progreso_actual, "/", encargo.progreso_objetivo)
				
				if encargo.progreso_actual >= encargo.progreso_objetivo:
					cumplido = true
		
		ConditionType.JUGADOR_GOLES:
			var goles_minimos = encargo.condicion_parametros.get("goles_minimos", 2)
			var max_goles_jugador = resultado_partido.get("max_goles_jugador", 0)
			
			if max_goles_jugador >= goles_minimos:
				cumplido = true
				print("EncargosManager: ¡Jugador marcó ", max_goles_jugador, " goles!")
		
		ConditionType.RACHA_VICTORIAS:
			if resultado_partido.get("victoria", false):
				encargo.progreso_actual += 1
				print("EncargosManager: Victoria en racha. Progreso: ", encargo.progreso_actual, "/", encargo.progreso_objetivo)
				
				if encargo.progreso_actual >= encargo.progreso_objetivo:
					cumplido = true
			else:
				# Se rompió la racha
				encargo.progreso_actual = 0
				print("EncargosManager: Racha rota, reiniciando progreso")
		
		ConditionType.USAR_JUGADOR:
			var posicion_requerida = encargo.condicion_parametros.get("posicion", "")
			var jugador_completo = resultado_partido.get("jugador_completo_" + posicion_requerida.to_lower(), false)
			
			if jugador_completo:
				cumplido = true
				print("EncargosManager: ¡Jugador ", posicion_requerida, " jugó todo el partido!")
	
	# Si se cumplió, completar el encargo
	if cumplido:
		completar_encargo(encargo)

func completar_encargo(encargo: Encargo):
	"""Marca un encargo como completado y otorga recompensas"""
	print("EncargosManager: ¡Encargo completado! ", encargo.titulo)
	
	encargo.estado = EncargoState.COMPLETADO
	
	# Otorgar recompensas
	if encargo.recompensa.has("dinero"):
		if GameManager and GameManager.has_method("add_money"):
			GameManager.add_money(encargo.recompensa["dinero"])
			print("EncargosManager: +", encargo.recompensa["dinero"], " monedas otorgadas")
	
	if encargo.recompensa.has("fama"):
		if GameManager and GameManager.has_method("add_fame"):
			GameManager.add_fame(encargo.recompensa["fama"])
			print("EncargosManager: +", encargo.recompensa["fama"], " puntos de fama otorgados")
	
	# Emitir señal
	encargo_completado.emit(encargo.id, encargo.recompensa)

func _on_season_ended():
	"""Se llama al final de cada temporada para renovar encargos"""
	print("EncargosManager: Final de temporada - renovando encargos")
	
	temporada_actual += 1
	generar_encargos_temporada()

func get_encargos_completados() -> int:
	"""Devuelve el número de encargos completados esta temporada"""
	var completados = 0
	for encargo in encargos_temporada:
		if encargo.estado == EncargoState.COMPLETADO:
			completados += 1
	return completados

func get_encargos_en_curso() -> int:
	"""Devuelve el número de encargos en curso"""
	var en_curso = 0
	for encargo in encargos_temporada:
		if encargo.estado == EncargoState.EN_CURSO:
			en_curso += 1
	return en_curso

# Funciones para debug
func debug_completar_encargo(encargo_id: String):
	"""Función de debug para completar manualmente un encargo"""
	var encargo = get_encargo_by_id(encargo_id)
	if encargo and encargo.estado == EncargoState.EN_CURSO:
		completar_encargo(encargo)

func debug_simular_resultado_partido(goleada: bool = false, porteria_cero: bool = false):
	"""Función de debug para simular resultados de partido"""
	var resultado = {
		"victoria": true,
		"goles_jugador": 3 if goleada else 1,
		"goles_rival": 0 if porteria_cero else 1,
		"max_goles_jugador": 2 if goleada else 1
	}
	
	_on_match_completed(resultado)
