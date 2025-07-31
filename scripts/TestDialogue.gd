extends Control

# TestDialogue - Sistema de diálogos simple para Godot 4.x

@onready var background = $Background
@onready var character_sprite = $CharacterSprite
@onready var dialogue_box = $DialogueBox
@onready var name_label = $DialogueBox/NameLabel
@onready var dialogue_text = $DialogueBox/DialogueText
@onready var continue_indicator = $DialogueBox/ContinueIndicator

var current_dialogue = []
var current_index = 0
var is_typing = false

# Personajes disponibles
var characters = {
	"narrator": {"name": "", "color": Color.WHITE},
	"grefg": {"name": "TheGrefg", "color": Color.MAGENTA},
	"westcol": {"name": "Westcol", "color": Color.ORANGE}
}

func _ready():
	# Configurar la escena inicial
	setup_scene()
	
	# Cargar el diálogo de prueba
	load_test_dialogue()

func setup_scene():
	continue_indicator.visible = false
	dialogue_text.text = ""
	
	# Configurar fondo
	if background:
		background.color = Color(0.2, 0.3, 0.8)  # Azul oscuro

func load_test_dialogue():
	current_dialogue = [
		{
			"character": "narrator",
			"text": "¡Bienvenido a La Velada Visual Novel!"
		},
		{
			"character": "grefg",
			"text": "¡Hola! Soy TheGrefg y este es solo el comienzo de una gran aventura."
		},
		{
			"character": "westcol",
			"text": "¡Ey parcero! ¡Vamos a hacer esto épico!"
		},
		{
			"character": "narrator",
			"text": "¿Estás listo para comenzar tu aventura en La Velada?"
		}
	]
	
	current_index = 0
	show_dialogue_line()

func _input(event):
	if event.is_action_pressed("ui_accept"):
		if is_typing:
			complete_current_text()
		elif current_index < current_dialogue.size() - 1:
			advance_dialogue()
		else:
			finish_dialogue()

func show_dialogue_line():
	if current_index >= current_dialogue.size():
		finish_dialogue()
		return
	
	var line = current_dialogue[current_index]
	
	# Configurar personaje
	if line.has("character"):
		var char_data = characters.get(line.character, {"name": line.character, "color": Color.WHITE})
		name_label.text = char_data.name
		name_label.modulate = char_data.color
	else:
		name_label.text = ""
	
	# Mostrar texto con animación
	type_text(line.text)

func type_text(text):
	is_typing = true
	continue_indicator.visible = false
	dialogue_text.text = ""
	
	# Animación de escritura caracter por caracter
	for i in range(text.length()):
		if not is_typing:  # Si se canceló la animación
			dialogue_text.text = text
			break
		
		dialogue_text.text += text[i]
		await get_tree().create_timer(0.03).timeout
	
	is_typing = false
	continue_indicator.visible = true

func complete_current_text():
	is_typing = false

func advance_dialogue():
	current_index += 1
	show_dialogue_line()

func finish_dialogue():
	print("Diálogo completado!")
	# Volver al menú principal
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
