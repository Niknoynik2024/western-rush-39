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
    _build_world()
    _build_player()
    _build_ui()

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
    var ground_body := StaticBody3D.new()
    ground_body.name = "GroundCollision"
    add_child(ground_body)
    var ground_shape := CollisionShape3D.new()
    var ground_box := BoxShape3D.new()
    ground_box.size = Vector3(520, 1, 520)
    ground_shape.shape = ground_box
    ground_shape.position.y = -0.6
    ground_body.add_child(ground_shape)
    _visual_box(self, "City_Ground", Vector3(0, -1.15, 0), Vector3(520, 1, 520), GRASS)

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

    for x in range(-190, 191, 20):
        _visual_box(self, "Road_Marking", Vector3(x, 0.13, -48), Vector3(8, 0.025, 0.35), Color("#e6dfc9"))
    for z in range(-135, 136, 20):
        _visual_box(self, "Road_Marking", Vector3(72, 0.14, z), Vector3(0.35, 0.025, 8), Color("#e6dfc9"))

    _label(self, "КАЛИНИНГРАД • KLD", Vector3(0, 22, -72), ACCENT)
    _label(self, "РЕКА ПРЕГОЛЯ", Vector3(-20, 2, 8), Color("#d5eaf2"))

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
    add_child(layer)
    var panel := ColorRect.new()
    panel.color = Color(0.04, 0.06, 0.08, 0.78)
    panel.position = Vector2(18, 18)
    panel.size = Vector2(390, 88)
    layer.add_child(panel)

    var title := Label.new()
    title.text = "WESTERN RUSH RP  |  KLD\nКалининград • тест карты 0.1"
    title.position = Vector2(34, 28)
    title.add_theme_font_size_override("font_size", 22)
    title.add_theme_color_override("font_color", Color.WHITE)
    layer.add_child(title)

    var hint := Label.new()
    hint.text = "Управление: стрелки клавиатуры • экранное управление добавим далее"
    hint.position = Vector2(20, 112)
    hint.add_theme_font_size_override("font_size", 15)
    hint.add_theme_color_override("font_color", Color("#f2d6a2"))
    layer.add_child(hint)

func _physics_process(delta: float) -> void:
    if player == null:
        return
    var direction := Vector3.ZERO
    direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
    direction.z = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
    direction = direction.normalized()
    player.velocity.x = direction.x * 9.0
    player.velocity.z = direction.z * 9.0
    if not player.is_on_floor():
        player.velocity.y -= 22.0 * delta
    else:
        player.velocity.y = -0.2
    player.move_and_slide()
