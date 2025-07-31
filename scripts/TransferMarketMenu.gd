extends Control

var transferable_button
var active_negotiations_button
var money_label
var back_button

func _ready():
	print("TransferMarketMenu: Inicializando menú principal del mercado de traspasos")
	
	# Buscar nodos
	transferable_button = get_node_or_null("VBoxContainer/ButtonsContainer/TransferableButton")
	active_negotiations_button = get_node_or_null("VBoxContainer/ButtonsContainer/ActiveNegotiationsButton")
	money_label = get_node_or_null("VBoxContainer/InfoContainer/MoneyLabel")
	back_button = get_node_or_null("VBoxContainer/InfoContainer/BackButton")
	
	# Conectar botones
	if transferable_button:
		transferable_button.pressed.connect(_on_transferable_pressed)
		print("TransferMarketMenu: Botón 'Transferibles' conectado")
	
	if active_negotiations_button:
		active_negotiations_button.pressed.connect(_on_active_negotiations_pressed)
		print("TransferMarketMenu: Botón 'Negociaciones Activas' conectado")
	
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
		print("TransferMarketMenu: Botón 'Volver' conectado")
	
	# Actualizar dinero
	update_money_display()
	
	# Actualizar contador de negociaciones activas
	update_negotiations_counter()
	
	print("TransferMarketMenu: Menú principal listo")

func update_money_display():
	if money_label and GameManager:
		var current_money = GameManager.get_money()
		money_label.text = "Dinero disponible: €%s" % current_money

func update_negotiations_counter():
	if active_negotiations_button and TransferMarketManager:
		var active_count = TransferMarketManager.get_active_negotiations().size()
		if active_count > 0:
			active_negotiations_button.text = "NEGOCIACIONES ACTIVAS (%d)" % active_count
		else:
			active_negotiations_button.text = "NEGOCIACIONES ACTIVAS"

func _on_transferable_pressed():
	print("TransferMarketMenu: Navegando a jugadores transferibles")
	get_tree().change_scene_to_file("res://scenes/TransferablePlayersMarket.tscn")

func _on_active_negotiations_pressed():
	print("TransferMarketMenu: Navegando a negociaciones activas")
	get_tree().change_scene_to_file("res://scenes/ActiveNegotiationsMarket.tscn")

func _on_back_pressed():
	print("TransferMarketMenu: Volviendo al menú del barrio")
	get_tree().change_scene_to_file("res://scenes/NeighborhoodMenu.tscn")
