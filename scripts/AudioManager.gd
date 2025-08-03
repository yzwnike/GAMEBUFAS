extends Node

# AudioManager - Gestor global de audio del juego
# Maneja volúmenes maestro, música y efectos de sonido

# Bus de audio
const MASTER_BUS = "Master"
const MUSIC_BUS = "Music"
const SFX_BUS = "SFX"

# Variables de volumen (0.0 a 1.0)
var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0

# Referencias a AudioStreamPlayer para música
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

# Configuración predeterminada
const DEFAULT_MASTER_VOLUME = 1.0
const DEFAULT_MUSIC_VOLUME = 0.8
const DEFAULT_SFX_VOLUME = 0.7

signal music_volume_changed(new_volume: float)

# Archivo de configuración
const CONFIG_FILE = "user://audio_settings.json"

signal volume_changed(bus_name: String, volume: float)

func _ready():
	print("AudioManager: Inicializando sistema de audio...")
	
	# Crear reproductores de audio
	setup_audio_players()
	
	# Configurar buses de audio
	setup_audio_buses()
	
	# Cargar configuración guardada
	load_audio_settings()
	
	print("AudioManager: Sistema de audio inicializado correctamente")

func setup_audio_players():
	# Crear reproductor de música
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = MUSIC_BUS
	add_child(music_player)
	
	# Crear reproductor de efectos de sonido
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.bus = SFX_BUS
	add_child(sfx_player)

func setup_audio_buses():
	# Asegurar que los buses existen
	var audio_server = AudioServer
	
	# Si no existen los buses, crearlos
	if audio_server.get_bus_index(MUSIC_BUS) == -1:
		audio_server.add_bus()
		audio_server.set_bus_name(audio_server.get_bus_count() - 1, MUSIC_BUS)
	
	if audio_server.get_bus_index(SFX_BUS) == -1:
		audio_server.add_bus()
		audio_server.set_bus_name(audio_server.get_bus_count() - 1, SFX_BUS)

# Funciones para controlar volumen
func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	var db = linear_to_db(master_volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MASTER_BUS), db)
	AudioServer.set_bus_mute(AudioServer.get_bus_index(MASTER_BUS), master_volume <= 0.01)
	volume_changed.emit(MASTER_BUS, master_volume)
	save_audio_settings()

func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	var db = linear_to_db(music_volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MUSIC_BUS), db)
	AudioServer.set_bus_mute(AudioServer.get_bus_index(MUSIC_BUS), music_volume <= 0.01)
	volume_changed.emit(MUSIC_BUS, music_volume)
	music_volume_changed.emit(music_volume)
	save_audio_settings()

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
	var db = linear_to_db(sfx_volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(SFX_BUS), db)
	AudioServer.set_bus_mute(AudioServer.get_bus_index(SFX_BUS), sfx_volume <= 0.01)
	volume_changed.emit(SFX_BUS, sfx_volume)
	save_audio_settings()

# Funciones para obtener volúmenes
func get_master_volume() -> float:
	return master_volume

func get_music_volume() -> float:
	return music_volume

func get_sfx_volume() -> float:
	return sfx_volume

# Funciones para reproducir audio
func play_music(stream: AudioStream, fade_in: bool = true):
	if not music_player:
		return
	
	if fade_in and music_player.playing:
		# Fade out música actual, luego reproducir nueva
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80, 0.5)
		await tween.finished
	
	music_player.stream = stream
	music_player.volume_db = 0
	music_player.play()
	
	if fade_in:
		music_player.volume_db = -80
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", 0, 0.5)

func stop_music(fade_out: bool = true):
	if not music_player or not music_player.playing:
		return
	
	if fade_out:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80, 0.5)
		await tween.finished
	
	music_player.stop()

func play_sfx(stream: AudioStream, volume_db: float = 0.0):
	if not sfx_player:
		return
	
	# Para efectos de sonido, crear un AudioStreamPlayer temporal
	var temp_player = AudioStreamPlayer.new()
	temp_player.bus = SFX_BUS
	temp_player.stream = stream
	temp_player.volume_db = volume_db
	add_child(temp_player)
	temp_player.play()
	
	# Eliminar el reproductor cuando termine
	temp_player.finished.connect(temp_player.queue_free)

# Guardar y cargar configuración
func save_audio_settings():
	var config = {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume
	}
	
	var file = FileAccess.open(CONFIG_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(config))
		file.close()
		print("AudioManager: Configuración de audio guardada")

func load_audio_settings():
	if FileAccess.file_exists(CONFIG_FILE):
		var file = FileAccess.open(CONFIG_FILE, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var result = json.parse(content)
			
			if result == OK:
				var config = json.data
				set_master_volume(config.get("master_volume", DEFAULT_MASTER_VOLUME))
				set_music_volume(config.get("music_volume", DEFAULT_MUSIC_VOLUME))
				set_sfx_volume(config.get("sfx_volume", DEFAULT_SFX_VOLUME))
				print("AudioManager: Configuración de audio cargada")
			else:
				print("AudioManager: Error al parsear configuración, usando valores por defecto")
				load_default_settings()
	else:
		print("AudioManager: No existe configuración previa, usando valores por defecto")
		load_default_settings()

func load_default_settings():
	set_master_volume(DEFAULT_MASTER_VOLUME)
	set_music_volume(DEFAULT_MUSIC_VOLUME)
	set_sfx_volume(DEFAULT_SFX_VOLUME)
