extends Control

## Pos-16: tela de Salvar/Carregar (pedido do usuario com mockup de
## referencia) — 3 slots fixos espelhando SaveSystem12. Aberta tanto pelo
## Menu Principal ("SALVAR / CARREGAR") quanto, futuramente, de dentro do
## jogo. Usa CorporateUI12 (kit novo), igual ao Menu Principal e a Fase 00.

const BG_TEX := preload("res://assets/Backgrounds/Runtime/Menu/save_slots_bg.png")
## save_slots_bg.png e paisagem (1537x1023) — em retrato so o cabecalho
## (titulo, ja recortado sem os 3 cards) fica no topo; os 3 slots viram
## paineis desenhados por codigo (CorporateUI12.make_dialogue_panel(),
## mesma moldura dourada/azul do balao de dialogo da Fase 00) empilhados
## abaixo, igual ao padrao adotado em main_menu_12.gd.
const HEADER_PORTRAIT_TEX := preload("res://assets/Backgrounds/Runtime/Menu/save_slots_header_portrait.png")
const MAIN_MENU_SCENE := "res://scenes/menu/main_menu_12.tscn"
const STAGE_SELECT_SCENE := "res://scenes/menu/stage_select_12.tscn"
const FASE00_SCENE := "res://scenes/playtest/platform_fase00_12.tscn"

var body_font: Font
var title_font: Font


func _ready() -> void:
	body_font = load("res://assets/Fonts/Runtime/MedievalSharp-Book.ttf")
	title_font = load("res://assets/Fonts/Runtime/MedievalScrollOfWisdom.ttf")

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

	# As 3 faixas de slot do mockup ficam entre ~16% e ~91% da altura.
	# Nota: save_slots_bg.png tem proporcao 1.5:1 (mais "quadrada" que a
	# tela 16:9), entao STRETCH_KEEP_ASPECT_COVERED corta ~9% do topo e
	# ~9% da base da imagem pra cobrir a tela toda — as fracoes abaixo ja
	# sao calculadas em cima da regiao realmente visivel (nao da imagem
	# crua), com folga extra reduzida nos espacos entre faixas pra sobrar
	# altura pro botao VOLTAR sem cortar a 3a faixa.
	var row_h := size.y * 0.235
	var row_gap := size.y * 0.022
	var start_y := size.y * 0.16
	var row_w := size.x * 0.62
	var row_x := size.x * 0.5 - row_w * 0.5

	for i in range(1, SaveSystem12.SLOT_COUNT + 1):
		_build_slot_row(i, Vector2(row_x, start_y + (i - 1) * (row_h + row_gap)), Vector2(row_w, row_h), false)

	var back_btn := Button.new()
	back_btn.text = "VOLTAR"
	back_btn.focus_mode = Control.FOCUS_NONE
	var back_w := size.x * 0.24
	var back_h := size.y * 0.06
	back_btn.position = Vector2(size.x * 0.5 - back_w * 0.5, size.y - back_h - size.y * 0.015)
	CorporateUI12.style_button(back_btn, true, body_font, 7, Color("f4e7c9"), Vector2(back_w, back_h))
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file(MAIN_MENU_SCENE))
	add_child(back_btn)


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
	header.position = Vector2(0, size.y * 0.025)
	header.size = Vector2(size.x, size.x * (225.0 / 1537.0))
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)

	var row_h := size.y * 0.195
	var row_gap := size.y * 0.016
	var start_y := header.position.y + header.size.y + size.y * 0.05
	var row_w := size.x * 0.86
	var row_x := size.x * 0.5 - row_w * 0.5

	for i in range(1, SaveSystem12.SLOT_COUNT + 1):
		_build_slot_row(i, Vector2(row_x, start_y + (i - 1) * (row_h + row_gap)), Vector2(row_w, row_h), true)

	var back_btn := Button.new()
	back_btn.text = "VOLTAR"
	back_btn.focus_mode = Control.FOCUS_NONE
	var back_w := size.x * 0.5
	var back_h := size.y * 0.05
	back_btn.position = Vector2(size.x * 0.5 - back_w * 0.5, size.y - back_h - size.y * 0.02)
	CorporateUI12.style_button(back_btn, true, body_font, 7, Color("f4e7c9"), Vector2(back_w, back_h))
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file(MAIN_MENU_SCENE))
	add_child(back_btn)


func _build_slot_row(slot: int, pos: Vector2, size: Vector2, draw_panel: bool) -> void:
	if draw_panel:
		# Retrato nao tem o card de pergaminho do fundo paisagem. O 9-patch
		# do balao de dialogo (CorporateUI12.make_dialogue_panel) tem
		# margens grandes demais pra essa faixa baixa e estica errado —
		# em vez disso, um Panel liso com o mesmo StyleBoxFlat
		# dourado/azul dos botoes, que escala bem em qualquer tamanho.
		var panel := Panel.new()
		panel.position = pos
		panel.size = size
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb := CorporateUI12.button_stylebox(false)
		sb.set_corner_radius_all(8)
		add_child(panel)
		panel.add_theme_stylebox_override("panel", sb)

	var meta := SaveSystem12.read_slot_meta(slot)
	var has_data := not meta.is_empty()
	var is_active := SaveSystem12.current_slot == slot

	# Inset horizontal maior que o padrao (0.03) porque a faixa "01/02/03"
	# do fundo (save_slots_bg.png) e um banner que invade a borda esquerda
	# do card — com 0.03 o texto nascia por baixo do banner.
	var status := Label.new()
	status.position = pos + Vector2(size.x * 0.1, size.y * 0.08)
	status.size = Vector2(size.x * 0.48, size.y * 0.8)
	status.add_theme_font_override("font", body_font)
	status.add_theme_font_size_override("font_size", 7)
	# Retrato usa painel navy (sem o card de pergaminho) — texto escuro
	# ficaria ilegivel, entao troca pra creme claro nesse caso.
	status.add_theme_color_override("font_color", Color("f4e7c9") if draw_panel else Color("2a1a0f"))
	status.autowrap_mode = TextServer.AUTOWRAP_WORD

	if has_data:
		var ratio := SaveSystem12.progress_ratio_from_meta(meta)
		var pct := int(round(ratio * 100.0))
		var prologue_done: bool = meta.get("prologue_cleared", false)
		var minutes := int(float(meta.get("play_seconds", 0.0)) / 60.0)
		var estado := "Fases liberadas" if prologue_done else "Fase 00 - Recepção"
		var badge := "ATIVO" if is_active else "SALVO"
		status.text = "[%s] %s\n%d%% dos personagens desbloqueados - %d min jogados" % [badge, estado, pct, minutes]
	else:
		status.text = "[VAZIO]\nNenhum progresso salvo."
	add_child(status)

	var action_btn := Button.new()
	action_btn.text = "CARREGAR" if has_data else "COMEÇAR"
	action_btn.focus_mode = Control.FOCUS_NONE
	var abtn_w := size.x * 0.36
	action_btn.position = pos + Vector2(size.x - abtn_w - size.x * 0.03, size.y * 0.14)
	CorporateUI12.style_button(action_btn, false, body_font, 7, Color("2a1a0f"), Vector2(abtn_w, size.y * 0.32))
	action_btn.pressed.connect(func(): _on_slot_action(slot, has_data))
	add_child(action_btn)

	if has_data:
		var delete_btn := Button.new()
		delete_btn.text = "APAGAR"
		delete_btn.focus_mode = Control.FOCUS_NONE
		delete_btn.position = pos + Vector2(size.x - abtn_w - size.x * 0.03, size.y * 0.56)
		CorporateUI12.style_button(delete_btn, true, body_font, 6, Color("f4e7c9"), Vector2(abtn_w, size.y * 0.26))
		delete_btn.pressed.connect(func(): _on_slot_delete(slot))
		add_child(delete_btn)


func _on_slot_action(slot: int, has_data: bool) -> void:
	if has_data:
		SaveSystem12.load_game(slot)
		get_tree().change_scene_to_file(STAGE_SELECT_SCENE if PartySelection12.prologue_cleared else FASE00_SCENE)
	else:
		SaveSystem12.new_game(slot)
		get_tree().change_scene_to_file(FASE00_SCENE)


func _on_slot_delete(slot: int) -> void:
	SaveSystem12.delete_slot(slot)
	get_tree().reload_current_scene()
