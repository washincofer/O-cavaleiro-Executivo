extends Control

## Sprint 12: tela de selecao de fase, no estilo do grid de robos-mestres da
## saga Mega Man. So a Caverna (Sprint 12) esta liberada; os outros 7 slots
## sao placeholders "EM BREVE" — as proximas fases entram aqui aos poucos.

const PREVIEW_PATH := "res://assets/UI/Runtime/stage_caverna_preview.png"
const LOADING_SCENE := "res://scenes/menu/loading_screen_12.tscn"

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

func _ready() -> void:
	custom_minimum_size = Vector2(320, 180)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("10141d")
	add_child(bg)

	var title := Label.new()
	title.text = "O CAVALEIRO EXECUTIVO"
	title.position = Vector2(0, 4)
	title.size = Vector2(320, 12)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 9)
	title.add_theme_color_override("font_color", Color("ffe26f"))
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "SELECAO DE FASE"
	subtitle.position = Vector2(0, 16)
	subtitle.size = Vector2(320, 10)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 7)
	add_child(subtitle)

	preview_tex = load(PREVIEW_PATH)

	var preview_frame := ColorRect.new()
	preview_frame.color = Color("2a2f3d")
	preview_frame.position = Vector2(104, 30)
	preview_frame.size = Vector2(112, 68)
	add_child(preview_frame)

	preview_rect = TextureRect.new()
	preview_rect.position = Vector2(108, 34)
	preview_rect.size = Vector2(104, 54)
	preview_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_rect.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(preview_rect)

	preview_label = Label.new()
	preview_label.position = Vector2(104, 88)
	preview_label.size = Vector2(112, 10)
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_label.add_theme_font_size_override("font_size", 7)
	preview_label.add_theme_color_override("font_color", Color("ffe26f"))
	add_child(preview_label)

	var cols := 4
	var tile_size := 36.0
	var gap := 5.0
	var grid_w: float = cols * tile_size + (cols - 1) * gap
	var start_x: float = (320.0 - grid_w) * 0.5
	var start_y := 104.0

	for i in range(STAGES.size()):
		var stage: Dictionary = STAGES[i]
		var col: int = i % cols
		var row: int = i / cols
		var x: float = start_x + col * (tile_size + gap)
		var y: float = start_y + row * (tile_size + gap)
		_build_tile(stage, i, Vector2(x, y), tile_size)

	var hint := Label.new()
	hint.text = "Clique na fase disponivel para comecar | ESC no jogo pausa e mostra os controles"
	hint.position = Vector2(0, 168)
	hint.size = Vector2(320, 10)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 6)
	add_child(hint)

	_show_preview(0)

func _build_tile(stage: Dictionary, index: int, pos: Vector2, size: float) -> void:
	var unlocked: bool = stage["unlocked"]
	var button := Button.new()
	button.position = pos
	button.size = Vector2(size, size)
	button.disabled = not unlocked
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 12)

	if unlocked:
		var icon := TextureRect.new()
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.texture = preview_tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_SCALE
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
		button.modulate = Color(1, 1, 1)
		button.pressed.connect(_on_stage_pressed)
	else:
		button.text = "?"
		button.modulate = Color(0.35, 0.35, 0.4)

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
