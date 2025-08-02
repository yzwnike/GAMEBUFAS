extends Node
class_name MenuSetupHelper

# Helper class para simplificar la implementación del sistema de hover en todos los menús

# Configuraciones predefinidas para botones comunes
static var common_button_configs = {
	"back": {
		"description": "Regresar al menú\nanterior",
		"icon_path": "res://assets/images/icons/back.png"
	},
	"squad": {
		"description": "Visualiza tu plantilla completa\ny gestiona a tus jugadores",
		"icon_path": "res://assets/images/icons/team.png"
	},
	"training": {
		"description": "Entrena con tu equipo\npara mejorar sus habilidades",
		"icon_path": "res://assets/images/icons/training.png"
	},
	"inventory": {
		"description": "Revisa tus objetos\ny suplementos disponibles",
		"icon_path": "res://assets/images/icons/inventory.png"
	},
	"psychologist": {
		"description": "Consulta con el psicólogo\npara mejorar la moral",
		"icon_path": "res://assets/images/icons/psychology.png"
	},
	"tournament": {
		"description": "Participa en el torneo\nTiki-Taka de fútbol",
		"icon_path": "res://assets/images/icons/tournament.png"
	},
	"neighborhood": {
		"description": "Explora el barrio para\nfichajes y compras",
		"icon_path": "res://assets/images/icons/neighborhood.png"
	},
	"transfer_market": {
		"description": "Busca y ficha\nnuevos jugadores",
		"icon_path": "res://assets/images/icons/transfer.png"
	},
	"mail": {
		"description": "Revisa tus correos\ny negociaciones",
		"icon_path": "res://assets/images/icons/mail.png"
	},
	"settings": {
		"description": "Ajusta las opciones\ny configuraciones del juego",
		"icon_path": "res://assets/images/icons/settings.png"
	},
	"new_game": {
		"description": "Inicia una nueva aventura en\nLa Velada del Año",
		"icon_path": "res://assets/images/icons/new_game.png"
	},
	"continue": {
		"description": "Continúa tu partida\nguardada desde donde la dejaste",
		"icon_path": "res://assets/images/icons/continue.png"
	},
	"quit": {
		"description": "Salir del juego\ny cerrar la aplicación",
		"icon_path": "res://assets/images/icons/quit.png"
	}
}

# Función principal para configurar múltiples botones fácilmente
static func setup_menu_hover_effects(menu_instance: Control, button_mappings: Dictionary):
	"""
	Configura efectos de hover para un menú completo.
	
	Parámetros:
	- menu_instance: La instancia del menú (self en el _ready del menú)
	- button_mappings: Diccionario que mapea nombres de botones a configuraciones
	
	Ejemplo de uso:
	MenuSetupHelper.setup_menu_hover_effects(self, {
		"back_button": "back",
		"squad_button": "squad",
		"training_button": "training"
	})
	"""
	var buttons_config = []
	
	for button_node_name in button_mappings:
		var config_key = button_mappings[button_node_name]
		var button_node = menu_instance.get_node_or_null(button_node_name)
		
		if button_node and common_button_configs.has(config_key):
			var config = common_button_configs[config_key]
			buttons_config.append({
				"button": button_node,
				"description": config.description,
				"icon": MenuAnimations.load_icon(config.icon_path)
			})
			print("MenuSetupHelper: Configurado botón ", button_node_name, " con config ", config_key)
		else:
			if not button_node:
				print("MenuSetupHelper: ADVERTENCIA - No se encontró el botón: ", button_node_name)
			if not common_button_configs.has(config_key):
				print("MenuSetupHelper: ADVERTENCIA - No existe configuración para: ", config_key)
	
	# Aplicar configuración a todos los botones
	MenuAnimations.setup_menu_buttons(buttons_config)
	print("MenuSetupHelper: ", buttons_config.size(), " botones configurados con efectos de hover")

# Función para configurar un botón individual con configuración personalizada
static func setup_custom_button_hover(button: Button, description: String, icon_path: String = ""):
	"""
	Configura un botón individual con descripción e icono personalizados.
	"""
	var icon = null
	if icon_path != "":
		icon = MenuAnimations.load_icon(icon_path)
	
	MenuAnimations.setup_advanced_button_hover(button, description, icon)
	print("MenuSetupHelper: Configurado botón personalizado con descripción: ", description)

# Función para agregar una nueva configuración común
static func add_common_config(key: String, description: String, icon_path: String):
	"""
	Añade una nueva configuración común que puede ser reutilizada.
	"""
	common_button_configs[key] = {
		"description": description,
		"icon_path": icon_path
	}
	print("MenuSetupHelper: Añadida configuración común: ", key)

# Función para obtener rutas de iconos comunes
static func get_icon_path(icon_name: String) -> String:
	"""
	Devuelve la ruta del icono solicitado.
	"""
	if common_button_configs.has(icon_name):
		return common_button_configs[icon_name].icon_path
	return ""

# Template de código para copiar en cualquier menú:
"""
# Añadir esto al _ready() de cualquier menú:

func setup_advanced_hover_effects():
	# OPCIÓN 1: Usar el helper (recomendado)
	MenuSetupHelper.setup_menu_hover_effects(self, {
		"BackButton": "back",
		"SquadButton": "squad", 
		"TrainingButton": "training",
		"InventoryButton": "inventory"
	})
	
	# OPCIÓN 2: Configuración manual para casos especiales
	# MenuSetupHelper.setup_custom_button_hover(
	#	my_special_button,
	#	"Descripción personalizada\npara este botón especial",
	#	"res://path/to/custom/icon.png"
	# )
"""
