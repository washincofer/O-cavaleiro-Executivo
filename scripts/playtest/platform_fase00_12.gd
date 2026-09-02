extends Node2D

## Pos-16: Fase 00 — Recepcao / Prologo (DESIGN LOCK v1.0 + entrega Polish
## v2 do usuario). Fase linear, sem chefe/subchefe/companions e sem
## inimigos (a propria entrega Polish v2 e explicita: "O projeto nao inclui
## inimigos nesta versao, conforme solicitado" — o combate tutorial que o
## documento de design descreve fica fora deste pacote). Termina fundando a
## nova empresa e liberando a Selecao de Fases; nao e revisitavel (nao
## aparece em `stage_select_12.gd:STAGES`).
##
## Porta quase 1:1 o motor de salas do prototipo (manifesto de
## plataformas/interacoes por tipo dialogue/transition/item/ending, camera
## com look-ahead, fade entre salas) só substituindo o placeholder tecnico
## (retangulos desenhados por `_draw()`) pelo sprite real do Cavaleiro
## Executivo (`Fase00Player12`) e o `Panel` cru do dialogo pelo balao
## dourado/azul de `CorporateUI12` — ver POLISH_NOTES.md da entrega: "o
## proximo passe deve ser so micro-ajuste... evitar alterar a composicao
## visual aprovada".
##
## Diferenca de escala importante: as 5 artes de sala sao 1672x941 (nao o
## pixel-art 320x180 do resto do jogo). Em vez de forcar essa arte a caber
## no content_scale_size padrao (o que a deixaria minuscula e cortaria a
## maior parte de cada sala do enquadramento), esta cena troca a janela
## pra 1280x720 (paisagem) / 720x1280 (retrato) so enquanto dura — 4x o
## 320x180/180x320 do resto do jogo, restaurado no unico ponto de saida
## (fim da fase, `_finish_and_go_to_stage_select()`).

const NATIVE_SIZE := Vector2(1672, 941)
const FASE00_LANDSCAPE_SIZE := Vector2i(1280, 720)
const FASE00_PORTRAIT_SIZE := Vector2i(720, 1280)
const BG_DIR := "res://assets/Backgrounds/Runtime/Fase00/"
const NPC_DIR := "res://assets/Characters/Fase00NPCs/Runtime/"
const STAGE_SELECT_SCENE := "res://scenes/menu/stage_select_12.tscn"
const PauseWatcher := preload("res://scripts/playtest/pause_watcher_12.gd")

const CAMERA_LOOKAHEAD_X := 86.0
const CAMERA_LOOKAHEAD_LERP := 5.5
const CAMERA_SMOOTHING := 7.5

# NPCs parados (sem moveset, conforme DesignLock: "Colegas genericos:
# variantes simples; sem moveset") desenhados na posicao de cada interacao
# que tiver essa chave — so decoracao, a interacao em si continua sendo o
# Marker2D/area de raio, igual ao prototipo.
const NPC_STANDEE := {
	"recepcionista": {"tex": "recepcionista_standee.png", "offset": Vector2(0, -66)},
	"rh": {"tex": "rh_standee.png", "offset": Vector2(0, -64)},
	"colega": {"tex": "colega_standee.png", "offset": Vector2(0, -64)},
}

# Retratos de dialogo: cavaleiro/coordenador ja existiam (8 expressoes);
# recepcionista/rh/colega sao novos, so com "neutro"/"reacao" (fase curta,
# poucos beats — nao precisa do conjunto completo de 8).
const PORTRAIT_DIR := "res://assets/UI/Runtime/Dialogue/"
const SPEAKER_NAME := {
	"cavaleiro": "CAVALEIRO EXECUTIVO",
	"recepcionista": "RECEPCIONISTA",
	"rh": "REPRESENTANTE DO RH",
	"colega": "COLEGA",
	"sistema": "SISTEMA",
}

const ROOMS := [
	{
		"id": "R00-01", "name": "Hall Principal",
		"objective": "Vá até Recursos Humanos.",
		"background": "r00_01_hall.png",
		# x=140 caiu dentro do retangulo de colisao do step_01 (x:80-200) —
		# o corpo do jogador (capsula ate 56px acima dos pes) ficava
		# encravado no degrau assim que a sala carregava. Ajuste de
		# colisao (POLISH_NOTES.md ja antecipa esse passo), nao mudanca de
		# composicao visual: o spawn so anda pra uma area de piso livre.
		"spawn_feet": Vector2(40, 770),
		"camera_vertical_offset": -250.0,
		# Mezanino e escada (linha 35-495 do manifesto original) sao so
		# cenario pintado no proprio background — como colisao, a escada
		# levava a um mezanino sem conexao de pulo alcancavel (145px de
		# distancia vertical do ultimo degrau, contra ~92px de pulo maximo
		# do perfil de movimento), virando um beco sem saida em cima da
		# rota obrigatoria pro balcao da recepcionista. Fase 00 e propaganda
		# "muito facil, sem risco" (DESIGN LOCK sec. 6) — manter so o piso
		# solido evita depender de timing de pulo pra progressao mandatoria.
		"platforms": [
			Rect2(0, 770, 1672, 70),
		],
		"interactions": [
			{
				"id": "recepcionista", "type": "dialogue", "npc": "recepcionista",
				"position": Vector2(800, 715), "radius": 105.0, "once": true,
				"prompt": "Falar com a recepcionista", "set_flag": "falou_recepcionista",
				"checkpoint_after": true,
				"lines": [
					["recepcionista", "neutro", "Bom dia. Recursos Humanos está esperando pelo senhor."],
					["cavaleiro", "duvida", "Eu não tinha reunião marcada."],
					["recepcionista", "reacao", "Agora tem."],
				],
			},
			{
				"id": "porta_rh", "type": "transition",
				"position": Vector2(1540, 720), "radius": 100.0,
				"prompt": "Entrar no Recursos Humanos", "requires": "falou_recepcionista",
				"locked_message": "A recepcionista parece estar tentando falar com você.",
				"target_room": "R00-02",
			},
		],
	},
	{
		"id": "R00-02", "name": "Recursos Humanos",
		"objective": "Participe da reunião de desligamento.",
		"background": "r00_02_rh.png",
		# mesmo ajuste do R00-01: x=160 caia dentro do left_riser (x:96-216).
		"spawn_feet": Vector2(40, 645),
		"camera_vertical_offset": -170.0,
		# Mesmo ajuste do R00-01: os dois "risers" ficavam bem no meio do
		# caminho obrigatorio ate reuniao_rh/saida_rh — so cenario agora.
		"platforms": [
			Rect2(0, 645, 1672, 65),
		],
		"interactions": [
			{
				"id": "reuniao_rh", "type": "dialogue", "npc": "rh",
				"position": Vector2(810, 585), "radius": 135.0, "once": true,
				"prompt": "Iniciar a reunião", "set_flag": "demitido", "checkpoint_after": true,
				"lines": [
					["rh", "neutro", "Obrigado por comparecer."],
					["cavaleiro", "duvida", "Eu trabalho três salas depois daqui."],
					["rh", "neutro", "Mesmo assim, agradecemos a disponibilidade."],
					["rh", "reacao", "Após uma criteriosa análise de desempenho, reestruturação organizacional, redimensionamento estratégico, adequação operacional e realinhamento de sinergias... a organização decidiu seguir sem os seus serviços."],
					["cavaleiro", "tenso", "Fui demitido?"],
					["rh", "neutro", "Preferimos dizer que sua jornada conosco foi concluída."],
					["cavaleiro", "serio", "Fui demitido."],
					["rh", "neutro", "Sim."],
				],
			},
			{
				"id": "saida_rh", "type": "transition",
				"position": Vector2(1515, 600), "radius": 110.0,
				"prompt": "Deixar o Recursos Humanos", "requires": "demitido",
				"locked_message": "A reunião ainda não terminou.",
				"target_room": "R00-03",
			},
		],
	},
	{
		"id": "R00-03", "name": "Corredor Pós-Desligamento",
		"objective": "Dirija-se à saída principal.",
		"background": "r00_03_corredor.png",
		"spawn_feet": Vector2(125, 718),
		"camera_vertical_offset": -225.0,
		# Mesmo ajuste: sacada + escada viram cenario, so o piso e solido.
		"platforms": [
			Rect2(0, 718, 1672, 62),
		],
		"interactions": [
			{
				"id": "colega_solidario", "type": "dialogue", "npc": "colega",
				"position": Vector2(600, 660), "radius": 105.0, "once": true,
				"prompt": "Falar com o antigo colega",
				"lines": [
					["colega", "neutro", "Soube agora."],
					["colega", "reacao", "Sinto muito."],
					["cavaleiro", "serio", "Eu também."],
				],
			},
			{
				"id": "objeto_pessoal", "type": "item",
				"position": Vector2(910, 660), "radius": 82.0, "once": true,
				"prompt": "Recolher objeto pessoal", "set_flag": "item_pessoal",
				"message": "Objeto pessoal recuperado: antiga placa de mesa.",
			},
			{
				"id": "saida_corredor", "type": "transition",
				"position": Vector2(1570, 660), "radius": 100.0,
				"prompt": "Seguir para a recepção", "target_room": "R00-04",
			},
		],
	},
	{
		"id": "R00-04", "name": "Recepção em Alerta",
		"objective": "Atravesse a recepção e alcance a porta principal.",
		"background": "r00_04_alerta.png",
		# mesmo ajuste: x=110 caia dentro do step_01 (x:105-210).
		"spawn_feet": Vector2(30, 765),
		"camera_vertical_offset": -255.0,
		# Mesmo ajuste: andar superior + escada viram cenario, so o piso e
		# solido (a rota obrigatoria ate a porta principal e toda no chao).
		"platforms": [
			Rect2(0, 765, 1672, 65),
		],
		"interactions": [
			{
				"id": "alerta_sem_inimigos", "type": "dialogue",
				"position": Vector2(700, 705), "radius": 140.0, "once": true,
				"auto": true, "auto_radius": 115.0, "set_flag": "alerta_ativado",
				"lines": [
					["sistema", "", "ALERTA PATRIMONIAL ATIVADO."],
					["cavaleiro", "bravo", "Claro. Agora resolveram trabalhar."],
				],
			},
			{
				"id": "saida_alerta", "type": "transition",
				"position": Vector2(1560, 710), "radius": 105.0,
				"prompt": "Abrir a porta principal", "target_room": "R00-05",
			},
		],
	},
	{
		"id": "R00-05", "name": "Porta Principal",
		"objective": "Saia da empresa.",
		"background": "r00_05_saida.png",
		"spawn_feet": Vector2(150, 782),
		"camera_vertical_offset": -250.0,
		"platforms": [Rect2(0, 782, 1672, 70)],
		"interactions": [
			{
				"id": "porta_final", "type": "ending",
				"position": Vector2(1140, 700), "radius": 175.0, "once": true,
				"prompt": "Deixar a empresa",
				"lines": [
					["cavaleiro", "serio", "Então é isso."],
					["cavaleiro", "tenso", "Anos construindo a empresa dos outros... e no fim eles decidem que não precisam mais de mim."],
					["cavaleiro", "neutro", "Tudo bem."],
					["cavaleiro", "serio", "Se não existe mais lugar para um Cavaleiro Executivo aqui... eu construo um lugar onde exista."],
				],
			},
		],
	},
]

var room_by_id: Dictionary = {}
var current_room: Dictionary = {}
var player: Fase00Player12
var camera: Camera2D
var room_root: Node2D
var interaction_root: Node2D
var flags: Dictionary = {}
var used_interactions: Dictionary = {}
var active_interaction: Dictionary = {}
var dialogue_lines: Array = []
var dialogue_index := 0
var pending_dialogue_action := Callable()
var transition_busy := false
var auto_trigger_guard := false
var body_font: Font
var title_font: Font

var room_title: Label
var objective_label: Label
var prompt_panel: Control
var prompt_label: Button
var dialogue_panel: Control
var dialogue_name: Label
var dialogue_text: Label
var dialogue_portrait: TextureRect
var fade_rect: ColorRect
var pause_panel: Control
var canvas: CanvasLayer
var ending_bg: Sprite2D


func _ready() -> void:
	get_window().content_scale_size = FASE00_PORTRAIT_SIZE if DeviceLayout12.is_portrait else FASE00_LANDSCAPE_SIZE
	body_font = load("res://assets/Fonts/Runtime/MedievalSharp-Book.ttf")
	title_font = load("res://assets/Fonts/Runtime/MedievalScrollOfWisdom.ttf")

	for room in ROOMS:
		room_by_id[String(room["id"])] = room

	_build_player()
	_build_ui()

	var watcher := PauseWatcher.new()
	add_child(watcher)
	watcher.toggle_requested.connect(_toggle_pause)

	_load_room("R00-01", false)


func _build_player() -> void:
	player = Fase00Player12.new()
	add_child(player)

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = CAMERA_SMOOTHING
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(NATIVE_SIZE.x)
	camera.limit_bottom = int(NATIVE_SIZE.y)
	player.add_child(camera)
	camera.make_current()


func _load_room(id: String, use_fade: bool) -> void:
	if not room_by_id.has(id) or transition_busy:
		return
	if use_fade:
		transition_busy = true
		await _fade_to(1.0, 0.18)
	_build_room(room_by_id[id])
	if use_fade:
		await get_tree().create_timer(0.08).timeout
		await _fade_to(0.0, 0.24)
		transition_busy = false


func _build_room(room: Dictionary) -> void:
	current_room = room
	if is_instance_valid(room_root):
		room_root.queue_free()
	room_root = Node2D.new()
	room_root.name = "Room_%s" % String(room["id"])
	add_child(room_root)
	move_child(room_root, 0)

	var bg := Sprite2D.new()
	bg.centered = false
	bg.texture = load(BG_DIR + String(room["background"]))
	room_root.add_child(bg)

	for rect in room["platforms"]:
		var body := StaticBody2D.new()
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		var r: Rect2 = rect
		rs.size = r.size
		cs.shape = rs
		cs.position = r.position + r.size * 0.5
		body.add_child(cs)
		room_root.add_child(body)

	interaction_root = Node2D.new()
	room_root.add_child(interaction_root)
	for raw in room["interactions"]:
		var marker := Marker2D.new()
		marker.position = raw["position"]
		marker.set_meta("interaction", raw)
		interaction_root.add_child(marker)

		var npc_key := String(raw.get("npc", ""))
		if NPC_STANDEE.has(npc_key):
			var cfg: Dictionary = NPC_STANDEE[npc_key]
			var standee := Sprite2D.new()
			standee.texture = load(NPC_DIR + String(cfg["tex"]))
			standee.position = marker.position + cfg["offset"]
			room_root.add_child(standee)

	var spawn: Vector2 = room["spawn_feet"]
	player.global_position = spawn
	player.respawn_position = spawn
	player.velocity = Vector2.ZERO
	camera.position = Vector2(0, float(room.get("camera_vertical_offset", -270.0)))

	room_title.text = "%s - %s" % [room["id"], room["name"]]
	objective_label.text = String(room["objective"])
	auto_trigger_guard = false


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	if transition_busy:
		return

	_update_camera_lookahead(delta)

	active_interaction = _find_nearest_interaction()
	prompt_panel.visible = not active_interaction.is_empty() and not dialogue_panel.visible
	if prompt_panel.visible:
		prompt_label.text = String(active_interaction.get("prompt", "INTERAGIR")).to_upper()

	_check_auto_interactions()

	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("attack"):
		if dialogue_panel.visible:
			_advance_dialogue()
		elif not active_interaction.is_empty():
			_execute_interaction(active_interaction)


func _update_camera_lookahead(delta: float) -> void:
	var target_x := CAMERA_LOOKAHEAD_X * player.facing
	camera.position.x = lerpf(camera.position.x, target_x, minf(1.0, delta * CAMERA_LOOKAHEAD_LERP))


func _find_nearest_interaction() -> Dictionary:
	if not is_instance_valid(interaction_root):
		return {}
	var best: Dictionary = {}
	var best_dist := INF
	for marker in interaction_root.get_children():
		var data: Dictionary = marker.get_meta("interaction")
		var id := String(data.get("id", ""))
		if bool(data.get("once", false)) and used_interactions.get(id, false):
			continue
		if bool(data.get("auto", false)):
			continue
		var dist: float = player.global_position.distance_to(marker.global_position)
		if dist <= float(data.get("radius", 90.0)) and dist < best_dist:
			best = data
			best_dist = dist
	return best


func _check_auto_interactions() -> void:
	if auto_trigger_guard or dialogue_panel.visible or not is_instance_valid(interaction_root):
		return
	for marker in interaction_root.get_children():
		var data: Dictionary = marker.get_meta("interaction")
		if not bool(data.get("auto", false)):
			continue
		var id := String(data.get("id", ""))
		if bool(data.get("once", false)) and used_interactions.get(id, false):
			continue
		var radius: float = float(data.get("auto_radius", data.get("radius", 90.0)))
		if player.global_position.distance_to(marker.global_position) <= radius:
			auto_trigger_guard = true
			_execute_interaction(data)
			return


func _execute_interaction(data: Dictionary) -> void:
	var req := String(data.get("requires", ""))
	if not req.is_empty() and not flags.get(req, false):
		_start_dialogue([["sistema", "", String(data.get("locked_message", "Ainda há algo que precisa ser resolvido antes de seguir."))]])
		return
	match String(data.get("type", "")):
		"dialogue":
			pending_dialogue_action = func(): _finish_interaction(data)
			_start_dialogue(data.get("lines", []))
		"transition":
			_load_room(String(data.get("target_room", "")), true)
		"item":
			_finish_interaction(data)
			_start_dialogue([["sistema", "", String(data.get("message", "Item obtido."))]])
		"ending":
			pending_dialogue_action = func(): _start_ending_sequence(data)
			_start_dialogue(data.get("lines", []))


func _finish_interaction(data: Dictionary) -> void:
	var flag := String(data.get("set_flag", ""))
	if not flag.is_empty():
		flags[flag] = true
	if bool(data.get("once", false)):
		used_interactions[String(data.get("id", ""))] = true


func _start_dialogue(lines: Array) -> void:
	if lines.is_empty():
		return
	dialogue_lines = lines
	dialogue_index = 0
	dialogue_panel.visible = true
	prompt_panel.visible = false
	player.input_enabled = false
	_refresh_dialogue()


func _refresh_dialogue() -> void:
	if dialogue_index >= dialogue_lines.size():
		_close_dialogue()
		return
	var line: Array = dialogue_lines[dialogue_index]
	var speaker_id := String(line[0])
	var expr := String(line[1])
	var text := String(line[2])

	dialogue_name.text = SPEAKER_NAME.get(speaker_id, speaker_id.to_upper())
	dialogue_text.text = text

	if speaker_id == "sistema" or expr.is_empty():
		dialogue_portrait.visible = false
	else:
		var path := "%s%s/%s.png" % [PORTRAIT_DIR, speaker_id, expr]
		if ResourceLoader.exists(path):
			dialogue_portrait.texture = load(path)
			dialogue_portrait.visible = true
		else:
			dialogue_portrait.visible = false


func _advance_dialogue() -> void:
	dialogue_index += 1
	_refresh_dialogue()


func _close_dialogue() -> void:
	dialogue_panel.visible = false
	player.input_enabled = true
	if pending_dialogue_action.is_valid():
		var cb := pending_dialogue_action
		pending_dialogue_action = Callable()
		cb.call()


## Beat de fundacao (DesignLock secao 2 e 3): depois da porta principal, o
## Cavaleiro passa pelo exterior da antiga empresa e chega ao escritorio
## inicial — nao sao salas jogaveis, so a mesma caixa de dialogo sobre uma
## imagem cheia, terminando em `_complete_phase()`.
func _start_ending_sequence(data: Dictionary) -> void:
	_finish_interaction(data)
	await _fade_to(1.0, 0.3)
	if is_instance_valid(room_root):
		room_root.visible = false
	if is_instance_valid(ending_bg):
		ending_bg.queue_free()
	# Os dois slides finais sao recortes menores que a arte de sala
	# (420x700/425x700, nao 1672x941) — centrados no mundo com a camera
	# solta dos limites da ultima sala, em vez de ancorados no canto
	# superior esquerdo como um fundo de sala normal. Precisa desgrudar a
	# camera do `player` primeiro: com `position_smoothing_enabled`, ela
	# recalcula a posicao a partir do proprio transform (pai + offset
	# local) todo frame — so travar `global_position` uma vez nao segura,
	# ela volta puxando pra perto do jogador no frame seguinte.
	camera.reparent(self)
	camera.limit_left = -100000
	camera.limit_top = -100000
	camera.limit_right = 100000
	camera.limit_bottom = 100000
	camera.position = Vector2.ZERO

	ending_bg = Sprite2D.new()
	ending_bg.centered = true
	ending_bg.texture = load(BG_DIR + "exterior_antiga_empresa.png")
	add_child(ending_bg)
	move_child(ending_bg, 0)
	await _fade_to(0.0, 0.3)

	pending_dialogue_action = func(): _show_office_slide()
	_start_dialogue([["sistema", "", "FASE 00 CONCLUÍDA — UMA NOVA EMPRESA COMEÇA."]])


func _show_office_slide() -> void:
	await _fade_to(1.0, 0.3)
	ending_bg.texture = load(BG_DIR + "escritorio_inicial.png")
	await _fade_to(0.0, 0.3)
	pending_dialogue_action = func(): _complete_phase()
	_start_dialogue([["cavaleiro", "neutro", "Agora só faltam clientes... e funcionários."]])


func _complete_phase() -> void:
	PartySelection12.prologue_cleared = true
	SaveSystem12.save_game()
	get_window().content_scale_size = DeviceLayout12.PORTRAIT_SIZE if DeviceLayout12.is_portrait else DeviceLayout12.LANDSCAPE_SIZE
	get_tree().change_scene_to_file(STAGE_SELECT_SCENE)


func _fade_to(alpha: float, seconds: float) -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade_rect, "modulate:a", alpha, seconds)
	await tween.finished


func _toggle_pause() -> void:
	if dialogue_panel.visible:
		return
	get_tree().paused = not get_tree().paused
	pause_panel.visible = get_tree().paused


## Toda a UI (HUD + dialogo + pausa + controles touch) construida em codigo,
## igual ao resto do projeto (nenhuma cena deste jogo pre-monta UI no
## .tscn — ver stage_select_12.tscn/platform_party_12.tscn). Dimensionada
## pro content_scale_size 1280x720/720x1280 desta fase, nao o 320x180
## padrao do resto do jogo.
func _build_ui() -> void:
	var is_portrait: bool = DeviceLayout12.is_portrait
	var size := Vector2(FASE00_PORTRAIT_SIZE) if is_portrait else Vector2(FASE00_LANDSCAPE_SIZE)

	canvas = CanvasLayer.new()
	add_child(canvas)

	room_title = Label.new()
	room_title.position = Vector2(24, 16)
	room_title.size = Vector2(size.x - 48, 32)
	# body_font, nao title_font: MedievalScrollOfWisdom.ttf nao tem o
	# glifo de "ã" (confirmado visualmente em "Recepção em Alerta" —
	# aparece um quadrado no lugar). MedievalSharp-Book.ttf ja e usado
	# pro objective_label logo abaixo com acentos normais.
	room_title.add_theme_font_override("font", body_font)
	room_title.add_theme_font_size_override("font_size", 20)
	room_title.add_theme_color_override("font_color", Color("ffe26f"))
	room_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	room_title.add_theme_constant_override("outline_size", 4)
	canvas.add_child(room_title)

	objective_label = Label.new()
	objective_label.position = Vector2(24, 54)
	objective_label.size = Vector2(size.x - 48, 24)
	objective_label.add_theme_font_override("font", body_font)
	objective_label.add_theme_font_size_override("font_size", 13)
	objective_label.add_theme_color_override("font_color", Color("d8e2f0"))
	objective_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	objective_label.add_theme_constant_override("outline_size", 3)
	canvas.add_child(objective_label)

	var prompt_w := 360.0 if not is_portrait else size.x - 80.0
	var prompt_btn := Button.new()
	prompt_btn.position = Vector2((size.x - prompt_w) * 0.5, size.y - (140.0 if is_portrait else 96.0))
	prompt_btn.size = Vector2(prompt_w, 44)
	CorporateUI12.style_button(prompt_btn, false, body_font, 13)
	prompt_btn.pressed.connect(func():
		if not active_interaction.is_empty():
			_execute_interaction(active_interaction))
	canvas.add_child(prompt_btn)
	prompt_panel = prompt_btn
	prompt_label = prompt_btn
	prompt_panel.visible = false

	var dlg_w: float = size.x - 80.0
	var dlg_h := 220.0 if not is_portrait else 320.0
	dialogue_panel = CorporateUI12.make_dialogue_panel()
	dialogue_panel.position = Vector2(40, size.y - dlg_h - 30.0)
	dialogue_panel.size = Vector2(dlg_w, dlg_h)
	dialogue_panel.visible = false
	canvas.add_child(dialogue_panel)

	dialogue_portrait = TextureRect.new()
	dialogue_portrait.position = Vector2(28, 66)
	dialogue_portrait.size = Vector2(140, 130)
	# expand_mode default (EXPAND_KEEP_SIZE) trava o minimum_size no
	# tamanho nativo da textura (443x443 pro cavaleiro!) e ignora o
	# `.size` explicito acima — IGNORE_SIZE e o que deixa o
	# STRETCH_KEEP_ASPECT_CENTERED de fato caber dentro da caixa pedida.
	dialogue_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dialogue_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dialogue_panel.add_child(dialogue_portrait)

	dialogue_name = Label.new()
	dialogue_name.position = Vector2(28, 22)
	dialogue_name.size = Vector2(dlg_w - 56, 36)
	dialogue_name.add_theme_font_override("font", title_font)
	dialogue_name.add_theme_font_size_override("font_size", 16)
	dialogue_name.add_theme_color_override("font_color", Color("ffe9b0"))
	dialogue_panel.add_child(dialogue_name)

	dialogue_text = Label.new()
	dialogue_text.position = Vector2(196, 66)
	dialogue_text.size = Vector2(dlg_w - 196 - 28, dlg_h - 90)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	dialogue_text.add_theme_font_override("font", body_font)
	dialogue_text.add_theme_font_size_override("font_size", 15)
	dialogue_text.add_theme_color_override("font_color", Color("1c1408"))
	dialogue_panel.add_child(dialogue_text)

	var advance_catcher := Button.new()
	advance_catcher.flat = true
	advance_catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	advance_catcher.focus_mode = Control.FOCUS_NONE
	advance_catcher.pressed.connect(func():
		if dialogue_panel.visible:
			_advance_dialogue())
	canvas.add_child(advance_catcher)
	canvas.move_child(advance_catcher, 0)

	pause_panel = _build_pause_panel(size)
	canvas.add_child(pause_panel)

	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 0.0
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(fade_rect)

	_build_touch_controls(canvas, size, is_portrait)


func _build_pause_panel(size: Vector2) -> Control:
	var panel := Control.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(dim)

	var label := Label.new()
	label.text = "PAUSADO\n\nESC para continuar"
	label.position = Vector2(0, size.y * 0.5 - 40)
	label.size = Vector2(size.x, 80)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", title_font)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color("ffe26f"))
	panel.add_child(label)

	return panel


## Botoes touch (left/right/jump) reaproveitando os mesmos icones de
## touch_controls_12.gd, so que reposicionados pro canvas 4x maior desta
## fase — as posicoes/escala daquele arquivo nao servem aqui.
func _build_touch_controls(layer: CanvasLayer, size: Vector2, is_portrait: bool) -> void:
	const ICON_DIR := "res://assets/UI/Runtime/TouchControls/"
	var buttons := [
		{"name": "left", "action": "move_left", "pos": Vector2(64, size.y - 200) if is_portrait else Vector2(64, 480)},
		{"name": "right", "action": "move_right", "pos": Vector2(200, size.y - 200) if is_portrait else Vector2(200, 480)},
		{"name": "jump", "action": "jump", "pos": Vector2(size.x - 140, size.y - 200) if is_portrait else Vector2(size.x - 140, 432)},
	]
	for cfg in buttons:
		var button := TouchScreenButton.new()
		button.texture_normal = load(ICON_DIR + cfg["name"] + "_normal.png")
		button.texture_pressed = load(ICON_DIR + cfg["name"] + "_pressed.png")
		button.action = cfg["action"]
		button.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
		button.position = cfg["pos"]
		button.scale = Vector2(4.6, 4.6)
		layer.add_child(button)
