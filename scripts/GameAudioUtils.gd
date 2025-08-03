extends Node

# GameAudioUtils - Utilidades para reproducir sonidos del juego
# Funciones convenientes para reproducir efectos y música

# Efectos de sonido del juego
enum SFXType {
	BUTTON_CLICK,
	BALL_PASS,
	GOAL_SCORED,
	WHISTLE,
	CROWD_CHEER,
	MENU_NAVIGATE,
	ERROR,
	SUCCESS,
	STAMINA_LOW,
	PAUSE_TOGGLE
}

# Cache de streams de audio para evitar cargar repetidamente
var sfx_cache = {}
var music_cache = {}

func _ready():
	print("GameAudioUtils: Sistema de utilidades de audio iniciado")
	preload_common_sounds()

func preload_common_sounds():
	# Precargar sonidos comunes para evitar delays
	print("GameAudioUtils: Precargando sonidos comunes...")
	
	# Nota: Estos archivos no existen aún, pero se pueden crear después
	# var button_click = preload("res://assets/audio/sfx/button_click.ogg")
	# sfx_cache[SFXType.BUTTON_CLICK] = button_click
	
	print("GameAudioUtils: Sonidos precargados (placeholder)")

# Función principal para reproducir efectos de sonido
func play_sfx(sfx_type: SFXType, volume_db: float = 0.0):
	if not AudioManager:
		print("GameAudioUtils: AudioManager no disponible")
		return
	
	var stream = get_sfx_stream(sfx_type)
	if stream:
		AudioManager.play_sfx(stream, volume_db)
	else:
		print("GameAudioUtils: No se encontró audio para tipo: ", sfx_type)

# Función para reproducir música de fondo
func play_background_music(music_name: String, fade_in: bool = true):
	if not AudioManager:
		print("GameAudioUtils: AudioManager no disponible")
		return
	
	var stream = get_music_stream(music_name)
	if stream:
		AudioManager.play_music(stream, fade_in)
	else:
		print("GameAudioUtils: No se encontró música: ", music_name)

# Obtener stream de efecto de sonido
func get_sfx_stream(sfx_type: SFXType) -> AudioStream:
	# Si está en cache, devolverlo
	if sfx_cache.has(sfx_type):
		return sfx_cache[sfx_type]
	
	# Intentar cargar desde archivo
	var file_path = get_sfx_file_path(sfx_type)
	if ResourceLoader.exists(file_path):
		var stream = load(file_path)
		sfx_cache[sfx_type] = stream
		return stream
	
	# Si no existe, crear un tono sintético simple
	return create_synthetic_sound(sfx_type)

# Obtener stream de música
func get_music_stream(music_name: String) -> AudioStream:
	if music_cache.has(music_name):
		return music_cache[music_name]
	
	var file_path = "res://assets/audio/music/" + music_name + ".ogg"
	if ResourceLoader.exists(file_path):
		var stream = load(file_path)
		music_cache[music_name] = stream
		return stream
	
	print("GameAudioUtils: Archivo de música no encontrado: ", file_path)
	return null

# Mapear tipos de SFX a rutas de archivo
func get_sfx_file_path(sfx_type: SFXType) -> String:
	match sfx_type:
		SFXType.BUTTON_CLICK:
			return "res://assets/audio/sfx/button_click.ogg"
		SFXType.BALL_PASS:
			return "res://assets/audio/sfx/ball_pass.ogg"
		SFXType.GOAL_SCORED:
			return "res://assets/audio/sfx/goal_scored.ogg"
		SFXType.WHISTLE:
			return "res://assets/audio/sfx/whistle.ogg"
		SFXType.CROWD_CHEER:
			return "res://assets/audio/sfx/crowd_cheer.ogg"
		SFXType.MENU_NAVIGATE:
			return "res://assets/audio/sfx/menu_navigate.ogg"
		SFXType.ERROR:
			return "res://assets/audio/sfx/error.ogg"
		SFXType.SUCCESS:
			return "res://assets/audio/sfx/success.ogg"
		SFXType.STAMINA_LOW:
			return "res://assets/audio/sfx/stamina_low.ogg"
		SFXType.PAUSE_TOGGLE:
			return "res://assets/audio/sfx/pause_toggle.ogg"
		_:
			return ""

# Crear sonidos sintéticos simples como placeholders
func create_synthetic_sound(sfx_type: SFXType) -> AudioStream:
	# Por ahora, crear un AudioStreamGenerator simple
	# En un juego real, esto podría usar AudioStreamGenerator para crear tonos
	print("GameAudioUtils: Creando sonido sintético para: ", sfx_type)
	
	# Placeholder - en versión completa se podría generar audio procedural
	return null

# Funciones convenientes para casos comunes
func play_button_click():
	play_sfx(SFXType.BUTTON_CLICK, -5.0)

func play_ball_pass():
	play_sfx(SFXType.BALL_PASS, -3.0)

func play_goal_scored():
	play_sfx(SFXType.GOAL_SCORED, 0.0)

func play_menu_navigate():
	play_sfx(SFXType.MENU_NAVIGATE, -8.0)

func play_error_sound():
	play_sfx(SFXType.ERROR, -2.0)

func play_success_sound():
	play_sfx(SFXType.SUCCESS, -2.0)

func play_stamina_low():
	play_sfx(SFXType.STAMINA_LOW, -1.0)

func play_pause_toggle():
	play_sfx(SFXType.PAUSE_TOGGLE, -4.0)

# Funciones para música de ambiente
func play_menu_music():
	play_background_music("menu_theme")

func play_game_music():
	play_background_music("game_theme")

func play_training_music():
	play_background_music("training_theme")

func stop_all_music():
	if AudioManager:
		AudioManager.stop_music(true)
