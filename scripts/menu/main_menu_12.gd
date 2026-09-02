extends Control

## Pos-16: Menu Principal (pedido do usuario com mockup de referencia) —
## entra no fluxo entre o video de intro (company_intro_12.gd) e o Stage
## Select. Primeiro acesso (sem save nenhum ainda) cai na Fase 00; depois
## dela concluida, tanto NOVO JOGO quanto CONTINUAR vao direto pro Stage
## Select. Usa CorporateUI12 (kit novo, so pras telas novas) — nao mexe no
## MedievalUI12 das 5 fases de chefe/telas de selecao existentes.
##
## O fundo (assets/Backgrounds/Runtime/Menu/main_menu_bg.png) ja e o
## mockup completo com o logo "O CAVALEIRO EXECUTIVO" e o pergaminho em
## branco prontos — so os botoes sao desenhados por cima, dentro da area
## do pergaminho.

const BG_TEX := preload("res://assets/Backgrounds/Runtime/Menu/main_menu_bg.png")
## main_menu_bg.png e paisagem (1430x732, proporcao ~1.95:1) — coberto numa
## tela retrato ele cortaria a maior parte da largura (so sobraria uma
## faixa central estreita), derrubando ate palavras do titulo pra fora da
## tela. Em retrato so o cabecalho (logo+titulo, ja recortado sem o
## pergaminho/castelo/casa) e mostrado no topo; os botoes ficam desenhados
## por codigo (CorporateUI12) sobre fundo solido, igual ao padrao ja usado
## em stage_select_12.gd pras telas existentes.
const HEADER_PORTRAIT_TEX := preload("res://assets/Backgrounds/Runtime/Menu/main_menu_header_portrait.png")
const MENU_BGM := preload("res://assets/Audio/Runtime/menu_theme.ogg")
const STAGE_SELECT_SCENE := "res://scenes/menu/stage_select_12.tscn"
const FASE00_SCENE := "res://scenes/playtest/platform_fase00_12.tscn"
const SAVE_SLOTS_SCENE := "res://scenes/menu/save_slots_12.tscn"

var body_font: Font
var title_font: Font
var music: AudioStreamPlayer


func _ready() -> void:
	body_font = load("res://assets/Fonts/Runtime/MedievalSharp-Book.ttf")
	title_font = load("res://assets/Fonts/Runtime/MedievalScrollOfWisdom.ttf")

	music = AudioStreamPlayer.new()
	music.stream = MENU_BGM
	if music.stream is AudioStreamOggVorbis:
		music.stream.loop = true
	music.volume_db = -8.0
	add_child(music)
	music.play()

	if DeviceLayout12.is_portrait:
		custom_minimum_size = Vector2(180, 320)
		_build_portrait_ui()
	else:
		custom_minimum_size = Vector2(320, 180)
		_build_landscape_ui()


func _build_landscape_ui() -> void:
	var size: Vector2 = custom_minimum_size

	var bg := TextureRect.new()
	bg.texture = BG_TEX
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Area do pergaminho em branco no mockup: centralizada, ~46% da altura
	# da tela paisagem. STRETCH_KEEP_ASPECT_COVERED centraliza a imagem
	# nos dois eixos, entao a mesma fracao vale pras duas orientacoes.
	var btn_w := size.x * 0.34
	var btn_h := size.y * 0.075
	var gap := size.y * 0.018
	var start_y := size.y * 0.53

	var y := start_y
	for entry in _button_entries():
		var btn := Button.new()
		btn.text = entry[0]
		btn.focus_mode = Control.FOCUS_NONE
		btn.position = Vector2(size.x * 0.5 - btn_w * 0.5, y)
		CorporateUI12.style_button(btn, false, body_font, 8, Color("2a1a0f"), Vector2(btn_w, btn_h))
		btn.pressed.connect(entry[1])
		add_child(btn)
		y += btn_h + gap


func _build_portrait_ui() -> void:
	var size: Vector2 = custom_minimum_size

	var bg := ColorRect.new()
	bg.color = CorporateUI12.NAVY
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var header := TextureRect.new()
	header.texture = HEADER_PORTRAIT_TEX
	header.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	header.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	header.position = Vector2(0, size.y * 0.04)
	header.size = Vector2(size.x, size.x * (250.0 / 580.0))
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)

	var btn_w := size.x * 0.72
	var btn_h := size.y * 0.075
	var gap := size.y * 0.02
	var start_y := header.position.y + header.size.y + size.y * 0.06

	var y := start_y
	for entry in _button_entries():
		var btn := Button.new()
		btn.text = entry[0]
		btn.focus_mode = Control.FOCUS_NONE
		btn.position = Vector2(size.x * 0.5 - btn_w * 0.5, y)
		CorporateUI12.style_button(btn, false, body_font, 7, Color("f4e7c9"), Vector2(btn_w, btn_h))
		btn.pressed.connect(entry[1])
		add_child(btn)
		y += btn_h + gap


func _button_entries() -> Array:
	return [
		["NOVO JOGO", _on_new_game_pressed],
		["CONTINUAR", _on_continue_pressed],
		["SALVAR / CARREGAR", _on_save_slots_pressed],
		["SAIR", _on_quit_pressed],
	]


func _has_any_save() -> bool:
	for n in range(1, SaveSystem12.SLOT_COUNT + 1):
		if SaveSystem12.slot_exists(n):
			return true
	return false


func _first_empty_slot() -> int:
	for n in range(1, SaveSystem12.SLOT_COUNT + 1):
		if not SaveSystem12.slot_exists(n):
			return n
	return 1


func _go_to(scene_path: String) -> void:
	if music:
		music.stop()
	get_tree().change_scene_to_file(scene_path)


func _on_new_game_pressed() -> void:
	SaveSystem12.new_game(_first_empty_slot())
	_go_to(FASE00_SCENE)


func _on_continue_pressed() -> void:
	var slot := SaveSystem12.most_recent_slot()
	if slot < 1:
		_on_new_game_pressed()
		return
	SaveSystem12.load_game(slot)
	_go_to(STAGE_SELECT_SCENE if PartySelection12.prologue_cleared else FASE00_SCENE)


func _on_save_slots_pressed() -> void:
	_go_to(SAVE_SLOTS_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()
