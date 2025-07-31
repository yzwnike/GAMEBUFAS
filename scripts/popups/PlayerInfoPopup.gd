extends AcceptDialog

@onready var player_image = $VBoxContainer/PlayerImage
@onready var player_name = $VBoxContainer/PlayerName
@onready var player_position = $VBoxContainer/PlayerPosition
@onready var player_overall = $VBoxContainer/PlayerOverall
@onready var attack_value = $VBoxContainer/StatsContainer/AttackStat/AttackValue
@onready var defense_value = $VBoxContainer/StatsContainer/DefenseStat/DefenseValue
@onready var speed_value = $VBoxContainer/StatsContainer/SpeedStat/SpeedValue
@onready var stamina_value = $VBoxContainer/StatsContainer/StaminaStat/StaminaValue
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
	player_overall.text = "Overall: " + str(player_data.overall)
	
	var image = load(player_data.image)
	if image != null:
		player_image.texture = image
	else:
		print("Advertencia: No se pudo cargar la imagen para ", player_data.name)
		# Usar imagen por defecto
		var default_image = load("res://assets/images/characters/proximamente2.png")
		if default_image != null:
			player_image.texture = default_image
	
	attack_value.text = str(player_data.attack)
	defense_value.text = str(player_data.defense)
	speed_value.text = str(player_data.speed)
	stamina_value.text = str(player_data.stamina)
	skill_value.text = str(player_data.skill)
	
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
	player_overall.text = "Overall: " + str(player_data.overall)
	
	var image = load(player_data.image)
	if image != null:
		player_image.texture = image
	else:
		var default_image = load("res://assets/images/characters/proximamente2.png")
		if default_image != null:
			player_image.texture = default_image
	
	attack_value.text = str(player_data.attack)
	defense_value.text = str(player_data.defense)
	speed_value.text = str(player_data.speed)
	stamina_value.text = str(player_data.stamina)
	skill_value.text = str(player_data.skill)
	
	player_description.text = player_data.description
	
	# Mostrar el popup
	popup_centered()

