extends Node3D

const ROAD := Color("#34383d")
const SIDEWALK := Color("#9a9a91")
const GRASS := Color("#536b4a")
const WATER := Color("#315f78")
const BUILDING_A := Color("#b8aa91")
const BUILDING_B := Color("#8d9698")
const BUILDING_C := Color("#c7c0ae")
const ACCENT := Color("#d69a45")

var player: CharacterBody3D
var camera: Camera3D
var player_visual: MeshInstance3D
var player_collision: CollisionShape3D
var vehicle_visual: Node3D
var in_vehicle := false
var mission_label: Label
var mission_done := false
var pedestrian_nodes: Array[Node3D] = []
var pedestrian_origins: Array[Vector3] = []
var pedestrian_time := 0.0
var vehicle_speed := 0.0
var touch_buttons: Dictionary = {}
var touch_hint: Label
var speed_label: Label
var camera_yaw := 0.0

func _ready() -> void:
    _setup_input()
    _build_world()
    _build_player()
    _build_vehicle()
    _build_pedestrians()
    _build_ui()

func _setup_input() -> void:
    for action_name in ["sprint", "interact"]:
        if not InputMap.has_action(action_name):
            InputMap.add_action(action_name)
    var key_bindings := {
        "ui_up": [KEY_W],
        "ui_down": [KEY_S],
        "ui_left": [KEY_A],
        "ui_right": [KEY_D],
        "sprint": [KEY_SHIFT],
        "interact": [KEY_E]
    }
    for action_name in key_bindings:
        for key_code in key_bindings[action_name]:
            var event := InputEventKey.new()
            event.physical_keycode = key_code
            InputMap.action_add_event(action_name, event)

func _mat(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.92
    return material

func _building_box(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, color: Color) -> void:
    # Solid building: visible mesh and matching collision so the player cannot walk through it.
    var body := StaticBody3D.new()
    body.name = node_name + "_Body"
    body.position = pos
    parent.add_child(body)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)

    var visual := MeshInstance3D.new()
    visual.name = node_name
    var mesh := BoxMesh.new()
    mesh.size = size
    visual.mesh = mesh
    visual.material_override = _mat(color)
    body.add_child(visual)

func _visual_box(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, color: Color) -> void:
    var item := MeshInstance3D.new()
    item.name = node_name
    var mesh := BoxMesh.new()
    mesh.size = size
    item.mesh = mesh
    item.position = pos
    item.material_override = _mat(color)
    parent.add_child(item)

func _label(parent: Node3D, value: String, pos: Vector3, color := Color.WHITE) -> void:
    var item := Label3D.new()
    item.text = value
    item.position = pos
    item.font_size = 48
    item.pixel_size = 0.012
    item.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    item.modulate = color
    parent.add_child(item)

func _build_world() -> void:
    var world_environment := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.62, 0.68, 0.76)
    environment.ambient_light_energy = 0.8
    world_environment.environment = environment
    add_child(world_environment)

    var sunlight := DirectionalLight3D.new()
    sunlight.rotation_degrees = Vector3(-48, -32, 0)
    sunlight.light_energy = 1.15
    sunlight.shadow_enabled = true
    add_child(sunlight)
    var ground_body := StaticBody3D.new()
    ground_body.name = "GroundCollision"
    add_child(ground_body)
    var ground_shape := CollisionShape3D.new()
    var ground_box := BoxShape3D.new()
    ground_box.size = Vector3(520, 1, 520)
    ground_shape.shape = ground_box
    ground_shape.position.y = -0.6
    ground_body.add_child(ground_shape)
    _visual_box(self, "City_Ground", Vector3(0, -0.6, 0), Vector3(520, 1, 520), GRASS)

    # Pregolya River and embankments.
    _visual_box(self, "Pregolya_River", Vector3(0, -0.35, 8), Vector3(520, 0.2, 42), WATER)
    _visual_box(self, "North_Embankment", Vector3(0, -0.12, -15), Vector3(520, 0.25, 5), SIDEWALK)
    _visual_box(self, "South_Embankment", Vector3(0, -0.12, 31), Vector3(520, 0.25, 5), SIDEWALK)

    # Main avenues and ring roads.
    _visual_box(self, "Leninsky_Prospekt", Vector3(0, 0.02, -48), Vector3(420, 0.18, 18), ROAD)
    _visual_box(self, "Moskovsky_Prospekt", Vector3(72, 0.03, 0), Vector3(18, 0.18, 420), ROAD)
    _visual_box(self, "Northern_Ring", Vector3(0, 0.02, -115), Vector3(420, 0.18, 14), ROAD)
    _visual_box(self, "Southern_Ring", Vector3(0, 0.02, 145), Vector3(420, 0.18, 14), ROAD)
    _visual_box(self, "Western_Road", Vector3(-175, 0.02, 0), Vector3(14, 0.18, 300), ROAD)
    _visual_box(self, "Eastern_Road", Vector3(175, 0.02, 0), Vector3(14, 0.18, 300), ROAD)

    # Three bridges across the river.
    for bridge_x in [-115.0, 18.0, 125.0]:
        _visual_box(self, "Bridge_Structure", Vector3(bridge_x, 0.15, 8), Vector3(16, 0.8, 58), Color("#777b7b"))
        _visual_box(self, "Bridge_Asphalt", Vector3(bridge_x, 0.62, 8), Vector3(11, 0.12, 56), ROAD)

    _district("СЕВЕРНЫЙ РАЙОН", Vector3(-85, 0, -170), 5, 3, 23)
    _district("ЦЕНТР KLD", Vector3(-65, 0, -78), 4, 2, 20)
    _district("ВОСТОЧНЫЙ РАЙОН", Vector3(118, 0, -105), 3, 4, 24)
    _district("ЗАПАДНЫЙ РАЙОН", Vector3(-125, 0, 75), 3, 3, 21)
    _district("ЮЖНЫЙ РАЙОН", Vector3(80, 0, 115), 4, 3, 22)
    _district("ПРОМЗОНА", Vector3(155, 0, 205), 4, 2, 28)

    _build_central_district()

    # Central square and schematic landmarks.
    _landmark("Администрация", Vector3(-25, 7, -105), Vector3(18, 14, 12), BUILDING_C)
    _landmark("Автовокзал", Vector3(80, 5, 165), Vector3(34, 10, 18), BUILDING_B)
    _landmark("Аэропорт", Vector3(-185, 5, -185), Vector3(54, 10, 24), BUILDING_B)
    _landmark("Больница", Vector3(125, 6, -165), Vector3(30, 12, 22), Color("#d6d6cf"))
    _landmark("Полиция", Vector3(-155, 5, -95), Vector3(24, 10, 18), Color("#8798a7"))

    _build_victory_square()
    _build_mira_avenue()
    _build_bridges()
    _build_pregolya_waterfront()
    _build_kneiphof_island()
    _build_cathedral()
    _build_fish_village()
    _build_street_details()
    _build_neighborhood_life()
    _build_city_services()

    for x in range(-190, 191, 20):
        _visual_box(self, "Road_Marking", Vector3(x, 0.13, -48), Vector3(8, 0.025, 0.35), Color("#e6dfc9"))
    for z in range(-135, 136, 20):
        _visual_box(self, "Road_Marking", Vector3(72, 0.14, z), Vector3(0.35, 0.025, 8), Color("#e6dfc9"))

    _label(self, "КАЛИНИНГРАД • KLD", Vector3(0, 22, -72), ACCENT)
    _label(self, "РЕКА ПРЕГОЛЯ", Vector3(-20, 2, 8), Color("#d5eaf2"))

func _build_central_district() -> void:
    # Central KLD street grid: broad avenues, side streets and pedestrian crossings.
    var asphalt := Color("#30363b")
    var pavement := Color("#aaa99f")
    var pale := Color("#e8dfc9")
    for road in [
        [Vector3(-45, 0.04, -112), Vector3(190, 0.18, 13)],
        [Vector3(-45, 0.04, -22), Vector3(190, 0.18, 13)],
        [Vector3(-105, 0.04, -67), Vector3(13, 0.18, 105)],
        [Vector3(28, 0.04, -67), Vector3(13, 0.18, 105)],
        [Vector3(95, 0.04, -67), Vector3(13, 0.18, 105)]
    ]:
        _visual_box(self, "Central_Street", road[0], road[1], asphalt)

    # Sidewalk strips frame the central streets.
    for x in [-114.0, -96.0, 19.0, 37.0, 86.0, 104.0]:
        _visual_box(self, "Central_Sidewalk", Vector3(x, 0.13, -67), Vector3(2.2, 0.22, 105), pavement)
    for z in [-121.0, -103.0, -31.0, -13.0]:
        _visual_box(self, "Central_Sidewalk", Vector3(-45, 0.13, z), Vector3(190, 0.22, 2.2), pavement)

    # Crosswalks at the main intersections.
    for z in [-22.0, -112.0]:
        for stripe in range(7):
            _visual_box(self, "Crosswalk_Stripe", Vector3(-5 + stripe * 2.0, 0.16, z), Vector3(1.0, 0.035, 9), pale)
    for x in [-105.0, 28.0]:
        for stripe in range(7):
            _visual_box(self, "Crosswalk_Stripe", Vector3(x, 0.16, -75 + stripe * 2.0), Vector3(9, 0.035, 1.0), pale)

    # Central blocks with varied building heights and muted historic-city colours.
    var facades := [Color("#c4b59c"), Color("#aeb5b4"), Color("#d0c8b6"), Color("#988f83"), Color("#c7b7a4")]
    var blocks := [
        Vector3(-82, 0, -92), Vector3(-82, 0, -55),
        Vector3(47, 0, -92), Vector3(47, 0, -55),
        Vector3(105, 0, -92), Vector3(105, 0, -55)
    ]
    for b in range(blocks.size()):
        var origin: Vector3 = blocks[b]
        for row in range(2):
            for col in range(2):
                var h := 12.0 + float((b + row + col) % 4) * 3.0
                var w := 13.0 + float((b + col) % 2) * 3.0
                var d := 12.0 + float((b + row) % 2) * 3.0
                var p := origin + Vector3(float(col) * 19.0, h / 2.0, float(row) * 19.0)
                _building_box(self, "Central_Historic_Building", p, Vector3(w, h, d), facades[(b + row + col) % facades.size()])

    # Pocket park and street furniture near Victory Square.
    # Four planted corners keep the square open while preserving the existing tree layout.
    for planter_pos in [Vector3(-42, 0.24, -94), Vector3(-8, 0.24, -94), Vector3(-42, 0.24, -66), Vector3(-8, 0.24, -66)]:
        _visual_box(self, "Victory_Square_Planter", planter_pos, Vector3(8, 0.24, 8), Color("#647b55"))
    for tree_pos in [
        Vector3(-42, 3, -94), Vector3(-8, 3, -94),
        Vector3(-42, 3, -66), Vector3(-8, 3, -66)
    ]:
        _visual_box(self, "Park_Tree_Trunk", tree_pos, Vector3(1.0, 6, 1.0), Color("#66513c"))
        _visual_box(self, "Park_Tree_Crown", tree_pos + Vector3(0, 4, 0), Vector3(5, 5, 5), Color("#486b48"))

    # Street lamps along the main pedestrian streets.
    for lamp_x in [-112.0, -94.0, 18.0, 36.0]:
        for lamp_z in [-105.0, -65.0, -25.0]:
            _visual_box(self, "Street_Lamp_Post", Vector3(lamp_x, 4, lamp_z), Vector3(0.25, 8, 0.25), Color("#34383b"))
            _visual_box(self, "Street_Lamp", Vector3(lamp_x, 8.2, lamp_z), Vector3(1.2, 0.35, 1.2), Color("#e7d6a4"))

    _label(self, "ЦЕНТР • ПРОСПЕКТ МИРА", Vector3(-45, 24, -118), Color("#f0d5a2"))
    _label(self, "УЛИЦЫ И ПЕРЕКРЁСТКИ", Vector3(28, 22, -18), Color("#f0d5a2"))

func _build_victory_square() -> void:
    # Victory Square detail pass: paved plaza, fountain basin, monument and seating.
    var stone := Color("#b9b5a8")
    var dark_stone := Color("#777b7b")
    var water := Color("#78aeb8")
    _visual_box(self, "Victory_Square_Paving", Vector3(-25, 0.22, -80), Vector3(50, 0.16, 40), stone)
    # Low stone edging defines the plaza perimeter without blocking pedestrians.
    for edge_z in [-100.0, -60.0]:
        _visual_box(self, "Victory_Square_Curb", Vector3(-25, 0.36, edge_z), Vector3(50, 0.18, 0.45), dark_stone)
    for edge_x in [-50.0, 0.0]:
        _visual_box(self, "Victory_Square_Curb", Vector3(edge_x, 0.36, -80), Vector3(0.45, 0.18, 40), dark_stone)
    _visual_box(self, "Victory_Square_Fountain_Basin", Vector3(-25, 0.48, -80), Vector3(12, 0.35, 12), dark_stone)
    _visual_box(self, "Victory_Square_Fountain_Water", Vector3(-25, 0.68, -80), Vector3(9.5, 0.08, 9.5), water)
    _visual_box(self, "Victory_Square_Fountain_Core", Vector3(-25, 1.15, -80), Vector3(2.2, 1.0, 2.2), Color("#d0d0c7"))
    # Low monument plinth and a simple vertical sculptural marker.
    _visual_box(self, "Victory_Square_Monument_Platform", Vector3(-25, 0.55, -96), Vector3(10, 0.7, 5), dark_stone)
    _visual_box(self, "Victory_Square_Monument", Vector3(-25, 4.0, -96), Vector3(2.0, 7.0, 2.0), Color("#c2b49b"))
    for bench_x in [-43.0, -7.0]:
        for bench_z in [-91.0, -69.0]:
            _visual_box(self, "Victory_Square_Bench_Seat", Vector3(bench_x, 0.8, bench_z), Vector3(4.0, 0.35, 1.0), Color("#765b43"))
            _visual_box(self, "Victory_Square_Bench_Legs", Vector3(bench_x, 0.4, bench_z), Vector3(3.5, 0.7, 0.25), dark_stone)
    for tile_x in range(-47, 0, 6):
        _visual_box(self, "Victory_Square_Paving_Line", Vector3(float(tile_x), 0.32, -80), Vector3(0.08, 0.025, 38), Color("#d8d2c3"))
    for tile_z in range(-98, -61, 6):
        _visual_box(self, "Victory_Square_Paving_Line", Vector3(-25, 0.32, float(tile_z)), Vector3(48, 0.025, 0.08), Color("#d8d2c3"))
    _label(self, "ПЛОЩАДЬ ПОБЕДЫ", Vector3(-25, 15, -104), Color("#f3dfb8"))

func _build_mira_avenue() -> void:
    # Prospect Mira corridor: boulevard median, sidewalks, crossings and street furniture.
    var dark_stone := Color("#777b7b")
    var asphalt := Color("#30363b")
    var pavement := Color("#b6b2a6")
    var lane_mark := Color("#e9e1cf")
    _visual_box(self, "Prospect_Mira_Asphalt", Vector3(-45, 0.19, -112), Vector3(205, 0.12, 13), asphalt)
    _visual_box(self, "Prospect_Mira_Median", Vector3(-45, 0.31, -112), Vector3(188, 0.18, 1.1), Color("#667653"))
    for avenue_center_x in [-45.0]:
        for offset in [-12.5, 12.5]:
            _visual_box(self, "Prospect_Mira_Sidewalk", Vector3(avenue_center_x, 0.2, -112 + offset), Vector3(205, 0.22, 3.0), pavement)
    # Tree planters and lamps alternate along the avenue edges.
    for x in range(-130, 51, 30):
        for z in [-121.0, -103.0]:
            _visual_box(self, "Prospect_Mira_Tree_Planter", Vector3(float(x), 0.42, z), Vector3(4.0, 0.35, 4.0), Color("#777b61"))
            _visual_box(self, "Prospect_Mira_Tree_Trunk", Vector3(float(x), 3.0, z), Vector3(0.55, 5.0, 0.55), Color("#66513c"))
            _visual_box(self, "Prospect_Mira_Tree_Crown", Vector3(float(x), 6.0, z), Vector3(4.5, 4.5, 4.5), Color("#486b48"))
    for x in [-115.0, -75.0, -35.0, 5.0, 45.0]:
        for z in [-126.0, -98.0]:
            _visual_box(self, "Prospect_Mira_Lamp_Post", Vector3(x, 4.0, z), Vector3(0.22, 8.0, 0.22), Color("#34383b"))
            _visual_box(self, "Prospect_Mira_Lamp_Head", Vector3(x, 8.1, z), Vector3(1.0, 0.3, 0.55), Color("#e7d6a4"))
    # Two simple public-transport stops facing the avenue.
    for stop_x in [-88.0, 18.0]:
        _visual_box(self, "Prospect_Mira_Bus_Stop_Base", Vector3(stop_x, 0.45, -99.0), Vector3(7.0, 0.25, 2.5), dark_stone)
        _visual_box(self, "Prospect_Mira_Bus_Stop_Roof", Vector3(stop_x, 3.0, -99.0), Vector3(7.0, 0.3, 2.5), Color("#59636a"))
        for support_x in [-2.8, 2.8]:
            _visual_box(self, "Prospect_Mira_Bus_Stop_Support", Vector3(stop_x + support_x, 1.7, -99.0), Vector3(0.18, 2.8, 0.18), dark_stone)
    _label(self, "ПРОСПЕКТ МИРА", Vector3(-45, 19, -130), Color("#f0d5a2"))

func _build_bridges() -> void:
    # Three drivable/walkable crossings with a collision deck and safe pedestrian rails.
    for bridge_x in [-115.0, 18.0, 125.0]:
        var deck := StaticBody3D.new()
        deck.name = "Bridge_Deck_Collision"
        deck.position = Vector3(bridge_x, 0.72, 8)
        add_child(deck)
        var deck_shape := CollisionShape3D.new()
        var deck_box := BoxShape3D.new()
        deck_box.size = Vector3(11.0, 0.35, 56.0)
        deck_shape.shape = deck_box
        deck.add_child(deck_shape)

        for side_x in [-6.0, 6.0]:
            _visual_box(self, "Bridge_Railing_Base", Vector3(bridge_x + side_x, 1.2, 8), Vector3(0.35, 1.0, 56), Color("#686d70"))
            _visual_box(self, "Bridge_Railing_Top", Vector3(bridge_x + side_x, 2.0, 8), Vector3(0.2, 0.2, 56), Color("#aeb1ae"))
        for lamp_z in [-14.0, 8.0, 30.0]:
            for side_x in [-5.0, 5.0]:
                _visual_box(self, "Bridge_Lamp_Post", Vector3(bridge_x + side_x, 3.0, lamp_z), Vector3(0.18, 4.0, 0.18), Color("#34383b"))
                _visual_box(self, "Bridge_Lamp_Head", Vector3(bridge_x + side_x, 5.1, lamp_z), Vector3(0.8, 0.25, 0.8), Color("#e7d6a4"))


func _build_pregolya_waterfront() -> void:
    # Continuous promenades on both banks, with stone edging, stairs, benches and lights.
    for bank_z in [-17.0, 33.0]:
        _visual_box(self, "Pregolya_Promenade", Vector3(0, 0.18, bank_z), Vector3(500, 0.32, 7.0), Color("#aaa99f"))
        _visual_box(self, "Pregolya_Quay_Edge", Vector3(0, 0.42, bank_z + (3.5 if bank_z < 0 else -3.5)), Vector3(500, 0.55, 0.7), Color("#777b7b"))
        for x in range(-230, 231, 38):
            _visual_box(self, "Embankment_Bench_Seat", Vector3(float(x), 0.82, bank_z), Vector3(3.4, 0.28, 0.8), Color("#765b43"))
            _visual_box(self, "Embankment_Bench_Legs", Vector3(float(x), 0.48, bank_z), Vector3(2.8, 0.65, 0.18), Color("#55585a"))
        for x in range(-215, 216, 28):
            _visual_box(self, "Embankment_Lamp_Post", Vector3(float(x), 3.2, bank_z + 2.0), Vector3(0.18, 6.4, 0.18), Color("#34383b"))
            _visual_box(self, "Embankment_Lamp_Head", Vector3(float(x), 6.5, bank_z + 2.0), Vector3(0.8, 0.28, 0.8), Color("#e7d6a4"))

    # Small piers extend into the river beside the historic centre and Fish Village.
    for pier_x in [-52.0, -25.0, 5.0, 42.0]:
        _visual_box(self, "Pregolya_Wooden_Pier", Vector3(pier_x, 0.05, 8), Vector3(8, 0.35, 13), Color("#80684e"))
        for rail_x in [-3.7, 3.7]:
            _visual_box(self, "Pier_Railing", Vector3(pier_x + rail_x, 0.75, 8), Vector3(0.18, 1.2, 13), Color("#5e5144"))
    _label(self, "НАБЕРЕЖНАЯ ПРЕГОЛИ", Vector3(-15, 8, -22), Color("#e4d5b8"))


func _build_kneiphof_island() -> void:
    # Raised, collidable Kneiphof island: the cathedral must stand on land, not over the river surface.
    var island := StaticBody3D.new()
    island.name = "Kneiphof_Island"
    island.position = Vector3(-65, -0.08, 18)
    add_child(island)

    var island_shape := CollisionShape3D.new()
    var island_box := BoxShape3D.new()
    island_box.size = Vector3(48, 0.8, 44)
    island_shape.shape = island_box
    island.add_child(island_shape)

    var island_mesh := MeshInstance3D.new()
    island_mesh.name = "Kneiphof_Ground"
    var ground_mesh := BoxMesh.new()
    ground_mesh.size = Vector3(48, 0.8, 44)
    island_mesh.mesh = ground_mesh
    island_mesh.material_override = _mat(Color("#77796b"))
    island.add_child(island_mesh)

    # Stone pedestrian paths and planted areas around the cathedral.
    _visual_box(self, "Kneiphof_Cathedral_Plaza", Vector3(-65, 0.36, 18), Vector3(38, 0.12, 32), Color("#aaa697"))
    _visual_box(self, "Kneiphof_North_Path", Vector3(-65, 0.38, 1), Vector3(7, 0.12, 10), Color("#c1b9a8"))
    _visual_box(self, "Kneiphof_South_Path", Vector3(-65, 0.38, 35), Vector3(7, 0.12, 8), Color("#c1b9a8"))

    for tree_x in [-84.0, -46.0]:
        for tree_z in [2.0, 34.0]:
            _visual_box(self, "Kneiphof_Tree_Trunk", Vector3(tree_x, 2.2, tree_z), Vector3(0.55, 4.4, 0.55), Color("#66513c"))
            _visual_box(self, "Kneiphof_Tree_Crown", Vector3(tree_x, 5.0, tree_z), Vector3(4.0, 4.0, 4.0), Color("#486b48"))

    # Two short pedestrian approaches join the island to both river banks.
    for bridge_z in [-9.5, 45.5]:
        var approach := StaticBody3D.new()
        approach.name = "Kneiphof_Pedestrian_Approach"
        approach.position = Vector3(-65, 0.55, bridge_z)
        add_child(approach)

        var approach_shape := CollisionShape3D.new()
        var approach_box := BoxShape3D.new()
        approach_box.size = Vector3(7.0, 0.45, 15.0)
        approach_shape.shape = approach_box
        approach.add_child(approach_shape)

        var approach_mesh := MeshInstance3D.new()
        var deck_mesh := BoxMesh.new()
        deck_mesh.size = Vector3(7.0, 0.45, 15.0)
        approach_mesh.mesh = deck_mesh
        approach_mesh.material_override = _mat(Color("#8c8980"))
        approach.add_child(approach_mesh)

        for rail_x in [-3.6, 3.6]:
            _visual_box(self, "Kneiphof_Approach_Railing", Vector3(-65 + rail_x, 1.45, bridge_z), Vector3(0.18, 1.8, 15.0), Color("#686d70"))

    # Pedestrian connection from the south approach towards the Fish Village quarter.
    _visual_box(self, "Kneiphof_Fish_Village_Walkway", Vector3(-30, 0.34, 43), Vector3(62, 0.18, 5), Color("#b8b1a2"))
    _label(self, "ОСТРОВ КНЕЙПХОФ", Vector3(-65, 8, -4), Color("#f0d5a2"))


func _build_cathedral() -> void:
    # Landmark-inspired silhouette of Königsberg Cathedral on Kneiphof island.
    var brick := Color("#9b8068")
    var roof := Color("#454b50")
    _building_box(self, "Cathedral_Main_Nave", Vector3(-65, 8.5, 18), Vector3(29, 17, 13), brick)
    _building_box(self, "Cathedral_Roof", Vector3(-65, 17.3, 18), Vector3(30, 1.0, 14), roof)
    for tower_x in [-76.0, -54.0]:
        _building_box(self, "Cathedral_Tower", Vector3(tower_x, 15.0, 10.5), Vector3(5.0, 30.0, 5.0), brick)
        var spire := MeshInstance3D.new()
        var spire_mesh := CylinderMesh.new()
        spire_mesh.top_radius = 0.0
        spire_mesh.bottom_radius = 3.2
        spire_mesh.height = 8.0
        spire_mesh.radial_segments = 4
        spire.mesh = spire_mesh
        spire.position = Vector3(tower_x, 34.0, 10.5)
        spire.material_override = _mat(roof)
        add_child(spire)
    # Tall narrow windows on both long facades.
    for window_x in range(-76, -53, 4):
        _visual_box(self, "Cathedral_Window", Vector3(float(window_x), 10.0, 11.35), Vector3(1.2, 5.0, 0.12), Color("#343d46"))
        _visual_box(self, "Cathedral_Window", Vector3(float(window_x), 10.0, 24.65), Vector3(1.2, 5.0, 0.12), Color("#343d46"))
    _label(self, "КАФЕДРАЛЬНЫЙ СОБОР", Vector3(-65, 42, 5), Color("#f0d5a2"))


func _build_fish_village() -> void:
    # Historic waterfront quarter: varied gabled blocks, arcades and a small market square.
    var plaster := [Color("#d5c5a8"), Color("#b8a28a"), Color("#d8d0bd"), Color("#aeb5b2")]
    var timber := Color("#5c5147")
    _visual_box(self, "Fish_Village_Square", Vector3(-5, 0.22, 48), Vector3(74, 0.3, 31), Color("#b7ae9d"))
    var building_data := [
        [Vector3(-32, 6, 39), Vector3(13, 12, 11)],
        [Vector3(-14, 8, 42), Vector3(14, 16, 12)],
        [Vector3(7, 7, 40), Vector3(15, 14, 12)],
        [Vector3(29, 5.5, 43), Vector3(13, 11, 11)],
        [Vector3(-25, 5, 62), Vector3(14, 10, 12)],
        [Vector3(1, 6, 63), Vector3(16, 12, 13)],
        [Vector3(25, 5, 62), Vector3(13, 10, 11)]
    ]
    for i in range(building_data.size()):
        var data: Array = building_data[i]
        var pos: Vector3 = data[0]
        var size: Vector3 = data[1]
        _building_box(self, "Fish_Village_Historic_House", pos, size, plaster[i % plaster.size()])
        _visual_box(self, "Fish_Village_Roof", pos + Vector3(0, size.y / 2.0 + 0.8, 0), Vector3(size.x + 1.0, 1.6, size.z + 1.0), Color("#56504a"))
        for beam_x in [-size.x * 0.3, size.x * 0.3]:
            _visual_box(self, "Fish_Village_Timber_Detail", pos + Vector3(beam_x, 0, size.z / 2.0 + 0.08), Vector3(0.22, size.y - 1.0, 0.18), timber)
    # Promenade-facing cafe terraces and planted tubs.
    for x in [-28.0, -5.0, 18.0, 39.0]:
        _visual_box(self, "Fish_Village_Terrace", Vector3(x, 0.65, 31.0), Vector3(7.0, 0.25, 3.5), Color("#80684e"))
        _visual_box(self, "Fish_Village_Planter", Vector3(x, 0.7, 66.0), Vector3(2.2, 1.0, 2.2), Color("#65734f"))
    _label(self, "РЫБНАЯ ДЕРЕВНЯ", Vector3(-5, 22, 30), Color("#f0d5a2"))


func _district(title: String, origin: Vector3, columns: int, rows: int, spacing: float) -> void:
    var colors := [BUILDING_A, BUILDING_B, BUILDING_C]
    for x in range(columns):
        for z in range(rows):
            var height := 9.0 + float((x * 7 + z * 3) % 4) * 3.2
            var width := 12.0 + float((x + z) % 3) * 2.0
            var depth := 12.0 + float((x * 2 + z) % 3) * 2.0
            var pos := origin + Vector3(float(x) * spacing, height / 2.0, float(z) * spacing)
            _building_box(self, "City_Block_Building", pos, Vector3(width, height, depth), colors[(x + z) % colors.size()])
    _label(self, title, origin + Vector3((columns - 1) * spacing / 2.0, 27, -12), ACCENT)

func _landmark(title: String, pos: Vector3, size: Vector3, color: Color) -> void:
    _building_box(self, title + "_Building", pos, size, color)
    _label(self, title, pos + Vector3(0, size.y / 2.0 + 4, 0), Color.WHITE)

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(-25, 2, -55)
    add_child(player)

    player_visual = MeshInstance3D.new()
    var capsule_mesh := CapsuleMesh.new()
    capsule_mesh.radius = 0.7
    capsule_mesh.height = 2.2
    player_visual.mesh = capsule_mesh
    player_visual.material_override = _mat(ACCENT)
    player.add_child(player_visual)

    player_collision = CollisionShape3D.new()
    var capsule_shape := CapsuleShape3D.new()
    capsule_shape.radius = 0.7
    capsule_shape.height = 2.2
    player_collision.shape = capsule_shape
    player.add_child(player_collision)

    camera = Camera3D.new()
    camera.position = Vector3(0, 8, 14)
    camera.rotation_degrees = Vector3(-24, 0, 0)
    camera.current = true
    player.add_child(camera)

func _build_ui() -> void:
    var layer := CanvasLayer.new()
    layer.name = "MobileHUD"
    add_child(layer)

    var panel := ColorRect.new()
    panel.color = Color(0.04, 0.06, 0.08, 0.78)
    panel.position = Vector2(18, 18)
    panel.size = Vector2(370, 76)
    layer.add_child(panel)

    var title := Label.new()
    title.text = "WESTERN RUSH RP  |  KLD\nМобильная версия • тест 0.2"
    title.position = Vector2(32, 26)
    title.add_theme_font_size_override("font_size", 20)
    title.add_theme_color_override("font_color", Color.WHITE)
    layer.add_child(title)

    var hint := Label.new()
    hint.text = "Слева — движение • справа — действия"
    hint.position = Vector2(20, 102)
    hint.add_theme_font_size_override("font_size", 15)
    hint.add_theme_color_override("font_color", Color("#f2d6a2"))
    layer.add_child(hint)
    touch_hint = hint

    speed_label = Label.new()
    speed_label.text = "0 KM/H"
    speed_label.anchor_left = 1.0
    speed_label.anchor_right = 1.0
    speed_label.offset_left = -210
    speed_label.offset_right = -20
    speed_label.offset_top = 24
    speed_label.offset_bottom = 76
    speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    speed_label.add_theme_font_size_override("font_size", 30)
    speed_label.add_theme_color_override("font_color", Color("#f2d6a2"))
    layer.add_child(speed_label)

    # Large on-screen buttons support simultaneous multi-touch on Android.
    touch_buttons["up"] = _add_touch_button(layer, "▲", "ui_up", 0.0, 1.0, 92, -218, 68, 68)
    touch_buttons["left"] = _add_touch_button(layer, "◀", "ui_left", 0.0, 1.0, 20, -146, 68, 68)
    touch_buttons["right"] = _add_touch_button(layer, "▶", "ui_right", 0.0, 1.0, 164, -146, 68, 68)
    touch_buttons["down"] = _add_touch_button(layer, "▼", "ui_down", 0.0, 1.0, 92, -74, 68, 68)
    touch_buttons["sprint"] = _add_touch_button(layer, "БЕГ", "sprint", 1.0, 1.0, -142, -112, 118, 88)
    touch_buttons["interact"] = _add_touch_button(layer, "E • АВТО", "interact", 1.0, 1.0, -142, -208, 118, 76)

    mission_label = Label.new()
    mission_label.text = "ЗАДАНИЕ: Найди машину и садись за руль"
    mission_label.position = Vector2(20, 145)
    mission_label.add_theme_font_size_override("font_size", 17)
    mission_label.add_theme_color_override("font_color", Color("#f2d6a2"))
    layer.add_child(mission_label)


func _add_touch_button(layer: CanvasLayer, caption: String, action: String, anchor_x: float, anchor_y: float, left: float, top: float, width: float, height: float) -> Button:
    var button := Button.new()
    button.text = caption
    button.anchor_left = anchor_x
    button.anchor_right = anchor_x
    button.anchor_top = anchor_y
    button.anchor_bottom = anchor_y
    button.offset_left = left
    button.offset_top = top
    button.offset_right = left + width
    button.offset_bottom = top + height
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 22)
    button.add_theme_color_override("font_color", Color.WHITE)
    button.custom_minimum_size = Vector2(width, height)
    layer.add_child(button)
    button.button_down.connect(_press_action.bind(action))
    button.button_up.connect(_release_action.bind(action))
    return button


func _update_touch_mode() -> void:
    if touch_buttons.is_empty():
        return
    touch_buttons["up"].text = "ГАЗ" if in_vehicle else "▲"
    touch_buttons["down"].text = "ТОРМ" if in_vehicle else "▼"
    touch_buttons["left"].text = "РУЛЬ ◀" if in_vehicle else "◀"
    touch_buttons["right"].text = "РУЛЬ ▶" if in_vehicle else "▶"
    touch_buttons["sprint"].visible = not in_vehicle
    touch_buttons["interact"].text = "ВЫЙТИ" if in_vehicle else "СЕСТЬ В АВТО"


func _press_action(action: String) -> void:
    Input.action_press(action)


func _release_action(action: String) -> void:
    Input.action_release(action)


func _input(event: InputEvent) -> void:
    # On Android, drag on the right side of the screen to rotate the third-person camera.
    if event is InputEventScreenDrag and event.position.x > get_viewport().get_visible_rect().size.x * 0.38:
        camera_yaw -= event.relative.x * 0.006
        if camera != null and player != null:
            camera.position = Vector3(0, 8, 14).rotated(Vector3.UP, camera_yaw)
            camera.look_at(player.global_position + Vector3(0, 1.0, 0), Vector3.UP)


func _physics_process(delta: float) -> void:
    if player == null:
        return

    if Input.is_action_just_pressed("interact"):
        if not in_vehicle and player.global_position.distance_to(vehicle_visual.global_position) < 13.0:
            in_vehicle = true
            player.global_position = vehicle_visual.global_position + Vector3(0, 1.1, 0)
            player_visual.visible = false
            vehicle_visual.visible = true
            mission_label.text = "ЗАДАНИЕ: Доедь до остановки у жилого квартала"
            _update_touch_mode()
        elif in_vehicle:
            in_vehicle = false
            player_visual.visible = true
            player.global_position = vehicle_visual.global_position + Vector3(2.5, 1.1, 0)
            vehicle_speed = 0.0
            mission_label.text = "ВЫШЕЛ ИЗ МАШИНЫ • Нажми E рядом с авто"
            _update_touch_mode()

    if in_vehicle:
        var throttle := Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
        var steering := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
        var target_speed := throttle * (26.0 if throttle >= 0.0 else 9.0)
        vehicle_speed = move_toward(vehicle_speed, target_speed, (16.0 if throttle != 0.0 else 9.0) * delta)
        if abs(vehicle_speed) > 0.15:
            player.rotation.y -= steering * delta * 1.8 * clamp(abs(vehicle_speed) / 12.0, 0.25, 1.0) * sign(vehicle_speed)
        var forward := -player.global_transform.basis.z
        player.velocity.x = forward.x * vehicle_speed
        player.velocity.z = forward.z * vehicle_speed
    else:
        var direction := Vector3.ZERO
        direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
        direction.z = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
        direction = direction.normalized()
        var move_speed := 12.0 if Input.is_action_pressed("sprint") else 7.0
        player.velocity.x = direction.x * move_speed
        player.velocity.z = direction.z * move_speed
        if direction.length_squared() > 0.001:
            player.rotation.y = lerp_angle(player.rotation.y, atan2(direction.x, -direction.z), delta * 8.0)

    if not player.is_on_floor():
        player.velocity.y -= 22.0 * delta
    else:
        player.velocity.y = -0.2

    player.move_and_slide()
    if speed_label != null:
        speed_label.text = "%d KM/H" % int(abs(vehicle_speed) * 3.6) if in_vehicle else "0 KM/H"
    if in_vehicle:
        vehicle_visual.global_position = player.global_position + Vector3(0, -1.1, 0)
        vehicle_visual.global_rotation.y = player.global_rotation.y

    if not mission_done and in_vehicle and player.global_position.distance_to(Vector3(62, 0, 72)) < 12.0:
        mission_done = true
        mission_label.text = "ЗАДАНИЕ ВЫПОЛНЕНО: Добрался до остановки! +500$"


func _build_street_details() -> void:
    # Street-level visual pass: lane separators, stop lines, crossings and facade rhythm.
    var lane_white := Color("#e8e3d5")
    var lane_yellow := Color("#d6b85f")
    var signal_dark := Color("#303438")
    var signal_red := Color("#d94b43")
    var signal_green := Color("#58a66b")
    var glass := Color("#526a75")
    var trim := Color("#6d6256")

    # Dashed centre lines and edge lines on the main east-west avenue.
    for x in range(-140, 56, 16):
        _visual_box(self, "Mira_Centre_Dash", Vector3(float(x), 0.31, -112), Vector3(7.0, 0.035, 0.22), lane_yellow)
    for z in [-119.0, -105.0]:
        _visual_box(self, "Mira_Road_Edge_Line", Vector3(-45, 0.30, z), Vector3(205, 0.035, 0.16), lane_white)

    # Stop bars and zebra crossings at the central intersections.
    for cross_x in [-105.0, 28.0]:
        for side_z in [-120.0, -104.0]:
            _visual_box(self, "Intersection_Stop_Line", Vector3(cross_x, 0.32, side_z), Vector3(10.0, 0.035, 0.55), lane_white)
        for stripe in range(8):
            _visual_box(self, "Mira_Zebra_Stripe", Vector3(cross_x - 5.0 + float(stripe) * 1.4, 0.33, -112), Vector3(0.75, 0.04, 5.5), lane_white)

    # Traffic-light poles and three stacked signal lenses at each major junction.
    for signal_x in [-112.0, -98.0, 21.0, 35.0]:
        for signal_z in [-122.0, -102.0]:
            _visual_box(self, "Traffic_Signal_Pole", Vector3(signal_x, 3.0, signal_z), Vector3(0.18, 6.0, 0.18), signal_dark)
            _visual_box(self, "Traffic_Signal_Housing", Vector3(signal_x, 6.2, signal_z), Vector3(0.72, 1.9, 0.42), signal_dark)
            _visual_box(self, "Traffic_Signal_Red", Vector3(signal_x, 6.75, signal_z - 0.23), Vector3(0.32, 0.32, 0.08), signal_red)
            _visual_box(self, "Traffic_Signal_Amber", Vector3(signal_x, 6.2, signal_z - 0.23), Vector3(0.32, 0.32, 0.08), lane_yellow)
            _visual_box(self, "Traffic_Signal_Green", Vector3(signal_x, 5.65, signal_z - 0.23), Vector3(0.32, 0.32, 0.08), signal_green)

    # Repeating shopfront glazing and stone piers along the Mira avenue blocks.
    for facade_x in [-82.0, 47.0, 105.0]:
        for facade_z in [-101.0, -83.0, -64.0, -46.0]:
            _visual_box(self, "Historic_Facade_Ground_Floor", Vector3(facade_x, 2.2, facade_z), Vector3(8.0, 4.2, 0.18), trim)
            for window_x in [-2.5, 0.0, 2.5]:
                _visual_box(self, "Historic_Facade_Window", Vector3(facade_x + window_x, 2.4, facade_z - 0.12), Vector3(1.65, 2.5, 0.08), glass)
            _visual_box(self, "Historic_Facade_Cornice", Vector3(facade_x, 4.55, facade_z), Vector3(9.0, 0.22, 0.35), Color("#d1c4ad"))
            for pier_x in [-4.2, 4.2]:
                _visual_box(self, "Historic_Facade_Pier", Vector3(facade_x + pier_x, 2.5, facade_z), Vector3(0.35, 4.8, 0.45), Color("#b9aa91"))

    # Pedestrian crossing signs at both ends of the central avenue crossings.
    for sign_x in [-114.0, -96.0, 19.0, 37.0]:
        _visual_box(self, "Crossing_Sign_Pole", Vector3(sign_x, 3.0, -124.0), Vector3(0.12, 6.0, 0.12), signal_dark)
        _visual_box(self, "Crossing_Sign_Plate", Vector3(sign_x, 5.8, -124.0), Vector3(1.1, 1.1, 0.12), Color("#e7e5d8"))


func _build_neighborhood_life() -> void:
    # Playable-feeling residential block: courtyard, parking, shops, bus stop and street furniture.
    var asphalt := Color("#34393d")
    var concrete := Color("#aaa79d")
    var brick := Color("#aa9882")
    var dark_trim := Color("#554d45")
    var glass := Color("#58717b")
    var green := Color("#55724d")
    var white := Color("#e7e1d4")

    # Small local access road and parking bays in the southern residential quarter.
    _visual_box(self, "Residential_Access_Road", Vector3(112, 0.18, 78), Vector3(92, 0.16, 12), asphalt)
    _visual_box(self, "Residential_Parking_Lot", Vector3(112, 0.22, 94), Vector3(66, 0.12, 22), Color("#777a78"))
    for x in range(82, 144, 10):
        _visual_box(self, "Parking_Bay_Line", Vector3(float(x), 0.31, 94), Vector3(0.16, 0.035, 18), white)
    _visual_box(self, "Parking_Aisle_Line", Vector3(112, 0.31, 84), Vector3(64, 0.035, 0.18), white)

    # Residential courtyard with a paved centre, lawn, benches and trees.
    _visual_box(self, "Residential_Courtyard", Vector3(34, 0.18, 92), Vector3(54, 0.24, 42), Color("#8f9684"))
    _visual_box(self, "Courtyard_Lawn", Vector3(34, 0.34, 92), Vector3(28, 0.12, 20), green)
    for tree_x in [13.0, 55.0]:
        for tree_z in [77.0, 107.0]:
            _visual_box(self, "Courtyard_Tree_Trunk", Vector3(tree_x, 2.6, tree_z), Vector3(0.5, 5.2, 0.5), Color("#66513c"))
            _visual_box(self, "Courtyard_Tree_Crown", Vector3(tree_x, 5.8, tree_z), Vector3(4.5, 4.5, 4.5), Color("#486b48"))
    for bench_x in [24.0, 44.0]:
        _visual_box(self, "Courtyard_Bench_Seat", Vector3(bench_x, 0.85, 92), Vector3(3.2, 0.25, 0.75), Color("#765b43"))
        _visual_box(self, "Courtyard_Bench_Legs", Vector3(bench_x, 0.48, 92), Vector3(2.8, 0.65, 0.16), dark_trim)

    # Four recognizable supermarket storefronts: Vester, Pyaterochka, Pobeda and SPAR.
    var shop_positions := [
        Vector3(60, 5.5, 57), Vector3(82, 5.5, 57),
        Vector3(104, 5.5, 57), Vector3(126, 5.5, 57)
    ]
    var shop_names := ["ВЕСТЕР", "ПЯТЁРОЧКА", "ПОБЕДА", "SPAR"]
    var sign_colors := [
        Color("#263d79"), Color("#d92732"),
        Color("#c72c36"), Color("#168348")
    ]
    var facade_colors := [brick, Color("#c2b6a3"), Color("#b3aaa0"), Color("#c8c0ad")]
    for i in range(shop_positions.size()):
        var p: Vector3 = shop_positions[i]
        _building_box(self, "Supermarket_" + str(i), p, Vector3(18, 11, 13), facade_colors[i])
        _visual_box(self, "Supermarket_Glassfront", Vector3(p.x, 2.3, p.z - 6.62), Vector3(12.0, 3.2, 0.12), glass)
        _visual_box(self, "Supermarket_Entrance", Vector3(p.x + 6.7, 2.1, p.z - 6.7), Vector3(1.5, 3.6, 0.16), dark_trim)
        _visual_box(self, "Supermarket_Sign_Backplate", Vector3(p.x, 4.8, p.z - 6.78), Vector3(15.5, 1.15, 0.24), sign_colors[i])
        _label(self, shop_names[i], Vector3(p.x, 4.85, p.z - 6.96), Color.WHITE)
        # Illuminated-looking brand strip above the entrance.
        _visual_box(self, "Supermarket_Sign_Light", Vector3(p.x, 5.55, p.z - 6.72), Vector3(14.5, 0.08, 0.12), Color("#f1e5c5"))

    # Covered bus shelter, stop pole and bench beside the local access road.
    _visual_box(self, "Neighborhood_Bus_Stop_Base", Vector3(62, 0.38, 72), Vector3(8, 0.25, 3), concrete)
    _visual_box(self, "Neighborhood_Bus_Stop_Roof", Vector3(62, 3.0, 72), Vector3(8, 0.25, 3), dark_trim)
    for x in [58.5, 65.5]:
        _visual_box(self, "Neighborhood_Bus_Stop_Support", Vector3(x, 1.7, 72), Vector3(0.16, 2.8, 0.16), dark_trim)
    _visual_box(self, "Neighborhood_Bus_Stop_Glass", Vector3(62, 1.8, 73.35), Vector3(6.5, 2.4, 0.08), glass)
    _visual_box(self, "Neighborhood_Bus_Stop_Bench", Vector3(62, 0.9, 71.2), Vector3(4.0, 0.25, 0.7), Color("#765b43"))
    _visual_box(self, "Bus_Stop_Pole", Vector3(68, 2.0, 69), Vector3(0.12, 4.0, 0.12), dark_trim)
    _visual_box(self, "Bus_Stop_Sign", Vector3(68, 4.0, 69), Vector3(0.8, 0.8, 0.12), Color("#4c7892"))

    # Waste/recycling point and bicycle racks add recognizable street-level detail.
    _visual_box(self, "Recycling_Bin", Vector3(78, 0.9, 75), Vector3(1.2, 1.8, 1.2), Color("#557b67"))
    _visual_box(self, "Waste_Bin", Vector3(81, 0.8, 75), Vector3(0.9, 1.6, 0.9), Color("#555d63"))
    for rack_x in [86.0, 88.0, 90.0]:
        _visual_box(self, "Bicycle_Rack", Vector3(rack_x, 0.8, 72), Vector3(0.12, 1.2, 1.2), Color("#555d63"))

    _label(self, "ЖИЛОЙ КВАРТАЛ • МАГАЗИНЫ • ОСТАНОВКА", Vector3(92, 20, 48), Color("#f0d5a2"))


func _build_parked_car(parent: Node3D, car_name: String, pos: Vector3, body_color: Color) -> void:
    var car := Node3D.new()
    car.name = car_name
    car.position = pos
    parent.add_child(car)
    _visual_box(car, "Body", Vector3(0, 0.72, 0), Vector3(4.1, 0.9, 1.9), body_color)
    _visual_box(car, "Cabin", Vector3(-0.25, 1.35, 0), Vector3(2.0, 0.72, 1.55), Color("#34434b"))
    _visual_box(car, "Windshield", Vector3(0.82, 1.34, 0), Vector3(0.08, 0.55, 1.42), Color("#829da5"))
    _visual_box(car, "Front_Bumper", Vector3(2.08, 0.55, 0), Vector3(0.16, 0.3, 1.9), Color("#34383b"))
    for wheel_x in [-1.25, 1.25]:
        for wheel_z in [-1.0, 1.0]:
            var wheel := MeshInstance3D.new()
            var wheel_mesh := CylinderMesh.new()
            wheel_mesh.top_radius = 0.38
            wheel_mesh.bottom_radius = 0.38
            wheel_mesh.height = 0.24
            wheel.mesh = wheel_mesh
            wheel.position = Vector3(wheel_x, 0.38, wheel_z)
            wheel.rotation_degrees.z = 90
            wheel.material_override = _mat(Color("#202326"))
            car.add_child(wheel)


func _build_city_services() -> void:
    # Real-life parking: marked bays, parked vehicles, accessible bay and lighting.
    var asphalt := Color("#34393d")
    var concrete := Color("#aaa79d")
    var white := Color("#e7e1d4")
    var yellow := Color("#d8b64f")
    _visual_box(self, "Shop_Parking_Asphalt", Vector3(112, 0.24, 94), Vector3(68, 0.14, 24), asphalt)
    for x in range(80, 147, 8):
        _visual_box(self, "Shop_Parking_Bay_Mark", Vector3(float(x), 0.34, 94), Vector3(0.14, 0.035, 18), white)
    _visual_box(self, "Parking_Access_Aisle", Vector3(112, 0.34, 82), Vector3(68, 0.035, 0.18), white)
    _visual_box(self, "Accessible_Parking_Bay", Vector3(142, 0.36, 94), Vector3(7.0, 0.04, 17), Color("#477da0"))
    _label(self, "P ♿", Vector3(142, 0.55, 94), Color.WHITE)
    _visual_box(self, "Shop_Parking_Pedestrian_Path", Vector3(112, 0.38, 78), Vector3(68, 0.12, 2.0), concrete)
    var parked_colors := [Color("#a9b4b8"), Color("#263d79"), Color("#8d3432"), Color("#d2c6a9"), Color("#3e6252")]
    var parked_x := [86.0, 98.0, 110.0, 122.0, 134.0]
    for i in range(parked_x.size()):
        _build_parked_car(self, "Parked_Car_%02d" % i, Vector3(parked_x[i], 0.35, 92.0), parked_colors[i])
    for lamp_x in [78.0, 146.0]:
        _visual_box(self, "Parking_Lamp_Post", Vector3(lamp_x, 3.5, 82), Vector3(0.18, 7.0, 0.18), Color("#34383b"))
        _visual_box(self, "Parking_Lamp_Head", Vector3(lamp_x, 7.1, 82), Vector3(0.9, 0.3, 0.9), Color("#e7d6a4"))

    # Shawarma takeaway with service window, menu board, canopy and outdoor tables.
    var shawarma_pos := Vector3(153, 5.5, 57)
    _building_box(self, "Shawarma_Pavilion", shawarma_pos, Vector3(16, 11, 12), Color("#c6b69a"))
    _visual_box(self, "Shawarma_Front_Glass", Vector3(153, 2.5, 50.8), Vector3(10.5, 3.5, 0.12), Color("#526a75"))
    _visual_box(self, "Shawarma_Service_Window", Vector3(153, 2.7, 50.65), Vector3(4.5, 2.0, 0.16), Color("#28343a"))
    _visual_box(self, "Shawarma_Canopy", Vector3(153, 4.6, 50.0), Vector3(13.0, 0.35, 2.0), Color("#a83b32"))
    _visual_box(self, "Shawarma_Sign_Backplate", Vector3(153, 5.2, 50.65), Vector3(13.5, 1.25, 0.25), Color("#8c2f27"))
    _label(self, "ШАУРМА  •  24 ЧАСА", Vector3(153, 5.25, 50.42), Color.WHITE)
    _visual_box(self, "Shawarma_Menu_Board", Vector3(162, 2.1, 51.0), Vector3(2.0, 2.8, 0.18), Color("#303438"))
    for table_x in [147.0, 159.0]:
        _visual_box(self, "Shawarma_Outdoor_Table", Vector3(table_x, 0.95, 43.0), Vector3(2.0, 0.18, 2.0), Color("#80684e"))
        _visual_box(self, "Shawarma_Table_Leg", Vector3(table_x, 0.48, 43.0), Vector3(0.18, 0.9, 0.18), Color("#55585a"))

    # Driving school and closed practice yard for the practical licence exam.
    var school_pos := Vector3(-145, 6.0, 178)
    _building_box(self, "Driving_School_Building", school_pos, Vector3(30, 12, 18), Color("#c5b69d"))
    _visual_box(self, "Driving_School_Entrance", Vector3(-145, 2.3, 168.8), Vector3(4.0, 3.8, 0.18), Color("#34434b"))
    _visual_box(self, "Driving_School_Sign_Plate", Vector3(-145, 5.8, 168.5), Vector3(25.0, 1.6, 0.25), Color("#315c77"))
    _label(self, "АВТОШКОЛА • KLD", Vector3(-145, 5.9, 168.25), Color.WHITE)
    _label(self, "ТЕОРИЯ  •  ПРАКТИКА  •  ЭКЗАМЕН", Vector3(-145, 15, 164), Color("#f0d5a2"))
    _visual_box(self, "Driving_Exam_Ground", Vector3(-112, 0.18, 178), Vector3(46, 0.18, 48), Color("#555b5d"))
    for x in [-132.0, -122.0, -112.0, -102.0, -92.0]:
        _visual_box(self, "Driving_Exam_Bay_Line", Vector3(x, 0.31, 191), Vector3(0.14, 0.035, 13), white)
    _visual_box(self, "Driving_Exam_Stop_Line", Vector3(-112, 0.32, 168), Vector3(34, 0.04, 0.5), yellow)
    for cone_pos in [Vector3(-128, 0.8, 174), Vector3(-120, 0.8, 180), Vector3(-112, 0.8, 174), Vector3(-104, 0.8, 180), Vector3(-96, 0.8, 174)]:
        var cone := MeshInstance3D.new()
        var cone_mesh := CylinderMesh.new()
        cone_mesh.top_radius = 0.08
        cone_mesh.bottom_radius = 0.55
        cone_mesh.height = 1.1
        cone.mesh = cone_mesh
        cone.position = cone_pos
        cone.material_override = _mat(Color("#e47b35"))
        add_child(cone)
    _visual_box(self, "Driving_Exam_Reverse_Lane_Left", Vector3(-128, 0.35, 197), Vector3(0.18, 0.08, 12), white)
    _visual_box(self, "Driving_Exam_Reverse_Lane_Right", Vector3(-112, 0.35, 197), Vector3(0.18, 0.08, 12), white)
    _visual_box(self, "Driving_Exam_Start_Finish_Gate", Vector3(-112, 3.0, 164), Vector3(12, 0.25, 0.25), yellow)
    for gate_x in [-118.0, -106.0]:
        _visual_box(self, "Driving_Exam_Gate_Post", Vector3(gate_x, 1.5, 164), Vector3(0.25, 3.0, 0.25), yellow)
    _label(self, "ПЛОЩАДКА СДАЧИ ПРАВ", Vector3(-112, 7, 157), Color("#f0d5a2"))
    _label(self, "ЗМЕЙКА  •  ПАРКОВКА  •  ЗАДНИЙ ХОД", Vector3(-112, 5, 204), Color.WHITE)
    _visual_box(self, "Driving_School_Access_Road", Vector3(-145, 0.16, 145), Vector3(18, 0.14, 44), asphalt)
    _visual_box(self, "Driving_School_Sidewalk", Vector3(-132, 0.25, 166), Vector3(3.0, 0.2, 26), concrete)
    _label(self, "АВТОШКОЛА →", Vector3(-145, 3.2, 139), Color("#f0d5a2"))


func _build_vehicle() -> void:
    # A simple drivable starter car. The player controller becomes the vehicle controller while seated.
    vehicle_visual = Node3D.new()
    vehicle_visual.name = "Starter_Car"
    vehicle_visual.position = Vector3(-14, 0, -55)
    vehicle_visual.visible = true
    add_child(vehicle_visual)

    _visual_box(vehicle_visual, "Car_Body", Vector3(0, 0.65, 0), Vector3(4.2, 1.0, 2.0), Color("#9c3030"))
    _visual_box(vehicle_visual, "Car_Hood", Vector3(1.35, 0.95, 0), Vector3(1.25, 0.45, 1.9), Color("#b53a35"))
    _visual_box(vehicle_visual, "Car_Cabin", Vector3(-0.45, 1.35, 0), Vector3(1.9, 0.9, 1.75), Color("#343f48"))
    _visual_box(vehicle_visual, "Car_Windshield", Vector3(0.48, 1.4, 0), Vector3(0.08, 0.65, 1.55), Color("#78929b"))
    for wheel_x in [-1.25, 1.25]:
        for wheel_z in [-1.05, 1.05]:
            var wheel := MeshInstance3D.new()
            var wheel_mesh := CylinderMesh.new()
            wheel_mesh.top_radius = 0.42
            wheel_mesh.bottom_radius = 0.42
            wheel_mesh.height = 0.28
            wheel_mesh.radial_segments = 12
            wheel.mesh = wheel_mesh
            wheel.position = Vector3(wheel_x, 0.35, wheel_z)
            wheel.rotation_degrees.z = 90
            wheel.material_override = _mat(Color("#202326"))
            vehicle_visual.add_child(wheel)
    _label(vehicle_visual, "WESTERN RUSH", Vector3(0, 2.1, -0.9), Color("#f2d6a2"))


func _build_pedestrians() -> void:
    # Lightweight pedestrian figures with simple sidewalk patrol routes.
    var starts := [
        Vector3(-8, 1.1, -28), Vector3(12, 1.1, -18),
        Vector3(52, 1.1, 67), Vector3(72, 1.1, 45),
        Vector3(-42, 1.1, 28), Vector3(5, 1.1, 55)
    ]
    var clothes := [Color("#526b82"), Color("#8b5947"), Color("#536c50"), Color("#7a6689")]
    for i in range(starts.size()):
        var npc := Node3D.new()
        npc.name = "Pedestrian_%02d" % i
        npc.position = starts[i]
        add_child(npc)
        var torso := MeshInstance3D.new()
        var torso_mesh := CapsuleMesh.new()
        torso_mesh.radius = 0.38
        torso_mesh.height = 1.25
        torso.mesh = torso_mesh
        torso.position.y = 0.15
        torso.material_override = _mat(clothes[i % clothes.size()])
        npc.add_child(torso)
        var head := MeshInstance3D.new()
        var head_mesh := SphereMesh.new()
        head_mesh.radius = 0.25
        head_mesh.height = 0.5
        head.mesh = head_mesh
        head.position.y = 1.0
        head.material_override = _mat(Color("#c6a17f"))
        npc.add_child(head)
        pedestrian_nodes.append(npc)
        pedestrian_origins.append(starts[i])


func _process(delta: float) -> void:
    pedestrian_time += delta
    for i in range(pedestrian_nodes.size()):
        var npc := pedestrian_nodes[i]
        var origin := pedestrian_origins[i]
        npc.position = origin + Vector3(sin(pedestrian_time * 0.45 + float(i)) * 3.0, 0, cos(pedestrian_time * 0.45 + float(i)) * 1.5)
        npc.rotation.y = sin(pedestrian_time * 0.45 + float(i)) * 0.5
