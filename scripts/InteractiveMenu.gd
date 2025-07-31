extends Control

@onready var hover_info_panel = $UILayer/HoverInfo
@onready var info_label = $UILayer/HoverInfo/InfoLabel
@onready var day_label = $UILayer/DayContainer/DayLabel

func _ready():
	print("InteractiveMenu: Inicializando menú interactivo...")
	
	# Verificar que todos los nodos existen
	var estadio_area = $ClickableAreas/EstadioArea
	var campo_area = $ClickableAreas/CampoArea
	var barrio_area = $ClickableAreas/BarrioArea
	
	if not estadio_area or not campo_area or not barrio_area:
		print("ERROR: No se pudieron encontrar todas las áreas clickables")
		return
	
	print("InteractiveMenu: Conectando señales...")
	
	# Conectar señales de hover
	estadio_area.mouse_entered.connect(func(): _on_area_hovered("estadio"))
	estadio_area.mouse_exited.connect(self._on_area_exited)
	
	campo_area.mouse_entered.connect(func(): _on_area_hovered("campo"))
	campo_area.mouse_exited.connect(self._on_area_exited)
	
	barrio_area.mouse_entered.connect(func(): _on_area_hovered("barrio"))
	barrio_area.mouse_exited.connect(self._on_area_exited)
	
	# Conectar señales de clic
	estadio_area.pressed.connect(func(): _on_area_clicked("estadio"))
	campo_area.pressed.connect(func(): _on_area_clicked("campo"))
	barrio_area.pressed.connect(func(): _on_area_clicked("barrio"))
	
	# Actualizar visualización del día
	update_day_display()
	
	# Conectar a la señal de cambio de día si existe
	if DayManager.has_signal("day_changed"):
		DayManager.day_changed.connect(update_day_display)
	
	print("InteractiveMenu: Menú interactivo listo")

func _on_area_hovered(area_name):
	hover_info_panel.visible = true
	
	match area_name:
		"estadio":
			info_label.text = "Torneo Tiki-Taka: Compite en el torneo de fútbol 7 y demuestra quién es el mejor equipo."
		"campo":
			info_label.text = "Campo de Entrenamiento: Mejora tus habilidades y las de tu equipo."
		"barrio":
			info_label.text = "El Barrio: Fichajes, enciclopedia de jugadores y tienda de suplementos."

func _on_area_exited():
	hover_info_panel.visible = false

func _on_area_clicked(area_name):
	print("InteractiveMenu: Área clickeada: ", area_name)
	
	match area_name:
		"estadio":
			print("Accediendo al Torneo Tiki-Taka...")
			get_tree().change_scene_to_file("res://scenes/TournamentMenu.tscn")
		"campo":
			print("Accediendo al Campo de Entrenamiento...")
			get_tree().change_scene_to_file("res://scenes/TrainingMenu.tscn")
		"barrio":
			print("Accediendo al Barrio...")
			get_tree().change_scene_to_file("res://scenes/NeighborhoodMenu.tscn")

# Actualizar visualización del día actual
func update_day_display():
	var current_day = DayManager.get_current_day()
	day_label.text = "Día %d" % current_day

