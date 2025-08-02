extends AcceptDialog

@onready var player_name_label = $VBoxContainer/PlayerName
@onready var experience_label = $VBoxContainer/ExperienceLabel
@onready var stat1_value = $VBoxContainer/ScrollContainer/StatsContainer/AttackUpgrade/AttackInfo/AttackValue
@onready var stat2_value = $VBoxContainer/ScrollContainer/StatsContainer/DefenseUpgrade/DefenseInfo/DefenseValue
@onready var stat3_value = $VBoxContainer/ScrollContainer/StatsContainer/SpeedUpgrade/SpeedInfo/SpeedValue
@onready var stat4_value = $VBoxContainer/ScrollContainer/StatsContainer/StaminaUpgrade/StaminaInfo/StaminaValue
@onready var stat5_value = $VBoxContainer/ScrollContainer/StatsContainer/SkillUpgrade/SkillInfo/SkillValue

@onready var stat1_label = $VBoxContainer/ScrollContainer/StatsContainer/AttackUpgrade/AttackInfo/AttackLabel
@onready var stat2_label = $VBoxContainer/ScrollContainer/StatsContainer/DefenseUpgrade/DefenseInfo/DefenseLabel
@onready var stat3_label = $VBoxContainer/ScrollContainer/StatsContainer/SpeedUpgrade/SpeedInfo/SpeedLabel
@onready var stat4_label = $VBoxContainer/ScrollContainer/StatsContainer/StaminaUpgrade/StaminaInfo/StaminaLabel
@onready var stat5_label = $VBoxContainer/ScrollContainer/StatsContainer/SkillUpgrade/SkillInfo/SkillLabel

@onready var stat1_button = $VBoxContainer/ScrollContainer/StatsContainer/AttackUpgrade/AttackUpgradeButton
@onready var stat2_button = $VBoxContainer/ScrollContainer/StatsContainer/DefenseUpgrade/DefenseUpgradeButton
@onready var stat3_button = $VBoxContainer/ScrollContainer/StatsContainer/SpeedUpgrade/SpeedUpgradeButton
@onready var stat4_button = $VBoxContainer/ScrollContainer/StatsContainer/StaminaUpgrade/StaminaUpgradeButton
@onready var stat5_button = $VBoxContainer/ScrollContainer/StatsContainer/SkillUpgrade/SkillUpgradeButton

var players_manager: Node
var current_player_id: String

# Variables para mapear las stats específicas de cada posición
var current_stats_mapping = {}
var current_player_position = ""

func _ready():
	# Obtener referencia al PlayersManager
	players_manager = get_node("/root/PlayersManager")
	if players_manager == null:
		print("ERROR: No se pudo encontrar PlayersManager")
		queue_free()
		return
	
	# Conectar señales
	confirmed.connect(queue_free)
	stat1_button.pressed.connect(_on_upgrade_stat.bind("stat1"))
	stat2_button.pressed.connect(_on_upgrade_stat.bind("stat2"))
	stat3_button.pressed.connect(_on_upgrade_stat.bind("stat3"))
	stat4_button.pressed.connect(_on_upgrade_stat.bind("stat4"))
	stat5_button.pressed.connect(_on_upgrade_stat.bind("stat5"))

func set_player(player_id: String):
	current_player_id = player_id
	var player_data = players_manager.get_player_by_id(player_id)
	if player_data == null:
		print("ERROR: Datos de jugador no encontrados")
		queue_free()
		return
	
	# Actualizar UI con datos del jugador
	player_name_label.text = "Mejorar a " + player_data.name
	
	update_stats_display(player_data)
	
	# Mostrar el popup
	popup_centered()

func update_stats_display(player_data: Dictionary):
	# Mapear las stats según la posición del jugador
	current_player_position = player_data.position
	match current_player_position:
		"Delantero":
			current_stats_mapping = {
				"stat1": "shooting", "stat2": "heading",
				"stat3": "dribbling", "stat4": "speed",
				"stat5": "positioning"
			}
			stat1_label.text = "Tiro:"
			stat2_label.text = "Cabeza:"
			stat3_label.text = "Regate:"
			stat4_label.text = "Velocidad:"
			stat5_label.text = "Posición:"
		"Mediocentro":
			current_stats_mapping = {
				"stat1": "short_pass", "stat2": "long_pass",
				"stat3": "dribbling", "stat4": "speed",
				"stat5": "concentration"
			}
			stat1_label.text = "P. Corto:"
			stat2_label.text = "P. Largo:"
			stat3_label.text = "Regate:"
			stat4_label.text = "Velocidad:"
			stat5_label.text = "Concentración:"
		"Defensa":
			current_stats_mapping = {
				"stat1": "marking", "stat2": "tackling",
				"stat3": "positioning", "stat4": "speed",
				"stat5": "heading"
			}
			stat1_label.text = "Marcaje:"
			stat2_label.text = "Entrada:"
			stat3_label.text = "Posición:"
			stat4_label.text = "Velocidad:"
			stat5_label.text = "Cabeza:"
		"Portero":
			current_stats_mapping = {
				"stat1": "reflexes", "stat2": "positioning",
				"stat3": "concentration", "stat4": "short_pass",
				"stat5": "speed"
			}
			stat1_label.text = "Reflejos:"
			stat2_label.text = "Posición:"
			stat3_label.text = "Concentración:"
			stat4_label.text = "P. Corto:"
			stat5_label.text = "Velocidad:"
		_:
			# Fallback para posiciones desconocidas
			current_stats_mapping = {
				"stat1": "shooting", "stat2": "marking",
				"stat3": "speed", "stat4": "stamina",
				"stat5": "concentration"
			}
			stat1_label.text = "Tiro:"
			stat2_label.text = "Marcaje:"
			stat3_label.text = "Velocidad:"
			stat4_label.text = "Resistencia:"
			stat5_label.text = "Concentración:"
	
	# Actualizar experiencia
	experience_label.text = "Puntos de Experiencia: " + str(player_data.experience)
	
	# Actualizar valores actuales según mapeo
	stat1_value.text = str(player_data.get(current_stats_mapping["stat1"], 0))
	stat2_value.text = str(player_data.get(current_stats_mapping["stat2"], 0))
	stat3_value.text = str(player_data.get(current_stats_mapping["stat3"], 0))
	stat4_value.text = str(player_data.get(current_stats_mapping["stat4"], 0))
	stat5_value.text = str(player_data.get(current_stats_mapping["stat5"], 0))
	
	# Actualizar botones con costos (1 punto por mejora)
	var cost = 1
	stat1_button.text = "Mejorar (+1) - Costo: " + str(cost) + " EXP"
	stat2_button.text = "Mejorar (+1) - Costo: " + str(cost) + " EXP"
	stat3_button.text = "Mejorar (+1) - Costo: " + str(cost) + " EXP"
	stat4_button.text = "Mejorar (+1) - Costo: " + str(cost) + " EXP"
	stat5_button.text = "Mejorar (+1) - Costo: " + str(cost) + " EXP"
	
	# Deshabilitar botones si no hay suficiente experiencia o la estadística está al máximo
	var has_enough_exp = player_data.experience >= cost
	stat1_button.disabled = not has_enough_exp or (player_data.get(current_stats_mapping["stat1"], 0) >= 99)
	stat2_button.disabled = not has_enough_exp or (player_data.get(current_stats_mapping["stat2"], 0) >= 99)
	stat3_button.disabled = not has_enough_exp or (player_data.get(current_stats_mapping["stat3"], 0) >= 99)
	stat4_button.disabled = not has_enough_exp or (player_data.get(current_stats_mapping["stat4"], 0) >= 99)
	stat5_button.disabled = not has_enough_exp or (player_data.get(current_stats_mapping["stat5"], 0) >= 99)

func _on_upgrade_stat(stat_key: String):
	# Obtener el nombre real de la estadística desde el mapeo
	var actual_stat = current_stats_mapping.get(stat_key, "")
	if actual_stat == "":
		print("ERROR: No se pudo mapear la estadística ", stat_key)
		return
	
	var success = players_manager.upgrade_player_with_substat(current_player_id, actual_stat, 1)
	if success:
		# Actualizar display
		var updated_player = players_manager.get_player_by_id(current_player_id)
		update_stats_display(updated_player)
		print("¡Jugador mejorado exitosamente! Estadística: ", actual_stat)
	else:
		print("Error al mejorar jugador - Estadística: ", actual_stat)
