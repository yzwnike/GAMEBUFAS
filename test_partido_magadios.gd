extends Control

# Script de prueba para lanzar directamente el partido vs Deportivo Magadios

func _ready():
	print("Cargando partido vs Deportivo Magadios...")
	# Esperar un momento y luego cambiar de escena
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/MatchDialogueScene.tscn")
