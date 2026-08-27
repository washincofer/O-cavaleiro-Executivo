extends Control

## Sprint 12: tela de loading artificial (~3s) entre a selecao de fase e o
## carregamento real da cena, no espirito das telas de loading classicas —
## mesmo a fase sendo leve o suficiente para carregar quase instantaneamente.

const NEXT_SCENE := "res://scenes/playtest/platform_party_12.tscn"
const LOAD_SECONDS := 3.0
const BAR_WIDTH := 160.0

var elapsed := 0.0
var bar_fill: ColorRect
var changed_scene := false

func _ready() -> void:
	custom_minimum_size = Vector2(320, 180)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("10141d")
	add_child(bg)

	var title_font: FontFile = load("res://assets/Fonts/Runtime/MedievalScrollOfWisdom.ttf")

	var title := Label.new()
	title.text = "CARREGANDO A CAVERNA..."
	title.position = Vector2(0, 76)
	title.size = Vector2(320, 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", title_font)
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color("ffe26f"))
	add_child(title)

	var bar_bg := ColorRect.new()
	bar_bg.position = Vector2(80, 102)
	bar_bg.size = Vector2(BAR_WIDTH, 8)
	bar_bg.color = Color("2a2f3d")
	add_child(bar_bg)

	bar_fill = ColorRect.new()
	bar_fill.position = Vector2(80, 102)
	bar_fill.size = Vector2(0, 8)
	bar_fill.color = Color("6fd67a")
	add_child(bar_fill)

func _process(delta: float) -> void:
	if changed_scene:
		return
	elapsed += delta
	var ratio: float = clampf(elapsed / LOAD_SECONDS, 0.0, 1.0)
	bar_fill.size = Vector2(BAR_WIDTH * ratio, 8.0)
	if elapsed >= LOAD_SECONDS:
		changed_scene = true
		get_tree().change_scene_to_file(NEXT_SCENE)
