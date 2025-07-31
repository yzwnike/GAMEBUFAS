extends AcceptDialog

@onready var player_name_label = $VBoxContainer/PlayerName
@onready var experience_label = $VBoxContainer/ExperienceLabel
@onready var attack_value = $VBoxContainer/ScrollContainer/StatsContainer/AttackUpgrade/AttackInfo/AttackValue
@onready var defense_value = $VBoxContainer/ScrollContainer/StatsContainer/DefenseUpgrade/DefenseInfo/DefenseValue
@onready var speed_value = $VBoxContainer/ScrollContainer/StatsContainer/SpeedUpgrade/SpeedInfo/SpeedValue
@onready var stamina_value = $VBoxContainer/ScrollContainer/StatsContainer/StaminaUpgrade/StaminaInfo/StaminaValue
@onready var skill_value = $VBoxContainer/ScrollContainer/StatsContainer/SkillUpgrade/SkillInfo/SkillValue

@onready var attack_button = $VBoxContainer/ScrollContainer/StatsContainer/AttackUpgrade/AttackUpgradeButton
@onready var defense_button = $VBoxContainer/ScrollContainer/StatsContainer/DefenseUpgrade/DefenseUpgradeButton
@onready var speed_button = $VBoxContainer/ScrollContainer/StatsContainer/SpeedUpgrade/SpeedUpgradeButton
@onready var stamina_button = $VBoxContainer/ScrollContainer/StatsContainer/StaminaUpgrade/StaminaUpgradeButton
@onready var skill_button = $VBoxContainer/ScrollContainer/StatsContainer/SkillUpgrade/SkillUpgradeButton

var players_manager: Node
var current_player_id: String

func _ready():
	# Obtener referencia al PlayersManager
	players_manager = get_node("/root/PlayersManager")
	if players_manager == null:
		print("ERROR: No se pudo encontrar PlayersManager")
		queue_free()
		return
	
	# Conectar señales
	confirmed.connect(queue_free)
	attack_button.pressed.connect(_on_upgrade_stat.bind("attack"))
	defense_button.pressed.connect(_on_upgrade_stat.bind("defense"))
	speed_button.pressed.connect(_on_upgrade_stat.bind("speed"))
	stamina_button.pressed.connect(_on_upgrade_stat.bind("stamina"))
	skill_button.pressed.connect(_on_upgrade_stat.bind("skill"))

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
	# Actualizar valores actuales
	experience_label.text = "Puntos de Experiencia: " + str(player_data.experience)
	attack_value.text = str(player_data.attack)
	defense_value.text = str(player_data.defense)
	speed_value.text = str(player_data.speed)
	stamina_value.text = str(player_data.stamina)
	skill_value.text = str(player_data.skill)
	
	# Actualizar botones con costos (1 punto por mejora)
	var cost = 1
	attack_button.text = "Mejorar (+1) - Costo: " + str(cost) + " EXP"
	defense_button.text = "Mejorar (+1) - Costo: " + str(cost) + " EXP"
	speed_button.text = "Mejorar (+1) - Costo: " + str(cost) + " EXP"
	stamina_button.text = "Mejorar (+1) - Costo: " + str(cost) + " EXP"
	skill_button.text = "Mejorar (+1) - Costo: " + str(cost) + " EXP"
	
	# Deshabilitar botones si no hay suficiente experiencia o la estadística está al máximo
	var has_enough_exp = player_data.experience >= cost
	attack_button.disabled = not has_enough_exp or (player_data.attack >= 99)
	defense_button.disabled = not has_enough_exp or (player_data.defense >= 99)
	speed_button.disabled = not has_enough_exp or (player_data.speed >= 99)
	stamina_button.disabled = not has_enough_exp or (player_data.stamina >= 99)
	skill_button.disabled = not has_enough_exp or (player_data.skill >= 99)

func _on_upgrade_stat(stat: String):
	var success = players_manager.upgrade_player_with_experience(current_player_id, stat, 1)
	if success:
		# Actualizar display
		var updated_player = players_manager.get_player_by_id(current_player_id)
		update_stats_display(updated_player)
		print("¡Jugador mejorado exitosamente!")
	else:
		print("Error al mejorar jugador")
