extends Control

# Minijuego de neutralización de Wang Li - "El Chino Imparable vs Tu Defensa"
# Vista superior donde debes interceptar pases destinados a Wang Li

@onready var game_area = $GameArea
@onready var player_character = $GameArea/PlayerCharacter
@onready var wang_li = $GameArea/WangLi
@onready var weak_teammates = $GameArea/WeakTeammates
@onready var ball = $GameArea/Ball
@onready var timer_label = $UI/HUD/TimerLabel
@onready var level_label = $UI/HUD/LevelLabel
@onready var wang_li_label = $UI/HUD/WangLiLabel
@onready var success_label = $UI/HUD/SuccessLabel
@onready var instruction_label = $UI/HUD/InstructionLabel
@onready var instruction_panel = $UI/InstructionPanel
@onready var instruction_text = $UI/InstructionPanel/InstructionText
@onready var start_button = $UI/InstructionPanel/StartButton
@onready var result_panel = $UI/ResultPanel
@onready var result_text = $UI/ResultPanel/ResultText
@onready var retry_button = $UI/ResultPanel/RetryButton
@onready var continue_button = $UI/ResultPanel/ContinueButton
@onready var next_level_button = $UI/ResultPanel/NextLevelButton

# Sistema de niveles
var current_level = 1
var max_levels = 3
var game_time = 30.0  # 30 segundos por nivel
var neutralizations_required = 5  # Neutralizaciones necesarias por nivel

# Variables del juego
var game_active = false
var time_remaining = 0.0
var neutralizations_count = 0
var failed_passes = 0

# Variables de personajes
var weak_players = []
var num_weak_players = 3
var player_speed = 150.0

# Variables de Wang Li
var wang_li_speed = 80.0
var wang_li_direction = Vector2.ZERO
var direction_change_timer = 0.0
var direction_change_interval = 2.0

# Variables de balón y pases
var ball_position = Vector2.ZERO
var ball_target = null
var ball_moving = false
var ball_speed = 200.0
var pass_timer = 0.0
var pass_interval = 3.0  # Intervalo entre pases
var pass_to_wang_li_chance = 0.7  # 70% de probabilidad de pasar a Wang Li

# Variables de control del jugador
var player_input = Vector2.ZERO

signal training_completed(success: bool)

func _ready():
    print("WangLiNeutralizationMiniGame: Iniciando minijuego de neutralización de Wang Li")
    setup_ui()
    setup_game_area()
    game_active = false

func setup_ui():
    result_panel.visible = false
    level_label.text = "NIVEL " + str(current_level) + "/" + str(max_levels)
    success_label.text = "Neutralizaciones: 0/" + str(neutralizations_required)
    start_button.pressed.connect(_on_start_pressed)
    
    # Configurar texto de instrucciones según el nivel
    if current_level == 1:
        instruction_panel.visible = true
        instruction_text.text = "🐉 NEUTRALIZAR A WANG LI - NIVEL 1\n\n" + \
            "OBJETIVO: Interceptar " + str(neutralizations_required) + " pases hacia Wang Li\n" + \
            "CONTROLES: WASD o flechas para moverte\n" + \
            "ESTRATEGIA: Wang Li (dragón dorado) recibe muchos pases\n" + \
            "Los jugadores débiles (círculos grises) son fáciles de ignorar\n" + \
            "DURACIÓN: 30 segundos\n\n" + \
            "¡Intercepta el balón antes de que llegue a Wang Li!"
    else:
        instruction_panel.visible = true
        var difficulty = ["FÁCIL", "MEDIO", "DIFÍCIL"][current_level - 1]
        instruction_text.text = "🐉 NIVEL " + str(current_level) + " - " + difficulty + "\n\n" + \
            "Wang Li se mueve más rápido y erráticamente.\n" + \
            "Los pases serán más frecuentes.\n\n" + \
            "¡Presiona INICIAR para continuar!"

    # Conectar botones del resultado
    retry_button.pressed.connect(_on_retry_pressed)
    continue_button.pressed.connect(_on_continue_pressed)
    next_level_button.pressed.connect(_on_next_level_pressed)
    next_level_button.visible = false

func setup_game_area():
    var game_center = game_area.size / 2
    
    # Limpiar personajes anteriores
    for player in weak_players:
        if player and is_instance_valid(player):
            player.queue_free()
    weak_players.clear()
    
    # Configurar personajes
    setup_player_character()
    setup_wang_li_character()
    setup_weak_players()
    setup_ball()
    
    # Configurar dirección inicial de Wang Li
    wang_li_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

func _on_start_pressed():
    instruction_panel.visible = false
    start_game()

func start_game():
    game_active = true
    time_remaining = game_time
    neutralizations_count = 0
    success_label.text = "Neutralizaciones: 0/" + str(neutralizations_required)

func _process(delta):
    if game_active:
        handle_player_input(delta)
        update_wang_li_movement(delta)
        update_ball_movement(delta)
        update_pass_timer(delta)
        update_timer(delta)
        check_neutralizations()
        check_ball_interception()

func handle_player_input(delta):
    # Obtener input del jugador con WASD y flechas
    player_input = Vector2.ZERO
    
    # Flechas direccionales
    if Input.is_action_pressed("ui_left"):
        player_input.x -= 1
    if Input.is_action_pressed("ui_right"):
        player_input.x += 1
    if Input.is_action_pressed("ui_up"):
        player_input.y -= 1
    if Input.is_action_pressed("ui_down"):
        player_input.y += 1
    
    # WASD - usar teclas directas
    if Input.is_key_pressed(KEY_A):
        player_input.x -= 1
    if Input.is_key_pressed(KEY_D):
        player_input.x += 1
    if Input.is_key_pressed(KEY_W):
        player_input.y -= 1
    if Input.is_key_pressed(KEY_S):
        player_input.y += 1
    
    # Normalizar y aplicar movimiento
    if player_input.length() > 0:
        player_input = player_input.normalized()
        var new_position = player_character.position + player_input * player_speed * delta
        
        # Mantener al jugador dentro del área de juego
        new_position.x = clamp(new_position.x, 25, game_area.size.x - 25)
        new_position.y = clamp(new_position.y, 25, game_area.size.y - 25)
        
        player_character.position = new_position

func update_wang_li_movement(delta):
    # Cambiar dirección periódicamente
    direction_change_timer += delta
    if direction_change_timer >= direction_change_interval:
        wang_li_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
        direction_change_timer = 0.0
        # Ajustar velocidad según el nivel
        wang_li_speed = 80.0 + (current_level * 20.0)
    
    # Mover Wang Li
    var new_position = wang_li.position + wang_li_direction * wang_li_speed * delta
    
    # Rebotar en los bordes
    if new_position.x < 25 or new_position.x > game_area.size.x - 25:
        wang_li_direction.x *= -1
    if new_position.y < 25 or new_position.y > game_area.size.y - 25:
        wang_li_direction.y *= -1
    
    # Aplicar posición con límites
    new_position.x = clamp(new_position.x, 25, game_area.size.x - 25)
    new_position.y = clamp(new_position.y, 25, game_area.size.y - 25)
    wang_li.position = new_position

func update_ball_movement(delta):
    if ball_moving and ball_target:
        var direction = (ball_target.position - ball.position).normalized()
        var new_position = ball.position + direction * ball_speed * delta
        
        # Verificar si llegó al destino
        if ball.position.distance_to(ball_target.position) < 30:
            ball_moving = false
            ball_target = null
            # Si llegó a Wang Li, falló la interceptación
            if ball_target == wang_li:
                failed_passes += 1
                print("Pase llegó a Wang Li! Fallos: ", failed_passes)
        
        ball.position = new_position

func update_pass_timer(delta):
    pass_timer += delta
    
    # Ajustar dificultad por nivel
    var current_interval = pass_interval
    var current_wang_li_chance = pass_to_wang_li_chance
    
    match current_level:
        1:  # FÁCIL
            current_interval = 3.5  # Pases más lentos
            current_wang_li_chance = 0.6  # 60% hacia Wang Li
        2:  # MEDIO
            current_interval = 2.5  # Pases normales
            current_wang_li_chance = 0.7  # 70% hacia Wang Li
        3:  # DIFÍCIL
            current_interval = 1.8  # Pases muy rápidos
            current_wang_li_chance = 0.8  # 80% hacia Wang Li
    
    if pass_timer >= current_interval:
        initiate_pass(current_wang_li_chance)
        pass_timer = 0.0

func initiate_pass(wang_li_chance: float = 0.7):
    if ball_moving:
        return  # No iniciar nuevo pase si el balón ya se está moviendo
    
    # Elegir origen del pase (jugador débil aleatorio)
    if weak_players.size() > 0:
        var passer = weak_players[randi() % weak_players.size()]
        ball.position = passer.position
        
        # Decidir destino del pase usando la probabilidad del nivel
        var roll = randf()
        if roll < wang_li_chance:
            # Pase hacia Wang Li (peligroso)
            ball_target = wang_li
            wang_li_label.text = "🐉 Wang Li: RECIBIENDO PASE!"
            wang_li_label.add_theme_color_override("font_color", Color.RED)
            print("Pase iniciado hacia Wang Li!")
        else:
            # Pase hacia otro jugador débil
            var receiver = weak_players[randi() % weak_players.size()]
            while receiver == passer and weak_players.size() > 1:
                receiver = weak_players[randi() % weak_players.size()]
            ball_target = receiver
            wang_li_label.text = "🐉 Wang Li: Esperando..."
            wang_li_label.add_theme_color_override("font_color", Color.YELLOW)
            print("Pase iniciado hacia jugador débil")
        
        ball_moving = true

func check_ball_interception():
    if ball_moving:
        var distance_to_ball = player_character.position.distance_to(ball.position)
        if distance_to_ball < 35:  # Radio de interceptación
            # Verificar si era un pase hacia Wang Li ANTES de parar el balón
            var was_pass_to_wang_li = (ball_target == wang_li)
            
            # ¡Interceptación exitosa!
            ball_moving = false
            ball_target = null
            
            # Solo contar si era un pase hacia Wang Li
            if was_pass_to_wang_li:
                neutralizations_count += 1
                success_label.text = "Neutralizaciones: " + str(neutralizations_count) + "/" + str(neutralizations_required)
                wang_li_label.text = "🐉 Wang Li: NEUTRALIZADO!"
                wang_li_label.add_theme_color_override("font_color", Color.GREEN)
                print("¡NEUTRALIZACIÓN EXITOSA! Total: ", neutralizations_count)
                
                # Efecto visual (opcional)
                create_interception_effect()
            else:
                wang_li_label.text = "🐉 Wang Li: Activo"
                wang_li_label.add_theme_color_override("font_color", Color.WHITE)
                print("Interceptado pase hacia jugador débil (no cuenta)")
            
            # Reposicionar balón con jugador débil aleatorio
            if weak_players.size() > 0:
                var new_holder = weak_players[randi() % weak_players.size()]
                ball.position = new_holder.position

func create_interception_effect():
    # Crear un efecto visual simple para la interceptación
    var effect = ColorRect.new()
    effect.size = Vector2(60, 60)
    effect.color = Color(0, 1, 0, 0.7)  # Verde transparente
    effect.position = player_character.position - Vector2(30, 30)
    game_area.add_child(effect)
    
    # Animar el efecto
    var tween = create_tween()
    tween.tween_property(effect, "modulate:a", 0.0, 0.5)
    tween.tween_callback(effect.queue_free)

func update_timer(delta):
    time_remaining -= delta
    timer_label.text = "⏰ " + str(int(time_remaining)) + "s"
    if time_remaining <= 0:
        end_game(neutralizations_count >= neutralizations_required)

func check_neutralizations():
    # Verificar si se completó el objetivo
    if neutralizations_count >= neutralizations_required:
        end_game(true)

func end_game(success):
    game_active = false
    result_panel.visible = true
    
    if success:
        if current_level < max_levels:
            result_text.text = "¡NIVEL " + str(current_level) + " COMPLETADO!\n\nWang Li está cada vez más desesperado..."
            next_level_button.visible = true
            continue_button.visible = false
        else:
            result_text.text = "¡TODOS LOS NIVELES COMPLETADOS!\n\n¡Has neutralizado completamente a Wang Li!\nEstá tan frustrado que está considerando\nregresar a China para fabricar iPhones."
            next_level_button.visible = false
            continue_button.visible = true
    else:
        result_text.text = "NIVEL " + str(current_level) + " FALLIDO\n\nWang Li sigue recibiendo demasiados pases.\n¡Necesitas ser más rápido interceptando!"
        next_level_button.visible = false
        continue_button.visible = false
    
    emit_signal("training_completed", success)

func _on_retry_pressed():
    result_panel.visible = false
    setup_game_area()

func _on_continue_pressed():
    # Conectar con el post-training dialogue
    print("WangLiNeutralizationMiniGame: Conectando con post-training dialogue...")
    get_tree().change_scene_to_file("res://scenes/PostTrainingDialogueScene.tscn")

func _on_next_level_pressed():
    current_level += 1
    if current_level <= max_levels:
        result_panel.visible = false
        setup_ui()
        setup_game_area()
    else:
        print("Todos los niveles completados!")
        emit_signal("training_completed", true)
        queue_free()  # Salir del minijuego

func setup_player_character():
    # Limpiar personaje anterior
    for child in player_character.get_children():
        child.queue_free()
    
    # Crear sprite del jugador (círculo azul)
    var player_sprite = ColorRect.new()
    player_sprite.size = Vector2(40, 40)
    player_sprite.color = Color(0.2, 0.5, 1.0, 0.9)
    player_sprite.position = Vector2(-20, -20)
    player_character.add_child(player_sprite)
    
    # Borde blanco
    var border = ColorRect.new()
    border.size = Vector2(44, 44)
    border.color = Color.WHITE
    border.position = Vector2(-22, -22)
    player_character.add_child(border)
    player_character.move_child(border, 0)
    
    # Etiqueta "TÚ"
    var label = Label.new()
    label.text = "TÚ"
    label.add_theme_font_size_override("font_size", 12)
    label.add_theme_color_override("font_color", Color.WHITE)
    label.position = Vector2(-12, -8)
    player_sprite.add_child(label)
    
    # Posición inicial
    player_character.position = game_area.size / 2 - Vector2(150, 0)

func setup_wang_li_character():
    # Limpiar Wang Li anterior
    for child in wang_li.get_children():
        child.queue_free()
    
    # Crear sprite de Wang Li (círculo dorado con dragón)
    var wang_sprite = ColorRect.new()
    wang_sprite.size = Vector2(50, 50)
    wang_sprite.color = Color(1.0, 0.8, 0.0, 0.9)  # Dorado
    wang_sprite.position = Vector2(-25, -25)
    wang_li.add_child(wang_sprite)
    
    # Borde rojo (peligroso)
    var border = ColorRect.new()
    border.size = Vector2(54, 54)
    border.color = Color.RED
    border.position = Vector2(-27, -27)
    wang_li.add_child(border)
    wang_li.move_child(border, 0)
    
    # Emoji de dragón
    var emoji = Label.new()
    emoji.text = "🐉"
    emoji.add_theme_font_size_override("font_size", 28)
    emoji.position = Vector2(-15, -18)
    wang_sprite.add_child(emoji)
    
    # Nombre "WANG LI"
    var name_bg = ColorRect.new()
    name_bg.size = Vector2(60, 18)
    name_bg.color = Color(0, 0, 0, 0.8)
    name_bg.position = Vector2(-30, -50)
    wang_li.add_child(name_bg)
    
    var name_label = Label.new()
    name_label.text = "WANG LI"
    name_label.add_theme_font_size_override("font_size", 12)
    name_label.add_theme_color_override("font_color", Color.YELLOW)
    name_label.position = Vector2(-28, -50)
    wang_li.add_child(name_label)
    
    # Posición inicial
    wang_li.position = game_area.size / 2 + Vector2(150, 0)

func setup_weak_players():
    var game_center = game_area.size / 2
    
    # Posiciones para jugadores débiles (forman triángulo)
    var positions = [
        game_center + Vector2(-100, -100),
        game_center + Vector2(100, -100),
        game_center + Vector2(0, 100)
    ]
    
    for i in range(num_weak_players):
        var weak_player = create_weak_player(positions[i], i + 1)
        weak_players.append(weak_player)
        weak_teammates.add_child(weak_player)

func create_weak_player(pos: Vector2, number: int) -> Control:
    var player = Control.new()
    player.position = pos
    
    # Sprite del jugador débil (círculo gris)
    var sprite = ColorRect.new()
    sprite.size = Vector2(30, 30)
    sprite.color = Color(0.5, 0.5, 0.5, 0.7)  # Gris opaco
    sprite.position = Vector2(-15, -15)
    player.add_child(sprite)
    
    # Borde gris oscuro
    var border = ColorRect.new()
    border.size = Vector2(34, 34)
    border.color = Color(0.3, 0.3, 0.3)
    border.position = Vector2(-17, -17)
    player.add_child(border)
    player.move_child(border, 0)
    
    # Emoji de jugador mediocre
    var emoji = Label.new()
    emoji.text = "😴"  # Durmiendo (mediocre)
    emoji.add_theme_font_size_override("font_size", 18)
    emoji.position = Vector2(-10, -12)
    sprite.add_child(emoji)
    
    return player

func setup_ball():
    # Limpiar balón anterior
    for child in ball.get_children():
        child.queue_free()
    
    # Crear sprite del balón
    var ball_sprite = ColorRect.new()
    ball_sprite.size = Vector2(20, 20)
    ball_sprite.color = Color.WHITE
    ball_sprite.position = Vector2(-10, -10)
    ball.add_child(ball_sprite)
    
    # Borde negro
    var border = ColorRect.new()
    border.size = Vector2(24, 24)
    border.color = Color.BLACK
    border.position = Vector2(-12, -12)
    ball.add_child(border)
    ball.move_child(border, 0)
    
    # Emoji de balón
    var emoji = Label.new()
    emoji.text = "⚽"
    emoji.add_theme_font_size_override("font_size", 16)
    emoji.position = Vector2(-8, -10)
    ball_sprite.add_child(emoji)
    
    # Posición inicial (con jugador débil aleatorio)
    if weak_players.size() > 0:
        var random_weak = weak_players[randi() % weak_players.size()]
        ball.position = random_weak.position
    else:
        ball.position = game_area.size / 2
