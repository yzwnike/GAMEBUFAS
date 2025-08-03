extends Node3D

@export var player_name : String
@export var player_image_path : String
@export var player_ovr : int

var animation_player
var player_panel

func _ready():
    var camera = Camera3D.new()
    camera.position = Vector3(0, 10, -30)
    add_child(camera)

    animation_player = AnimationPlayer.new()
    add_child(animation_player)

    var particles = GPUParticles3D.new()
    particles.amount = 500
    particles.emitting = true
    particles.process_material = create_particle_material()
    particles.position = Vector3(0, 0, 0)
    add_child(particles)

    animation_player.add_animation("reveal", create_reveal_animation())
    animation_player.play("reveal")

    # Panel
    player_panel = create_player_panel()
    player_panel.visible = false
    add_child(player_panel)

func create_particle_material() -> ParticleProcessMaterial:
    var material = ParticleProcessMaterial.new()
    material.gravity = Vector3(0, -1, 0)
    material.scale = 1.5
    material.color = Color(1, 1, 0.5)
    material.direction = Vector3(0, 1, 0)
    return material

func create_reveal_animation() -> Animation:
    var anim = Animation.new()
    anim.length = 5.0

    # Camera movement
    anim.track_set_path(anim.add_track(Animation.TYPE_TRANSFORM), $Camera3D)
    anim.track_insert_key(0, Vector3(0, 10, -30))
    anim.track_insert_key(5, Vector3(0, 1, -5))

    # Reveal panel after camera moves
    anim.connect("animation_finished", self, "_on_Reveal_Finished")
    return anim

func _on_Reveal_Finished():
    player_panel.visible = true

func create_player_panel() -> Control:
    var panel = Panel.new()
    panel.rect_size = Vector2(300, 200)
    panel.rect_position = Vector2(150, 210)

    var name_label = Label.new()
    name_label.text = player_name
    panel.add_child(name_label)

    var image_texture = preload(player_image_path)
    var image = TextureRect.new()
    image.texture = image_texture
    panel.add_child(image)

    return panel

