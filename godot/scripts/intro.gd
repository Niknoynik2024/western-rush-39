extends Control

const VIDEO_PATH := "res://art/western_rush_intro.ogv"
const MAP_SCENE := "res://scenes/kld_map.tscn"

@onready var video: VideoStreamPlayer = $Video

func _ready() -> void:
	video.finished.connect(_on_video_finished)
	video.stream = load(VIDEO_PATH)
	video.play()

func _on_video_finished() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://western_rush.cfg")
	cfg.set_value("player", "intro_seen", true)
	cfg.save("user://western_rush.cfg")
	get_tree().change_scene_to_file(MAP_SCENE)

func _on_skip_pressed() -> void:
	_on_video_finished()
