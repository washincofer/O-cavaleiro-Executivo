extends Node2D

## Fase nova "Docas do Armazem", a partir do pacote de 11 backgrounds do
## usuario (l01_docas_recebimento.png .. l11_doca_grossmanobra.png, escala
## nativa 1672x941 — mesma da Fase 00). O usuario confirmou que e uma fase
## separada da "Operacoes & Logistica" (mundo continuo) ja existente, nao
## uma substituicao — os nomes de sala batem com aquela fase de proposito
## (mesma historia/vilao Grossmanobra), mas esta e a versao "por salas"
## com o motor da Fase 00 (background fixo + camera com look-ahead +
## transicao com fade), em vez de um mundo largo continuo.
##
## Mecanica nova pedida pelo usuario: escada vertical (W/S), sem diagonal
## ("igual jogo do Mario") — ver `DocasPlayer12`. O pulo nao muda.
##
## Escopo desta entrega inicial: travessia das 11 salas (piso, escadas
## verticais nas salas com arte de armazenagem vertical, checkpoints,
## transicoes) SEM inimigos/subchefe/chefe reais ainda — o pacote nao veio
## com sprites de inimigo novos pra essa fase. L06 (Arena do Estevao) e L11
## (Doca do Grossmanobra) tem so um beat de dialogo marcando o confronto,
## mesmo padrao que a propria Fase 00 usou pra ficar "sem inimigos, conforme
## solicitado" na primeira entrega e ganhar combate depois.

const NATIVE_SIZE := Vector2(1672, 941)
const LANDSCAPE_SIZE := Vector2i(1280, 720)
const PORTRAIT_SIZE := Vector2i(720, 1280)
const BG_DIR := "res://assets/Backgrounds/Runtime/FaseLogistica/"
const STAGE_SELECT_SCENE := "res://scenes/menu/stage_select_12.tscn"
const PauseWatcher := preload("res://scripts/playtest/pause_watcher_12.gd")
const DocasPlayer := preload("res://scripts/playtest/docas_player_12.gd")

const CAMERA_LOOKAHEAD_X := 86.0
const CAMERA_LOOKAHEAD_LERP := 5.5
const CAMERA_SMOOTHING := 7.5

# Piso principal ocupa a faixa inferior das 11 artes (mesmo criterio da
# Fase 00: guia aproximado, nao pixel-exato). Escadas verticais (W/S) sao
# so nas salas cuja arte mostra armazenagem em varios andares — conteudo
# opcional, a rota obrigatoria e toda no piso.
const FLOOR := Rect2(0, 800, 1672, 141)

const ROOMS := [
	{
		"id": "L01", "name": "Docas de Recebimento",
		"objective": "Atravesse as docas de recebimento.",
		"background": "l01_docas_recebimento.png",
		"spawn_feet": Vector2(60, 800), "camera_vertical_offset": -260.0,
		"platforms": [FLOOR, Rect2(1000, 400, 180, 22)],
		"ladders": [Rect2(1080, 420, 24, 380)],
		"interactions": [
			{"id": "saida_l01", "type": "transition", "position": Vector2(1600, 750),
				"radius": 100.0, "prompt": "Avancar para a triagem", "target_room": "L02"},
		],
	},
	{
		"id": "L02", "name": "Triagem",
		"objective": "Passe pela area de triagem.",
		"background": "l02_triagem.png",
		"spawn_feet": Vector2(60, 800), "camera_vertical_offset": -260.0,
		"platforms": [FLOOR],
		"ladders": [],
		"interactions": [
			{"id": "saida_l02", "type": "transition", "position": Vector2(1600, 750),
				"radius": 100.0, "prompt": "Avancar para a separacao", "target_room": "L03"},
		],
	},
	{
		"id": "L03", "name": "Separacao e Conferencia",
		"objective": "Confira a carga e siga em frente.",
		"background": "l03_separacao_conferencia.png",
		"spawn_feet": Vector2(60, 800), "camera_vertical_offset": -260.0,
		"platforms": [FLOOR],
		"ladders": [],
		"interactions": [
			{"id": "saida_l03", "type": "transition", "position": Vector2(1600, 750),
				"radius": 100.0, "prompt": "Avancar para a armazenagem", "target_room": "L04"},
		],
	},
	{
		"id": "L04", "name": "Armazenagem Vertical",
		"objective": "Suba pelas prateleiras do armazem.",
		"background": "l04_armazenagem_vertical.png",
		"spawn_feet": Vector2(60, 800), "camera_vertical_offset": -320.0,
		"platforms": [FLOOR, Rect2(760, 460, 220, 22)],
		"ladders": [Rect2(860, 480, 24, 320)],
		"interactions": [
			{"id": "saida_l04", "type": "transition", "position": Vector2(1600, 750),
				"radius": 100.0, "prompt": "Avancar para a linha de operacoes", "target_room": "L05"},
		],
	},
	{
		"id": "L05", "name": "Linha de Operacoes",
		"objective": "Siga a linha de producao.",
		"background": "l05_linha_operacoes.png",
		"spawn_feet": Vector2(60, 800), "camera_vertical_offset": -260.0,
		"platforms": [FLOOR],
		"ladders": [],
		"interactions": [
			{"id": "saida_l05", "type": "transition", "position": Vector2(1600, 750),
				"radius": 100.0, "prompt": "Avancar para a arena do Estevao", "target_room": "L06"},
		],
	},
	{
		"id": "L06", "name": "Arena do Estevao",
		"objective": "Enfrente o Especialista de Seguranca Estevao.",
		"background": "l06_arena_estevao.png",
		"spawn_feet": Vector2(60, 800), "camera_vertical_offset": -260.0,
		"platforms": [FLOOR],
		"ladders": [],
		"interactions": [
			{"id": "confronto_estevao", "type": "dialogue", "position": Vector2(830, 750),
				"radius": 150.0, "once": true, "auto": true, "auto_radius": 130.0,
				"checkpoint_after": true, "set_flag": "estevao_confrontado",
				"lines": [
					["sistema", "", "O Especialista de Seguranca Estevao bloqueia a passagem."],
					["cavaleiro", "bravo", "Vou anotar isso no relatorio de incidentes."],
				]},
			{"id": "saida_l06", "type": "transition", "position": Vector2(1600, 750),
				"radius": 100.0, "prompt": "Seguir para o nucleo do armazem",
				"requires": "estevao_confrontado",
				"locked_message": "O Estevao ainda esta no caminho.",
				"target_room": "L07"},
		],
	},
	{
		"id": "L07", "name": "Nucleo do Armazem",
		"objective": "Atravesse o nucleo do armazem.",
		"background": "l07_nucleo_armazem.png",
		"spawn_feet": Vector2(60, 800), "camera_vertical_offset": -320.0,
		"platforms": [FLOOR, Rect2(700, 460, 220, 22)],
		"ladders": [Rect2(800, 480, 24, 320)],
		"interactions": [
			{"id": "saida_l07", "type": "transition", "position": Vector2(1600, 750),
				"radius": 100.0, "prompt": "Entrar no deposito de retencao", "target_room": "L08"},
		],
	},
	{
		"id": "L08", "name": "Deposito de Retencao",
		"objective": "Sala de retencao — atravesse com cuidado.",
		"background": "l08_deposito_retencao.png",
		"spawn_feet": Vector2(60, 800), "camera_vertical_offset": -260.0,
		"platforms": [FLOOR],
		"ladders": [],
		"interactions": [
			{"id": "saida_l08", "type": "transition", "position": Vector2(1600, 750),
				"radius": 100.0, "prompt": "Avancar para a expedicao pesada", "target_room": "L09"},
		],
	},
	{
		"id": "L09", "name": "Expedicao Pesada",
		"objective": "Passe pela expedicao de carga pesada.",
		"background": "l09_expedicao_pesada.png",
		"spawn_feet": Vector2(60, 800), "camera_vertical_offset": -300.0,
		"platforms": [FLOOR, Rect2(1180, 500, 200, 22)],
		"ladders": [Rect2(1260, 520, 24, 280)],
		"interactions": [
			{"id": "saida_l09", "type": "transition", "position": Vector2(1600, 750),
				"radius": 100.0, "prompt": "Avancar para a doca central", "target_room": "L10"},
		],
	},
	{
		"id": "L10", "name": "Doca Central",
		"objective": "Atravesse a doca central.",
		"background": "l10_doca_central.png",
		"spawn_feet": Vector2(60, 800), "camera_vertical_offset": -300.0,
		"platforms": [FLOOR, Rect2(120, 500, 200, 22)],
		"ladders": [Rect2(160, 520, 24, 280)],
		"interactions": [
			{"id": "checkpoint_l10", "type": "dialogue", "position": Vector2(300, 750),
				"radius": 130.0, "once": true, "auto": true, "auto_radius": 110.0,
				"checkpoint_after": true,
				"lines": [
					["cavaleiro", "serio", "A doca do Grossmanobra fica logo ali."],
				]},
			{"id": "saida_l10", "type": "transition", "position": Vector2(1600, 750),
				"radius": 100.0, "prompt": "Entrar na doca do Grossmanobra", "target_room": "L11"},
		],
	},
	{
		"id": "L11", "name": "Doca do Grossmanobra",
		"objective": "Confronte Danelmo Grossmanobra.",
		"background": "l11_doca_grossmanobra.png",
		"spawn_feet": Vector2(60, 800), "camera_vertical_offset": -260.0,
		"platforms": [FLOOR],
		"ladders": [],
		"interactions": [
			{"id": "confronto_grossmanobra", "type": "ending", "position": Vector2(836, 750),
				"radius": 170.0, "once": true,
				"lines": [
					["cavaleiro", "serio", "Grossmanobra."],
					["cavaleiro", "bravo", "Dessa vez o relatorio de desempenho e meu."],
				]},
		],
	},
]

var room_by_id: Dictionary = {}
var current_room: Dictionary = {}
var player: DocasPlayer
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
var checkpoint_room_id := "L01"
var body_font: Font
var title_font: Font
var debug_draw := false

var room_title: Label
var objective_label: Label
var prompt_panel: Control
var prompt_label: Button
var dialogue_panel: Control
var dialogue_name: Label
var dialogue_text: Label
var fade_rect: ColorRect
var pause_panel: Control
var canvas: CanvasLayer
var debug_overlay: Node2D


func _ready() -> void:
	get_window().content_scale_size = PORTRAIT_SIZE if DeviceLayout12.is_portrait else LANDSCAPE_SIZE
	body_font = load("res://assets/Fonts/Runtime/MedievalSharp-Book.ttf")
	title_font = load("res://assets/Fonts/Runtime/MedievalScrollOfWisdom.ttf")

	for room in ROOMS:
		room_by_id[String(room["id"])] = room

	_build_player()
	_build_ui()

	var watcher := PauseWatcher.new()
	add_child(watcher)
	watcher.toggle_requested.connect(_toggle_pause)

	_load_room("L01", false)


func _build_player() -> void:
	player = DocasPlayer.new()
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


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.physical_keycode == KEY_F1:
		debug_draw = not debug_draw
		if is_instance_valid(debug_overlay):
			debug_overlay.visible = debug_draw
	elif event.physical_keycode == KEY_R and not get_tree().paused:
		_load_room(current_room.get("id", "L01"), false)


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

	var platform_list: Array = room["platforms"]
	for i in range(platform_list.size()):
		var body := StaticBody2D.new()
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		var r: Rect2 = platform_list[i]
		rs.size = r.size
		cs.shape = rs
		cs.position = r.position + r.size * 0.5
		if i > 0:
			cs.one_way_collision = true
			cs.one_way_collision_margin = 6.0
		body.add_child(cs)
		room_root.add_child(body)

	var ladders: Array = room.get("ladders", [])
	player.set_meta("ladders", ladders)

	debug_overlay = Node2D.new()
	debug_overlay.visible = debug_draw
	debug_overlay.draw.connect(_draw_debug.bind(debug_overlay, platform_list, ladders))
	room_root.add_child(debug_overlay)
	debug_overlay.queue_redraw()

	interaction_root = Node2D.new()
	room_root.add_child(interaction_root)
	for raw in room["interactions"]:
		var marker := Marker2D.new()
		marker.position = raw["position"]
		marker.set_meta("interaction", raw)
		interaction_root.add_child(marker)

	var spawn: Vector2 = room["spawn_feet"]
	player.global_position = spawn
	player.respawn_position = spawn
	player.velocity = Vector2.ZERO
	player.on_ladder = false
	camera.position = Vector2(0, float(room.get("camera_vertical_offset", -270.0)))

	room_title.text = "%s - %s" % [room["id"], room["name"]]
	objective_label.text = String(room["objective"])
	auto_trigger_guard = false


func _draw_debug(overlay: Node2D, platform_list: Array, ladders: Array) -> void:
	for rect in platform_list:
		overlay.draw_rect(rect, Color(0.2, 1.0, 0.3, 0.35), true)
		overlay.draw_rect(rect, Color(0.2, 1.0, 0.3, 0.9), false, 2.0)
	for rect in ladders:
		overlay.draw_rect(rect, Color(1.0, 0.85, 0.2, 0.35), true)
		overlay.draw_rect(rect, Color(1.0, 0.85, 0.2, 0.9), false, 2.0)


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_update_camera(delta)
	_update_interactions()


func _update_camera(delta: float) -> void:
	# Camera e filha do player (posicao local, nao mundo) — o lookahead e
	# so um pequeno deslocamento pra frente do personagem, igual
	# `platform_fase00_12.gd:_update_camera_lookahead`. O enquadramento
	# dentro dos limites da sala e feito pelo `camera.limit_*` (Camera2D
	# aplica isso sozinho por cima da posicao local).
	var target_x := CAMERA_LOOKAHEAD_X * player.facing
	camera.position.x = lerpf(camera.position.x, target_x, minf(1.0, delta * CAMERA_LOOKAHEAD_LERP))


func _nearest_interaction() -> Marker2D:
	if not is_instance_valid(interaction_root):
		return null
	var best: Marker2D = null
	var best_dist := INF
	for child in interaction_root.get_children():
		var marker := child as Marker2D
		if marker == null:
			continue
		var raw: Dictionary = marker.get_meta("interaction")
		var id := String(raw["id"])
		if raw.get("once", false) and used_interactions.has(id):
			continue
		var dist := marker.position.distance_to(player.global_position)
		var radius: float = raw.get("radius", 90.0)
		if dist <= radius and dist < best_dist:
			best = marker
			best_dist = dist
	return best


func _update_interactions() -> void:
	if dialogue_panel.visible:
		return
	var marker := _nearest_interaction()
	if marker == null:
		prompt_panel.visible = false
		return
	var raw: Dictionary = marker.get_meta("interaction")
	if raw.get("auto", false) and not auto_trigger_guard:
		auto_trigger_guard = true
		_trigger_interaction(raw)
		return
	if raw.get("auto", false):
		prompt_panel.visible = false
		return
	var req: String = raw.get("requires", "")
	if req != "" and not flags.get(req, false):
		prompt_panel.visible = true
		prompt_label.text = String(raw.get("locked_message", "Requisito pendente."))
		if Input.is_action_just_pressed("interact"):
			pass
		return
	prompt_panel.visible = true
	prompt_label.text = String(raw.get("prompt", "Interagir"))
	if Input.is_action_just_pressed("interact"):
		_trigger_interaction(raw)


func _trigger_interaction(raw: Dictionary) -> void:
	var id := String(raw["id"])
	match String(raw.get("type", "")):
		"dialogue":
			active_interaction = raw
			dialogue_lines = raw.get("lines", [])
			dialogue_index = 0
			pending_dialogue_action = Callable(self, "_finish_dialogue_interaction")
			_show_dialogue_line()
		"transition":
			used_interactions[id] = true
			_load_room(String(raw["target_room"]), true)
		"ending":
			active_interaction = raw
			dialogue_lines = raw.get("lines", [])
			dialogue_index = 0
			pending_dialogue_action = Callable(self, "_finish_and_go_to_stage_select")
			_show_dialogue_line()


func _finish_dialogue_interaction() -> void:
	var raw := active_interaction
	var id := String(raw["id"])
	if raw.get("once", false):
		used_interactions[id] = true
	var flag: String = raw.get("set_flag", "")
	if flag != "":
		flags[flag] = true
	if raw.get("checkpoint_after", false):
		checkpoint_room_id = String(current_room["id"])
		SaveSystem12.save_game()
	dialogue_panel.visible = false
	get_tree().paused = false


func _show_dialogue_line() -> void:
	get_tree().paused = true
	dialogue_panel.visible = true
	var line: Array = dialogue_lines[dialogue_index]
	var speaker := String(line[0])
	dialogue_name.text = speaker.to_upper()
	dialogue_text.text = String(line[2])


func _unhandled_input(event: InputEvent) -> void:
	if dialogue_panel.visible and (event.is_action_pressed("interact") or event.is_action_pressed("jump") or (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed)):
		dialogue_index += 1
		if dialogue_index >= dialogue_lines.size():
			pending_dialogue_action.call()
		else:
			_show_dialogue_line()


func _finish_and_go_to_stage_select() -> void:
	dialogue_panel.visible = false
	get_tree().paused = false
	SaveSystem12.save_game()
	get_window().content_scale_size = Vector2i(320, 180)
	get_tree().change_scene_to_file(STAGE_SELECT_SCENE)


func _fade_to(alpha: float, duration: float) -> void:
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", alpha, duration)
	await tw.finished


func _toggle_pause() -> void:
	pause_panel.visible = not pause_panel.visible
	get_tree().paused = pause_panel.visible


func _build_ui() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)

	room_title = Label.new()
	room_title.add_theme_font_override("font", title_font)
	room_title.add_theme_font_size_override("font_size", 22)
	room_title.add_theme_color_override("font_color", Color("f0c85a"))
	room_title.position = Vector2(20, 14)
	canvas.add_child(room_title)

	objective_label = Label.new()
	objective_label.add_theme_font_override("font", body_font)
	objective_label.add_theme_font_size_override("font_size", 15)
	objective_label.add_theme_color_override("font_color", Color("d8d8d8"))
	objective_label.position = Vector2(20, 44)
	canvas.add_child(objective_label)

	prompt_panel = Control.new()
	prompt_panel.visible = false
	prompt_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_panel.position = Vector2(-160, -90)
	prompt_panel.size = Vector2(320, 40)
	canvas.add_child(prompt_panel)
	prompt_label = Button.new()
	prompt_label.disabled = true
	prompt_label.size = Vector2(320, 40)
	prompt_label.add_theme_font_override("font", body_font)
	prompt_panel.add_child(prompt_label)

	dialogue_panel = Control.new()
	dialogue_panel.visible = false
	dialogue_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dialogue_panel.position = Vector2(-420, -180)
	dialogue_panel.size = Vector2(840, 150)
	canvas.add_child(dialogue_panel)
	var dp_bg := ColorRect.new()
	dp_bg.color = Color(0.05, 0.06, 0.1, 0.92)
	dp_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialogue_panel.add_child(dp_bg)
	dialogue_name = Label.new()
	dialogue_name.add_theme_font_override("font", title_font)
	dialogue_name.add_theme_font_size_override("font_size", 18)
	dialogue_name.add_theme_color_override("font_color", Color("f0c85a"))
	dialogue_name.position = Vector2(20, 14)
	dialogue_panel.add_child(dialogue_name)
	dialogue_text = Label.new()
	dialogue_text.add_theme_font_override("font", body_font)
	dialogue_text.add_theme_font_size_override("font_size", 16)
	dialogue_text.add_theme_color_override("font_color", Color("e8e8e8"))
	dialogue_text.position = Vector2(20, 46)
	dialogue_text.size = Vector2(800, 90)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	dialogue_panel.add_child(dialogue_text)

	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 0.0
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(fade_rect)

	pause_panel = Control.new()
	pause_panel.visible = false
	pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(pause_panel)
	var pp_bg := ColorRect.new()
	pp_bg.color = Color(0, 0, 0, 0.72)
	pp_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_panel.add_child(pp_bg)
	var pp_label := Label.new()
	pp_label.text = "PAUSADO\nA/D — mover | Espaco — pular\nW/S — subir/descer escada\nE/Enter — interagir | F1 — colisoes | R — reiniciar sala\nESC — continuar"
	pp_label.add_theme_font_override("font", body_font)
	pp_label.add_theme_font_size_override("font_size", 16)
	pp_label.add_theme_color_override("font_color", Color("f0f0f0"))
	pp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pp_label.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.add_child(pp_label)
