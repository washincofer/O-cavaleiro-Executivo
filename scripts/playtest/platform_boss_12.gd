extends Node2D

## Sprint 13/14: fase da boss fight (fundo craftpix post-apocaliptico), estilo
## Super Kirby Clash — uma sala unica (sem scroll) onde o trio selecionado
## enfrenta um unico inimigo gigante, o NECROMANTE (pack "Necromancer").
##
## Mecanica do boss: a cada poucos segundos o boss entra em "windup" (aviso
## visual + textual) antes de um impacto em area. Ativar a habilidade
## especial (H) de QUALQUER personagem do grupo durante o windup interrompe
## o golpe e causa dano bonus — reaproveita a mesma tecla/mecanica unica de
## cada categoria (Estocada/Rajada, Tiro Perfurante, Teleporte) sem precisar
## de logica especifica por personagem.
##
## Deriva da estrutura de platform_party_12.gd (party/camera/seguidores/
## HUD/pausa), mas e um arquivo proprio (convencao das sprints anteriores:
## cada fase mantem seu controller independente) com um mundo bem menor
## (sala unica) e sem o puzzle de portao/interruptor.
##
## Sprint 16: primeira das 5 salas de boss convertida pro padrao retrato/
## paisagem, ponta a ponta (mundo + HUD + pausa). Ao contrario das telas de
## menu, aqui a sala ENCOLHE de verdade em retrato (world_width vira var,
## 320 em paisagem / 180 em retrato) em vez de so reposicionar — afastar a
## camera encolheria os sprites, que ja estao no limite de legibilidade num
## celular. `is_portrait` e lido uma unica vez em `_ready()` e ignorado
## depois (girar o celular no meio da luta nao reconstroi o mundo).
##
## Descoberta durante a implementacao, nao prevista no plano original: com
## `content_scale_size` em 180x320, a camera (zoom 1) passa a mostrar 320
## unidades de MUNDO na vertical, nao mais as 180 do design original — sem
## ajuste, sobraria ~140px de "vazio" abaixo do chao. A solucao: a camera
## fica fixa (sem pan horizontal, a sala cabe inteira nos 180px de largura)
## e sua posicao vertical revela ~110px extras de ceu ACIMA da sala (nunca
## abaixo — o chao/vao continuam exatamente onde a fisica ja espera),
## preenchidos por um degrade solido extraido do topo do proprio fundo
## (`_add_sky_fill_portrait`) em vez de deixar transparencia visivel.
##
## O HUD e o menu de pausa em retrato usam o helper compartilhado
## `BossHudPortrait12` (mesmo chrome nas 5 salas) — so a geometria do MUNDO
## (chao/vao/spawn/SLAM_RADIUS) continua especifica deste arquivo.

const Actor = preload("res://scripts/playtest/platform_actor_12.gd")
const Projectile = preload("res://scripts/playtest/platform_projectile_12.gd")
const PauseWatcher = preload("res://scripts/playtest/pause_watcher_12.gd")
const InterludeWatcher = preload("res://scripts/playtest/interlude_watcher_12.gd")
const HEALTH_BAR_TEX := preload("res://assets/UI/Runtime/MedievalFree/health_bar.png")
const TouchControls = preload("res://scenes/playtest/touch_controls_12.tscn")
const STAGE_SELECT_SCENE := "res://scenes/menu/stage_select_12.tscn"
const VICTORY_CUTSCENE_SCENE := "res://scenes/menu/victory_cutscene_12.tscn"
const PORTRAIT_DIR := "res://assets/UI/Runtime/Dialogue/"
const CAVALEIRO_ID := "cavaleiro"
const COORDENADOR_ID := "coordenador"

const WORLD_WIDTH_LANDSCAPE := 320.0
const WORLD_WIDTH_PORTRAIT := 180.0
const DEATH_Y := 210.0
const GROUND_TOP := 150.0
const RUINS_BG_PATH := "res://assets/Environment/Ruins/Runtime/ruins_bg.png"

var world_width := WORLD_WIDTH_LANDSCAPE
var is_portrait := false
var camera_half_width := 160.0
var camera_y := 90.0

var actors: Array[Actor] = []
var enemies: Array[Actor] = []
var party_slots: Array[Actor] = []
var active_actor: Actor = null
var active_party_slot := 0
var active_enemies := 0
var total_enemies := 0

var world_layer: Node2D
var actor_layer: Node2D
var projectile_layer: Node2D
var camera: Camera2D

var state_label: Label
var party_label: Label
var objective_label: Label
var event_label: Label
var hp_bars: Array = []
var event_timeout := 0.0
var completed := false
var game_over := false

var pause_layer: CanvasLayer
var is_paused := false

# Referenciados por metodos herdados da mesma familia de scripts (chamados
# a partir de platform_actor_12.gd para warrior/fire_mage); nesta fase nunca
# sao populados, entao os metodos que os usam permanecem inofensivos no-ops.
var rubble_body: StaticBody2D
var rubble_visual: ColorRect
var rubble_broken := false

var boss_actor: Actor = null
var boss_name_label: Label
var boss_bar_bg: NinePatchRect
var boss_bar_empty: ColorRect
var boss_bar_pos := Vector2(70, 21)
var boss_bar_size := Vector2(180, 8)

const SLAM_INTERVAL := 5.0
const SLAM_WINDUP_TIME := 1.3
const SLAM_STAGGER_TIME := 2.5
const SLAM_RADIUS_LANDSCAPE := 74.0
# Sala em retrato encolhe de 320 pra 180 de largura (boss centralizado em
# x=90 em vez de x=210) — raio igual ao da paisagem cobriria quase a sala
# inteira dos dois lados, tirando a opcao de recuar em vez de interromper
# com H. Reduzido pra deixar ~30px de margem de fuga ate a parede mais
# proxima mesmo em pé ao lado do boss.
const SLAM_RADIUS_PORTRAIT := 60.0
const INTERRUPT_BONUS_DAMAGE := 6
var slam_radius := SLAM_RADIUS_LANDSCAPE
var slam_timer := 3.0
var slam_windup := 0.0

# Pedido do usuario: o NECROMANTE tem a vida dividida em 3 partes — ao
# esgotar cada uma (menos a ultima), a luta pausa, o cenario de fundo troca
# (o "escopo"/prioridade mudou) e um dialogo estilo visual novel interrompe
# o combate antes de continuar. PHASE_HP_RATIOS[0] = limiar pra sair da fase
# 1 (100%-66%) pra fase 2; [1] = limiar da fase 2 (66%-33%) pra fase 3
# (33%-0%, sem mais interludios depois).
var bg_sprite: Sprite2D
var current_phase := 1
var phase_interlude_active := false
const PHASE_HP_RATIOS := [2.0 / 3.0, 1.0 / 3.0]
const PHASE_BACKGROUNDS := [
	RUINS_BG_PATH,
	"res://assets/Environment/Cemetery/Runtime/cemetery_bg.png",
	"res://assets/Environment/StarryNight/Runtime/starry_night_bg.png",
]

# Piada pedida pelo usuario: o Coordenador "vibe codou" um app num fim de
# semana e agora empurra a manutencao pro time de Sistemas, terminando numa
# risada maligna — isso acontece assim que a PRIMEIRA parte da barra de vida
# esgota. A segunda troca de fase e outra "mudanca de escopo" corporativa,
# sem relacao com a primeira (nao e uma continuacao da mesma piada).
const PHASE_INTERLUDES := [
	[
		{"speaker": "coordenador", "expr": "risada", "text": "Espera, espera, pausa a luta. Lembra daquele app que eu 'vibe codei' num fim de semana inteiro so no papo com a IA?"},
		{"speaker": "coordenador", "expr": "neutro", "text": "Subiu pra producao numa sexta as 18h. Ninguem revisou o codigo. Ninguem escreveu um teste sequer."},
		{"speaker": "cavaleiro", "expr": "duvida", "text": "E quem ficou de manter aquilo depois que quebrasse?"},
		{"speaker": "coordenador", "expr": "bravo", "text": "OTIMA pergunta. Resposta: NAO EU. ISSO AGORA E PROBLEMA DO TIME DE SISTEMAS!"},
		{"speaker": "coordenador", "expr": "grito", "text": "MUAHAHAHAHA! Que eles se virem com o meu 'MVP' em producao! Prioridade mudou, Cavaleiro — agora e a vez deles sofrerem."},
		{"speaker": "coordenador", "expr": "serio", "text": "Alias, falando em prioridade: a SUA tambem mudou de escopo. Nova sprint, mesmo Necromante. De volta ao combate."},
	],
	[
		{"speaker": "coordenador", "expr": "tenso", "text": "Ainda de pe? Impressionante. Bem, mais novidade fresca: reorganizaram o organograma DE NOVO."},
		{"speaker": "coordenador", "expr": "duvida", "text": "Meu cargo agora e 'Coordenador de Transformacao Digital'. Ninguem sabe o que isso significa. Nem eu."},
		{"speaker": "cavaleiro", "expr": "serio", "text": "Isso muda alguma coisa nesta luta?"},
		{"speaker": "coordenador", "expr": "bravo", "text": "Muda o ESCOPO! Sua nova prioridade e sobreviver a REUNIAO DE ALINHAMENTO que eu vou convocar AGORA MESMO."},
		{"speaker": "coordenador", "expr": "grito", "text": "SEM PAUTA. SEM HORARIO PRA ACABAR. TODOS OS STAKEHOLDERS. VAMOS."},
		{"speaker": "cavaleiro", "expr": "bravo", "text": "Prefiro apanhar de zumbi corporativo a entrar numa reuniao sem pauta. Vamos terminar isso."},
	],
]

var interlude_layer: CanvasLayer
var interlude_lines: Array = []
var interlude_line_index := 0
var interlude_portrait_left: Control
var interlude_portrait_right: Control
var interlude_name_label: Label
var interlude_text_label: Label

func _ready() -> void:
	is_portrait = DeviceLayout12.is_portrait
	if is_portrait:
		world_width = WORLD_WIDTH_PORTRAIT
		camera_half_width = world_width / 2.0
		camera_y = DEATH_Y - 160.0
		slam_radius = SLAM_RADIUS_PORTRAIT
	else:
		world_width = WORLD_WIDTH_LANDSCAPE
		camera_half_width = 160.0
		camera_y = 90.0
		slam_radius = SLAM_RADIUS_LANDSCAPE
	_build_world()
	_spawn_party()
	_spawn_enemies()
	_build_hud()
	_build_pause_menu()
	_build_pause_watcher()
	_set_active_party_slot(0, false)
	_update_hud()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
		return

	if game_over:
		_update_hud()
		return

	_handle_party_selection()
	_check_falls()
	_update_camera()

	if is_instance_valid(boss_actor) and boss_actor.alive:
		_update_boss_slam(delta)
		_check_boss_phase_transition()

	if event_timeout > 0.0:
		event_timeout -= delta
		if event_timeout <= 0.0 and is_instance_valid(event_label):
			event_label.text = ""

	if not completed and active_enemies <= 0 and total_enemies > 0:
		completed = true
		report_event("VITORIA — O NECROMANTE FOI DESTRUIDO")
		_handle_victory_reward()

	_update_hud()

func _handle_victory_reward() -> void:
	# Sprint 15: fases sem `stage_reward_role` (Ruinas incluida — Paladino/
	# Cavaleiro ja sao liberados pelas fases novas) mantem o fluxo antigo,
	# sem cutscene automatica: o jogador sai pelo ESC/"VOLTAR A SELECAO" ou
	# reinicia com R, como antes desta sprint.
	var reward: String = PartySelection12.stage_reward_role
	if reward == "" or not PartySelection12.unlock_role(reward):
		return
	PartySelection12.last_unlocked_role = reward
	get_tree().create_timer(2.2).timeout.connect(_go_to_victory_cutscene)

func _go_to_victory_cutscene() -> void:
	get_tree().change_scene_to_file(VICTORY_CUTSCENE_SCENE)

func _handle_party_selection() -> void:
	if Input.is_action_just_pressed("select_party_1"):
		_set_active_party_slot(0)
	elif Input.is_action_just_pressed("select_party_2"):
		_set_active_party_slot(1)
	elif Input.is_action_just_pressed("select_party_3"):
		_set_active_party_slot(2)

func _set_active_party_slot(slot: int, announce := true) -> bool:
	if slot < 0 or slot >= party_slots.size():
		return false

	var next_actor: Actor = party_slots[slot]
	if not is_instance_valid(next_actor) or not next_actor.alive:
		if announce:
			report_event("SLOT %d indisponivel" % [slot + 1])
		return false

	for member in party_slots:
		if is_instance_valid(member) and member.alive:
			member.set_controlled(false)

	active_party_slot = slot
	active_actor = next_actor
	active_actor.set_controlled(true)

	if announce:
		report_event("CONTROLE -> %d %s" % [slot + 1, active_actor.actor_name])
	return true

func _handoff_from_slot(dead_slot: int) -> void:
	for step in range(1, party_slots.size() + 1):
		var candidate_slot: int = (dead_slot + step) % party_slots.size()
		var candidate: Actor = party_slots[candidate_slot]
		if is_instance_valid(candidate) and candidate.alive:
			_set_active_party_slot(candidate_slot, false)
			report_event("AUTO HANDOFF -> %d %s" % [candidate_slot + 1, candidate.actor_name])
			return

	active_actor = null
	game_over = true
	report_event("GAME OVER — todos os membros foram derrotados")

func get_active_actor() -> Actor:
	return active_actor

func activate_actor_action(actor: Actor) -> void:
	if actor != active_actor or not actor.alive:
		return

	if actor.is_ranged:
		if actor.activate_ranged_attack():
			report_event("%s: ATAQUE A DISTANCIA" % actor.actor_name)
		else:
			report_event("%s: em recarga" % actor.actor_name)
	else:
		if actor.melee_attack():
			report_event("%s: ATAQUE" % actor.actor_name)
		else:
			report_event("%s: em recarga" % actor.actor_name)

func activate_actor_special(actor: Actor) -> void:
	if actor != active_actor or not actor.alive:
		return
	if not actor.activate_special():
		report_event("%s: habilidade em recarga" % actor.actor_name)
		return
	match actor.role:
		"warrior", "knight", "cavaleiro_executivo":
			report_event("%s: ESTOCADA" % actor.actor_name)
		"archer", "lightning_mage":
			report_event("%s: TIRO PERFURANTE" % actor.actor_name)
		"mage", "wanderer":
			report_event("%s: CONJURANDO TELEPORTE" % actor.actor_name)
		"fire_mage", "paladin":
			report_event("%s: RAJADA DE FOGO" % actor.actor_name)
		"bridge_heroine":
			report_event("%s: INVOCA PONTE" % actor.actor_name)
	_try_interrupt_slam(actor)

func melee_attack_from(source: Actor) -> bool:
	var victim: Actor = _nearest_enemy_in_range(source.global_position, 38.0, 30.0)
	if is_instance_valid(victim):
		victim.take_damage(1, source)
		return true
	return false

func spawn_party_projectile(owner_actor: Actor, direction: Vector2, kind: String) -> void:
	var projectile := Projectile.new()
	projectile_layer.add_child(projectile)
	projectile.global_position = owner_actor.global_position + Vector2(owner_actor.facing * 13.0, -12.0)
	projectile.setup(self, owner_actor, direction, kind)

func try_projectile_hit(projectile: Projectile, owner_actor: Actor) -> bool:
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.alive:
			continue
		if projectile.global_position.distance_to(enemy.global_position + Vector2(0, -7)) <= 15.0:
			enemy.take_damage(1, owner_actor)
			return true
	return false

func _nearest_enemy_in_range(origin: Vector2, max_x: float, max_y: float) -> Actor:
	var result: Actor = null
	var best := INF
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.alive:
			continue
		var delta: Vector2 = enemy.global_position - origin
		if absf(delta.x) <= max_x and absf(delta.y) <= max_y:
			var d: float = delta.length_squared()
			if d < best:
				best = d
				result = enemy
	return result

func closest_alive_ally(_source = null) -> Actor:
	if is_instance_valid(active_actor) and active_actor.alive:
		return active_actor
	for member in party_slots:
		if is_instance_valid(member) and member.alive:
			return member
	return null

func _check_falls() -> void:
	for actor in actors:
		if not is_instance_valid(actor) or not actor.alive or actor.global_position.y <= DEATH_Y:
			continue

		if actor.team == "ally" and not actor.is_controlled:
			_rescue_inactive_ally(actor)
		else:
			actor.force_kill()

func _rescue_inactive_ally(actor: Actor) -> void:
	if not is_instance_valid(active_actor) or not active_actor.alive:
		return

	var preferred_x: float = clampf(active_actor.global_position.x + actor.follow_offset_x, 18.0, world_width - 18.0)
	var rescue_position: Vector2 = _safe_floor_position(preferred_x, active_actor.global_position.y)

	if rescue_position == Vector2.INF:
		rescue_position = _safe_floor_position(active_actor.global_position.x, active_actor.global_position.y)

	if rescue_position == Vector2.INF:
		rescue_position = active_actor.global_position + Vector2(-12.0 * active_actor.facing, -6.0)

	actor.global_position = rescue_position
	actor.velocity = Vector2.ZERO
	actor.facing = active_actor.facing
	report_event("%s: RESGATE DE FOLLOW" % actor.actor_name)

func _safe_floor_position(x: float, reference_y: float) -> Vector2:
	var from := Vector2(x, maxf(36.0, reference_y - 90.0))
	var to := Vector2(x, minf(DEATH_Y - 8.0, reference_y + 130.0))
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return Vector2.INF
	return Vector2(x, hit.position.y - 8.0)

func has_floor_ahead(actor: Actor, direction: float, horizontal_distance := 14.0) -> bool:
	if not is_instance_valid(actor) or absf(direction) < 0.01:
		return true

	var from: Vector2 = actor.global_position + Vector2(signf(direction) * horizontal_distance, -3.0)
	var to: Vector2 = from + Vector2(0.0, 34.0)
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return not hit.is_empty()

func _on_actor_died(actor: Actor) -> void:
	if actor.team == "enemy":
		active_enemies = maxi(0, active_enemies - 1)
		return

	var was_active: bool = actor == active_actor
	var dead_slot: int = actor.party_slot
	if was_active:
		_handoff_from_slot(dead_slot)
	else:
		report_event("%s foi derrotado" % actor.actor_name)

	if _alive_party_count() == 0:
		active_actor = null
		game_over = true
		report_event("GAME OVER — todos os membros foram derrotados")

func _alive_party_count() -> int:
	var count := 0
	for member in party_slots:
		if is_instance_valid(member) and member.alive:
			count += 1
	return count

func _update_camera() -> void:
	if not is_instance_valid(camera) or not is_instance_valid(active_actor):
		return
	var target_x: float = clampf(active_actor.global_position.x, camera_half_width, world_width - camera_half_width)
	camera.global_position = Vector2(target_x, camera_y)

func try_break_rubble(_actor: Actor) -> void:
	# Nao ha entulho nesta fase; mantido apenas porque platform_actor_12.gd
	# chama controller.try_break_rubble() incondicionalmente durante o
	# fluxo de golpe do Guerreiro (Estocada).
	pass

func summon_bridge_from(_actor: Actor) -> void:
	# Nao ha vao para atravessar nesta fase; mantido apenas porque
	# platform_actor_12.gd chama controller.summon_bridge_from()
	# incondicionalmente na especial da Heroina da Ponte.
	pass

func fire_burst_from(actor: Actor) -> void:
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.alive:
			if enemy.global_position.distance_to(actor.global_position) <= 46.0:
				enemy.take_damage(1, actor)

func teleport_actor(actor: Actor, direction: float) -> void:
	var distance := 180.0
	var from: Vector2 = actor.global_position
	var to: Vector2 = from + Vector2(direction * distance, 0.0)
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		to = hit.position - Vector2(direction * 4.0, 0.0)
		report_event("%s: TELEPORTE BLOQUEADO POR OBSTACULO" % actor.actor_name)
	else:
		report_event("%s: TELEPORTE" % actor.actor_name)
	actor.global_position = to
	actor.velocity = Vector2.ZERO

func _spawn_actor(
	p_name: String,
	team: String,
	role: String,
	position: Vector2,
	tint: Color,
	party_slot := -1
) -> Actor:
	var actor := Actor.new()
	actor_layer.add_child(actor)
	actor.global_position = position
	actor.setup(self, p_name, team, role, tint, party_slot)
	actor.died.connect(_on_actor_died)
	actors.append(actor)
	if team == "enemy":
		enemies.append(actor)
		active_enemies += 1
		total_enemies += 1
	return actor

func report_event(message: String) -> void:
	if is_instance_valid(event_label):
		event_label.text = message
	event_timeout = 3.0

# --- Mundo: sala unica com fundo craftpix (post-apocaliptico) ---------------

func _build_world() -> void:
	world_layer = Node2D.new()
	world_layer.name = "World"
	add_child(world_layer)

	_add_background()
	_add_ground()
	if is_portrait:
		_add_sky_fill_portrait()
		_add_ledge(Rect2(6, 116, 44, 14))
		_add_ledge(Rect2(130, 116, 44, 14))
	else:
		_add_ledge(Rect2(6, 116, 50, 14))
		_add_ledge(Rect2(264, 116, 50, 14))

	_add_wall_collision(Rect2(-12, 0, 12, DEATH_Y))
	_add_wall_collision(Rect2(world_width, 0, 12, DEATH_Y))

	actor_layer = Node2D.new()
	actor_layer.name = "Actors"
	actor_layer.y_sort_enabled = true
	add_child(actor_layer)

	projectile_layer = Node2D.new()
	projectile_layer.name = "Projectiles"
	add_child(projectile_layer)

	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_right = int(world_width)
	if is_portrait:
		camera.limit_top = int(camera_y - 160.0)
		camera.limit_bottom = int(camera_y + 160.0)
	else:
		camera.limit_top = 0
		camera.limit_bottom = int(DEATH_Y)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.enabled = true
	camera.global_position = Vector2(camera_half_width, camera_y)
	add_child(camera)

func _add_background() -> void:
	var bg := Sprite2D.new()
	bg.texture = load(RUINS_BG_PATH)
	bg.centered = false
	bg.z_index = -10
	if is_portrait:
		# Recorta a fatia central de 180px do fundo original (320x180) em
		# vez de espremer/distorcer — a sala em retrato so mostra uma faixa
		# horizontal mais estreita da mesma arte, sem reescalar. Todos os
		# fundos de PHASE_BACKGROUNDS tem as mesmas dimensoes (320x180),
		# entao o mesmo recorte serve pras trocas de fase.
		bg.region_enabled = true
		bg.region_rect = Rect2(70, 0, WORLD_WIDTH_PORTRAIT, 180)
		bg.position = Vector2(0, 0)
	else:
		bg.position = Vector2(0, 0)
	world_layer.add_child(bg)
	bg_sprite = bg

func _add_sky_fill_portrait() -> void:
	# Com content_scale_size 180x320 a camera mostra 320 unidades de mundo
	# na vertical (nao mais as 180 do fundo original) — sem isso sobraria
	# transparencia visivel acima da sala. Um degrade solido simples,
	# extraido do topo do proprio fundo, preenche esse espaco extra.
	var top_color := Color("3d2018")
	var deep_color := Color("1c0e0a")
	var fill_top: float = camera_y - 160.0
	var band_count := 4
	var band_h: float = (0.0 - fill_top) / band_count
	for i in range(band_count):
		var band := ColorRect.new()
		band.position = Vector2(0, fill_top + i * band_h)
		band.size = Vector2(world_width, band_h + 1.0)
		band.color = deep_color.lerp(top_color, float(i) / float(band_count - 1))
		band.z_index = -11
		world_layer.add_child(band)

func _add_ground() -> void:
	var rect := Rect2(0, GROUND_TOP, world_width, DEATH_Y - GROUND_TOP)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = rect.get_center()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	world_layer.add_child(body)

	var rim := ColorRect.new()
	rim.position = rect.position
	rim.size = Vector2(rect.size.x, 4.0)
	rim.color = Color("6b5744")
	rim.z_index = -1
	world_layer.add_child(rim)

	var fill := ColorRect.new()
	fill.position = rect.position + Vector2(0, 4.0)
	fill.size = Vector2(rect.size.x, rect.size.y - 4.0)
	fill.color = Color("241c17")
	fill.z_index = -1
	world_layer.add_child(fill)

func _add_ledge(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = rect.get_center()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.one_way_collision = true
	collision.one_way_collision_margin = 6.0
	body.add_child(collision)
	world_layer.add_child(body)

	# Pilar de apoio ate o chao, para a plataforma nao parecer flutuando
	# sem explicacao — um monte de entulho tosco, coerente com o cenario.
	var pillar_w: float = rect.size.x * 0.4
	var pillar := Polygon2D.new()
	var cx: float = rect.get_center().x
	pillar.polygon = PackedVector2Array([
		Vector2(cx - pillar_w * 0.5, rect.position.y + rect.size.y),
		Vector2(cx + pillar_w * 0.5, rect.position.y + rect.size.y),
		Vector2(cx + pillar_w * 0.35, GROUND_TOP),
		Vector2(cx - pillar_w * 0.35, GROUND_TOP),
	])
	pillar.color = Color("352a22")
	pillar.z_index = -2
	world_layer.add_child(pillar)

	var rim := ColorRect.new()
	rim.position = rect.position
	rim.size = Vector2(rect.size.x, 4.0)
	rim.color = Color("6b5744")
	rim.z_index = -1
	world_layer.add_child(rim)

	var fill := ColorRect.new()
	fill.position = rect.position + Vector2(0, 4.0)
	fill.size = Vector2(rect.size.x, rect.size.y - 4.0)
	fill.color = Color("4a3d33")
	fill.z_index = -1
	world_layer.add_child(fill)

func _add_wall_collision(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = rect.get_center()

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	world_layer.add_child(body)

# --- Party e boss ------------------------------------------------------------

const ROLE_TINT := {
	"warrior": Color("cfd6e0"),
	"archer": Color("8fd67a"),
	"mage": Color("b48cff"),
	"fire_mage": Color("ff9a52"),
	"lightning_mage": Color("fff27a"),
	"wanderer": Color("7fe0d1"),
	"paladin": Color("ffe08a"),
	"knight": Color("aac4e8"),
	"bridge_heroine": Color("ffb3d1"),
	"cavaleiro_executivo": Color("d4af37"),
}

func _role_tint(role: String) -> Color:
	return ROLE_TINT.get(role, Color("ffe26f"))

const SLOT_SPAWN_X_LANDSCAPE := [64.0, 46.0, 28.0]
const SLOT_SPAWN_X_PORTRAIT := [48.0, 30.0, 12.0]
const SLOT_FOLLOW_OFFSET := [-18.0, -18.0, -36.0]
const ACTOR_GROUND_Y := GROUND_TOP - 34.0
const BOSS_SPAWN_X_LANDSCAPE := 210.0
const BOSS_SPAWN_X_PORTRAIT := 90.0

func _spawn_party() -> void:
	var roles: Array[String] = PartySelection12.get_party_roles()
	var slot_spawn_x: Array = SLOT_SPAWN_X_PORTRAIT if is_portrait else SLOT_SPAWN_X_LANDSCAPE
	party_slots = []
	for i in range(roles.size()):
		var role: String = roles[i]
		var display_name: String = Actor.DISPLAY_NAME.get(role, role.to_upper())
		var tint: Color = ROLE_TINT.get(role, Color.WHITE)
		var actor := _spawn_actor(display_name, "ally", role, Vector2(slot_spawn_x[i], ACTOR_GROUND_Y), tint, i)
		actor.follow_offset_x = SLOT_FOLLOW_OFFSET[i]
		party_slots.append(actor)

func _spawn_enemies() -> void:
	var boss_x: float = BOSS_SPAWN_X_PORTRAIT if is_portrait else BOSS_SPAWN_X_LANDSCAPE
	boss_actor = _spawn_actor("NECROMANTE", "enemy", "necromancer", Vector2(boss_x, ACTOR_GROUND_Y), Color("8a6fd1"))
	# Ataque de contato mais espacado que o padrao: o boss se apoia
	# principalmente no impacto em area (windup/slam) como ameaca central,
	# nao em dano constante corpo a corpo.
	boss_actor.attack_cooldown_max = 1.3

func _update_boss_slam(delta: float) -> void:
	if slam_windup > 0.0:
		slam_windup -= delta
		var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.02)
		boss_actor.sprite.modulate = boss_actor.base_modulate.lerp(Color(1.0, 0.3, 0.25), pulse)
		if slam_windup <= 0.0:
			_resolve_slam()
	else:
		slam_timer -= delta
		if slam_timer <= 0.0:
			_start_slam_windup()

func _start_slam_windup() -> void:
	slam_windup = SLAM_WINDUP_TIME
	report_event("O NECROMANTE SE PREPARA PARA UM IMPACTO — INTERROMPA COM H!")

func _resolve_slam() -> void:
	boss_actor.sprite.modulate = boss_actor.base_modulate
	report_event("NECROMANTE: IMPACTO DEVASTADOR")
	for member in party_slots:
		if is_instance_valid(member) and member.alive:
			if member.global_position.distance_to(boss_actor.global_position) <= slam_radius:
				member.take_damage(1, boss_actor)
				var dir: float = signf(member.global_position.x - boss_actor.global_position.x)
				if dir == 0.0:
					dir = 1.0
				member.velocity = Vector2(dir * 220.0, -120.0)
	slam_timer = SLAM_INTERVAL

func _try_interrupt_slam(actor: Actor) -> void:
	if slam_windup <= 0.0 or not is_instance_valid(boss_actor) or not boss_actor.alive:
		return
	slam_windup = 0.0
	slam_timer = SLAM_INTERVAL + SLAM_STAGGER_TIME
	boss_actor.sprite.modulate = boss_actor.base_modulate
	boss_actor.take_damage(INTERRUPT_BONUS_DAMAGE, actor)
	report_event("%s INTERROMPEU O NECROMANTE! (+%d de dano)" % [actor.actor_name, INTERRUPT_BONUS_DAMAGE])

# --- Interludios de troca de fase (pedido do usuario) -------------------------

func _check_boss_phase_transition() -> void:
	if phase_interlude_active or current_phase > PHASE_HP_RATIOS.size():
		return
	var idx: int = current_phase - 1
	var ratio: float = float(boss_actor.hp) / float(maxi(boss_actor.max_hp, 1))
	if ratio <= PHASE_HP_RATIOS[idx]:
		current_phase += 1
		_start_phase_interlude(current_phase)

func _start_phase_interlude(phase: int) -> void:
	phase_interlude_active = true
	get_tree().paused = true
	boss_actor.sprite.modulate = boss_actor.base_modulate
	slam_windup = 0.0
	if is_instance_valid(bg_sprite) and phase - 1 < PHASE_BACKGROUNDS.size():
		bg_sprite.texture = load(PHASE_BACKGROUNDS[phase - 1])
	interlude_lines = PHASE_INTERLUDES[phase - 2]
	interlude_line_index = 0
	_build_interlude_ui()
	_show_interlude_line()

func _build_interlude_ui() -> void:
	interlude_layer = CanvasLayer.new()
	interlude_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	interlude_layer.layer = 15
	add_child(interlude_layer)

	var watcher := InterludeWatcher.new()
	watcher.advance_requested.connect(_on_interlude_advance)
	interlude_layer.add_child(watcher)

	var w: float = WORLD_WIDTH_PORTRAIT if is_portrait else WORLD_WIDTH_LANDSCAPE
	var h: float = 320.0 if is_portrait else 180.0

	var dim := ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = Vector2(w, h)
	dim.color = Color(0, 0, 0, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interlude_layer.add_child(dim)

	var title_font: FontFile = load("res://assets/Fonts/Runtime/MedievalScrollOfWisdom.ttf")
	var body_font: FontFile = load("res://assets/Fonts/Runtime/MedievalSharp-Book.ttf")

	if is_portrait:
		interlude_portrait_left = _build_interlude_portrait_slot(Vector2(4, 30), Vector2(84, 84))
		interlude_portrait_right = _build_interlude_portrait_slot(Vector2(92, 30), Vector2(84, 84))

		var box := ColorRect.new()
		box.position = Vector2(4, 122)
		box.size = Vector2(172, 150)
		box.color = Color(0.02, 0.02, 0.03, 0.92)
		interlude_layer.add_child(box)

		interlude_name_label = Label.new()
		interlude_name_label.position = Vector2(10, 128)
		interlude_name_label.size = Vector2(160, 12)
		interlude_name_label.add_theme_font_override("font", title_font)
		interlude_name_label.add_theme_font_size_override("font_size", 10)
		interlude_name_label.add_theme_color_override("font_color", Color("ffe26f"))
		interlude_layer.add_child(interlude_name_label)

		interlude_text_label = Label.new()
		interlude_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		interlude_text_label.add_theme_font_override("font", body_font)
		interlude_text_label.add_theme_font_size_override("font_size", 7)
		interlude_text_label.add_theme_color_override("font_color", Color("f4e7c9"))
		interlude_text_label.position = Vector2(10, 144)
		interlude_text_label.custom_minimum_size = Vector2(160, 110)
		interlude_text_label.size = Vector2(160, 110)
		interlude_layer.add_child(interlude_text_label)

		var hint := Label.new()
		hint.text = "toque para continuar"
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.position = Vector2(0, 300)
		hint.size = Vector2(180, 12)
		hint.add_theme_font_override("font", body_font)
		hint.add_theme_font_size_override("font_size", 6)
		hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
		interlude_layer.add_child(hint)
	else:
		interlude_portrait_left = _build_interlude_portrait_slot(Vector2(6, 20), Vector2(110, 110))
		interlude_portrait_right = _build_interlude_portrait_slot(Vector2(204, 20), Vector2(110, 110))

		var box := ColorRect.new()
		box.position = Vector2(4, 132)
		box.size = Vector2(312, 44)
		box.color = Color(0.02, 0.02, 0.03, 0.92)
		interlude_layer.add_child(box)

		interlude_name_label = Label.new()
		interlude_name_label.position = Vector2(10, 135)
		interlude_name_label.size = Vector2(300, 10)
		interlude_name_label.add_theme_font_override("font", title_font)
		interlude_name_label.add_theme_font_size_override("font_size", 9)
		interlude_name_label.add_theme_color_override("font_color", Color("ffe26f"))
		interlude_layer.add_child(interlude_name_label)

		interlude_text_label = Label.new()
		interlude_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		interlude_text_label.add_theme_font_override("font", body_font)
		interlude_text_label.add_theme_font_size_override("font_size", 7)
		interlude_text_label.add_theme_color_override("font_color", Color("f4e7c9"))
		interlude_text_label.position = Vector2(10, 146)
		interlude_text_label.custom_minimum_size = Vector2(300, 28)
		interlude_text_label.size = Vector2(300, 28)
		interlude_layer.add_child(interlude_text_label)

		var hint := Label.new()
		hint.text = "clique / tecla para continuar"
		hint.position = Vector2(4, 168)
		hint.size = Vector2(230, 10)
		hint.add_theme_font_override("font", body_font)
		hint.add_theme_font_size_override("font_size", 5)
		hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
		interlude_layer.add_child(hint)

func _build_interlude_portrait_slot(pos: Vector2, size: Vector2) -> Control:
	var holder := Control.new()
	holder.position = pos
	holder.size = size
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interlude_layer.add_child(holder)
	return holder

func _set_interlude_portrait(slot: Control, character_id: String, expr: String, dim: bool) -> void:
	for child in slot.get_children():
		child.queue_free()
	var path := "%s%s/%s.png" % [PORTRAIT_DIR, character_id, expr]
	var tex_rect := TextureRect.new()
	if ResourceLoader.exists(path):
		tex_rect.texture = load(path)
	tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.modulate = Color(0.55, 0.55, 0.6) if dim else Color(1, 1, 1)
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# position/size por ultimo — mesma armadilha de sempre (expand_mode antes
	# de entrar na tree infla o minimum_size pro tamanho nativo da textura).
	tex_rect.position = Vector2.ZERO
	tex_rect.custom_minimum_size = slot.size
	tex_rect.size = slot.size
	slot.add_child(tex_rect)

func _show_interlude_line() -> void:
	var line: Dictionary = interlude_lines[interlude_line_index]
	var speaker: String = line["speaker"]
	var expr: String = line["expr"]
	var is_cavaleiro: bool = speaker == CAVALEIRO_ID
	_set_interlude_portrait(interlude_portrait_left, CAVALEIRO_ID, "neutro" if not is_cavaleiro else expr, not is_cavaleiro)
	_set_interlude_portrait(interlude_portrait_right, COORDENADOR_ID, "neutro" if is_cavaleiro else expr, is_cavaleiro)
	interlude_name_label.text = "CAVALEIRO EXECUTIVO" if is_cavaleiro else "O COORDENADOR"
	interlude_text_label.text = line["text"]

func _on_interlude_advance() -> void:
	interlude_line_index += 1
	if interlude_line_index >= interlude_lines.size():
		_finish_interlude()
	else:
		_show_interlude_line()

func _finish_interlude() -> void:
	if is_instance_valid(interlude_layer):
		interlude_layer.queue_free()
	get_tree().paused = false
	phase_interlude_active = false
	report_event("O NECROMANTE RETOMA O COMBATE")

# --- HUD ---------------------------------------------------------------------

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	if is_portrait:
		var refs := BossHudPortrait12.build_hud(canvas, "NECROMANTE")
		party_label = refs["party_label"]
		objective_label = refs["objective_label"]
		boss_name_label = refs["boss_name_label"]
		boss_bar_bg = refs["boss_bar_bg"]
		boss_bar_empty = refs["boss_bar_empty"]
		state_label = refs["state_label"]
		event_label = refs["event_label"]
		boss_bar_pos = refs["boss_bar_pos"]
		boss_bar_size = refs["boss_bar_size"]
		hp_bars = PartyHpBars12.build(canvas, party_slots, 34.0, _role_tint)
		return

	var panel := ColorRect.new()
	panel.position = Vector2(0, 0)
	panel.size = Vector2(320, 18)
	panel.color = Color(0.02, 0.025, 0.035, 0.55)
	canvas.add_child(panel)

	party_label = Label.new()
	party_label.position = Vector2(4, 0)
	party_label.add_theme_font_size_override("font_size", 7)
	party_label.add_theme_color_override("font_color", Color("ffe26f"))
	panel.add_child(party_label)

	objective_label = Label.new()
	objective_label.position = Vector2(4, 9)
	objective_label.add_theme_font_size_override("font_size", 6)
	panel.add_child(objective_label)

	var body_font: FontFile = load("res://assets/Fonts/Runtime/MedievalSharp-Book.ttf")

	boss_name_label = Label.new()
	boss_name_label.text = "NECROMANTE"
	boss_name_label.position = Vector2(boss_bar_pos.x, boss_bar_pos.y - 8.0)
	boss_name_label.size = Vector2(boss_bar_size.x, 8)
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.add_theme_font_override("font", body_font)
	boss_name_label.add_theme_font_size_override("font_size", 6)
	boss_name_label.add_theme_color_override("font_color", Color("e8b3a0"))
	canvas.add_child(boss_name_label)

	# health_bar.png (pack Medieval Free) ja vem 100% cheia (sem variante
	# vazia) — um NinePatchRect estica so a faixa central preservando as
	# pontas arredondadas, e a barra "esvazia" da direita para a esquerda
	# cobrindo a fatia sem vida com um retangulo escuro (boss_bar_empty).
	boss_bar_bg = NinePatchRect.new()
	boss_bar_bg.texture = HEALTH_BAR_TEX
	boss_bar_bg.position = boss_bar_pos
	boss_bar_bg.size = boss_bar_size
	boss_bar_bg.patch_margin_left = 6
	boss_bar_bg.patch_margin_right = 6
	boss_bar_bg.patch_margin_top = 2
	boss_bar_bg.patch_margin_bottom = 2
	canvas.add_child(boss_bar_bg)

	boss_bar_empty = ColorRect.new()
	boss_bar_empty.color = Color("2c1a1c")
	canvas.add_child(boss_bar_empty)

	var title_font: FontFile = load("res://assets/Fonts/Runtime/MedievalScrollOfWisdom.ttf")

	state_label = Label.new()
	state_label.position = Vector2(0, 76)
	state_label.size = Vector2(320, 20)
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_label.add_theme_font_override("font", title_font)
	state_label.add_theme_font_size_override("font_size", 14)
	state_label.add_theme_color_override("font_color", Color("ffe26f"))
	state_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	state_label.add_theme_constant_override("outline_size", 4)
	canvas.add_child(state_label)

	var help := Label.new()
	help.text = "ESC: pausar e ver instrucoes"
	help.position = Vector2(5, 168)
	help.add_theme_font_size_override("font_size", 6)
	canvas.add_child(help)

	event_label = Label.new()
	event_label.position = Vector2(6, 155)
	event_label.add_theme_font_size_override("font_size", 7)
	event_label.add_theme_color_override("font_color", Color("ffe26f"))
	canvas.add_child(event_label)

	hp_bars = PartyHpBars12.build(canvas, party_slots, 22.0, _role_tint)

	canvas.add_child(TouchControls.instantiate())

func _update_hud() -> void:
	if not is_instance_valid(state_label):
		return

	if game_over:
		state_label.text = "GAME OVER — R reinicia"
	elif completed:
		state_label.text = "VITORIA — R reinicia"
	else:
		state_label.text = ""

	PartyHpBars12.update(hp_bars, active_actor)

	var parts: Array[String] = []
	for i in range(party_slots.size()):
		var member: Actor = party_slots[i]
		if not is_instance_valid(member):
			continue
		var marker := ">" if member == active_actor and member.alive else " "
		parts.append("%s%d:%s" % [marker, i + 1, member.actor_name])
	party_label.text = " | ".join(parts)

	if is_instance_valid(boss_actor) and boss_actor.alive:
		objective_label.text = "derrote o Necromante — H interrompe o impacto"
		var ratio: float = clampf(float(boss_actor.hp) / float(maxi(boss_actor.max_hp, 1)), 0.0, 1.0)
		var inset_x: float = boss_bar_size.x * 0.09
		var inset_y: float = boss_bar_size.y * 0.143
		var interior_w: float = boss_bar_size.x - inset_x * 2.0
		var interior_h: float = boss_bar_size.y - inset_y * 2.0
		var empty_w: float = interior_w * (1.0 - ratio)
		boss_bar_empty.position = Vector2(boss_bar_pos.x + inset_x + (interior_w - empty_w), boss_bar_pos.y + inset_y)
		boss_bar_empty.size = Vector2(empty_w, interior_h)
	else:
		objective_label.text = ""
		if is_instance_valid(boss_bar_empty):
			boss_bar_empty.visible = false
		if is_instance_valid(boss_bar_bg):
			boss_bar_bg.visible = false
		if is_instance_valid(boss_name_label):
			boss_name_label.visible = false

func _build_pause_watcher() -> void:
	var watcher := PauseWatcher.new()
	watcher.toggle_requested.connect(_toggle_pause)
	add_child(watcher)

func _toggle_pause() -> void:
	# ESC nao deve abrir/fechar o menu de pausa normal por cima de um
	# interludio de troca de fase (ver _start_phase_interlude) — senao um
	# segundo ESC destravaria a SceneTree com o dialogo do interludio ainda
	# na tela, retomando a luta escondida atras dele.
	if phase_interlude_active:
		return
	is_paused = not is_paused
	get_tree().paused = is_paused
	pause_layer.visible = is_paused

const PAUSE_INSTRUCTIONS := "OBJETIVO\nDerrote o NECROMANTE, um chefe unico com muita vida.\nDe tempos em tempos ele se prepara para um IMPACTO em area\n(aviso na tela) — use a habilidade especial (H) de QUALQUER\npersonagem do seu grupo durante o aviso para INTERROMPER o\ngolpe e causar dano bonus. Se o impacto acontecer, quem\nestiver perto leva dano e e arremessado para tras.\n\nCONTROLES\nA/D mover | ESPACO pular (2x no ar) | K dash\n1/2/3 trocar personagem | J atacar | H especial\nR reiniciar a fase | ESC pausar/continuar"

func _build_pause_menu() -> void:
	if is_portrait:
		pause_layer = BossHudPortrait12.build_pause_menu(PAUSE_INSTRUCTIONS, _toggle_pause, _on_back_to_select_pressed)
		add_child(pause_layer)
		return

	pause_layer = CanvasLayer.new()
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_layer.layer = 10
	add_child(pause_layer)

	var dim := ColorRect.new()
	dim.position = Vector2(0, 0)
	dim.size = Vector2(320, 180)
	dim.color = Color(0, 0, 0, 0.72)
	pause_layer.add_child(dim)

	var panel := ColorRect.new()
	panel.position = Vector2(26, 6)
	panel.size = Vector2(268, 170)
	panel.color = Color("1b2028")
	pause_layer.add_child(panel)

	var title_font: FontFile = load("res://assets/Fonts/Runtime/MedievalScrollOfWisdom.ttf")
	var body_font: FontFile = load("res://assets/Fonts/Runtime/MedievalSharp-Book.ttf")

	var title := Label.new()
	title.text = "PAUSADO"
	title.position = Vector2(26, 9)
	title.size = Vector2(268, 12)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", title_font)
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color("ffe26f"))
	pause_layer.add_child(title)

	var instructions := Label.new()
	instructions.text = PAUSE_INSTRUCTIONS
	instructions.position = Vector2(38, 24)
	instructions.size = Vector2(244, 120)
	instructions.add_theme_font_override("font", body_font)
	instructions.add_theme_font_size_override("font_size", 6)
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD
	pause_layer.add_child(instructions)

	var resume_btn := Button.new()
	resume_btn.text = "CONTINUAR"
	resume_btn.focus_mode = Control.FOCUS_NONE
	resume_btn.position = Vector2(46, 150)
	MedievalUI12.style_button(resume_btn, false, body_font, 8, Color("2a1a0f"), Vector2(100, 18))
	resume_btn.pressed.connect(_toggle_pause)
	pause_layer.add_child(resume_btn)

	var back_btn := Button.new()
	back_btn.text = "VOLTAR A SELECAO"
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.position = Vector2(156, 150)
	MedievalUI12.style_button(back_btn, true, body_font, 8, Color("f4e7c9"), Vector2(120, 18))
	back_btn.pressed.connect(_on_back_to_select_pressed)
	pause_layer.add_child(back_btn)

	pause_layer.visible = false

func _on_back_to_select_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(STAGE_SELECT_SCENE)
