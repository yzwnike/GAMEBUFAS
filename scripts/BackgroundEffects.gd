extends Node2D

# Script para contener efectos de fondo utilizando shaders
var shader_material: ShaderMaterial

func _ready():
    shader_material = ShaderMaterial.new()
    shader_material.shader = load("res://shaders/background.shader")
    # Asignar shader al fondo
    $Background.material = shader_material

    # Animar propiedades del shader para crear efectos visuales
    var tween = get_tree().create_tween()
    tween.tween_property(shader_material, "shader_param/wave_amplitude", 0.2, 2.0)
    tween.tween_property(shader_material, "shader_param/wave_amplitude", 0.05, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tween.set_loops(-1).seek(0)
