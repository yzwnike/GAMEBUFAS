extends Control

# PauseMenu script
signal resume_requested
signal settings_requested
signal main_menu_requested
signal quit_requested

@onready var resume_button = $PausePanel/VBoxContainer/ResumeButton
@onready var settings_button = $PausePanel/VBoxContainer/SettingsButton
@onready var main_menu_button = $PausePanel/VBoxContainer/MainMenuButton
@onready var quit_button = $PausePanel/VBoxContainer/QuitButton

# Menú de ajustes de audio
var audio_settings_scene = preload("res://scenes/AudioSettingsMenu.tscn")
var current_audio_settings = null

func _ready():
	resume_button.connect("pressed", _on_resume_pressed)
	settings_button.connect("pressed", _on_settings_pressed)
	main_menu_button.connect("pressed", _on_main_menu_pressed)
	quit_button.connect("pressed", _on_quit_pressed)
	
	# Hacer visible el menú al crearse
	visible = true

func _on_resume_pressed():
	resume_requested.emit()

func _on_settings_pressed():
	settings_requested.emit()
	show_audio_settings()

func _on_main_menu_pressed():
	main_menu_requested.emit()

func _on_quit_pressed():
	quit_requested.emit()
	get_tree().quit()

func show_audio_settings():
	if current_audio_settings:
		return
	
	# Instanciar el menú de ajustes de audio
	current_audio_settings = audio_settings_scene.instantiate()
	current_audio_settings.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Conectar señal de cierre
	current_audio_settings.close_requested.connect(hide_audio_settings)
	
	# Añadir al menú de pausa
	add_child(current_audio_settings)
	current_audio_settings.show_menu()

func hide_audio_settings():
	if current_audio_settings:
		current_audio_settings.hide_menu()
		await current_audio_settings.tree_exited
		current_audio_settings = null
