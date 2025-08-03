extends Node

# Singleton del sistema de correos
signal new_mail_received(mail_data: Dictionary)
signal mail_read(mail_id: String)

var mails: Array = []
var next_mail_id: int = 1

# Estructuras de datos para mails
var mail_templates = {
	"low_morale_complaint": {
		"type": "player_complaint",
		"subject": "Situación en el equipo",
		"template": "Hola, soy {player_name}.\n\nEstoy escribiendo para expresar mi preocupación sobre mi situación actual en el equipo. Mi moral está muy baja ({current_morale}/10) y siento que las cosas no van bien.\n\nNecesito que la situación cambie o me veré obligado a considerar otras opciones, incluyendo dejar el club.\n\nEspero que podamos resolver esto pronto.\n\nSaludos,\n{player_name}"
	},
	"negotiation_response": {
		"type": "negotiation_update",
		"subject": "Respuesta a oferta por {player_name}",
		"template": "Estimado Director Deportivo,\n\nTenemos noticias sobre tu oferta por {player_name}.\n\n{response_content}\n\nPuedes revisar los detalles completos en la sección de Negociaciones Activas.\n\nSaludos cordiales,\nDepartamento de Traspasos"
	}
}

func _ready():
	print("MailManager: Sistema de correos inicializado")
	
	# Cargar correos guardados
	load_mails_data()
	
	# Conectar a la señal de cambio de moral de los jugadores
	if has_node("/root/PlayersManager"):
		var players_manager = get_node("/root/PlayersManager")
		# Verificar moral de jugadores al inicio y después de cada cambio
		check_player_morale_periodically()
	
	# Conectar a las respuestas de negociaciones
	if has_node("/root/TransferMarketManager"):
		var transfer_manager = get_node("/root/TransferMarketManager")
		transfer_manager.negotiation_response_received.connect(_on_negotiation_response_received)
		print("MailManager: Conectado a señal de respuestas de negociaciones")

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Vaciar todos los correos al cerrar el juego
		clear_all_mails()
		print("MailManager: Correos vaciados al cerrar el juego")

func _exit_tree():
	# También vaciar correos cuando el nodo se destruye
	clear_all_mails()
	print("MailManager: Correos vaciados al salir del árbol de nodos")

# Verificar la moral de los jugadores periódicamente
func check_player_morale_periodically():
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.0  # Verificar cada segundo (para testing, en producción sería más largo)
	timer.timeout.connect(_on_morale_check_timer)
	timer.start()

func _on_morale_check_timer():
	var players_manager = get_node("/root/PlayersManager")
	if not players_manager:
		return
	
	var players = players_manager.get_all_players()
	for player in players:
		var current_morale = players_manager.get_player_morale(player.id)
		
		# Si la moral es 0 y no hay un correo reciente de este jugador
		if current_morale == 0 and not has_recent_complaint_from_player(player.id):
			create_low_morale_mail(player)

# Verificar si ya hay un correo reciente de queja de este jugador
func has_recent_complaint_from_player(player_id: String) -> bool:
	for mail in mails:
		if mail.type == "player_complaint" and mail.player_id == player_id:
			# Si el correo es de las últimas 24 horas (o en este caso, si ya existe uno)
			return true
	return false

# Crear correo de moral baja
func create_low_morale_mail(player_data: Dictionary):
	var players_manager = get_node("/root/PlayersManager")
	var current_morale = players_manager.get_player_morale(player_data.id)
	
	var template = mail_templates["low_morale_complaint"]
	var mail_content = template.template.format({
		"player_name": player_data.name,
		"current_morale": current_morale
	})
	
	var mail_data = {
		"id": "mail_" + str(next_mail_id),
		"type": template.type,
		"player_id": player_data.id,
		"player_name": player_data.name,
		"subject": template.subject,
		"content": mail_content,
		"is_read": false,
		"timestamp": Time.get_unix_time_from_system(),
		"priority": "high"
	}
	
	mails.append(mail_data)
	next_mail_id += 1
	
	print("📧 MailManager: Nuevo correo de ", player_data.name, " por moral baja")
	new_mail_received.emit(mail_data)
	
	# Guardar los correos
	save_mails_data()

# Obtener todos los correos
func get_all_mails() -> Array:
	return mails

# Obtener correos no leídos
func get_unread_mails() -> Array:
	var unread = []
	for mail in mails:
		if not mail.is_read:
			unread.append(mail)
	return unread

# Marcar correo como leído
func mark_mail_as_read(mail_id: String):
	for mail in mails:
		if mail.id == mail_id:
			mail.is_read = true
			mail_read.emit(mail_id)
			save_mails_data()
			return

# Eliminar correo
func delete_mail(mail_id: String):
	for i in range(mails.size()):
		if mails[i].id == mail_id:
			mails.remove_at(i)
			save_mails_data()
			return

# Verificar si hay correos no leídos
func has_unread_mails() -> bool:
	return get_unread_mails().size() > 0

# Obtener número de correos no leídos
func get_unread_count() -> int:
	return get_unread_mails().size()

# Vaciar todos los correos
func clear_all_mails():
	mails.clear()
	next_mail_id = 1
	save_mails_data()
	print("MailManager: Todos los correos han sido eliminados")

# Eliminar correos de negociación específicos
func delete_negotiation_mails(player_id: String = ""):
	var mails_to_remove = []
	
	# Recopilar correos de negociación a eliminar
	for i in range(mails.size()):
		var mail = mails[i]
		if mail.type == "negotiation_update":
			# Si se especifica player_id, solo borrar ese, sino borrar todos
			if player_id == "" or mail.player_id == player_id:
				mails_to_remove.append(i)
	
	# Eliminar en orden inverso para no afectar los índices
	for i in range(mails_to_remove.size() - 1, -1, -1):
		mails.remove_at(mails_to_remove[i])
	
	if mails_to_remove.size() > 0:
		save_mails_data()
		print("MailManager: Eliminados ", mails_to_remove.size(), " correos de negociación")

# Guardar correos en archivo
func save_mails_data():
	var save_data = {
		"mails": mails,
		"next_mail_id": next_mail_id
	}
	
	var file = FileAccess.open("user://mails_data.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

# Cargar correos desde archivo
func load_mails_data():
	var file = FileAccess.open("user://mails_data.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var data = json.data
			mails = data.get("mails", [])
			next_mail_id = data.get("next_mail_id", 1)
			print("MailManager: Correos cargados: ", mails.size())
		else:
			print("MailManager: Error al parsear datos de correos")
	else:
		print("MailManager: No se encontró archivo de correos, empezando limpio")

# Manejar respuesta de negociación
func _on_negotiation_response_received(player_id: String, response: Dictionary):
	print("📧 MailManager: Respuesta de negociación recibida para jugador ", player_id, " - estado: ", response.status)
	
	# Obtener información del jugador desde TransferMarketManager
	var transfer_manager = get_node("/root/TransferMarketManager")
	var negotiation = transfer_manager.get_negotiation_by_id(player_id)
	
	if negotiation.is_empty():
		print("MailManager: No se pudo obtener información de la negociación")
		return
	
	var player_name = negotiation.get("player_name", "Jugador desconocido")
	
	# Generar contenido del correo según el tipo de respuesta
	var response_content = generate_negotiation_response_content(response)
	
	# Crear el correo
	create_negotiation_mail(player_name, player_id, response_content)

# Generar contenido del correo según la respuesta
func generate_negotiation_response_content(response: Dictionary) -> String:
	var content = ""
	
	match response.status:
		"accepted":
			content = "🎉 ¡EXCELENTES NOTICIAS! 🎉\n\n¡El representante ha ACEPTADO tu oferta! El jugador está listo para unirse a FC Bufas.\n\nPuedes finalizar la transferencia desde Negociaciones Activas."
		"counter_offer":
			var counter_amount = response.get("counter_offer", 0)
			content = "💰 CONTRAOFERTA RECIBIDA 💰\n\nEl representante ha respondido con una contraoferta de €" + str(counter_amount) + ".\n\nPuedes revisar los detalles y decidir si aceptar, rechazar, o hacer una nueva contraoferta."
		"rejected":
			content = "❌ OFERTA RECHAZADA ❌\n\nLamentablemente, el representante ha rechazado tu oferta. La negociación ha terminado.\n\nPuedes intentar con otros jugadores en el mercado de traspasos."
		_:
			content = "Hemos recibido una respuesta del representante. Revisa los detalles en Negociaciones Activas."
	
	return content

# Crear correo de respuesta de negociación
func create_negotiation_mail(player_name: String, player_id: String, response_content: String):
	var template = mail_templates["negotiation_response"]
	
	# Formatear el asunto y contenido
	var mail_subject = template.subject.format({"player_name": player_name})
	var mail_content = template.template.format({
		"player_name": player_name,
		"response_content": response_content
	})
	
	var mail_data = {
		"id": "mail_" + str(next_mail_id),
		"type": template.type,
		"player_id": player_id,
		"player_name": player_name,
		"subject": mail_subject,
		"content": mail_content,
		"is_read": false,
		"timestamp": Time.get_unix_time_from_system(),
		"priority": "medium",
		"action_type": "view_negotiations"  # Para el botón de acción
	}
	
	mails.append(mail_data)
	next_mail_id += 1
	
	print("📧 MailManager: Nuevo correo de negociación para ", player_name)
	new_mail_received.emit(mail_data)
	
	# Guardar los correos
	save_mails_data()
