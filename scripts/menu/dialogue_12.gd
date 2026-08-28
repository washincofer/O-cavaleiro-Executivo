extends Control

## Sprint pos-16 (pedido do usuario): dialogo estilo visual novel antes de
## cada fase de boss, contando a historia da hierarquia corporativa —
## Especialista/Chefe de Divisao/Coordenador/Gerente/Gerente Executivo/
## Diretor/Presidente — cada rank e um dos inimigos ja existentes no jogo
## (ver VILLAIN_INFO: "monster_role" aponta pro mesmo role de
## platform_actor_12.gd usado na fase). O retrato humano de cada rank
## (enviado pelo usuario aos poucos, um faceset de 8 expressoes por vez) e
## quem "negocia" no dialogo antes de se revelar como o monstro na luta.
##
## `stage_select_12.gd` guarda qual roteiro mostrar em
## `PartySelection12.pending_dialogue_id` (chave de DIALOGUE_LINES) e o
## fundo da fase em `pending_dialogue_bg` antes de trocar pra esta cena.
##
## Retratos: `res://assets/UI/Runtime/Dialogue/<character_id>/<expr>.png`.
## NENHUM desses arquivos existe ainda (os facesets chegam aos poucos,
## colados na conversa — precisam ser enviados como ARQUIVO/upload pra
## poderem ser recortados e salvos aqui) — `_portrait_texture()` cai num
## placeholder (retangulo colorido + nome) quando o arquivo nao existe, e
## `_build_placeholder()` monta ele, entao a cena funciona ponta a ponta
## mesmo sem nenhuma arte ainda. Assim que os PNGs entrarem nas pastas
## certas, os retratos reais aparecem sozinhos, sem mudar nada aqui.
##
## As 8 chaves de expressao usadas (mesma convencao pros dois facesets ja
## vistos — Cavaleiro Executivo e Coordenador — ambos uma folha 4x2):
## "neutro" (canto superior esq., meio-sorriso), "risada" (sorriso largo/
## piscando), "serio" (olhar intenso), "tenso" (surpreso ou serio-carrancudo,
## varia por personagem), "bravo" (dentes cerrados), "constrangido" (sorriso
## encabulado coçando a cabeça — ou so um sorriso largo, varia), "duvida"
## (cetico ou chorando, varia por personagem), "grito" (boca aberta, bravo).

const CHARACTER_SELECT_SCENE := "res://scenes/menu/character_select_12.tscn"
const TITLE_FONT_PATH := "res://assets/Fonts/Runtime/MedievalScrollOfWisdom.ttf"
const BODY_FONT_PATH := "res://assets/Fonts/Runtime/MedievalSharp-Book.ttf"
const PORTRAIT_DIR := "res://assets/UI/Runtime/Dialogue/"

const CAVALEIRO_ID := "cavaleiro"
const CAVALEIRO_NAME := "CAVALEIRO EXECUTIVO"

const VILLAIN_INFO := {
	"especialista": {"name": "O ESPECIALISTA", "rank": "Subchefe — Nivel 1", "monster_role": "bat"},
	"chefe_divisao": {"name": "O CHEFE DE DIVISAO", "rank": "Subchefe — Nivel 2", "monster_role": "rat"},
	"coordenador": {"name": "O COORDENADOR", "rank": "Subchefe Maior — Nivel 3", "monster_role": "necromancer"},
	"gerente": {"name": "O GERENTE", "rank": "Chefe — Nivel 4", "monster_role": "dragon"},
	"gerente_executivo": {"name": "O GERENTE EXECUTIVO", "rank": "Chefe — Nivel 5", "monster_role": "ogre"},
	"diretor": {"name": "O DIRETOR", "rank": "Chefe — Nivel 6", "monster_role": "slime"},
	"presidente": {"name": "O PRESIDENTE", "rank": "Chefe Final — Nivel 7", "monster_role": "satyr"},
}

# {"speaker": CAVALEIRO_ID ou a chave do vilao, "expr": uma das 8 chaves}
const DIALOGUE_LINES := {
	"coordenador": [
		{"speaker": "cavaleiro", "expr": "serio", "text": "As Ruinas do Departamento Antigo... dizem que o Coordenador nunca aprovou uma ferias sequer."},
		{"speaker": "coordenador", "expr": "neutro", "text": "Chegou as 10h01. Um minuto de atraso. Isso vai constar no seu relatorio de desempenho... para sempre."},
		{"speaker": "cavaleiro", "expr": "bravo", "text": "Um minuto?! Fico ate depois da meia-noite toda semana!"},
		{"speaker": "coordenador", "expr": "serio", "text": "E por isso mesmo que precisamos falar do seu banco de horas. Vai zerar. Hoje."},
		{"speaker": "cavaleiro", "expr": "duvida", "text": "Zerar? Tenho quase duzentas horas acumuladas!"},
		{"speaker": "coordenador", "expr": "neutro", "text": "Exatamente. Zera. A empresa nao deve nada a ninguem — o RH ja confirmou."},
		{"speaker": "coordenador", "expr": "bravo", "text": "Alias, vi no seu calendario um compromisso chamado 'CASAMENTO'. Vai ter que remarcar."},
		{"speaker": "cavaleiro", "expr": "grito", "text": "E o MEU casamento!"},
		{"speaker": "coordenador", "expr": "neutro", "text": "E a nossa Sprint Review. Prioridades, Cavaleiro."},
		{"speaker": "coordenador", "expr": "serio", "text": "Soube tambem que anda 'estudando' pra um doutorado. Doutorado e besteira. Ninguem aqui valoriza isso."},
		{"speaker": "cavaleiro", "expr": "tenso", "text": "Isso nao e da sua conta."},
		{"speaker": "coordenador", "expr": "risada", "text": "Tudo e da minha conta. Alias, vou marcar uma weekly pra discutir isso. Segunda, 8h."},
		{"speaker": "coordenador", "expr": "duvida", "text": "Ah, e eu vou faltar. Mas voces se reunem do mesmo jeito."},
		{"speaker": "cavaleiro", "expr": "bravo", "text": "Voce marca reuniao so pra faltar?!"},
		{"speaker": "coordenador", "expr": "neutro", "text": "E uma habilidade de gestao avancada. Alias, sabia que o Claude faz um trabalho melhor que voce? Ele pelo menos entrega no prazo."},
		{"speaker": "cavaleiro", "expr": "grito", "text": "ISSO NEM FAZ SENTIDO NESSE MUNDO!"},
		{"speaker": "coordenador", "expr": "serio", "text": "Acha que eu virei Subchefe Maior so preenchendo planilha? Cada relatorio de desempenho negativo que eu assino... alimenta alguma coisa aqui embaixo."},
		{"speaker": "coordenador", "expr": "bravo", "text": "Cada '1:1' cancelado em cima da hora. Cada promocao prometida e nunca paga. Tudo isso fica aqui. E cresce."},
		{"speaker": "cavaleiro", "expr": "tenso", "text": "Essas ruinas nao sao so um departamento abandonado, sao?"},
		{"speaker": "coordenador", "expr": "grito", "text": "E UM CEMITERIO DE CARREIRAS! E eu sou o zelador que nunca larga o cargo!", "fx": "transform"},
		{"speaker": "coordenador", "expr": "grito", "text": "SINTAM O PESO DE CADA META NAO BATIDA... ACORDEM, EX-COLABORADORES! TEMOS UMA SPRINT PRA FECHAR!"},
		{"speaker": "cavaleiro", "expr": "grito", "text": "Ele nao esta gerenciando... ele esta INVOCANDO! Vou fechar essa sprint eu mesmo!"},
	],
	"gerente": [
		{"speaker": "cavaleiro", "expr": "neutro", "text": "Entao e aqui que o Gerente guarda o orcamento do trimestre inteiro..."},
		{"speaker": "gerente", "expr": "risada", "text": "Cada centavo que chega as minhas maos... fica nas minhas maos. Isso se chama gestao de recursos."},
		{"speaker": "cavaleiro", "expr": "serio", "text": "Prometeu aumento pra equipe inteira ha dois anos."},
		{"speaker": "gerente", "expr": "constrangido", "text": "E prometo de novo no proximo trimestre. E no outro. E no outro..."},
		{"speaker": "cavaleiro", "expr": "bravo", "text": "Chega. Ou devolve o orcamento, ou eu tomo."},
		{"speaker": "gerente", "expr": "grito", "text": "TOME, SE CONSEGUIR!"},
	],
	"gerente_executivo": [
		{"speaker": "cavaleiro", "expr": "neutro", "text": "O Gerente Executivo do Cemiterio das Entregas — onde todo prazo perdido vai descansar."},
		{"speaker": "gerente_executivo", "expr": "bravo", "text": "PRAZO E PRA ONTEM! Quem nao entrega, eu ENTERRO."},
		{"speaker": "cavaleiro", "expr": "duvida", "text": "Isso nao e um pouco... desproporcional?"},
		{"speaker": "gerente_executivo", "expr": "grito", "text": "DESPROPORCIONAL E VOCE QUESTIONANDO MEU CRONOGRAMA!"},
		{"speaker": "cavaleiro", "expr": "serio", "text": "Vou mostrar o que acontece quando alguem finalmente diz nao."},
	],
	"especialista": [
		{"speaker": "cavaleiro", "expr": "duvida", "text": "O Especialista... nunca esta na mesa dele. Sempre 'em reuniao'."},
		{"speaker": "especialista", "expr": "constrangido", "text": "Ah, voce me pegou numa... pausa estrategica."},
		{"speaker": "cavaleiro", "expr": "bravo", "text": "Sua pausa estrategica dura seis meses e ninguem sabe o que voce faz."},
		{"speaker": "especialista", "expr": "risada", "text": "Sou um ESPECIALISTA. Especialista em... desaparecer quando precisam de mim."},
		{"speaker": "cavaleiro", "expr": "serio", "text": "Hoje voce nao foge."},
	],
	"presidente": [
		{"speaker": "cavaleiro", "expr": "serio", "text": "O Presidente. Depois de tudo isso, finalmente cara a cara."},
		{"speaker": "presidente", "expr": "neutro", "text": "Achou mesmo que ia chegar ate aqui? Impressionante. Quase orgulho de verdade."},
		{"speaker": "cavaleiro", "expr": "bravo", "text": "Voce escondido nessa floresta enquanto a empresa inteira desmorona la embaixo."},
		{"speaker": "presidente", "expr": "risada", "text": "Eu NAO desmorono. Eu me ADAPTO. Sou pequeno, rapido, e voce nunca vai me acertar."},
		{"speaker": "cavaleiro", "expr": "grito", "text": "Isso e o que veremos."},
		{"speaker": "presidente", "expr": "grito", "text": "ENTAO VENHA. VAMOS VER QUEM REALMENTE MERECE O CARGO."},
	],
}

var title_font: FontFile
var body_font: FontFile
var lines: Array = []
var line_index := 0
var villain_id := ""

var portrait_left: Control
var portrait_right: Control
var name_label: Label
var text_label: Label
var advance_hint: Label
var changed_scene := false

func _ready() -> void:
	# O root Control tambem e STOP por padrao — sem isso ele mesmo engole
	# todo clique na tela antes de virar _unhandled_input (mesma armadilha
	# dos filhos, ver comentario em _build_background).
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_font = load(TITLE_FONT_PATH)
	body_font = load(BODY_FONT_PATH)
	villain_id = PartySelection12.pending_dialogue_id
	lines = DIALOGUE_LINES.get(villain_id, [])

	if DeviceLayout12.is_portrait:
		custom_minimum_size = Vector2(180, 320)
		_build_portrait()
	else:
		custom_minimum_size = Vector2(320, 180)
		_build_landscape()

	if lines.is_empty():
		_go_to_character_select()
		return
	_show_line()

func _build_background(size: Vector2) -> void:
	# mouse_filter = IGNORE em tudo que e so visual — sem isso os Controls
	# (STOP por padrao) engolem o clique antes dele virar _unhandled_input
	# e o dialogo nunca avanca.
	var bg_path: String = PartySelection12.pending_dialogue_bg
	if bg_path != "" and ResourceLoader.exists(bg_path):
		var bg := TextureRect.new()
		bg.texture = load(bg_path)
		bg.position = Vector2.ZERO
		bg.size = size
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
	else:
		var fallback := ColorRect.new()
		fallback.position = Vector2.ZERO
		fallback.size = size
		fallback.color = Color("15121c")
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(fallback)

	var scrim := ColorRect.new()
	scrim.position = Vector2.ZERO
	scrim.size = size
	scrim.color = Color(0.03, 0.02, 0.05, 0.45)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

func _build_landscape() -> void:
	_build_background(Vector2(320, 180))

	portrait_left = _build_portrait_slot(Vector2(6, 20), Vector2(110, 110))
	portrait_right = _build_portrait_slot(Vector2(204, 20), Vector2(110, 110))

	var box := ColorRect.new()
	box.position = Vector2(4, 132)
	box.size = Vector2(312, 44)
	box.color = Color(0.02, 0.02, 0.03, 0.85)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)

	name_label = Label.new()
	name_label.position = Vector2(10, 135)
	name_label.size = Vector2(300, 10)
	name_label.add_theme_font_override("font", title_font)
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", Color("ffe26f"))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_label)

	text_label = Label.new()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_label.add_theme_font_override("font", body_font)
	text_label.add_theme_font_size_override("font_size", 7)
	text_label.add_theme_color_override("font_color", Color("f4e7c9"))
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# size por ultimo (autowrap+fonte antes de entrar na tree pode inflar o
	# minimum_size e o Control nao encolhe sozinho depois).
	text_label.position = Vector2(10, 146)
	text_label.custom_minimum_size = Vector2(300, 28)
	text_label.size = Vector2(300, 28)
	add_child(text_label)

	advance_hint = Label.new()
	advance_hint.text = "clique / tecla para continuar"
	advance_hint.position = Vector2(4, 168)
	advance_hint.size = Vector2(230, 10)
	advance_hint.add_theme_font_override("font", body_font)
	advance_hint.add_theme_font_size_override("font_size", 5)
	advance_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	advance_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(advance_hint)

	_build_skip_button(Vector2(240, 2), Vector2(76, 14))

func _build_portrait() -> void:
	_build_background(Vector2(180, 320))

	portrait_left = _build_portrait_slot(Vector2(4, 30), Vector2(84, 84))
	portrait_right = _build_portrait_slot(Vector2(92, 30), Vector2(84, 84))

	var box := ColorRect.new()
	box.position = Vector2(4, 122)
	box.size = Vector2(172, 150)
	box.color = Color(0.02, 0.02, 0.03, 0.85)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)

	name_label = Label.new()
	name_label.position = Vector2(10, 128)
	name_label.size = Vector2(160, 12)
	name_label.add_theme_font_override("font", title_font)
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", Color("ffe26f"))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_label)

	text_label = Label.new()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_label.add_theme_font_override("font", body_font)
	text_label.add_theme_font_size_override("font_size", 7)
	text_label.add_theme_color_override("font_color", Color("f4e7c9"))
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_label.position = Vector2(10, 144)
	text_label.custom_minimum_size = Vector2(160, 110)
	text_label.size = Vector2(160, 110)
	add_child(text_label)

	advance_hint = Label.new()
	advance_hint.text = "toque para continuar"
	advance_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	advance_hint.position = Vector2(0, 300)
	advance_hint.size = Vector2(180, 12)
	advance_hint.add_theme_font_override("font", body_font)
	advance_hint.add_theme_font_size_override("font_size", 6)
	advance_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	advance_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(advance_hint)

	_build_skip_button(Vector2(48, 4), Vector2(84, 16))

func _build_skip_button(pos: Vector2, size: Vector2) -> void:
	var skip_button := Button.new()
	skip_button.text = "PULAR >>"
	skip_button.focus_mode = Control.FOCUS_NONE
	skip_button.position = pos
	MedievalUI12.style_button(skip_button, true, body_font, 6, Color("f4e7c9"), size)
	skip_button.pressed.connect(_go_to_character_select)
	add_child(skip_button)

func _build_portrait_slot(pos: Vector2, size: Vector2) -> Control:
	var holder := Control.new()
	holder.position = pos
	holder.size = size
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	return holder

func _portrait_character_id(speaker: String) -> String:
	if speaker == CAVALEIRO_ID:
		return CAVALEIRO_ID
	return speaker

func _portrait_display_name(speaker: String) -> String:
	if speaker == CAVALEIRO_ID:
		return CAVALEIRO_NAME
	return VILLAIN_INFO.get(speaker, {}).get("name", speaker.to_upper())

func _set_portrait(slot: Control, speaker: String, expr: String, dim: bool) -> void:
	for child in slot.get_children():
		child.queue_free()

	var character_id: String = _portrait_character_id(speaker)
	var path := "%s%s/%s.png" % [PORTRAIT_DIR, character_id, expr]
	if ResourceLoader.exists(path):
		var tex_rect := TextureRect.new()
		tex_rect.texture = load(path)
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.modulate = Color(0.55, 0.55, 0.6) if dim else Color(1, 1, 1)
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# position/custom_minimum_size/size por ultimo — expand_mode antes de
		# entrar na tree pode inflar o minimum_size pro tamanho nativo da
		# textura (fotos de retrato sao bem maiores que os sprites do jogo),
		# e o Control nao encolhe sozinho depois (mesma armadilha do
		# loading_screen_12.gd).
		tex_rect.position = Vector2.ZERO
		tex_rect.custom_minimum_size = slot.size
		tex_rect.size = slot.size
		slot.add_child(tex_rect)
	else:
		_build_placeholder(slot, _portrait_display_name(speaker), dim)

func _build_placeholder(slot: Control, display_name: String, dim: bool) -> void:
	var panel := ColorRect.new()
	panel.position = Vector2.ZERO
	panel.size = slot.size
	panel.color = Color(0.16, 0.13, 0.08, 0.55) if dim else Color(0.22, 0.17, 0.09, 0.9)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(panel)

	var label := Label.new()
	label.text = display_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_override("font", body_font)
	label.add_theme_font_size_override("font_size", 6)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.55) if dim else Color("f4e7c9"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = Vector2(4, 0)
	label.custom_minimum_size = Vector2(slot.size.x - 8.0, slot.size.y)
	label.size = Vector2(slot.size.x - 8.0, slot.size.y)
	slot.add_child(label)

func _show_line() -> void:
	var line: Dictionary = lines[line_index]
	var speaker: String = line["speaker"]
	var expr: String = line["expr"]
	var is_cavaleiro: bool = speaker == CAVALEIRO_ID

	_set_portrait(portrait_left, CAVALEIRO_ID, "neutro" if not is_cavaleiro else expr, not is_cavaleiro)
	_set_portrait(portrait_right, villain_id, "neutro" if is_cavaleiro else expr, is_cavaleiro)

	name_label.text = _portrait_display_name(speaker)
	text_label.text = line["text"]

	if line.get("fx", "") == "transform":
		_play_transform_fx()

## Efeito especial pedido pelo usuario pro momento em que o vilao se revela
## como o monstro da luta (ex.: Coordenador -> Necromante): flash roxo
## rapido (a "energia" da transformacao) + tremor de tela curto, sem travar
## o avanco do dialogo (o jogador ainda pode clicar durante a animacao).
func _play_transform_fx() -> void:
	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0.55, 0.1, 0.75, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

	var flash_tween := create_tween()
	flash_tween.tween_property(flash, "color:a", 0.8, 0.06)
	flash_tween.tween_property(flash, "color:a", 0.0, 0.55)
	flash_tween.tween_callback(flash.queue_free)

	var base_pos: Vector2 = position
	var shake_tween := create_tween()
	for i in range(8):
		var offset := Vector2(randf_range(-5.0, 5.0), randf_range(-4.0, 4.0))
		shake_tween.tween_property(self, "position", base_pos + offset, 0.03)
	shake_tween.tween_property(self, "position", base_pos, 0.03)

func _unhandled_input(event: InputEvent) -> void:
	if changed_scene:
		return
	var advance := false
	if event is InputEventKey and event.pressed and not event.echo:
		advance = true
	elif event is InputEventMouseButton and event.pressed:
		advance = true
	elif event is InputEventScreenTouch and event.pressed:
		advance = true
	if not advance:
		return
	line_index += 1
	if line_index >= lines.size():
		_go_to_character_select()
	else:
		_show_line()

func _go_to_character_select() -> void:
	if changed_scene:
		return
	changed_scene = true
	PartySelection12.pending_dialogue_id = ""
	PartySelection12.pending_dialogue_bg = ""
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)
