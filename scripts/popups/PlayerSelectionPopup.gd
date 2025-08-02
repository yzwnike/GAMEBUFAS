extends AcceptDialog

signal player_selected(player_id: String)

@onready var players_container = $VBoxContainer/ScrollContainer/PlayersContainer
@onready var instruction_label = $VBoxContainer/InstructionLabel

var players_manager: Node
var item_data: Dictionary

func _ready():
	# Obtener referencia al PlayersManager
	players_manager = get_node("/root/PlayersManager")
	if players_manager == null:
		print("ERROR: No se pudo encontrar PlayersManager")
		queue_free()
		return
	
	# Conectar señal de cierre
	confirmed.connect(queue_free)

func set_item(item_data: Dictionary):
	self.item_data = item_data
	
	# Actualizar instrucciones
	instruction_label.text = "Selecciona un jugador para aplicar: " + item_data.name
	
	# Mostrar jugadores
	display_players()
	
	# Mostrar el popup
	popup_centered()

func display_players():
	# Limpiar contenedor
	for child in players_container.get_children():
		child.queue_free()
	
	var players = players_manager.get_all_players()
	
	for player_data in players:
		create_player_button(player_data)

func create_player_button(player_data: Dictionary):
	var button = Button.new()
	var button_text = player_data.name + " (" + player_data.position + ") - Overall: " + str(player_data.overall)
	
	# Mostrar estadística específica que se va a mejorar
	if item_data.has("stat"):
		var current_stat = 0
		match item_data.stat:
			"attack":
				current_stat = player_data.attack
			"defense":
				current_stat = player_data.defense
			"speed":
				current_stat = player_data.speed
			"stamina":
				# Para stamina, mostrar current_stamina (stamina para partidos) en lugar de la estadística base
				current_stat = players_manager.get_player_stamina(player_data.id)
			"skill":
				current_stat = player_data.skill
			"morale":
				# Para moral, obtener la moral actual del jugador
				current_stat = players_manager.get_player_morale(player_data.id)
		
		# Formatear la visualización según el tipo de estadística
		if item_data.stat == "stamina":
			# Para stamina, mostrar formato X/3
			button_text += " | Stamina: " + str(current_stat) + "/" + str(players_manager.MAX_STAMINA)
		elif item_data.stat == "morale":
			# Para moral, mostrar formato especial con límite
			button_text += " | Moral: " + str(current_stat) + "/" + str(players_manager.MAX_MORALE)
		else:
			# Para otras estadísticas, mostrar formato normal
			button_text += " | " + item_data.stat.capitalize() + ": " + str(current_stat)
	
	button.text = button_text
	button.pressed.connect(_on_player_button_pressed.bind(player_data.id))
	
	players_container.add_child(button)

func _on_player_button_pressed(player_id: String):
	print("PlayerSelectionPopup: Jugador seleccionado - ", player_id)
	player_selected.emit(player_id)
	queue_free()
