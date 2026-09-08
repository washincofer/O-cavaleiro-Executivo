extends Control

## Selecao de fases canonica do jogo atual.
## Remove mapas de prototipo antigos do fluxo principal e apresenta somente
## as fases oficiais construidas ate aqui: Operacoes & Logistica e Tecnologia.

const CHARACTER_SELECT_SCENE := "res://scenes/menu/character_select_12.tscn"
const MENU_BG := "res://assets/Backgrounds/Runtime/Menu/main_menu_bg.png"
const FONT_TITLE := "res://assets/Fonts/Runtime/MedievalScrollOfWisdom.ttf"
const FONT_BODY := "res://assets/Fonts/Runtime/MedievalSharp-Book.ttf"

const STAGES := [
	{
		"number": "01",
		"name": "OPERACOES & LOGISTICA",
		"subtitle": "Docas, armazenagem e expedicao",
		"preview": "res://assets/Backgrounds/Runtime/FaseLogistica/l01_docas_recebimento.png",
		"target": "res://scenes/playtest/platform_fase01_operacoes_12.tscn",
		"loading": "CARREGANDO OPERACOES & LOGISTICA...",
	},
	{
		"number": "02",
		"name": "TECNOLOGIA",
		"subtitle": "Infraestrutura, redes e governanca",
		"preview": "",
		"target": "res://scenes/playtest/platform_fase02_tecnologia_12.tscn",
		"loading": "CARREGANDO TECNOLOGIA...",
	},
]

var title_font: Font
var body_font: Font

func _ready() -> void:
	SaveSystem12.save_game()
	title_font = load(FONT_TITLE)
	body_font = load(FONT_BODY)
	_build_ui()

func _build_ui() -> void:
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.texture = load(MENU_BG)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.42, 0.42, 0.48, 1.0)
	add_child(bg)

	var veil := ColorRect.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.02, 0.025, 0.04, 0.72)
	add_child(veil)

	var title := Label.new()
	title.text = "SELECAO DE FASE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", title_font)
	title.add_theme_font_size_override("font_size", 15 if not DeviceLayout12.is_portrait else 11)
	title.add_theme_color_override("font_color", Color("f5d76e"))
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 10
	title.offset_bottom = 34
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "O CAVALEIRO EXECUTIVO"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_override("font", body_font)
	subtitle.add_theme_font_size_override("font_size", 7)
	subtitle.add_theme_color_override("font_color", Color("b8c5d9"))
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	subtitle.offset_top = 31
	subtitle.offset_bottom = 44
	add_child(subtitle)

	if DeviceLayout12.is_portrait:
		_build_portrait_cards()
	else:
		_build_landscape_cards()

func _build_landscape_cards() -> void:
	for i in range(STAGES.size()):
		_build_stage_card(STAGES[i], Vector2(16 + i * 150, 54), Vector2(138, 104))
	_build_locked_card(Vector2(166, 164), Vector2(138, 12), "PROXIMAS FASES EM DESENVOLVIMENTO")

func _build_portrait_cards() -> void:
	for i in range(STAGES.size()):
		_build_stage_card(STAGES[i], Vector2(10, 54 + i * 112), Vector2(160, 102))
	_build_locked_card(Vector2(10, 282), Vector2(160, 24), "PROXIMAS FASES")

func _build_stage_card(stage: Dictionary, pos: Vector2, size: Vector2) -> void:
	var frame := Panel.new()
	frame.position = pos
	frame.size = size
	frame.add_theme_stylebox_override("panel", MedievalUI12.button_stylebox(false))
	add_child(frame)

	var button := Button.new()
	button.position = pos + Vector2(4, 4)
	button.size = size - Vector2(8, 8)
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_open_stage.bind(stage))
	add_child(button)

	var preview := TextureRect.new()
	preview.position = Vector2(2, 2)
	preview.size = Vector2(button.size.x - 4, button.size.y - 34)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if String(stage["preview"]) != "" and ResourceLoader.exists(String(stage["preview"])):
		preview.texture = load(String(stage["preview"]))
	else:
		preview.modulate = Color("19334a")
	button.add_child(preview)

	var shade := ColorRect.new()
	shade.position = preview.position
	shade.size = preview.size
	shade.color = Color(0.0, 0.0, 0.0, 0.28)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(shade)

	var number := Label.new()
	number.text = "FASE %s" % stage["number"]
	number.position = Vector2(8, 7)
	number.size = Vector2(button.size.x - 16, 12)
	number.add_theme_font_override("font", body_font)
	number.add_theme_font_size_override("font_size", 7)
	number.add_theme_color_override("font_color", Color("e8c45a"))
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(number)

	var name := Label.new()
	name.text = stage["name"]
	name.position = Vector2(4, button.size.y - 31)
	name.size = Vector2(button.size.x - 8, 13)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_font_override("font", title_font)
	name.add_theme_font_size_override("font_size", 8)
	name.add_theme_color_override("font_color", Color("fff1a8"))
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(name)

	var sub := Label.new()
	sub.text = stage["subtitle"]
	sub.position = Vector2(4, button.size.y - 17)
	sub.size = Vector2(button.size.x - 8, 12)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", body_font)
	sub.add_theme_font_size_override("font_size", 6)
	sub.add_theme_color_override("font_color", Color("b9c8da"))
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(sub)

func _build_locked_card(pos: Vector2, size: Vector2, text: String) -> void:
	var label := Label.new()
	label.position = pos
	label.size = size
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", body_font)
	label.add_theme_font_size_override("font_size", 6)
	label.add_theme_color_override("font_color", Color("7d8795"))
	add_child(label)

func _open_stage(stage: Dictionary) -> void:
	PartySelection12.target_scene = String(stage["target"])
	PartySelection12.loading_title = String(stage["loading"])
	PartySelection12.selection_mode = PartySelection12.MODE_FREE
	PartySelection12.stage_reward_role = ""
	PartySelection12.required_role = ""
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)
