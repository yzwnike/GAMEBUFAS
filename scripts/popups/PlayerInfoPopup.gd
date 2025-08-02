extends AcceptDialog

@onready var player_image = $VBoxContainer/PlayerImage
@onready var player_name = $VBoxContainer/PlayerName
@onready var player_position = $VBoxContainer/PlayerPosition
@onready var player_overall = $VBoxContainer/PlayerOverall
@onready var attack_label = $VBoxContainer/StatsContainer/AttackStat/AttackLabel
@onready var attack_value = $VBoxContainer/StatsContainer/AttackStat/AttackValue
@onready var defense_label = $VBoxContainer/StatsContainer/DefenseStat/DefenseLabel
@onready var defense_value = $VBoxContainer/StatsContainer/DefenseStat/DefenseValue
@onready var speed_label = $VBoxContainer/StatsContainer/SpeedStat/SpeedLabel
@onready var speed_value = $VBoxContainer/StatsContainer/SpeedStat/SpeedValue
@onready var stamina_label = $VBoxContainer/StatsContainer/StaminaStat/StaminaLabel
@onready var stamina_value = $VBoxContainer/StatsContainer/StaminaStat/StaminaValue
@onready var skill_label = $VBoxContainer/StatsContainer/SkillStat/SkillLabel
@onready var skill_value = $VBoxContainer/StatsContainer/SkillStat/SkillValue
@onready var player_description = $VBoxContainer/PlayerDescription

var players_manager: Node

func _ready():
	# Obtener referencia al PlayersManager
	players_manager = get_node("/root/PlayersManager")
	if players_manager == null:
		print("ERROR: No se pudo encontrar PlayersManager")
		queue_free()
		return
	
	# Conectar señal de cierre
	confirmed.connect(queue_free)

func set_player(player_id: String):
	var player_data = players_manager.get_player_by_id(player_id)
	if player_data == null:
		print("ERROR: Datos de jugador no encontrados")
		queue_free()
		return
	
	# Actualizar UI con datos del jugador
	player_name.text = player_data.name
	player_position.text = player_data.position
	# Calcular OVR dinámicamente
	var calculated_overall = calculate_player_overall(player_data)
	player_overall.text = "Overall: " + str(calculated_overall)
	
	var image = load(player_data.image)
	if image != null:
		player_image.texture = image
	else:
		print("Advertencia: No se pudo cargar la imagen para ", player_data.name)
		# Usar imagen por defecto
		var default_image = load("res://assets/images/characters/proximamente2.png")
		if default_image != null:
			player_image.texture = default_image
	
	# Mostrar los 5 substats más importantes según la posición del jugador
	match player_data.position:
		"Delantero":
			attack_label.text = "Tiro:"
			attack_value.text = str(player_data.shooting)
			defense_label.text = "Cabeza:"
			defense_value.text = str(player_data.heading)
			speed_label.text = "Regate:"
			speed_value.text = str(player_data.dribbling)
			stamina_label.text = "Velocidad:"
			stamina_value.text = str(player_data.speed)
			skill_label.text = "Posición:"
			skill_value.text = str(player_data.positioning)
		"Mediocentro":
			attack_label.text = "P. Corto:"
			attack_value.text = str(player_data.short_pass)
			defense_label.text = "P. Largo:"
			defense_value.text = str(player_data.long_pass)
			speed_label.text = "Regate:"
			speed_value.text = str(player_data.dribbling)
			stamina_label.text = "Velocidad:"
			stamina_value.text = str(player_data.speed)
			skill_label.text = "Concentración:"
			skill_value.text = str(player_data.concentration)
		"Defensa":
			attack_label.text = "Marcaje:"
			attack_value.text = str(player_data.marking)
			defense_label.text = "Entrada:"
			defense_value.text = str(player_data.tackling)
			speed_label.text = "Posición:"
			speed_value.text = str(player_data.positioning)
			stamina_label.text = "Velocidad:"
			stamina_value.text = str(player_data.speed)
			skill_label.text = "Cabeza:"
			skill_value.text = str(player_data.heading)
		"Portero":
			attack_label.text = "Reflejos:"
			attack_value.text = str(player_data.reflexes)
			defense_label.text = "Posición:"
			defense_value.text = str(player_data.positioning)
			speed_label.text = "Concentración:"
			speed_value.text = str(player_data.concentration)
			stamina_label.text = "P. Corto:"
			stamina_value.text = str(player_data.short_pass)
			skill_label.text = "Velocidad:"
			skill_value.text = str(player_data.speed)
		_:
			# Fallback para posiciones desconocidas
			attack_value.text = "Tiro: " + str(player_data.shooting)
			defense_value.text = "Marcaje: " + str(player_data.marking)
			speed_value.text = "Velocidad: " + str(player_data.speed)
			stamina_value.text = "Resistencia: " + str(player_data.stamina)
			skill_value.text = "Concentración: " + str(player_data.concentration)
	
	player_description.text = player_data.description
	
	# Mostrar el popup
	popup_centered()

func set_player_direct(player_data: Dictionary):
	# Este método es para la enciclopedia, que ya tiene los datos completos
	if player_data == null:
		print("ERROR: Datos de jugador (directos) no encontrados")
		queue_free()
		return
	
	# Actualizar UI con datos del jugador
	player_name.text = player_data.name
	player_position.text = player_data.position
	# Calcular OVR dinámicamente
	var calculated_overall = calculate_player_overall(player_data)
	player_overall.text = "Overall: " + str(calculated_overall)
	
	var image = load(player_data.image)
	if image != null:
		player_image.texture = image
	else:
		var default_image = load("res://assets/images/characters/proximamente2.png")
		if default_image != null:
			player_image.texture = default_image
	
	# Mostrar los 5 substats más importantes según la posición del jugador
	match player_data.position:
		"Delantero":
			attack_label.text = "Tiro:"
			attack_value.text = str(player_data.get("shooting", 0))
			defense_label.text = "Cabeza:"
			defense_value.text = str(player_data.get("heading", 0))
			speed_label.text = "Regate:"
			speed_value.text = str(player_data.get("dribbling", 0))
			stamina_label.text = "Velocidad:"
			stamina_value.text = str(player_data.get("speed", 0))
			skill_label.text = "Posición:"
			skill_value.text = str(player_data.get("positioning", 0))
		"Mediocentro":
			attack_label.text = "P. Corto:"
			attack_value.text = str(player_data.get("short_pass", 0))
			defense_label.text = "P. Largo:"
			defense_value.text = str(player_data.get("long_pass", 0))
			speed_label.text = "Regate:"
			speed_value.text = str(player_data.get("dribbling", 0))
			stamina_label.text = "Velocidad:"
			stamina_value.text = str(player_data.get("speed", 0))
			skill_label.text = "Cabeza:"
			skill_value.text = str(player_data.get("heading", 0))
		"Defensa":
			attack_label.text = "Marcaje:"
			attack_value.text = str(player_data.get("marking", 0))
			defense_label.text = "Entrada:"
			defense_value.text = str(player_data.get("tackling", 0))
			speed_label.text = "Posición:"
			speed_value.text = str(player_data.get("positioning", 0))
			stamina_label.text = "Velocidad:"
			stamina_value.text = str(player_data.get("speed", 0))
			skill_label.text = "Concentración:"
			skill_value.text = str(player_data.get("concentration", 0))
		"Portero":
			attack_label.text = "Reflejos:"
			attack_value.text = str(player_data.get("reflexes", 0))
			defense_label.text = "Posición:"
			defense_value.text = str(player_data.get("positioning", 0))
			speed_label.text = "Concentración:"
			speed_value.text = str(player_data.get("concentration", 0))
			stamina_label.text = "P. Corto:"
			stamina_value.text = str(player_data.get("short_pass", 0))
			skill_label.text = "Velocidad:"
			skill_value.text = str(player_data.get("speed", 0))
		_:
			# Fallback - usar estadísticas antiguas si existen, sino substats
			attack_value.text = "Tiro: " + str(player_data.get("shooting", player_data.get("attack", 0)))
			defense_value.text = "Defensa: " + str(player_data.get("marking", player_data.get("defense", 0)))
			speed_value.text = "Velocidad: " + str(player_data.get("speed", 0))
			stamina_value.text = "Resistencia: " + str(player_data.get("stamina", 0))
			skill_value.text = "Concentración: " + str(player_data.get("concentration", player_data.get("skill", 0)))
	
	player_description.text = player_data.description
	
	# Mostrar el popup
	popup_centered()

# Función para calcular el OVR dinámicamente basado en substats y posición
func calculate_player_overall(player: Dictionary) -> int:
	# Calcular overall basado en substats y posición (5 substats con 0.2 cada uno = 100%)
	var total = 0.0
	match player.position:
		"Delantero":
			total += player.get("shooting", 0) * 0.2
			total += player.get("heading", 0) * 0.2
			total += player.get("dribbling", 0) * 0.2
			total += player.get("speed", 0) * 0.2
			total += player.get("positioning", 0) * 0.2
		"Mediocentro":
			total += player.get("short_pass", 0) * 0.2
			total += player.get("long_pass", 0) * 0.2
			total += player.get("dribbling", 0) * 0.2
			total += player.get("concentration", 0) * 0.2
			total += player.get("speed", 0) * 0.2
		"Defensa":
			total += player.get("marking", 0) * 0.2
			total += player.get("tackling", 0) * 0.2
			total += player.get("positioning", 0) * 0.2
			total += player.get("speed", 0) * 0.2
			total += player.get("heading", 0) * 0.2
		"Portero":
			total += player.get("reflexes", 0) * 0.2
			total += player.get("positioning", 0) * 0.2
			total += player.get("concentration", 0) * 0.2
			total += player.get("short_pass", 0) * 0.2
			total += player.get("speed", 0) * 0.2
		_:
			# Para posiciones desconocidas, usar un promedio general
			total += player.get("shooting", 0) + player.get("heading", 0) + player.get("short_pass", 0) + player.get("long_pass", 0) + player.get("dribbling", 0)
			total += player.get("speed", 0) + player.get("marking", 0) + player.get("tackling", 0) + player.get("reflexes", 0) + player.get("positioning", 0)
			total += player.get("concentration", 0)
			total /= 11.0
			return int(total)
	
	return int(total)

