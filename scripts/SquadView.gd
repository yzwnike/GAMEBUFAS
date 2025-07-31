extends Control

@onready var grid_container = $VBoxContainer/ScrollContainer/MarginContainer/GridContainer
@onready var back_button = $VBoxContainer/Footer/BackButton

var players_manager: Node

# Escena del popup de información
const PLAYER_INFO_POPUP = "res://scenes/popups/PlayerInfoPopup.tscn"
# Escena del popup de mejora
const UPGRADE_PLAYER_POPUP = "res://scenes/popups/UpgradePlayerPopup.tscn"


func _ready():
	print("SquadView: Inicializando vista de plantilla...")
	
	# Obtener referencia al PlayersManager
	players_manager = get_node("/root/PlayersManager")
	if players_manager == null:
		print("ERROR: No se pudo encontrar PlayersManager")
		return
	
	# Conectar botón de volver
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Mostrar la plantilla de jugadores
	display_squad()
	
	# Conectar señal de mejora de jugador para refrescar la vista
	players_manager.player_upgraded.connect(_on_player_upgraded)

func display_squad():
	print("SquadView: Generando grid de jugadores...")
	
	# Limpiar la grilla
	for child in grid_container.get_children():
		child.queue_free()
	
	# Obtener todos los jugadores
	var players = players_manager.get_all_players()
	
	# Crear una tarjeta para cada jugador
	for player_data in players:
		create_player_card(player_data)
	
	print("SquadView: Plantilla mostrada con ", players.size(), " jugadores")

func create_player_card(player_data: Dictionary):
	# Crear el contenedor de la tarjeta
	var card = PanelContainer.new()
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	
	# Añadir un StyleBox para el borde
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.2, 0.2, 0.3, 0.8)
	stylebox.border_width_bottom = 2
	stylebox.border_color = Color.WHITE
	card.add_theme_stylebox_override("panel", stylebox)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	# Nombre del jugador
	var name_label = Label.new()
	name_label.text = player_data.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 28)
	vbox.add_child(name_label)
	
	# Imagen del jugador
	var texture_rect = TextureRect.new()
	var player_image = load(player_data.image)
	if player_image != null:
		texture_rect.texture = player_image
	else:
		print("Advertencia: No se pudo cargar la imagen para ", player_data.name, ": ", player_data.image)
		# Usar imagen por defecto si está disponible
		var default_image = load("res://assets/images/characters/proximamente2.png")
		if default_image != null:
			texture_rect.texture = default_image
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.custom_minimum_size = Vector2(150, 150)
	vbox.add_child(texture_rect)
	
# Stamina
	var stamina_label = Label.new()
	var stamina_value = players_manager.get_player_stamina(player_data.id)
	stamina_label.text = "Stamina: " + str(stamina_value) + " / " + str(players_manager.MAX_STAMINA)
	stamina_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamina_label.add_theme_font_size_override("font_size", 20)
	stamina_label.add_theme_color_override("font_color", Color.ORANGE)
	vbox.add_child(stamina_label)

# Overall
	var overall_label = Label.new()
	overall_label.text = "Overall: " + str(player_data.overall)
	overall_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overall_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(overall_label)
	
	# Experiencia
	var experience_label = Label.new()
	var exp_value = player_data.get("experience", 0)
	experience_label.text = "EXP: " + str(exp_value)
	experience_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	experience_label.add_theme_font_size_override("font_size", 18)
	experience_label.add_theme_color_override("font_color", Color.CYAN)
	vbox.add_child(experience_label)
	
	# Botones de acción
	var hbox = HBoxContainer.new()
	hbox.alignment = HBoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)
	
	var improve_button = Button.new()
	improve_button.text = "Mejorar"
	improve_button.pressed.connect(_on_improve_button_pressed.bind(player_data.id))
	hbox.add_child(improve_button)
	
	var info_button = Button.new()
	info_button.text = "Info"
	info_button.pressed.connect(_on_info_button_pressed.bind(player_data.id))
	hbox.add_child(info_button)
	
	grid_container.add_child(card)

func _on_improve_button_pressed(player_id: String):
	print("SquadView: Mejorar jugador ", player_id)
	# Cargar la escena de mejora como popup
	var popup_scene = load(UPGRADE_PLAYER_POPUP).instantiate()
	add_child(popup_scene)
	popup_scene.set_player(player_id)

func _on_info_button_pressed(player_id: String):
	print("SquadView: Ver info del jugador ", player_id)
	# Cargar la escena de info como popup
	var popup_scene = load(PLAYER_INFO_POPUP).instantiate()
	add_child(popup_scene)
	popup_scene.set_player(player_id)

func _on_player_upgraded(player_id: String):
	# Refrescar la vista de la plantilla
	display_squad()

func _on_back_button_pressed():
	print("SquadView: Volviendo al menú de entrenamiento...")
	get_tree().change_scene_to_file("res://scenes/TrainingMenu.tscn")

# Función para manejar la tecla ESC (volver atrás)
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
