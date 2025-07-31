extends Node
class_name MenuAnimations

# Sistema base de animaciones para menús

# Animar entrada de botones desde diferentes direcciones
static func animate_buttons_entrance(buttons: Array, duration: float = 1.0, direction: String = "bottom"):
	var tween = SceneTree().current_scene.get_tree().create_tween()
	
	for i in range(buttons.size()):
		var button = buttons[i]
		var original_pos = button.position
		var start_offset = Vector2()
		
		match direction:
			"bottom":
				start_offset = Vector2(0, 200)
			"top":
				start_offset = Vector2(0, -200)
			"left":
				start_offset = Vector2(-200, 0)
			"right":
				start_offset = Vector2(200, 0)
		
		button.position = original_pos + start_offset
		button.modulate = Color(1, 1, 1, 0)
		
		# Animación escalonada
		var delay = i * 0.1
		tween.parallel().tween_delay(delay)
		tween.parallel().tween_property(button, "position", original_pos, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(button, "modulate:a", 1.0, duration * 0.5)

# Animar hover de botones con escalado y brillo
static func setup_button_hover(button: Button, scale_multiplier: float = 1.1):
	var original_scale = button.scale
	var hover_tween: Tween
	
	button.mouse_entered.connect(func():
		if hover_tween:
			hover_tween.kill()
		hover_tween = button.get_tree().create_tween()
		hover_tween.tween_property(button, "scale", original_scale * scale_multiplier, 0.2)
		hover_tween.parallel().tween_property(button, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.2)
	)
	
	button.mouse_exited.connect(func():
		if hover_tween:
			hover_tween.kill()
		hover_tween = button.get_tree().create_tween()
		hover_tween.tween_property(button, "scale", original_scale, 0.2)
		hover_tween.parallel().tween_property(button, "modulate", Color.WHITE, 0.2)
	)

# Animar fondo con shader y efectos
static func animate_background_entrance(background: TextureRect, duration: float = 2.0):
	background.modulate = Color(1, 1, 1, 0)
	var tween = background.get_tree().create_tween()
	tween.tween_property(background, "modulate:a", 1.0, duration)

# Efecto de pulsación para elementos importantes
static func pulse_element(element: Control, scale_range: float = 0.1, duration: float = 1.0):
	var original_scale = element.scale
	var tween = element.get_tree().create_tween()
	tween.set_loops()
	tween.tween_property(element, "scale", original_scale * (1.0 + scale_range), duration * 0.5)
	tween.tween_property(element, "scale", original_scale, duration * 0.5)

# Transición de salida para cambio de escena
static func exit_transition(control: Control, callback: Callable, duration: float = 0.5):
	var tween = control.get_tree().create_tween()
	tween.tween_property(control, "modulate:a", 0.0, duration)
	tween.tween_callback(callback)
