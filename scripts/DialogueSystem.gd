extends Control

# Sistema de diálogos estilo Doki Doki Literature Club
# Inspirado en La Velada del Año

onready var character_name_label = $DialogueBox/NameLabel
onready var dialogue_text = $DialogueBox/DialogueText
onready var background = $Background
onready var character_sprite = $CharacterSprite
onready var continue_indicator = $DialogueBox/ContinueIndicator
onready var choice_container = $ChoiceContainer

var current_dialogue = []
var current_index = 0
var is_typing = false
var typing_speed = 0.05
var auto_advance = false

# Personajes disponibles
var characters = {
	"narrator": {"name": "", "color": Color.white},
	"grefg": {"name": "TheGrefg", "color": Color.purple},
	"westcol": {"name": "Westcol", "color": Color.orange},
	"perxitaa": {"name": "Perxitaa", "color": Color.cyan},
	"viruzz": {"name": "Viruzz", "color": Color.red},
	"tomas": {"name": "Tomás", "color": Color.green},
	"rivaldios": {"name": "Rivaldios", "color": Color.yellow},
	"peereira": {"name": "Peereira", "color": Color.pink},
	"alana": {"name": "Alana", "color": Color.magenta},
	"arigeli": {"name": "Arigeli", "color": Color.lime},
	"andoni": {"name": "Andoni", "color": Color.aqua}
}

# Backgrounds disponibles
var backgrounds = {
	"campo": "res://assets/images/backgrounds/campo.png",
	"vestuario": "res://assets/images/backgrounds/vestuario.png",
	"entrenamiento": "res://assets/images/backgrounds/gym.png",
	"campovertical": "res://assets/images/backgrounds/campovertical.png"
}

signal dialogue_finished
signal choice_made(choice_id)

func _ready():
	continue_indicator.visible = false
	choice_container.visible = false
	dialogue_text.text = ""
	
func _input(event):
	if event.is_action_pressed("ui_accept"):
		if is_typing:
			# Saltar animación de escritura
			complete_current_text()
		elif current_index < current_dialogue.size():
			# Avanzar al siguiente diálogo
			advance_dialogue()
		else:
			# Finalizar diálogo
			emit_signal("dialogue_finished")

func load_dialogue(dialogue_data):
	current_dialogue = dialogue_data
	current_index = 0
	if current_dialogue.size() > 0:
		show_dialogue_line()

func show_dialogue_line():
	if current_index >= current_dialogue.size():
		emit_signal("dialogue_finished")
		return
		
	var line = current_dialogue[current_index]
	
	# Cambiar fondo si es necesario
	if line.has("background"):
		change_background(line.background)
	
	# Mostrar/ocultar personaje
	if line.has("character"):
		show_character(line.character)
		var char_data = characters.get(line.character, {"name": line.character, "color": Color.white})
		character_name_label.text = char_data.name
		character_name_label.modulate = char_data.color
	else:
		hide_character()
		character_name_label.text = ""
	
	# Mostrar opciones si las hay
	if line.has("choices"):
		show_choices(line.choices)
		return
	
	# Efectos especiales
	if line.has("effect"):
		apply_effect(line.effect)
	
	# Mostrar texto con animación
	type_text(line.text)

func type_text(text):
	is_typing = true
	continue_indicator.visible = false
	dialogue_text.text = ""
	
	# Animación de escritura caracter por caracter
	for i in range(text.length()):
		dialogue_text.text += text[i]
		yield(get_tree().create_timer(typing_speed), "timeout")
		
		# Verificar si se canceló la animación
		if not is_typing:
			dialogue_text.text = text
			break
	
	is_typing = false
	continue_indicator.visible = true

func complete_current_text():
	is_typing = false

func advance_dialogue():
	current_index += 1
	show_dialogue_line()

func change_background(bg_name):
	if backgrounds.has(bg_name):
		background.texture = load(backgrounds[bg_name])

func show_character(character_name):
	# Mapear nombres de personajes a archivos específicos
	var character_files = {
		"grefg": "grefg.png",
		"westcol": "westcol.png", 
		"perxitaa": "perxitaa.png",
		"viruzz": "viruz.png",  # Nota: el archivo se llama viruz sin la segunda z
		"tomas": "tomas.png",
		"rivaldios": "rivaldios.png"
	}
	
	var filename = character_files.get(character_name, character_name + ".png")
	var character_path = "res://assets/images/characters/" + filename
	
	if ResourceLoader.exists(character_path):
		character_sprite.texture = load(character_path)
		character_sprite.visible = true
	else:
		hide_character()
		print("Advertencia: No se encontró la imagen del personaje: ", character_name, " en ", character_path)

func hide_character():
	character_sprite.visible = false

func show_choices(choices):
	choice_container.visible = true
	
	# Limpiar opciones anteriores
	for child in choice_container.get_children():
		child.queue_free()
	
	# Crear botones para cada opción
	for i in range(choices.size()):
		var choice = choices[i]
		var button = Button.new()
		button.text = choice.text
		button.connect("pressed", self, "_on_choice_selected", [choice.id])
		choice_container.add_child(button)

func _on_choice_selected(choice_id):
	choice_container.visible = false
	emit_signal("choice_made", choice_id)
	advance_dialogue()

func apply_effect(effect_name):
	match effect_name:
		"shake":
			# Efecto de temblor de pantalla
			var tween = Tween.new()
			add_child(tween)
			tween.interpolate_property(self, "rect_position", 
				rect_position, rect_position + Vector2(5, 5), 0.1)
			tween.start()
			yield(tween, "tween_completed")
			tween.interpolate_property(self, "rect_position", 
				rect_position, Vector2.ZERO, 0.1)
			tween.start()
			yield(tween, "tween_completed")
			tween.queue_free()
		
		"flash":
			# Efecto de flash blanco
			var flash = ColorRect.new()
			flash.color = Color.white
			flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(flash)
			flash.modulate.a = 0.8
			var tween = Tween.new()
			add_child(tween)
			tween.interpolate_property(flash, "modulate:a", 0.8, 0.0, 0.5)
			tween.start()
			yield(tween, "tween_completed")
			flash.queue_free()
			tween.queue_free()
