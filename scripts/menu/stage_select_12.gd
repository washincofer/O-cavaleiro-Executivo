extends Control

## Sprint 12: tela de selecao de fase, no estilo do grid de robos-mestres da
## saga Mega Man — painel anguloso, portais com moldura colorida e parafusos,
## tela de preview central. So a Caverna (Sprint 12) esta liberada; os
## outros 7 slots sao placeholders "?" — as proximas fases entram aqui aos
## poucos.

const Actor = preload("res://scripts/playtest/platform_actor_12.gd")
const CHARACTER_SELECT_SCENE := "res://scenes/menu/character_select_12.tscn"
const DIALOGUE_SCENE := "res://scenes/menu/dialogue_12.tscn"
const TITLE_FONT_PATH := "res://assets/Fonts/Runtime/MedievalScrollOfWisdom.ttf"
const BODY_FONT_PATH := "res://assets/Fonts/Runtime/MedievalSharp-Book.ttf"

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
	{
		"name": "CAVERNA",
		"unlocked": true,
		"preview": "res://assets/UI/Runtime/stage_caverna_preview.png",
		"target_scene": "res://scenes/playtest/platform_party_12.tscn",
		"loading_title": "CARREGANDO A CAVERNA...",
		"selection_mode": "categorized",
	},
	{
		"name": "RUINAS",
		"unlocked": true,
		"preview": "res://assets/Environment/Ruins/Runtime/ruins_bg.png",
		"target_scene": "res://scenes/playtest/platform_boss_12.tscn",
		"loading_title": "CARREGANDO AS RUINAS...",
		"selection_mode": "free",
		"dialogue_id": "coordenador",
	},
	{
		"name": "FLORESTA",
		"unlocked": true,
		"preview": "res://assets/Environment/Forest/Runtime/forest_bg.png",
		"target_scene": "res://scenes/playtest/platform_boss_forest_12.tscn",
		"loading_title": "CARREGANDO A FLORESTA...",
		"selection_mode": "free",
		"reward_role": "paladin",
		"dialogue_id": "presidente",
	},
	{
		"name": "CEMITERIO",
		"unlocked": true,
		"preview": "res://assets/Environment/Cemetery/Runtime/cemetery_bg.png",
		"target_scene": "res://scenes/playtest/platform_boss_cemetery_12.tscn",
		"loading_title": "CARREGANDO O CEMITERIO...",
		"selection_mode": "free",
		"reward_role": "knight",
		"dialogue_id": "gerente_executivo",
	},
	{
		"name": "NOITE ESTRELADA",
		"unlocked": true,
		"preview": "res://assets/Environment/StarryNight/Runtime/starry_night_bg.png",
		"target_scene": "res://scenes/playtest/platform_boss_starrynight_12.tscn",
		"loading_title": "CARREGANDO A NOITE ESTRELADA...",
		"selection_mode": "free",
		"reward_role": "bridge_heroine",
		"dialogue_id": "especialista",
	},
	{
		"name": "COVIL DO TESOURO",
		"unlocked": true,
		"preview": "res://assets/Environment/TreasureHoard/Runtime/treasure_bg.png",
		"target_scene": "res://scenes/playtest/platform_boss_treasurehoard_12.tscn",
		"loading_title": "CARREGANDO O COVIL DO TESOURO...",
		"selection_mode": "gated",
		"required_role": "bridge_heroine",
		"dialogue_id": "gerente",
	},
	{"name": "?", "unlocked": false},
	{"name": "?", "unlocked": false},
]

var preview_rect: TextureRect
var preview_label: Label
var title_font: FontFile
var body_font: FontFile
var glow_borders: Array[ColorRect] = []
var glow_colors: Array[Color] = []
var glow_t := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(320, 180)

	title_font = load(TITLE_FONT_PATH)
	body_font = load(BODY_FONT_PATH)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("0a0e16")
	add_child(bg)

	_add_angled_panel()

	var title := Label.new()
	title.text = "O CAVALEIRO EXECUTIVO"
	title.position = Vector2(0, 9)
	title.size = Vector2(320, 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", title_font)
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color("ffe26f"))
	title.add_theme_color_override("font_outline_color", Color("241a05"))
	title.add_theme_constant_override("outline_size", 3)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "S E L E C A O   D E   F A S E"
	subtitle.position = Vector2(0, 22)
	subtitle.size = Vector2(320, 10)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_override("font", body_font)
	subtitle.add_theme_font_size_override("font_size", 6)
	subtitle.add_theme_color_override("font_color", Color("8fa6c9"))
	add_child(subtitle)

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
	if glow_borders.is_empty():
		return
	glow_t += delta * 3.0
	var pulse: float = 0.7 + 0.3 * sin(glow_t)
	for i in range(glow_borders.size()):
		var border: ColorRect = glow_borders[i]
		if is_instance_valid(border):
			border.color = glow_colors[i] * pulse

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

	# Sprint 16: nameplate com o botao Medieval Free (MedievalUI12) no lugar
	# do texto flutuante sem fundo — primeira aplicacao real do helper de
	# skin fora do probe de dev.
	var label_bg := Panel.new()
	label_bg.position = Vector2(8, 128)
	label_bg.size = Vector2(156, 12)
	label_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_bg.add_theme_stylebox_override("panel", MedievalUI12.button_stylebox(true))
	add_child(label_bg)

	preview_label = Label.new()
	preview_label.position = Vector2(8, 128)
	preview_label.size = Vector2(156, 12)
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview_label.add_theme_font_override("font", body_font)
	preview_label.add_theme_font_size_override("font_size", 10)
	preview_label.add_theme_color_override("font_color", Color("ffe26f"))
	preview_label.add_theme_color_override("font_outline_color", Color("241a05"))
	preview_label.add_theme_constant_override("outline_size", 2)
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

func _is_stage_gated(stage: Dictionary) -> bool:
	var required_role: String = stage.get("required_role", "")
	return required_role != "" and not PartySelection12.is_unlocked(required_role)

func _build_tile(stage: Dictionary, index: int, pos: Vector2, size: Vector2) -> void:
	var exists: bool = stage["unlocked"]
	var gated: bool = exists and _is_stage_gated(stage)
	var playable: bool = exists and not gated
	var accent: Color = TILE_COLORS[index % TILE_COLORS.size()]

	var border := ColorRect.new()
	border.position = pos
	border.size = size
	border.color = accent if playable else Color("2a2f3a")
	add_child(border)

	var inner := ColorRect.new()
	inner.position = pos + Vector2(2, 2)
	inner.size = size - Vector2(4, 4)
	inner.color = Color("11141c") if playable else Color("15171d")
	add_child(inner)

	var button := Button.new()
	button.position = pos + Vector2(2, 2)
	button.size = size - Vector2(4, 4)
	button.disabled = not playable
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.add_theme_font_override("font", body_font)
	button.add_theme_font_size_override("font_size", 11)

	if exists:
		var icon := TextureRect.new()
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.texture = load(stage["preview"])
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_SCALE
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if gated:
			icon.modulate = Color(0.32, 0.32, 0.38, 0.65)
		button.add_child(icon)

	if playable:
		button.pressed.connect(_on_stage_pressed.bind(index))
		glow_borders.append(border)
		glow_colors.append(accent)
	elif gated:
		# Fase existe mas exige um personagem ainda bloqueado (Sprint 15:
		# Covil do Tesouro exige a Heroina da Ponte, dona da mecanica de
		# ponte usada no vao da sala) — mostra a arte escurecida com um
		# aviso curto, em vez do "?" generico das fases ainda inexistentes.
		var lock_label := Label.new()
		lock_label.text = "TRANCADA"
		lock_label.position = Vector2(2, size.y * 0.5 - 6)
		lock_label.size = Vector2(size.x - 4, 12)
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_label.add_theme_font_override("font", body_font)
		lock_label.add_theme_font_size_override("font_size", 7)
		lock_label.add_theme_color_override("font_color", Color("d9c9a8"))
		lock_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		lock_label.add_theme_constant_override("outline_size", 2)
		lock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(lock_label)
	else:
		button.text = "?"
		button.add_theme_color_override("font_color", Color("454b58"))
		button.add_theme_color_override("font_disabled_color", Color("454b58"))

	button.mouse_entered.connect(_show_preview.bind(index))
	add_child(button)

func _show_preview(index: int) -> void:
	var stage: Dictionary = STAGES[index]
	if not stage["unlocked"]:
		preview_rect.texture = null
		preview_label.text = "EM BREVE"
		return
	preview_rect.texture = load(stage["preview"])
	if _is_stage_gated(stage):
		var required_role: String = stage["required_role"]
		preview_label.text = "REQUER: %s" % Actor.DISPLAY_NAME.get(required_role, required_role.to_upper())
	else:
		preview_label.text = stage["name"]

func _on_stage_pressed(index: int) -> void:
	var stage: Dictionary = STAGES[index]
	PartySelection12.target_scene = stage["target_scene"]
	PartySelection12.loading_title = stage["loading_title"]
	PartySelection12.selection_mode = stage.get("selection_mode", PartySelection12.MODE_CATEGORIZED)
	PartySelection12.stage_reward_role = stage.get("reward_role", "")
	PartySelection12.required_role = stage.get("required_role", "")
	if PartySelection12.selection_mode == PartySelection12.MODE_GATED:
		# Garante que o personagem exigido pela fase E o Cavaleiro Executivo
		# (obrigatorio em qualquer grupo) sempre entrem — sem isso o vao da
		# sala nao teria como ser cruzado, ou o grupo ficaria sem o
		# protagonista fixo.
		PartySelection12.free_roles = PartySelection12.mandatory_free_roles(PartySelection12.required_role)
	elif PartySelection12.selection_mode == PartySelection12.MODE_FREE:
		PartySelection12.free_roles = PartySelection12.mandatory_free_roles()
	var dialogue_id: String = stage.get("dialogue_id", "")
	if dialogue_id != "":
		PartySelection12.pending_dialogue_id = dialogue_id
		PartySelection12.pending_dialogue_bg = stage.get("preview", "")
		get_tree().change_scene_to_file(DIALOGUE_SCENE)
		return
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)
