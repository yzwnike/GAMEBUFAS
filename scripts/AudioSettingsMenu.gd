extends Control

# AudioSettingsMenu - Menú de ajustes de audio con interfaz de ruedita
signal close_requested

# Referencias a controles de audio
@onready var master_slider: HSlider = $MainContainer/WheelPanel/VBoxContainer/MasterVolume/VolumeSlider
@onready var music_slider: HSlider = $MainContainer/WheelPanel/VBoxContainer/MusicVolume/VolumeSlider
@onready var sfx_slider: HSlider = $MainContainer/WheelPanel/VBoxContainer/SFXVolume/VolumeSlider
@onready var master_label: Label = $MainContainer/WheelPanel/VBoxContainer/MasterVolume/VolumeLabel
@onready var music_label: Label = $MainContainer/WheelPanel/VBoxContainer/MusicVolume/VolumeLabel
@onready var sfx_label: Label = $MainContainer/WheelPanel/VBoxContainer/SFXVolume/VolumeLabel
@onready var close_button: Button = $MainContainer/WheelPanel/VBoxContainer/CloseButton

# Variable para efecto de rotación de la ruedita
var rotation_tween: Tween

func _ready():
	print("AudioSettingsMenu: Inicializando menú de ajustes de audio...")
	
	# Configurar sliders
	setup_sliders()
	
	# Conectar señales
	connect_signals()
	
	# Cargar valores actuales del AudioManager
	load_current_values()
	
	# Crear efecto visual de ruedita
	create_wheel_effect()
	
	print("AudioSettingsMenu: Menú de ajustes listo")

func setup_sliders():
	# Configurar rangos de los sliders (0 a 100 para mejor UI)
	if master_slider:
		master_slider.min_value = 0
		master_slider.max_value = 100
		master_slider.step = 1
	
	if music_slider:
		music_slider.min_value = 0
		music_slider.max_value = 100
		music_slider.step = 1
	
	if sfx_slider:
		sfx_slider.min_value = 0
		sfx_slider.max_value = 100
		sfx_slider.step = 1

func connect_signals():
	# Conectar cambios de volumen
	if master_slider:
		master_slider.value_changed.connect(_on_master_volume_changed)
	if music_slider:
		music_slider.value_changed.connect(_on_music_volume_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# Conectar botón de cerrar
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func load_current_values():
	if not AudioManager:
		return
	
	# Cargar valores actuales (convertir de 0.0-1.0 a 0-100)
	if master_slider:
		master_slider.value = AudioManager.get_master_volume() * 100
	if music_slider:
		music_slider.value = AudioManager.get_music_volume() * 100
	if sfx_slider:
		sfx_slider.value = AudioManager.get_sfx_volume() * 100
	
	# Actualizar etiquetas
	update_volume_labels()

func update_volume_labels():
	if master_label and master_slider:
		master_label.text = str(int(master_slider.value)) + "%"
	if music_label and music_slider:
		music_label.text = str(int(music_slider.value)) + "%"
	if sfx_label and sfx_slider:
		sfx_label.text = str(int(sfx_slider.value)) + "%"

func create_wheel_effect():
	# Crear efecto visual de ruedita giratoria (deshabilitado por ahora)
	# rotation_tween = create_tween()
	# rotation_tween.set_loops()
	# rotation_tween.tween_property(self, "rotation", 2 * PI, 5.0)
	# rotation_tween.tween_interval(1.0)
	pass # Sin rotación por ahora

func _on_master_volume_changed(value: float):
	if AudioManager:
		AudioManager.set_master_volume(value / 100.0)
	master_label.text = str(int(value)) + "%"
	print("AudioSettings: Volumen maestro cambiado a ", int(value), "%")

func _on_music_volume_changed(value: float):
	if AudioManager:
		AudioManager.set_music_volume(value / 100.0)
	music_label.text = str(int(value)) + "%"
	print("AudioSettings: Volumen de música cambiado a ", int(value), "%")

func _on_sfx_volume_changed(value: float):
	if AudioManager:
		AudioManager.set_sfx_volume(value / 100.0)
	sfx_label.text = str(int(value)) + "%"
	print("AudioSettings: Volumen de efectos cambiado a ", int(value), "%")

func _on_close_pressed():
	close_requested.emit()

# Función para mostrar/ocultar el menú con animación
func show_menu():
	visible = true
	modulate = Color(1, 1, 1, 0)
	scale = Vector2(0.8, 0.8)
	
	var show_tween = create_tween()
	show_tween.set_parallel(true)
	show_tween.tween_property(self, "modulate:a", 1.0, 0.15)  # Más rápido
	show_tween.tween_property(self, "scale", Vector2(1, 1), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_menu():
	var hide_tween = create_tween()
	hide_tween.set_parallel(true)
	hide_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	hide_tween.tween_property(self, "scale", Vector2(0.5, 0.5), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await hide_tween.finished
	visible = false
