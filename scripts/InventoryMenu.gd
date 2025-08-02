extends Control

@onready var grid_container = $VBoxContainer/ScrollContainer/MarginContainer/GridContainer
@onready var back_button = $VBoxContainer/Footer/BackButton

var game_manager: Node
var players_manager: Node
var shop_products: Array = []

# Escenas de popups
const PLAYER_SELECTION_POPUP = "res://scenes/popups/PlayerSelectionPopup.tscn"

func _ready():
	print("InventoryMenu: Inicializando inventario...")
	
	# Cargar datos de la tienda para obtener detalles de los productos
	load_shop_data()
	
	# Obtener referencia al GameManager
	game_manager = get_node("/root/GameManager")
	if game_manager == null:
		print("ERROR: No se pudo encontrar GameManager")
	else:
		# Conectar señal de actualización de inventario
		game_manager.inventory_updated.connect(display_inventory)
	
	# Obtener referencia al PlayersManager
	players_manager = get_node("/root/PlayersManager")
	if players_manager == null:
		print("ERROR: No se pudo encontrar PlayersManager")
	
	# Conectar señales
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Mostrar inventario
	display_inventory()
	
	print("InventoryMenu: Inventario listo")

func load_shop_data():
	print("InventoryMenu: Cargando datos de productos de la tienda...")
	
	var file = FileAccess.open("res://data/shop_data.json", FileAccess.READ)
	if file == null:
		print("ERROR: No se pudo cargar shop_data.json")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("ERROR: Error al parsear shop_data.json")
		return
	
	var data = json.data
	shop_products = data.products
	
	print("InventoryMenu: Datos de productos cargados correctamente")

func display_inventory():
	if game_manager == null:
		return
	
	var inventory = game_manager.get_inventory()
	print("InventoryMenu: Mostrando inventario - ", inventory)
	
	# Limpiar la grilla
	for child in grid_container.get_children():
		child.queue_free()
	
	# Crear tarjeta para cada item en el inventario
	for item_id in inventory.keys():
		var quantity = inventory[item_id]
		var product_data = get_product_by_id(item_id)
		
		if product_data != null and quantity > 0:
			create_item_card(product_data, quantity)

func create_item_card(product_data: Dictionary, quantity: int):
	# Crear contenedor de la tarjeta
	var card = PanelContainer.new()
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	
	# Estilo de la tarjeta
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.2, 0.3, 0.2, 0.8)
	stylebox.border_width_bottom = 2
	stylebox.border_color = Color.LIME_GREEN
	card.add_theme_stylebox_override("panel", stylebox)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	# Nombre del item
	var name_label = Label.new()
	name_label.text = product_data.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(name_label)
	
	# Imagen del item
	var texture_rect = TextureRect.new()
	var product_image = load(product_data.image)
	if product_image != null:
		texture_rect.texture = product_image
	else:
		var default_image = load("res://assets/images/items/placeholder.png")
		if default_image != null:
			texture_rect.texture = default_image
	
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.custom_minimum_size = Vector2(100, 100)
	vbox.add_child(texture_rect)
	
	# Cantidad
	var quantity_label = Label.new()
	quantity_label.text = "Cantidad: " + str(quantity)
	quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(quantity_label)
	
	# Botón de uso
	var use_button = Button.new()
	use_button.text = "Usar"
	use_button.pressed.connect(_on_use_button_pressed.bind(product_data.id))
	vbox.add_child(use_button)
	
	grid_container.add_child(card)

func _on_use_button_pressed(item_id: String):
	print("InventoryMenu: Botón de usar presionado para ", item_id)
	
	var product_data = get_product_by_id(item_id)
	if product_data == null:
		return
	
	# Lógica de uso de items
	match product_data.type:
		"stat_boost":
			# Abrir popup de selección de jugador
			open_player_selection_popup(product_data)
		"position_boost":
			# Aplicar mejora a todos los jugadores de la posición
			apply_position_boost(product_data)
			# Reducir la cantidad del item
			if game_manager != null:
				game_manager.add_item_to_inventory(item_id, -1)

func get_product_by_id(product_id: String):
	for product in shop_products:
		if product.id == product_id:
			return product
	return null

func _on_back_button_pressed():
	print("InventoryMenu: Volviendo al menú de entrenamiento...")
	get_tree().change_scene_to_file("res://scenes/TrainingMenu.tscn")

# Función para manejar la tecla ESC (volver atrás)
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()

func open_player_selection_popup(item_data: Dictionary):
	var popup_scene = load(PLAYER_SELECTION_POPUP).instantiate()
	add_child(popup_scene)
	popup_scene.set_item(item_data)
	popup_scene.player_selected.connect(_on_player_selected_for_boost.bind(item_data))

func _on_player_selected_for_boost(player_id: String, item_data: Dictionary):
	print("Aplicando ", item_data.name, " a ", player_id)
	
	if players_manager == null:
		print("ERROR: PlayersManager no está disponible")
		return
	
	# Verificar el tipo de ítem para aplicar correctamente
	if item_data.stat == "stamina":
		# Para ítems de stamina, usar recharge_stamina que afecta current_stamina
		players_manager.recharge_stamina(player_id, item_data.value)
	elif item_data.stat == "morale":
		# Para ítems de moral, usar boost_morale
		players_manager.boost_morale(player_id, item_data.value)
	else:
		# Para otros stats, usar upgrade_player
		players_manager.upgrade_player(player_id, item_data.stat, item_data.value)
	
	# Reducir la cantidad del item
	if game_manager != null:
		game_manager.add_item_to_inventory(item_data.id, -1)

func apply_position_boost(item_data: Dictionary):
	if players_manager == null:
		print("ERROR: PlayersManager no está disponible")
		return
	
	var players = players_manager.get_all_players()
	var position_to_boost = item_data.position
	var stat_to_boost = item_data.stat
	var boost_value = item_data.value
	
	for player in players:
		if player.position == position_to_boost:
			players_manager.upgrade_player(player.id, stat_to_boost, boost_value)
			print("Mejora de posición aplicada a: ", player.name)
	
	print("Mejora de posición completada para ", position_to_boost)
