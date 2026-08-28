extends Control

## Sprint 13: intro da empresa (video de abertura) antes da tela de selecao
## de fase. Toca uma unica vez ao abrir o jogo (run/main_scene), com opcao
## de pular via qualquer tecla/clique. Godot 4 so reproduz video nativamente
## em Ogg Theora (.ogv) — o mp4 original foi convertido via ffmpeg
## (libtheora/libvorbis) em assets/Video/Runtime/company_intro.ogv.
##
## Sprint 16: primeira das 4 telas de menu restantes convertidas pro padrao
## retrato/paisagem — `_build_landscape()` e o layout original (320x180,
## geometria intocada); ganhou uma irma `_build_portrait()` (180x320)
## escolhida uma vez em `_ready()`. O video (aspecto 16:9) usa `expand=true`
## nos dois modos, mas em retrato o Control do player fica menor que o
## canvas (soletra-boxed dentro dele) em vez de esticar o video pra um
## retangulo 9:16 e distorcer a imagem. O botao PULAR ganha o skin
## Medieval Free (MedievalUI12) nos dois modos.

const VIDEO_PATH := "res://assets/Video/Runtime/company_intro.ogv"
const STAGE_SELECT_SCENE := "res://scenes/menu/stage_select_12.tscn"
const BODY_FONT_PATH := "res://assets/Fonts/Runtime/MedievalSharp-Book.ttf"
const VIDEO_ASPECT := 320.0 / 180.0

var player: VideoStreamPlayer
var changed_scene := false

func _ready() -> void:
	if DeviceLayout12.is_portrait:
		custom_minimum_size = Vector2(180, 320)
		_build_portrait()
	else:
		custom_minimum_size = Vector2(320, 180)
		_build_landscape()

func _build_landscape() -> void:
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

	_build_skip_button(Vector2(240, 4), Vector2(72, 16))

func _build_portrait() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("000000")
	add_child(bg)

	# Video mantem o aspecto 16:9 nativo (letterboxed dentro do canvas
	# 180x320) em vez de esticar pra um retangulo 9:16 e distorcer a
	# imagem — largura cheia (180), altura calculada, centralizado.
	var video_h := 180.0 / VIDEO_ASPECT
	var video_y := (320.0 - video_h) * 0.5

	player = VideoStreamPlayer.new()
	player.stream = load(VIDEO_PATH)
	player.position = Vector2(0, video_y)
	player.size = Vector2(180, video_h)
	player.expand = true
	player.autoplay = true
	player.finished.connect(_go_to_stage_select)
	add_child(player)

	var skip_hint := Label.new()
	skip_hint.text = "clique ou aperte qualquer tecla para pular"
	skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	skip_hint.add_theme_font_override("font", load(BODY_FONT_PATH))
	skip_hint.add_theme_font_size_override("font_size", 7)
	skip_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	# size por ultimo — mesma armadilha do loading_screen_12.gd (autowrap +
	# fonte antes de entrar na tree infla o minimum_size, e o Control nao
	# encolhe sozinho depois).
	skip_hint.position = Vector2(4, video_y + video_h + 12)
	skip_hint.custom_minimum_size = Vector2(172, 20)
	skip_hint.size = Vector2(172, 20)
	add_child(skip_hint)

	_build_skip_button(Vector2(50, video_y - 24), Vector2(80, 18))

func _build_skip_button(pos: Vector2, size: Vector2) -> void:
	# Botao real (Control) alem da deteccao generica de tecla/clique/toque
	# em _unhandled_input — em touchscreens um Button nativo responde de
	# forma mais confiavel que checar o tipo do evento bruto durante a
	# reproducao do video.
	var skip_button := Button.new()
	skip_button.text = "PULAR >>"
	skip_button.focus_mode = Control.FOCUS_NONE
	skip_button.position = pos
	MedievalUI12.style_button(skip_button, true, load(BODY_FONT_PATH), 7, Color("f4e7c9"), size)
	skip_button.pressed.connect(_go_to_stage_select)
	add_child(skip_button)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_go_to_stage_select()
	elif event is InputEventMouseButton and event.pressed:
		_go_to_stage_select()
	elif event is InputEventScreenTouch and event.pressed:
		_go_to_stage_select()

func _go_to_stage_select() -> void:
	if changed_scene:
		return
	changed_scene = true
	get_tree().change_scene_to_file(STAGE_SELECT_SCENE)
