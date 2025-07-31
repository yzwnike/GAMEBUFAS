extends Control

@onready var gacha_button = $CenterContainer/GachaContainer/ButtonContainer/GachaButton
@onready var back_button = $CenterContainer/GachaContainer/BackButton
@onready var money_label = $CenterContainer/GachaContainer/MoneyLabel
@onready var title_label = $CenterContainer/GachaContainer/TitleLabel
@onready var result_popup = $ResultPopup
@onready var player_name = $ResultPopup/ResultContainer/PlayerName
@onready var player_stats = $ResultPopup/ResultContainer/PlayerStats
@onready var player_image = $ResultPopup/ResultContainer/PlayerImage
@onready var animation_player = $AnimationPlayer
@onready var particle_system = $ParticleSystem

func _ready():
	print("GachaponScene: Inicializando gachapón...")
	print("GachaponScene: Tickets Bufas en GameManager: ", GameManager.get_tickets_bufas())
	setup_styles()
	update_money_display()
	connect_buttons()
	TransferManager.player_obtained.connect(_on_player_obtained)
	print("GachaponScene: Inicialización completa")

func setup_styles():
	# Estilo del título
	var title_settings = LabelSettings.new()
	title_settings.font_size = 36
	title_settings.font_color = Color.YELLOW
	title_settings.outline_size = 2
	title_settings.outline_color = Color.BLACK
	title_label.label_settings = title_settings

func connect_buttons():
	print("GachaponScene: Conectando botones...")
	if gacha_button:
		gacha_button.pressed.connect(_on_gacha_button_pressed)
		print("GachaponScene: Botón gachapón conectado")
	else:
		print("ERROR: Botón gachapón no encontrado")
	
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
		print("GachaponScene: Botón volver conectado")
	else:
		print("ERROR: Botón volver no encontrado")

func _on_gacha_button_pressed():
	print("GachaponScene: Botón gachapón presionado!")
	perform_gacha()

func perform_gacha():
	print("GachaponScene: Intentando realizar gachapón...")
	print("GachaponScene: Tickets Bufas disponibles: ", GameManager.get_tickets_bufas())
	print("GachaponScene: Costo del gachapón: ", TransferManager.get_gacha_cost())
	
	if not TransferManager.can_perform_gacha():
		var tickets = GameManager.get_tickets_bufas()
		var cost = TransferManager.get_gacha_cost()
		if tickets < cost:
			show_message("No tienes suficientes Tickets Bufas. Necesitas: %s, Tienes: %s" % [cost, tickets])
		else:
			show_message("No hay jugadores disponibles para fichar.")
		return

	print("GachaponScene: Iniciando gachapón...")
	animation_player.play("gacha_spin")
	var obtained_player = TransferManager.perform_gacha_pull()

	if obtained_player and not obtained_player.is_empty():
		print("GachaponScene: Jugador obtenido: ", obtained_player.name)
		display_player(obtained_player)
	else:
		print("GachaponScene: Error - No se obtuvo ningún jugador")
		show_message("Error al obtener jugador. Inténtalo de nuevo.")

	update_money_display()

func show_message(message: String):
	# Mostrar un mensaje de error o advertencia
	print("GachaponScene: ", message)

func display_player(player_data: Dictionary):
	player_name.text = player_data.name
	player_stats.text = "Overall: %s\nPosición: %s" % [player_data.overall, player_data.position]
	# Intentar cargar la imagen
	if ResourceLoader.exists(player_data.image):
		player_image.texture = load(player_data.image)
	else:
		print("GachaponScene: No se pudo cargar la imagen: ", player_data.image)
	result_popup.popup_centered()

func update_money_display():
	money_label.text = "Tickets Bufas: %s" % GameManager.get_tickets_bufas()

func _on_back_button_pressed():
	print("GachaponScene: Botón volver presionado!")
	print("GachaponScene: Volviendo al menú de fichajes...")
	get_tree().change_scene_to_file("res://scenes/Fichajes.tscn")

func _on_player_obtained(player_data: Dictionary):
	# Activar efectos de partículas cuando se obtiene un jugador
	particle_system.emitting = true
	print("GachaponScene: ¡Efecto de partículas activado!")

# Función para manejar la tecla ESC (volver atrás)
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()

