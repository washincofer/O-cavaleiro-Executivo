extends Control

## Sprint 12: tela de selecao de fase, no estilo do grid de robos-mestres da
## saga Mega Man — painel anguloso, portais com moldura colorida e parafusos,
## tela de preview central. So a Caverna (Sprint 12) esta liberada; os
## outros 7 slots sao placeholders "?" — as proximas fases entram aqui aos
## poucos.

const PREVIEW_PATH := "res://assets/UI/Runtime/stage_caverna_preview.png"
const LOADING_SCENE := "res://scenes/menu/loading_screen_12.tscn"

const TILE_COLORS := [
	Color("ffd23f"),
	Color("5c8ee0"),
	Color("5ce07a"),
	Color("c25ce0"),
	Color("e0a15c"),
	Color("5ce0d6"),
	Color("e05ca1"),
	Color("8892a6"),
]

const STAGES := [
	{"name": "CAVERNA", "unlocked": true},
	{"name": "?", "unlocked": false},
	{"name": "?", "unlocked": false},
	{"name": "?", "unlocked": false},
	{"name": "?", "unlocked": false},
	{"name": "?", "unlocked": false},
	{"name": "?", "unlocked": false},
	{"name": "?", "unlocked": false},
]

var preview_rect: TextureRect
var preview_label: Label
var preview_tex: Texture2D
var display_font: SystemFont
var glow_border: ColorRect
var glow_t := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(320, 180)

	display_font = SystemFont.new()
	display_font.font_names = PackedStringArray(["Arial Black", "Segoe UI", "Impact", "sans-serif"])

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("0a0e16")
	add_child(bg)

	_add_angled_panel()

	var title := Label.new()
	title.text = "O CAVALEIRO EXECUTIVO"
	title.position = Vector2(0, 2)
	title.size = Vector2(320, 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", display_font)
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color("ffe26f"))
	title.add_theme_color_override("font_outline_color", Color("241a05"))
	title.add_theme_constant_override("outline_size", 3)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "S E L E C A O   D E   F A S E"
	subtitle.position = Vector2(0, 16)
	subtitle.size = Vector2(320, 10)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 6)
	subtitle.add_theme_color_override("font_color", Color("8fa6c9"))
	add_child(subtitle)

	preview_tex = load(PREVIEW_PATH)
	_build_preview_panel()

	var cols := 2
	var tile_size := Vector2(68, 30)
	var gap := 4.0
	var grid_pos := Vector2(172, 30)

	for i in range(STAGES.size()):
		var col: int = i % cols
		var row: int = i / cols
		var pos := grid_pos + Vector2(col * (tile_size.x + gap), row * (tile_size.y + gap))
		_build_tile(STAGES[i], i, pos, tile_size)

	var hint := Label.new()
	hint.text = "CLIQUE NA FASE DISPONIVEL PARA COMECAR"
	hint.position = Vector2(0, 169)
	hint.size = Vector2(320, 10)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 6)
	hint.add_theme_color_override("font_color", Color("8fa6c9"))
	add_child(hint)

	_show_preview(0)

func _process(delta: float) -> void:
	if not is_instance_valid(glow_border):
		return
	glow_t += delta * 3.0
	var pulse: float = 0.7 + 0.3 * sin(glow_t)
	glow_border.color = Color(TILE_COLORS[0].r, TILE_COLORS[0].g, TILE_COLORS[0].b) * pulse

func _add_angled_panel() -> void:
	var cut := 10.0
	var ox := 4.0
	var oy := 3.0
	var w := 312.0
	var h := 174.0
	var panel := Polygon2D.new()
	panel.polygon = PackedVector2Array([
		Vector2(ox + cut, oy), Vector2(ox + w - cut, oy),
		Vector2(ox + w, oy + cut), Vector2(ox + w, oy + h - cut),
		Vector2(ox + w - cut, oy + h), Vector2(ox + cut, oy + h),
		Vector2(ox, oy + h - cut), Vector2(ox, oy + cut),
	])
	panel.color = Color("161b28")
	add_child(panel)

	var inset := 3.0
	var inner := Polygon2D.new()
	inner.polygon = PackedVector2Array([
		Vector2(ox + cut, oy + inset), Vector2(ox + w - cut, oy + inset),
		Vector2(ox + w - inset, oy + cut), Vector2(ox + w - inset, oy + h - cut),
		Vector2(ox + w - cut, oy + h - inset), Vector2(ox + cut, oy + h - inset),
		Vector2(ox + inset, oy + h - cut), Vector2(ox + inset, oy + cut),
	])
	inner.color = Color("11141d")
	add_child(inner)

func _build_preview_panel() -> void:
	var outer := ColorRect.new()
	outer.position = Vector2(8, 30)
	outer.size = Vector2(156, 116)
	outer.color = Color("3a4258")
	add_child(outer)

	var bezel := ColorRect.new()
	bezel.position = Vector2(12, 34)
	bezel.size = Vector2(148, 92)
	bezel.color = Color("0d1015")
	add_child(bezel)

	preview_rect = TextureRect.new()
	preview_rect.position = Vector2(15, 37)
	preview_rect.size = Vector2(142, 86)
	preview_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_rect.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(preview_rect)

	for corner in [Vector2(12, 34), Vector2(160, 34), Vector2(12, 126), Vector2(160, 126)]:
		_add_bolt(corner)

	preview_label = Label.new()
	preview_label.position = Vector2(8, 128)
	preview_label.size = Vector2(156, 12)
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_label.add_theme_font_override("font", display_font)
	preview_label.add_theme_font_size_override("font_size", 10)
	preview_label.add_theme_color_override("font_color", Color("ffe26f"))
	add_child(preview_label)

func _add_bolt(pos: Vector2) -> void:
	var bolt := ColorRect.new()
	bolt.position = pos - Vector2(2.5, 2.5)
	bolt.size = Vector2(5, 5)
	bolt.color = Color("1a1e28")
	add_child(bolt)

	var hl := ColorRect.new()
	hl.position = pos - Vector2(1.0, 1.5)
	hl.size = Vector2(2, 2)
	hl.color = Color("5a6478")
	add_child(hl)

func _build_tile(stage: Dictionary, index: int, pos: Vector2, size: Vector2) -> void:
	var unlocked: bool = stage["unlocked"]
	var accent: Color = TILE_COLORS[index % TILE_COLORS.size()]

	var border := ColorRect.new()
	border.position = pos
	border.size = size
	border.color = accent if unlocked else Color("2a2f3a")
	add_child(border)

	var inner := ColorRect.new()
	inner.position = pos + Vector2(2, 2)
	inner.size = size - Vector2(4, 4)
	inner.color = Color("11141c") if unlocked else Color("15171d")
	add_child(inner)

	var button := Button.new()
	button.position = pos + Vector2(2, 2)
	button.size = size - Vector2(4, 4)
	button.disabled = not unlocked
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.add_theme_font_override("font", display_font)
	button.add_theme_font_size_override("font_size", 11)

	if unlocked:
		var icon := TextureRect.new()
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.texture = preview_tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_SCALE
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
		button.pressed.connect(_on_stage_pressed)
		glow_border = border
	else:
		button.text = "?"
		button.add_theme_color_override("font_color", Color("454b58"))
		button.add_theme_color_override("font_disabled_color", Color("454b58"))

	button.mouse_entered.connect(_show_preview.bind(index))
	add_child(button)

func _show_preview(index: int) -> void:
	var stage: Dictionary = STAGES[index]
	if stage["unlocked"]:
		preview_rect.texture = preview_tex
		preview_label.text = stage["name"]
	else:
		preview_rect.texture = null
		preview_label.text = "EM BREVE"

func _on_stage_pressed() -> void:
	get_tree().change_scene_to_file(LOADING_SCENE)
