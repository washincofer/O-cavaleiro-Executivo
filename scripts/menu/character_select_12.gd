extends Control

## Sprint 12: selecao de personagens estilo Super Smash Bros, entre a tela de
## selecao de fase e o loading. O elenco tem 6 personagens jogaveis, mas cada
## um pertence a UMA das 3 categorias de mecanica do puzzle da fase (quebrar
## entulho / atravessar a barreira magica / teleportar). Por isso a escolha
## e sempre "um de cada categoria" (like picking a fighter per slot) em vez
## de livre entre os 6 — assim qualquer combinacao final consegue terminar a
## Provacao do Trio.
##
## Sprint 16: a mais trabalhosa das 4 telas convertidas pro padrao retrato/
## paisagem — `_build_landscape()` e o layout original (320x180, geometria
## intocada); ganhou uma irma `_build_portrait()` (180x320). `_build_tile()`
## e `_build_free_tile()` foram generalizadas pra aceitar `tile_w`/`tile_h`
## explicitos em vez dos consts do modulo, pra serem reaproveitadas nos dois
## layouts em vez de duplicadas. Em retrato: as 3 categorias viram 3 linhas
## empilhadas (2 opcoes lado a lado, em vez de coluna); a grade livre vira
## 2 colunas x 5 linhas (em vez de 3x3, que nao cabe em 180px de largura).
## Botoes COMECAR/VOLTAR ganham o skin Medieval Free nos dois modos.

const Actor = preload("res://scripts/playtest/platform_actor_12.gd")
const TITLE_FONT_PATH := "res://assets/Fonts/Runtime/AoboshiOne-Regular.ttf"
const BODY_FONT_PATH := "res://assets/Fonts/Runtime/AoboshiOne-Regular.ttf"
const LOADING_SCENE := "res://scenes/menu/loading_screen_12.tscn"
const STAGE_SELECT_SCENE := "res://scenes/menu/stage_select_12.tscn"

const PORTRAIT_PATH := {
	"cavaleiro_executivo": "res://assets/UI/Runtime/Portraits/cavaleiro_executivo.png",
	"warrior": "res://assets/UI/Runtime/Portraits/warrior.png",
	"archer": "res://assets/UI/Runtime/Portraits/archer.png",
	"mage": "res://assets/UI/Runtime/Portraits/mage.png",
	"fire_mage": "res://assets/UI/Runtime/Portraits/fire_mage.png",
	"lightning_mage": "res://assets/UI/Runtime/Portraits/lightning_mage.png",
	"wanderer": "res://assets/UI/Runtime/Portraits/wanderer.png",
	"paladin": "res://assets/UI/Runtime/Portraits/paladin.png",
	"knight": "res://assets/UI/Runtime/Portraits/knight.png",
	"bridge_heroine": "res://assets/UI/Runtime/Portraits/bridge_heroine.png",
}

# Elenco livre (fases de boss): qualquer 3 (com o Cavaleiro Executivo
# sempre fixo — ver `PartySelection12.MANDATORY_ROLE`/`toggle_free_role`),
# sem categorias. Paladino, Cavaleiro e Heroina da Ponte so aparecem aqui,
# nunca na selecao por categoria da Caverna (e comecam bloqueados ate
# vencer a fase que libera cada um — ver `PartySelection12.is_unlocked`).
# 3x4 (12 vagas) para caber os 10 personagens do elenco completo (Cavaleiro
# Executivo + os 9 originais) sem sobrepor a faixa "SEU GRUPO".
const FREE_GRID_ROLES := [
	"cavaleiro_executivo",
	"warrior", "archer", "mage", "fire_mage", "lightning_mage", "wanderer",
	"paladin", "knight", "bridge_heroine",
]
const FREE_COLS := 3
const FREE_TILE_W := 100.0
const FREE_TILE_H := 14.0
const FREE_TILE_GAP := 1.0
const FREE_GRID_X := 6.0
const FREE_GRID_Y := 34.0
const FREE_ACCENT := Color("ffd23f")

const CATEGORY_LABEL := {
	"breaker": "QUEBRA ENTULHO",
	"piercer": "ATRAVESSA BARREIRA",
	"teleporter": "CRUZA O VAO",
}

const CATEGORY_ACCENT := {
	"breaker": Color("e0a15c"),
	"piercer": Color("5ce07a"),
	"teleporter": Color("c25ce0"),
}

const ROLE_TAG := {
	"cavaleiro_executivo": "ESTOCADA",
	"warrior": "ESTOCADA",
	"fire_mage": "RAJADA",
	"archer": "PERFURANTE",
	"lightning_mage": "PERFURANTE",
	"mage": "TELEPORTE",
	"wanderer": "TELEPORTE",
}

const COL_X := [6.0, 112.0, 218.0]
const COL_W := 96.0
const TILE_W := 90.0
const TILE_H := 23.0
const TILE_GAP := 3.0
const TILE_Y := 44.0

var title_font: FontFile
var body_font: FontFile
var selected: Dictionary = {}
var tile_border_by_key: Dictionary = {}
var preview_portrait: Array[TextureRect] = []
var preview_name: Array[Label] = []

func _ready() -> void:
	title_font = load(TITLE_FONT_PATH)
	body_font = load(BODY_FONT_PATH)
	selected = PartySelection12.selection.duplicate()

	if DeviceLayout12.is_portrait:
		custom_minimum_size = Vector2(180, 320)
		_build_portrait()
	else:
		custom_minimum_size = Vector2(320, 180)
		_build_landscape()

	_refresh_selection_visuals()
	_refresh_preview_strip()

func _build_landscape() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("0a0e16")
	add_child(bg)

	var title := Label.new()
	title.text = "SELECAO DE PERSONAGENS"
	title.position = Vector2(0, 9)
	title.size = Vector2(320, 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", title_font)
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color("ffe26f"))
	title.add_theme_color_override("font_outline_color", Color("241a05"))
	title.add_theme_constant_override("outline_size", 3)
	add_child(title)

	var is_free: bool = _uses_free_grid()

	var subtitle := Label.new()
	subtitle.text = _subtitle_text(is_free)
	subtitle.position = Vector2(0, 22)
	subtitle.size = Vector2(320, 8)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_override("font", body_font)
	subtitle.add_theme_font_size_override("font_size", 6)
	subtitle.add_theme_color_override("font_color", Color("8fa6c9"))
	add_child(subtitle)

	if is_free:
		_build_free_grid()
	else:
		for i in range(PartySelection12.CATEGORIES.size()):
			_build_category_column(PartySelection12.CATEGORIES[i], COL_X[i])

	_build_preview_strip()
	_build_buttons()

	var hint := Label.new()
	hint.text = "CLIQUE PARA ESCOLHER  -  COMECAR PARA JOGAR"
	hint.position = Vector2(0, 168)
	hint.size = Vector2(320, 10)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_override("font", body_font)
	hint.add_theme_font_size_override("font_size", 6)
	hint.add_theme_color_override("font_color", Color("8fa6c9"))
	add_child(hint)

func _subtitle_text(is_free: bool) -> String:
	if PartySelection12.selection_mode == PartySelection12.MODE_GATED:
		return "CAVALEIRO EXECUTIVO + %s FIXOS — MAIS 1" % Actor.DISPLAY_NAME.get(PartySelection12.required_role, "")
	elif is_free:
		return "CAVALEIRO EXECUTIVO FIXO — ESCOLHA MAIS 2"
	return "CAVALEIRO EXECUTIVO FIXO — ESCOLHA MAIS 2"

func _build_portrait() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("0a0e16")
	add_child(bg)

	var title := Label.new()
	title.text = "SELECAO DE\nPERSONAGENS"
	title.position = Vector2(0, 4)
	title.size = Vector2(180, 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", title_font)
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color("ffe26f"))
	title.add_theme_color_override("font_outline_color", Color("241a05"))
	title.add_theme_constant_override("outline_size", 3)
	add_child(title)

	var is_free: bool = _uses_free_grid()

	var subtitle := Label.new()
	subtitle.text = _subtitle_text(is_free)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD
	subtitle.add_theme_font_override("font", body_font)
	subtitle.add_theme_font_size_override("font_size", 6)
	subtitle.add_theme_color_override("font_color", Color("8fa6c9"))
	# size por ultimo (mesma armadilha do loading_screen_12.gd: autowrap +
	# fonte antes de entrar na tree infla o minimum_size, e o Control nao
	# encolhe sozinho depois).
	subtitle.position = Vector2(4, 32)
	subtitle.custom_minimum_size = Vector2(172, 16)
	subtitle.size = Vector2(172, 16)
	add_child(subtitle)

	if is_free:
		_build_free_grid_portrait(54.0)
	else:
		for i in range(PartySelection12.CATEGORIES.size()):
			_build_category_row_portrait(PartySelection12.CATEGORIES[i], 54.0 + i * 38.0)

	_build_preview_strip_portrait(180.0)
	_build_buttons_portrait(246.0)

	var hint := Label.new()
	hint.text = "CLIQUE PARA ESCOLHER"
	hint.position = Vector2(0, 304)
	hint.size = Vector2(180, 12)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_override("font", body_font)
	hint.add_theme_font_size_override("font_size", 6)
	hint.add_theme_color_override("font_color", Color("8fa6c9"))
	add_child(hint)

func _build_category_column(category: String, col_x: float) -> void:
	var accent: Color = CATEGORY_ACCENT[category]

	var label := Label.new()
	label.text = CATEGORY_LABEL[category]
	label.position = Vector2(col_x, 34)
	label.size = Vector2(COL_W, 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", body_font)
	label.add_theme_font_size_override("font_size", 6)
	label.add_theme_color_override("font_color", accent)
	add_child(label)

	var options: Array = PartySelection12.OPTIONS[category]
	var tile_x: float = col_x + (COL_W - TILE_W) / 2.0
	for i in range(options.size()):
		var role: String = options[i]
		var tile_y: float = TILE_Y + i * (TILE_H + TILE_GAP)
		_build_tile(category, role, accent, Vector2(tile_x, tile_y), TILE_W, TILE_H)

func _build_tile(category: String, role: String, accent: Color, pos: Vector2, tile_w: float, tile_h: float) -> void:
	var border := ColorRect.new()
	border.position = pos
	border.size = Vector2(tile_w, tile_h)
	border.color = Color("2a2f3a")
	add_child(border)
	tile_border_by_key["%s:%s" % [category, role]] = border

	var inner := ColorRect.new()
	inner.position = pos + Vector2(1, 1)
	inner.size = Vector2(tile_w, tile_h) - Vector2(2, 2)
	inner.color = Color("11141c")
	add_child(inner)

	var portrait := TextureRect.new()
	portrait.position = pos + Vector2(2, 1)
	portrait.size = Vector2(20.0, tile_h - 2.0)
	portrait.texture = load(PORTRAIT_PATH[role])
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(portrait)

	var name_label := Label.new()
	name_label.text = Actor.DISPLAY_NAME.get(role, role.to_upper())
	name_label.position = pos + Vector2(24, 1)
	name_label.size = Vector2(tile_w - 26.0, 11)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.add_theme_font_override("font", body_font)
	name_label.add_theme_font_size_override("font_size", 6)
	name_label.add_theme_color_override("font_color", Color("e8e2d0"))
	name_label.clip_text = true
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_label)

	var tag_label := Label.new()
	tag_label.text = ROLE_TAG.get(role, "")
	tag_label.position = pos + Vector2(24, 12)
	tag_label.size = Vector2(tile_w - 26.0, 10)
	tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tag_label.add_theme_font_override("font", body_font)
	tag_label.add_theme_font_size_override("font_size", 5)
	tag_label.add_theme_color_override("font_color", accent)
	tag_label.clip_text = true
	tag_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tag_label)

	var button := Button.new()
	button.position = pos
	button.size = Vector2(tile_w, tile_h)
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.text = ""
	button.pressed.connect(_on_tile_pressed.bind(category, role))
	add_child(button)

func _on_tile_pressed(category: String, role: String) -> void:
	selected[category] = role
	_refresh_selection_visuals()
	_refresh_preview_strip()

func _build_category_row_portrait(category: String, row_y: float) -> void:
	# Sprint 16: em retrato as 3 categorias viram 3 linhas empilhadas (em
	# vez de 3 colunas) — cada linha com as 2 opcoes lado a lado.
	var accent: Color = CATEGORY_ACCENT[category]

	var label := Label.new()
	label.text = CATEGORY_LABEL[category]
	label.position = Vector2(4, row_y)
	label.size = Vector2(172, 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.add_theme_font_override("font", body_font)
	label.add_theme_font_size_override("font_size", 6)
	label.add_theme_color_override("font_color", accent)
	add_child(label)

	var options: Array = PartySelection12.OPTIONS[category]
	var tile_w := 83.0
	var tile_h := 26.0
	var tile_y := row_y + 9
	for i in range(options.size()):
		var role: String = options[i]
		var tile_x: float = 5.0 + i * (tile_w + 4.0)
		_build_tile(category, role, accent, Vector2(tile_x, tile_y), tile_w, tile_h)

func _build_free_grid() -> void:
	for i in range(FREE_GRID_ROLES.size()):
		var role: String = FREE_GRID_ROLES[i]
		var col: int = i % FREE_COLS
		var row: int = i / FREE_COLS
		var pos := Vector2(
			FREE_GRID_X + col * (FREE_TILE_W + FREE_TILE_GAP),
			FREE_GRID_Y + row * (FREE_TILE_H + FREE_TILE_GAP)
		)
		_build_free_tile(role, pos, FREE_TILE_W, FREE_TILE_H)

func _build_free_grid_portrait(grid_y: float) -> void:
	# Sprint 16: grade livre em retrato vira 2 colunas x 5 linhas (em vez de
	# 3x3, que nao cabe em 180px de largura) — os mesmos 9 personagens.
	var cols := 2
	var tile_w := 83.0
	var tile_h := 21.0
	var gap := 4.0
	for i in range(FREE_GRID_ROLES.size()):
		var role: String = FREE_GRID_ROLES[i]
		var col: int = i % cols
		var row: int = i / cols
		var pos := Vector2(
			5.0 + col * (tile_w + gap),
			grid_y + row * (tile_h + gap)
		)
		_build_free_tile(role, pos, tile_w, tile_h)

func _build_free_tile(role: String, pos: Vector2, tile_w: float, tile_h: float) -> void:
	# Sprint 15: personagens ainda nao desbloqueados aparecem na mesma grade,
	# mas escurecidos e sem botao — "so mostra/permite os desbloqueados" sem
	# reorganizar o layout fixo a cada novo heroi liberado.
	var locked: bool = not PartySelection12.is_unlocked(role)

	var border := ColorRect.new()
	border.position = pos
	border.size = Vector2(tile_w, tile_h)
	border.color = Color("2a2f3a")
	add_child(border)
	tile_border_by_key["free:%s" % role] = border

	var inner := ColorRect.new()
	inner.position = pos + Vector2(1, 1)
	inner.size = Vector2(tile_w, tile_h) - Vector2(2, 2)
	inner.color = Color("0a0c11") if locked else Color("11141c")
	add_child(inner)

	var portrait := TextureRect.new()
	portrait.position = pos + Vector2(2, 1)
	portrait.size = Vector2(22.0, tile_h - 2.0)
	portrait.texture = load(PORTRAIT_PATH[role])
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if locked:
		portrait.modulate = Color(0.3, 0.3, 0.35, 0.75)
	add_child(portrait)

	var name_label := Label.new()
	name_label.text = "BLOQUEADO" if locked else Actor.DISPLAY_NAME.get(role, role.to_upper())
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_override("font", body_font)
	name_label.add_theme_font_size_override("font_size", 5)
	name_label.add_theme_color_override("font_color", Color("50545f") if locked else Color("e8e2d0"))
	name_label.clip_text = true
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# size por ultimo (autowrap+fonte antes de entrar na tree pode inflar o
	# minimum_size, e o Control nao encolhe sozinho depois).
	name_label.position = pos + Vector2(25, 0)
	name_label.custom_minimum_size = Vector2(tile_w - 27.0, tile_h)
	name_label.size = Vector2(tile_w - 27.0, tile_h)
	add_child(name_label)

	if locked:
		return

	var button := Button.new()
	button.position = pos
	button.size = Vector2(tile_w, tile_h)
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.text = ""
	button.pressed.connect(_on_free_tile_pressed.bind(role))
	add_child(button)

func _on_free_tile_pressed(role: String) -> void:
	PartySelection12.toggle_free_role(role)
	_refresh_selection_visuals()
	_refresh_preview_strip()

func _uses_free_grid() -> bool:
	return PartySelection12.selection_mode == PartySelection12.MODE_FREE \
		or PartySelection12.selection_mode == PartySelection12.MODE_GATED

func _refresh_selection_visuals() -> void:
	if _uses_free_grid():
		for key in tile_border_by_key.keys():
			var role: String = key.split(":")[1]
			var border: ColorRect = tile_border_by_key[key]
			border.color = FREE_ACCENT if PartySelection12.free_roles.has(role) else Color("2a2f3a")
		return

	for key in tile_border_by_key.keys():
		var parts: PackedStringArray = key.split(":")
		var category: String = parts[0]
		var role: String = parts[1]
		var border: ColorRect = tile_border_by_key[key]
		var is_selected: bool = selected.get(category, "") == role
		border.color = CATEGORY_ACCENT[category] if is_selected else Color("2a2f3a")

func _build_preview_strip() -> void:
	var caption := Label.new()
	caption.text = "SEU GRUPO"
	caption.position = Vector2(6, 96)
	caption.size = Vector2(200, 8)
	caption.add_theme_font_override("font", body_font)
	caption.add_theme_font_size_override("font_size", 6)
	caption.add_theme_color_override("font_color", Color("8fa6c9"))
	add_child(caption)

	var slot_x := [8.0, 62.0, 116.0]
	for i in range(3):
		var frame := ColorRect.new()
		frame.position = Vector2(slot_x[i], 106)
		frame.size = Vector2(44, 40)
		frame.color = Color("1a1e28")
		add_child(frame)

		var portrait := TextureRect.new()
		portrait.position = Vector2(slot_x[i] + 4, 108)
		portrait.size = Vector2(36, 26)
		portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(portrait)
		preview_portrait.append(portrait)

		var name_label := Label.new()
		name_label.position = Vector2(slot_x[i], 136)
		name_label.size = Vector2(44, 8)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_override("font", body_font)
		name_label.add_theme_font_size_override("font_size", 5)
		name_label.add_theme_color_override("font_color", Color("e8e2d0"))
		add_child(name_label)
		preview_name.append(name_label)

func _build_preview_strip_portrait(y: float) -> void:
	var caption := Label.new()
	caption.text = "SEU GRUPO"
	caption.position = Vector2(6, y)
	caption.size = Vector2(168, 8)
	caption.add_theme_font_override("font", body_font)
	caption.add_theme_font_size_override("font_size", 6)
	caption.add_theme_color_override("font_color", Color("8fa6c9"))
	add_child(caption)

	var slot_x := [7.0, 65.0, 123.0]
	var frame_y := y + 10
	for i in range(3):
		var frame := ColorRect.new()
		frame.position = Vector2(slot_x[i], frame_y)
		frame.size = Vector2(50, 44)
		frame.color = Color("1a1e28")
		add_child(frame)

		var portrait := TextureRect.new()
		portrait.position = Vector2(slot_x[i] + 5, frame_y + 2)
		portrait.size = Vector2(40, 30)
		portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(portrait)
		preview_portrait.append(portrait)

		var name_label := Label.new()
		name_label.position = Vector2(slot_x[i], frame_y + 33)
		name_label.size = Vector2(50, 10)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_override("font", body_font)
		name_label.add_theme_font_size_override("font_size", 6)
		name_label.add_theme_color_override("font_color", Color("e8e2d0"))
		add_child(name_label)
		preview_name.append(name_label)

func _refresh_preview_strip() -> void:
	if _uses_free_grid():
		var roles: Array[String] = PartySelection12.free_roles
		for i in range(3):
			if i < roles.size():
				preview_portrait[i].texture = load(PORTRAIT_PATH[roles[i]])
				preview_portrait[i].visible = true
				preview_name[i].text = Actor.DISPLAY_NAME.get(roles[i], roles[i].to_upper())
			else:
				preview_portrait[i].visible = false
				preview_name[i].text = "?"
		return

	for i in range(PartySelection12.CATEGORIES.size()):
		var category: String = PartySelection12.CATEGORIES[i]
		var role: String = selected.get(category, PartySelection12.DEFAULT_SELECTION[category])
		preview_portrait[i].texture = load(PORTRAIT_PATH[role])
		preview_portrait[i].visible = true
		preview_name[i].text = Actor.DISPLAY_NAME.get(role, role.to_upper())

func _build_buttons() -> void:
	var start_button := Button.new()
	start_button.text = "COMECAR"
	start_button.focus_mode = Control.FOCUS_NONE
	start_button.position = Vector2(184, 104)
	KenneyUI12.style_button(start_button, true, 11, Vector2(128, 28))
	start_button.pressed.connect(_on_start_pressed)
	add_child(start_button)

	var back_button := Button.new()
	back_button.text = "VOLTAR"
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.position = Vector2(184, 136)
	KenneyUI12.style_button(back_button, false, 7, Vector2(128, 16))
	back_button.pressed.connect(_on_back_pressed)
	add_child(back_button)

func _build_buttons_portrait(y: float) -> void:
	var start_button := Button.new()
	start_button.text = "COMECAR"
	start_button.focus_mode = Control.FOCUS_NONE
	start_button.position = Vector2(20, y)
	KenneyUI12.style_button(start_button, true, 11, Vector2(140, 28))
	start_button.pressed.connect(_on_start_pressed)
	add_child(start_button)

	var back_button := Button.new()
	back_button.text = "VOLTAR"
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.position = Vector2(20, y + 34)
	KenneyUI12.style_button(back_button, false, 7, Vector2(140, 18))
	back_button.pressed.connect(_on_back_pressed)
	add_child(back_button)

func _on_start_pressed() -> void:
	if _uses_free_grid():
		if PartySelection12.free_roles.size() < PartySelection12.FREE_PARTY_SIZE:
			return
		get_tree().change_scene_to_file(LOADING_SCENE)
		return
	for category in PartySelection12.CATEGORIES:
		PartySelection12.set_role(category, selected[category])
	get_tree().change_scene_to_file(LOADING_SCENE)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(STAGE_SELECT_SCENE)
