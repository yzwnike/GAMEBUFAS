extends Control

@onready var grid_container = $VBoxContainer/ScrollContainer/MarginContainer/GridContainer
@onready var back_button = $VBoxContainer/Footer/BackButton
@onready var search_line_edit = $VBoxContainer/Header/VBoxContainer/SearchContainer/SearchLineEdit
@onready var position_filter = $VBoxContainer/Header/VBoxContainer/FilterContainer/PositionFilter
@onready var team_filter = $VBoxContainer/Header/VBoxContainer/FilterContainer/TeamFilter

var all_players: Array = []
var filtered_players: Array = []

# Escena del popup de información
const PLAYER_INFO_POPUP = "res://scenes/popups/PlayerInfoPopup.tscn"

func _ready():
	print("PlayerEncyclopedia: Inicializando enciclopedia de jugadores...")
	
	# Cargar datos de jugadores
	load_encyclopedia_data()
	
	# Configurar filtros
	setup_filters()
	
	# Conectar señales
	back_button.pressed.connect(_on_back_button_pressed)
	search_line_edit.text_changed.connect(_on_search_text_changed)
	position_filter.item_selected.connect(_on_position_filter_changed)
	team_filter.item_selected.connect(_on_team_filter_changed)
	
	# Mostrar todos los jugadores inicialmente
	filtered_players = all_players.duplicate()
	display_players()
	
	print("PlayerEncyclopedia: Enciclopedia lista con ", all_players.size(), " jugadores")

func load_encyclopedia_data():
	print("PlayerEncyclopedia: Cargando datos de la enciclopedia...")
	
	var file = FileAccess.open("res://data/encyclopedia_data.json", FileAccess.READ)
	if file == null:
		print("ERROR: No se pudo cargar encyclopedia_data.json")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("ERROR: Error al parsear encyclopedia_data.json")
		return
	
	var data = json.data
	all_players = data.all_players
	
	print("PlayerEncyclopedia: Datos cargados correctamente")

func setup_filters():
	# Configurar filtro de posiciones
	position_filter.add_item("Todas las posiciones")
	var positions = {}
	for player in all_players:
		positions[player.position] = true
	
	for position in positions.keys():
		position_filter.add_item(position)
	
	# Configurar filtro de equipos
	team_filter.add_item("Todos los equipos")
	var teams = {}
	for player in all_players:
		teams[player.team] = true
	
	for team in teams.keys():
		team_filter.add_item(team)

func display_players():
	print("PlayerEncyclopedia: Mostrando ", filtered_players.size(), " jugadores")
	
	# Limpiar la grilla
	for child in grid_container.get_children():
		child.queue_free()
	
	# Crear tarjeta para cada jugador filtrado
	for player_data in filtered_players:
		create_player_card(player_data)

func create_player_card(player_data: Dictionary):
	# Crear el contenedor de la tarjeta
	var card = PanelContainer.new()
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	
	# Estilo de la tarjeta
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.15, 0.15, 0.25, 0.9)
	stylebox.border_width_bottom = 2
	stylebox.border_color = get_team_color(player_data.team)
	card.add_theme_stylebox_override("panel", stylebox)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	# Nombre del jugador
	var name_label = Label.new()
	name_label.text = player_data.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(name_label)
	
	# Imagen del jugador
	var texture_rect = TextureRect.new()
	var player_image = load(player_data.image)
	if player_image != null:
		texture_rect.texture = player_image
	else:
		var default_image = load("res://assets/images/characters/proximamente2.png")
		if default_image != null:
			texture_rect.texture = default_image
	
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.custom_minimum_size = Vector2(120, 120)
	vbox.add_child(texture_rect)
	
	# Overall
	var overall_label = Label.new()
	overall_label.text = "Overall: " + str(player_data.overall)
	overall_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overall_label.add_theme_font_size_override("font_size", 16)
	overall_label.add_theme_color_override("font_color", get_overall_color(player_data.overall))
	vbox.add_child(overall_label)
	
	# Posición
	var position_label = Label.new()
	position_label.text = player_data.position
	position_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	position_label.add_theme_font_size_override("font_size", 14)
	position_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	vbox.add_child(position_label)
	
	# Equipo
	var team_label = Label.new()
	team_label.text = player_data.team
	team_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	team_label.add_theme_font_size_override("font_size", 12)
	team_label.add_theme_color_override("font_color", get_team_color(player_data.team))
	vbox.add_child(team_label)
	
	# Botón de información
	var info_button = Button.new()
	info_button.text = "Ver Info"
	info_button.add_theme_font_size_override("font_size", 12)
	info_button.pressed.connect(_on_info_button_pressed.bind(player_data))
	vbox.add_child(info_button)
	
	grid_container.add_child(card)

func get_team_color(team_name: String) -> Color:
	match team_name:
		"FC Bufas":
			return Color.YELLOW
		"Deportivo Magadios":
			return Color.RED
		"Patrulla Canina":
			return Color.BLUE
		"Reyes de Jalisco":
			return Color.ORANGE
		"Inter de Panzones":
			return Color.GREEN
		"Chocolateros FC":
			return Color(0.6, 0.3, 0.1)  # Brown
		"Fantasy FC":
			return Color.MAGENTA
		"Picacachorras FC":
			return Color.CYAN
		_:
			return Color.WHITE

func get_overall_color(overall: int) -> Color:
	if overall >= 90:
		return Color.GOLD
	elif overall >= 85:
		return Color.ORANGE
	elif overall >= 80:
		return Color.GREEN
	elif overall >= 75:
		return Color.YELLOW
	else:
		return Color.WHITE

func _on_search_text_changed(new_text: String):
	apply_filters()

func _on_position_filter_changed(index: int):
	apply_filters()

func _on_team_filter_changed(index: int):
	apply_filters()

func apply_filters():
	var search_text = search_line_edit.text.to_lower()
	var selected_position = position_filter.get_item_text(position_filter.selected)
	var selected_team = team_filter.get_item_text(team_filter.selected)
	
	filtered_players.clear()
	
	for player in all_players:
		var matches_search = search_text.is_empty() or player.name.to_lower().contains(search_text)
		var matches_position = selected_position == "Todas las posiciones" or player.position == selected_position
		var matches_team = selected_team == "Todos los equipos" or player.team == selected_team
		
		if matches_search and matches_position and matches_team:
			filtered_players.append(player)
	
	display_players()

func _on_info_button_pressed(player_data: Dictionary):
	print("PlayerEncyclopedia: Ver info del jugador ", player_data.name)
	# Crear un popup de información temporal usando los datos existentes
	var popup_scene = load(PLAYER_INFO_POPUP).instantiate()
	add_child(popup_scene)
	
	# Simular el método set_player usando los datos directos
	popup_scene.set_player_direct(player_data)

func _on_back_button_pressed():
	print("PlayerEncyclopedia: Volviendo al menú del barrio...")
	get_tree().change_scene_to_file("res://scenes/NeighborhoodMenu.tscn")

# Función para manejar la tecla ESC (volver atrás)
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
