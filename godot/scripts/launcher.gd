extends Control

const CITY_TEXTURE = preload("res://art/launcher_city.svg")
const CAR_TEXTURE = preload("res://art/launcher_car.svg")
const MAP_SCENE = "res://scenes/kld_map.tscn"

var nick_edit: LineEdit
var info_label: Label
var car: TextureRect

func _ready() -> void:
	_build_interface()
	_start_car_animation()

func _build_interface() -> void:
	var bg := TextureRect.new()
	bg.texture = CITY_TEXTURE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.045, 0.34)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var top := _panel("СЕРВЕР: ПОДГОТОВКА     •     WESTERN RUSH RP", Color(0.025, 0.035, 0.055, 0.88))
	top.anchor_left = 0.59
	top.anchor_right = 0.97
	top.anchor_top = 0.035
	top.anchor_bottom = 0.12
	add_child(top)

	var logo := Label.new()
	logo.text = "WESTERN\nRUSH RP"
	logo.position = Vector2(42, 34)
	logo.size = Vector2(390, 175)
	logo.add_theme_font_size_override("font_size", 58)
	logo.add_theme_color_override("font_color", Color.WHITE)
	logo.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	logo.add_theme_constant_override("shadow_offset_x", 4)
	logo.add_theme_constant_override("shadow_offset_y", 5)
	add_child(logo)

	var subtitle := Label.new()
	subtitle.text = "ROLEPLAY  •  KALININGRAD"
	subtitle.position = Vector2(48, 204)
	subtitle.add_theme_font_size_override("font_size", 17)
	subtitle.add_theme_color_override("font_color", Color(0.86, 0.9, 0.96))
	add_child(subtitle)

	var nick_panel := _panel("", Color(0.025, 0.03, 0.045, 0.88))
	nick_panel.position = Vector2(32, 285)
	nick_panel.size = Vector2(355, 84)
	add_child(nick_panel)
	var nick_title := _label("ВАШ НИКНЕЙМ", 15, Color(0.7, 0.76, 0.84))
	nick_title.position = Vector2(54, 296)
	nick_title.size = Vector2(300, 22)
	add_child(nick_title)
	nick_edit = LineEdit.new()
	nick_edit.position = Vector2(50, 320)
	nick_edit.size = Vector2(300, 34)
	nick_edit.placeholder_text = "Введите игровой ник"
	nick_edit.text = _load_nick()
	nick_edit.max_length = 24
	nick_edit.add_theme_font_size_override("font_size", 20)
	add_child(nick_edit)

	var server_panel := _panel("", Color(0.025, 0.03, 0.045, 0.88))
	server_panel.position = Vector2(32, 382)
	server_panel.size = Vector2(355, 92)
	add_child(server_panel)
	var server_title := _label("СЕРВЕР №1", 21, Color.WHITE)
	server_title.position = Vector2(54, 394)
	server_title.size = Vector2(300, 28)
	add_child(server_title)
	var server_sub := _label("Калининград  •  Тестовый мир", 15, Color(0.7, 0.77, 0.86))
	server_sub.position = Vector2(54, 427)
	server_sub.size = Vector2(300, 24)
	add_child(server_sub)

	car = TextureRect.new()
	car.texture = CAR_TEXTURE
	car.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	car.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	car.anchor_left = 0.29
	car.anchor_right = 0.77
	car.anchor_top = 0.46
	car.anchor_bottom = 0.89
	car.offset_left = 0
	car.offset_right = 0
	car.offset_top = 0
	car.offset_bottom = 0
	add_child(car)

	var play := _button("▶   ИГРАТЬ", Color(0.78, 0.035, 0.055), Color(1, 0.12, 0.14))
	play.anchor_left = 0.73
	play.anchor_right = 0.97
	play.anchor_top = 0.69
	play.anchor_bottom = 0.84
	play.pressed.connect(_on_play_pressed)
	add_child(play)

	info_label = _label("Добро пожаловать в Western Rush RP!\nТвой город начинается здесь.", 17, Color.WHITE)
	info_label.anchor_left = 0.035
	info_label.anchor_right = 0.36
	info_label.anchor_top = 0.70
	info_label.anchor_bottom = 0.84
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(info_label)

	var nav := _panel("", Color(0.015, 0.02, 0.035, 0.94))
	nav.anchor_left = 0.02
	nav.anchor_right = 0.98
	nav.anchor_top = 0.88
	nav.anchor_bottom = 0.985
	add_child(nav)
	var menu := HBoxContainer.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_theme_constant_override("separation", 8)
	nav.add_child(menu)
	for item in ["⌂  ГЛАВНАЯ", "▤  НОВОСТИ", "⚙  НАСТРОЙКИ", "♙  ПРОФИЛЬ"]:
		var b := Button.new()
		b.text = item
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 18)
		b.add_theme_color_override("font_color", Color(0.9, 0.92, 0.97))
		b.add_theme_stylebox_override("normal", _style(Color(0.06, 0.075, 0.1, 0.65), 8))
		b.add_theme_stylebox_override("hover", _style(Color(0.42, 0.045, 0.065, 0.95), 8))
		b.pressed.connect(_on_menu_pressed.bind(item))
		menu.add_child(b)

	var version := _label("v1.0  •  MOBILE", 12, Color(0.68, 0.72, 0.8))
	version.anchor_left = 0.84
	version.anchor_right = 0.97
	version.anchor_top = 0.85
	version.anchor_bottom = 0.88
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(version)

func _start_car_animation() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(car, "position:x", 18.0, 2.8).from(-18.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(car, "position:x", -18.0, 2.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_play_pressed() -> void:
	var nick := nick_edit.text.strip_edges()
	if nick.is_empty():
		info_label.text = "Сначала введи игровой никнейм слева."
		return
	var cfg := ConfigFile.new()
	cfg.set_value("player", "nickname", nick)
	cfg.save("user://western_rush.cfg")
	get_tree().change_scene_to_file(MAP_SCENE)

func _on_menu_pressed(item: String) -> void:
	match item:
		"⌂  ГЛАВНАЯ":
			info_label.text = "Добро пожаловать в Western Rush RP!\nТвой город начинается здесь."
		"▤  НОВОСТИ":
			info_label.text = "НОВОСТИ\nПроект находится в разработке. Скоро появятся первые события."
		"⚙  НАСТРОЙКИ":
			info_label.text = "НАСТРОЙКИ\nИгровые параметры будут доступны в следующем обновлении."
		"♙  ПРОФИЛЬ":
			info_label.text = "ПРОФИЛЬ\nТвой ник: " + nick_edit.text

func _load_nick() -> String:
	var cfg := ConfigFile.new()
	if cfg.load("user://western_rush.cfg") == OK:
		return str(cfg.get_value("player", "nickname", ""))
	return ""

func _panel(text_value: String, color: Color) -> Panel:
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", _style(color, 14))
	return p

func _style(color: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = Color(0.72, 0.78, 0.88, 0.38)
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

func _label(value: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

func _button(value: String, normal_color: Color, hover_color: Color) -> Button:
	var b := Button.new()
	b.text = value
	b.add_theme_font_size_override("font_size", 30)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _style(normal_color, 18))
	b.add_theme_stylebox_override("hover", _style(hover_color, 18))
	b.add_theme_stylebox_override("pressed", _style(Color(0.48, 0.025, 0.04), 18))
	return b
