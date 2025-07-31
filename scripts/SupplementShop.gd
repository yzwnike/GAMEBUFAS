extends Control

@onready var grid_container = $VBoxContainer/ScrollContainer/MarginContainer/GridContainer
@onready var back_button = $VBoxContainer/Footer/BackButton
@onready var money_label = $VBoxContainer/Header/VBoxContainer/MoneyLabel
@onready var background_rect = $BackgroundRect

var shop_products: Array = []

var game_manager: Node

func _ready():
	print("SupplementShop: Inicializando tienda...")
	
	# Cargar imagen de fondo
	var bg_texture = load("res://assets/images/backgrounds/tienda.png")
	if bg_texture != null:
		background_rect.texture = bg_texture
	else:
		print("Advertencia: No se pudo cargar la imagen de fondo de la tienda.")
	
	# Cargar datos de la tienda
	load_shop_data()
	
	# Obtener referencia al GameManager
	game_manager = get_node("/root/GameManager")
	if game_manager == null:
		print("ERROR: No se pudo encontrar GameManager")
	else:
		# Conectar señal de actualización de dinero
		game_manager.money_updated.connect(_on_money_updated)
		# Actualizar el label de dinero
		_on_money_updated(game_manager.get_money())
	
	# Conectar señales
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Mostrar productos
	display_products()
	
	print("SupplementShop: Tienda lista con ", shop_products.size(), " productos")

func load_shop_data():
	print("SupplementShop: Cargando datos de productos...")
	
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
	
	print("SupplementShop: Datos de productos cargados correctamente")

func display_products():
	# Limpiar la grilla
	for child in grid_container.get_children():
		child.queue_free()
	
	# Crear tarjeta para cada producto
	for product_data in shop_products:
		create_product_card(product_data)

func create_product_card(product_data: Dictionary):
	# Crear contenedor de la tarjeta
	var card = PanelContainer.new()
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	
	# Estilo de la tarjeta
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.3, 0.3, 0.4, 0.7)
	stylebox.border_width_bottom = 2
	stylebox.border_color = Color.GOLD
	card.add_theme_stylebox_override("panel", stylebox)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	# Nombre del producto
	var name_label = Label.new()
	name_label.text = product_data.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(name_label)
	
	# Imagen del producto
	var texture_rect = TextureRect.new()
	var product_image = load(product_data.image)
	if product_image != null:
		texture_rect.texture = product_image
	else:
		var default_image = load("res://assets/images/items/placeholder.png") # Placeholder si no existe la imagen
		if default_image != null:
			texture_rect.texture = default_image
	
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.custom_minimum_size = Vector2(100, 100)
	vbox.add_child(texture_rect)
	
	# Descripción
	var desc_label = Label.new()
	desc_label.text = product_data.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	
	# Precio
	var price_label = Label.new()
	price_label.text = "Precio: $" + str(product_data.price)
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(price_label)
	
	# Botón de compra
	var buy_button = Button.new()
	buy_button.text = "Comprar"
	buy_button.pressed.connect(_on_buy_button_pressed.bind(product_data.id))
	vbox.add_child(buy_button)
	
	grid_container.add_child(card)

func _on_buy_button_pressed(product_id: String):
	print("SupplementShop: Botón de compra presionado para ", product_id)
	
	if game_manager == null:
		print("ERROR: GameManager no está disponible")
		return
	
	var product = get_product_by_id(product_id)
	if product == null:
		print("ERROR: Producto no encontrado")
		return
	
	# Lógica de compra
	if game_manager.get_money() >= product.price:
		game_manager.add_money(-product.price)
		game_manager.add_item_to_inventory(product_id, 1)
		print("¡Compra exitosa! Has comprado: ", product.name)
		# TODO: Mostrar notificación de compra exitosa
	else:
		print("Dinero insuficiente para comprar ", product.name)
		# TODO: Mostrar notificación de dinero insuficiente

func get_product_by_id(product_id: String):
	for product in shop_products:
		if product.id == product_id:
			return product
	return null

func _on_money_updated(new_amount: int):
	money_label.text = "Dinero: $" + str(new_amount)

func _on_back_button_pressed():
	print("SupplementShop: Volviendo al menú del barrio...")
	get_tree().change_scene_to_file("res://scenes/NeighborhoodMenu.tscn")

# Función para manejar la tecla ESC (volver atrás)
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
