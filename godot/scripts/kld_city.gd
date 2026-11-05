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

func _ready() -> void:
    _setup_input()
    _build_world()
    _build_player()
    _build_ui()

func _setup_input() -> void:
    if not InputMap.has_action("sprint"):
        InputMap.add_action("sprint")
    var key_bindings := {
        "ui_up": [KEY_W],
        "ui_down": [KEY_S],
        "ui_left": [KEY_A],
        "ui_right": [KEY_D],
        "sprint": [KEY_SHIFT]
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
    _visual_box(self, "Victory_Square", Vector3(-25, 0.08, -80), Vector3(54, 0.2, 44), Color("#a9a79c"))
    _visual_box(self, "Square_Fountain", Vector3(-25, 0.35, -80), Vector3(8, 0.5, 8), Color("#6e9da8"))
    _landmark("Администрация", Vector3(-25, 7, -105), Vector3(18, 14, 12), BUILDING_C)
    _landmark("Кафедральный собор", Vector3(-65, 11, 18), Vector3(15, 22, 18), Color("#a58e72"))
    _landmark("Рыбная деревня", Vector3(-8, 5, 45), Vector3(42, 10, 16), Color("#c0a27c"))
    _landmark("Автовокзал", Vector3(80, 5, 165), Vector3(34, 10, 18), BUILDING_B)
    _landmark("Аэропорт", Vector3(-185, 5, -185), Vector3(54, 10, 24), BUILDING_B)
    _landmark("Больница", Vector3(125, 6, -165), Vector3(30, 12, 22), Color("#d6d6cf"))
    _landmark("Полиция", Vector3(-155, 5, -95), Vector3(24, 10, 18), Color("#8798a7"))

    _build_victory_square()
    _build_mira_avenue()

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
        [Vector3(-45, 0.04, -67), Vector3(13, 0.18, 105)]
    ]:
        _visual_box(self, "Central_Street", road[0], road[1], asphalt)

    # Sidewalk strips frame the central streets.
    for x in [-114.0, -96.0, 19.0, 37.0, -54.0, -36.0]:
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
        Vector3(-82, 0, -92), Vector3(-82, 0, -42),
        Vector3(-12, 0, -92), Vector3(-12, 0, -42),
        Vector3(62, 0, -92), Vector3(62, 0, -42)
    ]
    for b in range(blocks.size()):
        var origin: Vector3 = blocks[b]
        for row in range(2):
            for col in range(2):
                var h := 12.0 + float((b + row + col) % 4) * 3.0
                var w := 13.0 + float((b + col) % 2) * 3.0
                var d := 12.0 + float((b + row) % 2) * 3.0
                var p := origin + Vector3(float(col) * 19.0, h / 2.0, float(row) * 19.0)
                _visual_box(self, "Central_Historic_Building", p, Vector3(w, h, d), facades[(b + row + col) % facades.size()])

    # Pocket park and street furniture near Victory Square.
    _visual_box(self, "Central_Pocket_Park", Vector3(-25, 0.12, -80), Vector3(42, 0.24, 34), Color("#647b55"))
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
    _label(self, "ПЛОЩАДЬ ПОБЕДЫ", Vector3(-25, 15, -104), Color("#f3dfb8"))

func _build_mira_avenue() -> void:
    # Prospect Mira corridor: boulevard median, sidewalks, crossings and street furniture.
    var asphalt := Color("#30363b")
    var pavement := Color("#b6b2a6")
    var lane_mark := Color("#e9e1cf")
    _visual_box(self, "Prospect_Mira_Asphalt", Vector3(-45, 0.19, -112), Vector3(205, 0.12, 13), asphalt)
    _visual_box(self, "Prospect_Mira_Median", Vector3(-45, 0.31, -112), Vector3(188, 0.18, 1.1), Color("#667653"))
    for side_x in [-45.0]:
        for offset in [-8.5, 8.5]:
            _visual_box(self, "Prospect_Mira_Sidewalk", Vector3(side_x, 0.2, -112 + offset), Vector3(205, 0.22, 2.0), pavement)
    for mark_x in range(-140, 56, 18):
        _visual_box(self, "Prospect_Mira_Lane_Marking", Vector3(float(mark_x), 0.29, -112), Vector3(7.0, 0.025, 0.18), lane_mark)
    # Tree planters and lamps alternate along the avenue edges.
    for x in range(-130, 51, 30):
        for z in [-121.0, -103.0]:
            _visual_box(self, "Prospect_Mira_Tree_Planter", Vector3(float(x), 0.42, z), Vector3(4.0, 0.35, 4.0), Color("#777b61"))
            _visual_box(self, "Prospect_Mira_Tree_Trunk", Vector3(float(x), 3.0, z), Vector3(0.55, 5.0, 0.55), Color("#66513c"))
            _visual_box(self, "Prospect_Mira_Tree_Crown", Vector3(float(x), 6.0, z), Vector3(4.5, 4.5, 4.5), Color("#486b48"))
    for x in [-115.0, -75.0, -35.0, 5.0, 45.0]:
        for z in [-123.0, -101.0]:
            _visual_box(self, "Prospect_Mira_Lamp_Post", Vector3(x, 4.0, z), Vector3(0.22, 8.0, 0.22), Color("#34383b"))
            _visual_box(self, "Prospect_Mira_Lamp_Head", Vector3(x, 8.1, z), Vector3(1.0, 0.3, 0.55), Color("#e7d6a4"))
    # Two simple public-transport stops facing the avenue.
    for stop_x in [-88.0, 18.0]:
        _visual_box(self, "Prospect_Mira_Bus_Stop_Base", Vector3(stop_x, 0.45, -99.0), Vector3(7.0, 0.25, 2.5), dark_stone)
        _visual_box(self, "Prospect_Mira_Bus_Stop_Roof", Vector3(stop_x, 3.0, -99.0), Vector3(7.0, 0.3, 2.5), Color("#59636a"))
        for support_x in [-2.8, 2.8]:
            _visual_box(self, "Prospect_Mira_Bus_Stop_Support", Vector3(stop_x + support_x, 1.7, -99.0), Vector3(0.18, 2.8, 0.18), dark_stone)
    _label(self, "ПРОСПЕКТ МИРА", Vector3(-45, 19, -130), Color("#f0d5a2"))

func _district(title: String, origin: Vector3, columns: int, rows: int, spacing: float) -> void:
    var colors := [BUILDING_A, BUILDING_B, BUILDING_C]
    for x in range(columns):
        for z in range(rows):
            var height := 9.0 + float((x * 7 + z * 3) % 4) * 3.2
            var width := 12.0 + float((x + z) % 3) * 2.0
            var depth := 12.0 + float((x * 2 + z) % 3) * 2.0
            var pos := origin + Vector3(float(x) * spacing, height / 2.0, float(z) * spacing)
            _visual_box(self, "City_Block_Building", pos, Vector3(width, height, depth), colors[(x + z) % colors.size()])
    _label(self, title, origin + Vector3((columns - 1) * spacing / 2.0, 27, -12), ACCENT)

func _landmark(title: String, pos: Vector3, size: Vector3, color: Color) -> void:
    _visual_box(self, title + "_Building", pos, size, color)
    _label(self, title, pos + Vector3(0, size.y / 2.0 + 4, 0), Color.WHITE)

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(-25, 2, -55)
    add_child(player)

    var capsule := MeshInstance3D.new()
    var capsule_mesh := CapsuleMesh.new()
    capsule_mesh.radius = 0.7
    capsule_mesh.height = 2.2
    capsule.mesh = capsule_mesh
    capsule.material_override = _mat(ACCENT)
    player.add_child(capsule)

    var collision := CollisionShape3D.new()
    var capsule_shape := CapsuleShape3D.new()
    capsule_shape.radius = 0.7
    capsule_shape.height = 2.2
    collision.shape = capsule_shape
    player.add_child(collision)

    camera = Camera3D.new()
    camera.position = Vector3(0, 42, 34)
    camera.rotation_degrees = Vector3(-52, 0, 0)
    camera.current = true
    player.add_child(camera)

func _build_ui() -> void:
    var layer := CanvasLayer.new()
    layer.name = "MobileHUD"
    add_child(layer)

    var panel := ColorRect.new()
    panel.color = Color(0.04, 0.06, 0.08, 0.82)
    panel.position = Vector2(18, 18)
    panel.size = Vector2(410, 104)
    layer.add_child(panel)

    var title := Label.new()
    title.text = "WESTERN RUSH RP  |  KLD"
    title.position = Vector2(34, 26)
    title.add_theme_font_size_override("font_size", 23)
    title.add_theme_color_override("font_color", Color.WHITE)
    layer.add_child(title)

    var status := Label.new()
    status.text = "КАЛИНИНГРАД  •  ГРАЖДАНСКИЙ СЕРВЕР  •  0 ₽"
    status.position = Vector2(35, 64)
    status.add_theme_font_size_override("font_size", 14)
    status.add_theme_color_override("font_color", Color("#f2d6a2"))
    layer.add_child(status)

    var hint := Label.new()
    hint.text = "Клавиатура: WASD / стрелки     Телефон: экранные кнопки"
    hint.position = Vector2(20, 132)
    hint.add_theme_font_size_override("font_size", 15)
    hint.add_theme_color_override("font_color", Color("#f2d6a2"))
    layer.add_child(hint)

    # Large touch controls remain visible on phones and tablets.
    _add_touch_button(layer, "▲", "ui_up", Vector2(112, 510))
    _add_touch_button(layer, "▼", "ui_down", Vector2(112, 620))
    _add_touch_button(layer, "◀", "ui_left", Vector2(8, 565))
    _add_touch_button(layer, "▶", "ui_right", Vector2(216, 565))
    _add_touch_button(layer, "БЕГ", "sprint", Vector2(1050, 590), Vector2(150, 88))

func _add_touch_button(layer: CanvasLayer, caption: String, action: String, button_position: Vector2, button_size := Vector2(96, 82)) -> void:
    var button := Button.new()
    button.text = caption
    button.position = button_position
    button.size = button_size
    button.add_theme_font_size_override("font_size", 25)
    button.add_theme_color_override("font_color", Color.WHITE)
    button.add_theme_color_override("font_hover_color", Color("#ffe0a8"))
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color(0.05, 0.08, 0.11, 0.72)
    normal.border_color = Color(0.82, 0.62, 0.32, 0.9)
    normal.set_border_width_all(2)
    normal.set_corner_radius_all(16)
    button.add_theme_stylebox_override("normal", normal)
    var pressed := StyleBoxFlat.new()
    pressed.bg_color = Color(0.55, 0.34, 0.12, 0.92)
    pressed.set_corner_radius_all(16)
    button.add_theme_stylebox_override("pressed", pressed)
    button.button_down.connect(func(): Input.action_press(action))
    button.button_up.connect(func(): Input.action_release(action))
    layer.add_child(button)

func _physics_process(delta: float) -> void:
    if player == null:
        return
    var direction := Vector3.ZERO
    direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
    direction.z = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
    direction = direction.normalized()
    var move_speed := 15.0 if Input.is_action_pressed("sprint") else 9.0
    player.velocity.x = direction.x * move_speed
    player.velocity.z = direction.z * move_speed
    if not player.is_on_floor():
        player.velocity.y -= 22.0 * delta
    else:
        player.velocity.y = -0.2
    player.move_and_slide()
