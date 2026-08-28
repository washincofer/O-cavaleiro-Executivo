extends Control

## Sprint 12: tela de loading artificial (~3s) entre a selecao de fase e o
## carregamento real da cena, no espirito das telas de loading classicas —
## mesmo a fase sendo leve o suficiente para carregar quase instantaneamente.
##
## Sprint 16: primeira tela convertida para o padrao retrato/paisagem —
## `_build_landscape()` e o layout original (320x180, intocado); ganhou
## uma irma `_build_portrait()` (180x320) escolhida uma vez em `_ready()`
## via `DeviceLayout12.is_portrait`. Serve de prova de conceito pro padrao
## que as outras 4 telas de menu vao seguir.

const LOAD_SECONDS := 3.0

var bar_width := 160.0
var bar_pos := Vector2(80, 102)

var elapsed := 0.0
var bar_fill: ColorRect
var changed_scene := false

func _ready() -> void:
	if DeviceLayout12.is_portrait:
		custom_minimum_size = Vector2(180, 320)
		_build_portrait()
	else:
		custom_minimum_size = Vector2(320, 180)
		_build_landscape()

func _build_landscape() -> void:
	bar_width = 160.0
	bar_pos = Vector2(80, 102)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("10141d")
	add_child(bg)

	var title_font: FontFile = load("res://assets/Fonts/Runtime/MedievalScrollOfWisdom.ttf")

	var title := Label.new()
	title.text = PartySelection12.loading_title
	title.position = Vector2(0, 76)
	title.size = Vector2(320, 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", title_font)
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color("ffe26f"))
	add_child(title)

	_build_bar()

func _build_portrait() -> void:
	bar_width = 120.0
	bar_pos = Vector2(30, 176)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("10141d")
	add_child(bg)

	var title_font: FontFile = load("res://assets/Fonts/Runtime/MedievalScrollOfWisdom.ttf")

	var title := Label.new()
	title.text = PartySelection12.loading_title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.clip_text = true
	title.add_theme_font_override("font", title_font)
	title.add_theme_font_size_override("font_size", 7)
	title.add_theme_color_override("font_color", Color("ffe26f"))
	# `size` precisa ser o ultimo campo setado: com autowrap+fonte aplicados
	# antes de entrar na tree, o Godot infla o minimum_size (mede a string
	# inteira sem quebra) e o Control so cresce pra caber o minimo, nunca
	# encolhe sozinho depois — setar por ultimo garante que o size fique
	# nos 172x34 pretendidos em vez de travar num valor inflado.
	title.position = Vector2(4, 134)
	title.custom_minimum_size = Vector2(172, 34)
	title.size = Vector2(172, 34)
	add_child(title)

	_build_bar()

func _build_bar() -> void:
	var bar_bg := ColorRect.new()
	bar_bg.position = bar_pos
	bar_bg.size = Vector2(bar_width, 8)
	bar_bg.color = Color("2a2f3d")
	add_child(bar_bg)

	bar_fill = ColorRect.new()
	bar_fill.position = bar_pos
	bar_fill.size = Vector2(0, 8)
	bar_fill.color = Color("6fd67a")
	add_child(bar_fill)

func _process(delta: float) -> void:
	if changed_scene:
		return
	elapsed += delta
	var ratio: float = clampf(elapsed / LOAD_SECONDS, 0.0, 1.0)
	bar_fill.size = Vector2(bar_width * ratio, 8.0)
	if elapsed >= LOAD_SECONDS:
		changed_scene = true
		get_tree().change_scene_to_file(PartySelection12.target_scene)
