extends Control

## Sprint 13: intro da empresa (video de abertura) antes da tela de selecao
## de fase. Toca uma unica vez ao abrir o jogo (run/main_scene), com opcao
## de pular via qualquer tecla/clique. Godot 4 so reproduz video nativamente
## em Ogg Theora (.ogv) — o mp4 original foi convertido via ffmpeg
## (libtheora/libvorbis) em assets/Video/Runtime/company_intro.ogv.

const VIDEO_PATH := "res://assets/Video/Runtime/company_intro.ogv"
const STAGE_SELECT_SCENE := "res://scenes/menu/stage_select_12.tscn"
const BODY_FONT_PATH := "res://assets/Fonts/Runtime/MedievalSharp-Book.ttf"

var player: VideoStreamPlayer
var changed_scene := false

func _ready() -> void:
	custom_minimum_size = Vector2(320, 180)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("000000")
	add_child(bg)

	player = VideoStreamPlayer.new()
	player.stream = load(VIDEO_PATH)
	player.position = Vector2(0, 0)
	player.size = Vector2(320, 180)
	player.expand = true
	player.autoplay = true
	player.finished.connect(_go_to_stage_select)
	add_child(player)

	var skip_hint := Label.new()
	skip_hint.text = "clique ou aperte qualquer tecla para pular"
	skip_hint.position = Vector2(0, 168)
	skip_hint.size = Vector2(320, 10)
	skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_hint.add_theme_font_override("font", load(BODY_FONT_PATH))
	skip_hint.add_theme_font_size_override("font_size", 6)
	skip_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	add_child(skip_hint)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_go_to_stage_select()
	elif event is InputEventMouseButton and event.pressed:
		_go_to_stage_select()

func _go_to_stage_select() -> void:
	if changed_scene:
		return
	changed_scene = true
	get_tree().change_scene_to_file(STAGE_SELECT_SCENE)
