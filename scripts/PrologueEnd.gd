extends Control

@onready var prologue_label = $CenterContainer/VBoxContainer/PrologueLabel
@onready var subtitle_label = $CenterContainer/VBoxContainer/SubtitleLabel
@onready var continue_label = $CenterContainer/VBoxContainer/ContinueLabel

var can_continue = false
var is_transitioning = false

func _ready():
	# Ocultar todo al principio
	prologue_label.modulate.a = 0
	subtitle_label.modulate.a = 0
	continue_label.modulate.a = 0
	
	# Aplicar estilos de fuente desde el código
	var title_font = LabelSettings.new()
	title_font.font_size = 72
	title_font.font_color = Color.WHITE
	title_font.outline_size = 5
	title_font.outline_color = Color.BLACK
	prologue_label.label_settings = title_font
	
	var subtitle_font = LabelSettings.new()
	subtitle_font.font_size = 36
	subtitle_font.font_color = Color(0.8, 0.8, 0.8)
	subtitle_label.label_settings = subtitle_font
	
	var continue_font = LabelSettings.new()
	continue_font.font_size = 24
	continue_font.font_color = Color.GOLD
	continue_label.label_settings = continue_font
	
	play_animation()

func play_animation():
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Animación del título
	tween.tween_property(prologue_label, "modulate:a", 1, 2.0)
	tween.tween_interval(1.5)
	
	# Animación del subtítulo
	tween.tween_property(subtitle_label, "modulate:a", 1, 1.5)
	tween.tween_interval(1.0)
	
	# Animación del texto de continuar
	tween.tween_property(continue_label, "modulate:a", 1, 1.0)
	
	# Cuando la animación termine, permitir continuar
	tween.finished.connect(func(): can_continue = true)

func _input(event):
	# No hacer nada si no se puede continuar o si ya se está transicionando
	if not can_continue or is_transitioning:
		return

	if event.is_action_pressed("ui_accept"):
		is_transitioning = true
		print("¡Botón presionado! Intentando cambiar a InteractiveMenu.tscn...")
		
		# Intentar cargar el menú interactivo
		var result = get_tree().change_scene_to_file("res://scenes/InteractiveMenu.tscn")
		if result != OK:
			print("Error al cargar InteractiveMenu.tscn, código: ", result)
			print("Cargando MainMenu.tscn como respaldo...")
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

