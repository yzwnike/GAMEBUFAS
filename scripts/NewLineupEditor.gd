extends Control

# Variables
var formation_selector
var field_container
var players_scroll
var players_container
var back_button
var save_button

var formation: String = "3-2-1"  # Default formation
var field_positions: Dictionary = {}
var available_players: Array = []
var selected_player = null

# Drag and drop variables
var is_dragging = false
var drag_player = null
var drag_preview = null
var drag_offset = Vector2()

# Formations dictionary
var formations = {
    "3-2-1": {"defense": 3, "midfield": 2, "forward": 1},
    "1-3-2": {"defense": 1, "midfield": 3, "forward": 2}
}

# Line colors for different sections
var line_colors = {
    "goalkeeper": Color.YELLOW,
    "defense": Color.BLUE,
    "midfield": Color.GREEN,
    "forward": Color.RED
}

func _ready():
    print("LineupEditor: Initializing...")
    if not setup_ui():
        print("ERROR: UI setup failed")
        return

    setup_formation_selector()
    connect_signals()
    load_available_players()
    create_field()
    display_available_players()
    load_lineup_from_file()

    print("LineupEditor: Initialization complete")

func setup_ui() -> bool:
    formation_selector = get_node("VBoxContainer/TopPanel/FormationSelector")
    field_container = get_node("VBoxContainer/MainContainer/FieldContainer/Field")
    players_scroll = get_node("VBoxContainer/MainContainer/PlayersPanel/ScrollContainer")
    players_container = get_node("VBoxContainer/MainContainer/PlayersPanel/ScrollContainer/PlayersContainer")
    back_button = get_node("VBoxContainer/TopPanel/BackButton")
    save_button = get_node("VBoxContainer/TopPanel/SaveButton")

    return formation_selector and field_container and players_container and back_button and save_button

func setup_formation_selector():
    formation_selector.clear()
    formation_selector.add_item("3-2-1 (Defensa sólida)")
    formation_selector.add_item("1-3-2 (Control medio)")
    formation_selector.selected = 0

func connect_signals():
    formation_selector.connect("item_selected", self, "_on_formation_changed")
    back_button.connect("pressed", self, "_on_back_pressed")
    save_button.connect("pressed", self, "_on_save_lineup")

func load_available_players():
    available_players = []  # Load from a data source
    print("LineupEditor: Loaded " + str(available_players.size()) + " players")

func create_field():
    field_positions.clear()
    var field_bg = ColorRect.new()
    field_bg.color = Color(0.1, 0.6, 0.1)
    field_bg.size = Vector2(800, 600)
    field_bg.position = Vector2(0, 0)
    field_container.add_child(field_bg)
    draw_field_lines()
    create_positions_for_formation()


func draw_field_lines():
    var border = Line2D.new()
    border.width = 3
    border.default_color = Color.WHITE
    border.add_point(Vector2(50, 50))
    border.add_point(Vector2(750, 50))
    border.add_point(Vector2(750, 550))
    border.add_point(Vector2(50, 550))
    border.add_point(Vector2(50, 50))
    field_container.add_child(border)

func create_positions_for_formation():
    # Similar logic to place players
    pass

func display_available_players():
    # Displaying players logic
    pass

func load_lineup_from_file():
    # Loading lineup logic
    pass

func _on_formation_changed(index: int):
    match index:
        0: formation = "3-2-1"
        1: formation = "1-3-2"
    create_field()

func _on_back_pressed():
    get_tree().change_scene_to_file("res://scenes/PreMatchMenu.tscn")

func _on_save_lineup():
    print("LineupEditor: Saving lineup...")
    # Save lineup logic

func can_place_player_in_slot(player: Dictionary, slot_name: String) -> bool:
    return true  # Logic to verify if a player can be placed in a slot

