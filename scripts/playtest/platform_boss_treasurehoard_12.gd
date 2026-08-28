extends Node2D

## Sprint 15: 6a fase de boss fight e FINAL DA SPRINT — o Covil do Tesouro
## (fundo montado a partir do pack "treasure-hoard-platform" da Gothicvania,
## Legacy Collection: sky/hills/gold-pile/ground em camadas). Unico inimigo
## gigante: o DRAGAO (pack "Grotto-escape-2-boss-dragon"), cujas folhas Idle
## (6 frames, reaproveitada como "move" tambem — ele guarda o tesouro parado,
## "speed": 0 em ROLE_BODY) e Breath (7, usada como "attack") vieram prontas
## do pack, sem Hurt/Death (mesmo caso ja tratado sem problemas pelo Ogro).
##
## DIFERENTE das outras fases de boss: esta e a fase "com mecanica
## exclusiva" pedida no briefing — so aparece jogavel na selecao de fase se
## a HEROINA DA PONTE ja estiver desbloqueada (`stage_select_12.gd`,
## `PartySelection12.required_role`), e o modo de selecao "gated" forca ela
## num dos 3 slots do grupo (`PartySelection12.toggle_free_role` recusa
## remove-la). A sala tem um VAO de verdade entre o grupo e o dragao — cair
## nele mata o personagem ativo como em qualquer buraco (`_check_falls`) —
## e so a especial dela (`summon_bridge_from`, chamada por
## `Actor._summon_bridge()`) constroi uma ponte temporaria para atravessar
## (ver `_spawn_bridge`/`_despawn_bridge` abaixo). Nas outras fases essa
## mesma chamada e um no-op inofensivo (nao ha vao para atravessar).
##
## Sem recompensa de personagem (`stage_reward_role` fica vazio para esta
## fase) — e a fase final da sequencia de herois da Sprint 15, nao uma porta
## de entrada para mais um.
##
## Arquivo proprio (convencao das sprints anteriores: cada fase mantem seu
## controller independente), copiado de platform_boss_starrynight_12.gd com
## o boss, o cenario e o layout do chao (vao + ponte) trocados/adaptados.
##
## Sprint 16: convertida pro padrao retrato/paisagem — a mais arriscada das
## 5 salas de boss por causa do VAO. Analise de fisica (speed=92,
## jump_velocity=-245, gravity=760, dash 1.55x) confirma que o vao de 70px
## ja e pulavel sem a ponte na paisagem publicada (~92px de alcance com
## pulo+dash) — um desbalanceamento PRE-EXISTENTE, fora do escopo desta
## sprint (o plano so pedia pra reportar, nao consertar). Por isso, em
## retrato, o VAO fica em EXATOS 70px (gap_left_x/gap_right_x viram vars,
## nao mudam de largura) — so as plataformas dos dois lados encolhem, e o
## raio de proximidade da ponte (`summon_bridge_from`) e reajustado pra nao
## cobrir a sala quase inteira numa largura de 180px. Camera/HUD/pausa
## seguem o mesmo padrao das outras 4 salas (ver platform_boss_12.gd).
##
## Pedido do usuario (pos-Sprint 16): o Dragao nao ficava mais parado
## guardando o tesouro — agora "voa" de verdade (`_update_dragon_flight`,
## puramente visual/patrulha curta na propria plataforma, sem tocar no
## `speed=0` do ROLE_BODY nem na logica de perseguicao compartilhada) e
## ganhou um SEGUNDO ataque independente do sopro de fogo: ele some da tela
## (`_update_fire_rain`, maquina de estados "" -> vanish -> raining ->
## returning) e uma chuva de fogo cai do ceu em ondas, comecando no centro
## da sala e se espalhando para os dois lados ate os cantos
## (`_spawn_fire_wave`/`_spawn_fire_impact`) — esquivavel (sair da faixa
## avisada), diferente do sopro que se interrompe com H.

const Actor = preload("res://scripts/playtest/platform_actor_12.gd")
const Projectile = preload("res://scripts/playtest/platform_projectile_12.gd")
const PauseWatcher = preload("res://scripts/playtest/pause_watcher_12.gd")
const HEALTH_BAR_TEX := preload("res://assets/UI/Runtime/MedievalFree/health_bar.png")
const TouchControls = preload("res://scenes/playtest/touch_controls_12.tscn")
const STAGE_SELECT_SCENE := "res://scenes/menu/stage_select_12.tscn"
const VICTORY_CUTSCENE_SCENE := "res://scenes/menu/victory_cutscene_12.tscn"

const WORLD_WIDTH_LANDSCAPE := 320.0
const WORLD_WIDTH_PORTRAIT := 180.0
const DEATH_Y := 210.0
const GROUND_TOP := 150.0
const TREASUREHOARD_BG_PATH := "res://assets/Environment/TreasureHoard/Runtime/treasure_bg.png"

var world_width := WORLD_WIDTH_LANDSCAPE
var is_portrait := false
var camera_half_width := 160.0
var camera_y := 90.0

# Vao real no chao entre o grupo (plataforma esquerda) e o Dragao (direita)
# — a mecanica exclusiva da fase. So a especial da Heroina da Ponte
# (`summon_bridge_from`) constroi uma travessia; cair no vao mata o
# personagem ativo como qualquer buraco (`_check_falls`). Largura do vao
# (gap_right_x - gap_left_x = 70) e IGUAL nos dois modos de proposito —
# so a posicao/tamanho das plataformas dos lados muda.
const GAP_LEFT_X_LANDSCAPE := 140.0
const GAP_RIGHT_X_LANDSCAPE := 210.0
const GAP_LEFT_X_PORTRAIT := 40.0
const GAP_RIGHT_X_PORTRAIT := 110.0
const RIGHT_PLATFORM_OFFSET_LANDSCAPE := 55.0
const RIGHT_PLATFORM_OFFSET_PORTRAIT := 35.0
const BRIDGE_PROXIMITY_LANDSCAPE := 60.0
const BRIDGE_PROXIMITY_PORTRAIT := 45.0
const BRIDGE_DURATION := 6.0

var gap_left_x := GAP_LEFT_X_LANDSCAPE
var gap_right_x := GAP_RIGHT_X_LANDSCAPE
var gap_center_x := (GAP_LEFT_X_LANDSCAPE + GAP_RIGHT_X_LANDSCAPE) * 0.5
var right_platform_x := GAP_RIGHT_X_LANDSCAPE
var right_platform_offset := RIGHT_PLATFORM_OFFSET_LANDSCAPE
var bridge_proximity := BRIDGE_PROXIMITY_LANDSCAPE

var bridge_body: StaticBody2D = null
var bridge_visual: ColorRect = null
var bridge_timer := 0.0

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
const SLAM_WINDUP_TIME := 1.4
const SLAM_STAGGER_TIME := 2.4
const SLAM_RADIUS_LANDSCAPE := 90.0
# Mesma logica das outras 4 salas: sala em retrato encolhe pra 180 de
# largura — raio reduzido preserva a opcao de recuar em vez de so
# interromper com H (a plataforma direita, onde o Dragao fica, e a que
# mais importa aqui: 70 de largura, raio precisa deixar folga real).
const SLAM_RADIUS_PORTRAIT := 72.0
const INTERRUPT_BONUS_DAMAGE := 6
var slam_radius := SLAM_RADIUS_LANDSCAPE
var slam_timer := 3.0
var slam_windup := 0.0

# Voo: o Dragao nao fica mais parado — flutua (bob vertical no sprite,
# puramente visual) e desliza devagar de um lado a outro da plataforma
# direita (posicao real, entra no calculo de SLAM_RADIUS normalmente).
var dragon_flight_time := 0.0

# Segundo ataque, independente do sopro de fogo (SLAM_*): o Dragao some da
# tela (voa para fora) e uma chuva de fogo cai do ceu, comecando no CENTRO
# da sala e se espalhando em ondas para os dois lados ate os cantos —
# esquiva (sair da faixa avisada), nao interrompe com H como o sopro.
const FIRE_RAIN_INTERVAL := 16.0
const FIRE_RAIN_VANISH_TIME := 0.9
const FIRE_RAIN_WAVE_COUNT := 5
const FIRE_RAIN_WAVE_GAP := 0.55
const FIRE_RAIN_WARN_TIME := 0.4
const FIRE_RAIN_RETURN_TIME := 0.7
const FIRE_RAIN_DAMAGE := 1
var fire_rain_timer := 9.0
var fire_rain_state := ""
var fire_rain_state_time := 0.0
var fire_rain_wave_index := 0
var fire_rain_wave_timer := 0.0

func _ready() -> void:
	is_portrait = DeviceLayout12.is_portrait
	if is_portrait:
		world_width = WORLD_WIDTH_PORTRAIT
		camera_half_width = world_width / 2.0
		camera_y = DEATH_Y - 160.0
		slam_radius = SLAM_RADIUS_PORTRAIT
		gap_left_x = GAP_LEFT_X_PORTRAIT
		gap_right_x = GAP_RIGHT_X_PORTRAIT
		right_platform_x = GAP_RIGHT_X_PORTRAIT
		right_platform_offset = RIGHT_PLATFORM_OFFSET_PORTRAIT
		bridge_proximity = BRIDGE_PROXIMITY_PORTRAIT
	else:
		world_width = WORLD_WIDTH_LANDSCAPE
		camera_half_width = 160.0
		camera_y = 90.0
		slam_radius = SLAM_RADIUS_LANDSCAPE
		gap_left_x = GAP_LEFT_X_LANDSCAPE
		gap_right_x = GAP_RIGHT_X_LANDSCAPE
		right_platform_x = GAP_RIGHT_X_LANDSCAPE
		right_platform_offset = RIGHT_PLATFORM_OFFSET_LANDSCAPE
		bridge_proximity = BRIDGE_PROXIMITY_LANDSCAPE
	gap_center_x = (gap_left_x + gap_right_x) * 0.5
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
		_update_dragon_flight(delta)
		_update_fire_rain(delta)

	_handle_bridge(delta)

	if event_timeout > 0.0:
		event_timeout -= delta
		if event_timeout <= 0.0 and is_instance_valid(event_label):
			event_label.text = ""

	if not completed and active_enemies <= 0 and total_enemies > 0:
		completed = true
		report_event("VITORIA — O DRAGAO FOI DERROTADO")
		_handle_victory_reward()

	_update_hud()

func _handle_victory_reward() -> void:
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

# --- Mundo: sala unica com fundo do ceu noturno estrelado --------------------

func _build_world() -> void:
	world_layer = Node2D.new()
	world_layer.name = "World"
	add_child(world_layer)

	_add_background()
	_add_ground_segment(Rect2(0, GROUND_TOP, gap_left_x, DEATH_Y - GROUND_TOP))
	_add_ground_segment(Rect2(gap_right_x, GROUND_TOP, world_width - gap_right_x, DEATH_Y - GROUND_TOP))
	if is_portrait:
		_add_sky_fill_portrait()
		_add_ledge(Rect2(2, 116, 28, 14))
		_add_ledge(Rect2(130, 116, 40, 14))
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
	bg.texture = load(TREASUREHOARD_BG_PATH)
	bg.centered = false
	bg.z_index = -10
	if is_portrait:
		bg.region_enabled = true
		bg.region_rect = Rect2(70, 0, WORLD_WIDTH_PORTRAIT, 180)
	bg.position = Vector2(0, 0)
	world_layer.add_child(bg)

func _add_sky_fill_portrait() -> void:
	# Mesma tecnica das outras 4 salas — degrade solido extraido do topo do
	# fundo do Covil do Tesouro preenche o espaco extra revelado acima da
	# sala quando content_scale_size passa a ser 180x320.
	var top_color := Color("501433")
	var deep_color := Color("200817")
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

func _add_ground_segment(rect: Rect2) -> void:
	# Duas chamadas (esquerda/direita) em vez de um unico chao de ponta a
	# ponta — o vao entre gap_left_x/gap_right_x fica sem colisao nenhuma,
	# a mecanica exclusiva desta fase (ver `summon_bridge_from`).
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
	rim.color = Color("ffb35c")
	rim.z_index = -1
	world_layer.add_child(rim)

	var fill := ColorRect.new()
	fill.position = rect.position + Vector2(0, 4.0)
	fill.size = Vector2(rect.size.x, rect.size.y - 4.0)
	fill.color = Color("3a1f10")
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

	# Pilha de moedas de ouro ate o chao, coerente com o Covil do Tesouro
	# (em vez do pilar de entulho das Ruinas).
	var pillar_w: float = rect.size.x * 0.4
	var pillar := Polygon2D.new()
	var cx: float = rect.get_center().x
	pillar.polygon = PackedVector2Array([
		Vector2(cx - pillar_w * 0.5, rect.position.y + rect.size.y),
		Vector2(cx + pillar_w * 0.5, rect.position.y + rect.size.y),
		Vector2(cx + pillar_w * 0.35, GROUND_TOP),
		Vector2(cx - pillar_w * 0.35, GROUND_TOP),
	])
	pillar.color = Color("7a4a1a")
	pillar.z_index = -2
	world_layer.add_child(pillar)

	var rim := ColorRect.new()
	rim.position = rect.position
	rim.size = Vector2(rect.size.x, 4.0)
	rim.color = Color("ffb35c")
	rim.z_index = -1
	world_layer.add_child(rim)

	var fill := ColorRect.new()
	fill.position = rect.position + Vector2(0, 4.0)
	fill.size = Vector2(rect.size.x, rect.size.y - 4.0)
	fill.color = Color("3a1f10")
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
# Diferente das outras 4 salas: aqui a plataforma esquerda em retrato so vai
# ate gap_left_x_portrait=40 (nao a sala inteira) — [48,30,12] usado nas
# outras salas cairia no vao (48 > 40). Valores proprios, com folga do
# raio de colisao (ate 7px) tanto da parede (x=0) quanto da borda do vao.
const SLOT_SPAWN_X_PORTRAIT := [26.0, 18.0, 10.0]
const SLOT_FOLLOW_OFFSET_LANDSCAPE := [-18.0, -18.0, -36.0]
# A plataforma esquerda em retrato so tem 40px (contra 140 na paisagem) — os
# offsets da paisagem fariam o 3o personagem tentar seguir ate x=-10 (dentro
# da parede) e travar visivelmente contra ela. Reduzidos na mesma proporcao
# de SLOT_SPAWN_X_PORTRAIT (espacamento 8 em vez de 18).
const SLOT_FOLLOW_OFFSET_PORTRAIT := [-8.0, -8.0, -16.0]
const ACTOR_GROUND_Y := GROUND_TOP - 34.0

func _spawn_party() -> void:
	var roles: Array[String] = PartySelection12.get_party_roles()
	var slot_spawn_x: Array = SLOT_SPAWN_X_PORTRAIT if is_portrait else SLOT_SPAWN_X_LANDSCAPE
	var slot_follow_offset: Array = SLOT_FOLLOW_OFFSET_PORTRAIT if is_portrait else SLOT_FOLLOW_OFFSET_LANDSCAPE
	party_slots = []
	for i in range(roles.size()):
		var role: String = roles[i]
		var display_name: String = Actor.DISPLAY_NAME.get(role, role.to_upper())
		var tint: Color = ROLE_TINT.get(role, Color.WHITE)
		var actor := _spawn_actor(display_name, "ally", role, Vector2(slot_spawn_x[i], ACTOR_GROUND_Y), tint, i)
		actor.follow_offset_x = slot_follow_offset[i]
		party_slots.append(actor)

func _spawn_enemies() -> void:
	boss_actor = _spawn_actor("DRAGAO", "enemy", "dragon", Vector2(right_platform_x + right_platform_offset, ACTOR_GROUND_Y), Color("ffb35c"))
	# O Dragao nunca sai do lugar (guarda o tesouro — "speed": 0 em
	# ROLE_BODY), entao o contato so acontece se o grupo se aproximar demais;
	# a ameaca principal e o sopro de fogo em area, com raio grande o
	# suficiente para alcancar quem atravessou a ponte mas ainda hesita perto
	# da borda (ver SLAM_* acima).
	boss_actor.attack_cooldown_max = 1.5

func _handle_bridge(delta: float) -> void:
	if not is_instance_valid(bridge_body):
		return
	bridge_timer -= delta
	if bridge_timer <= 1.5:
		bridge_visual.visible = int(bridge_timer * 6.0) % 2 == 0
	if bridge_timer <= 0.0:
		_despawn_bridge()

func summon_bridge_from(actor: Actor) -> void:
	if absf(actor.global_position.x - gap_center_x) > bridge_proximity:
		report_event("%s: PONTE (aproxime-se do vao para usar)" % actor.actor_name)
		return
	_spawn_bridge()
	report_event("%s INVOCOU UMA PONTE SOBRE O VAO!" % actor.actor_name)

func _spawn_bridge() -> void:
	_despawn_bridge()
	var rect := Rect2(gap_left_x, GROUND_TOP, gap_right_x - gap_left_x, DEATH_Y - GROUND_TOP)
	bridge_body = StaticBody2D.new()
	bridge_body.collision_layer = 1
	bridge_body.collision_mask = 0
	bridge_body.position = rect.get_center()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(rect.size.x, 10.0)
	collision.shape = shape
	collision.position = Vector2(0, -rect.size.y * 0.5 + 5.0)
	bridge_body.add_child(collision)
	world_layer.add_child(bridge_body)

	bridge_visual = ColorRect.new()
	bridge_visual.position = Vector2(rect.position.x, GROUND_TOP - 4.0)
	bridge_visual.size = Vector2(rect.size.x, 6.0)
	bridge_visual.color = Color("8a6a3f")
	bridge_visual.z_index = -1
	world_layer.add_child(bridge_visual)

	bridge_timer = BRIDGE_DURATION

func _despawn_bridge() -> void:
	if is_instance_valid(bridge_body):
		bridge_body.queue_free()
	if is_instance_valid(bridge_visual):
		bridge_visual.queue_free()
	bridge_body = null
	bridge_visual = null

func _update_boss_slam(delta: float) -> void:
	if fire_rain_state != "":
		return
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
	report_event("O DRAGAO INSPIRA PARA UM SOPRO DE FOGO — INTERROMPA COM H!")

func _resolve_slam() -> void:
	boss_actor.sprite.modulate = boss_actor.base_modulate
	report_event("DRAGAO: SOPRO DE FOGO DEVASTADOR")
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
	report_event("%s INTERROMPEU O DRAGAO! (+%d de dano)" % [actor.actor_name, INTERRUPT_BONUS_DAMAGE])

func _update_dragon_flight(delta: float) -> void:
	# Puramente visual (bob no sprite) + deslize real na plataforma direita —
	# nunca roda durante a sequencia de sumico/chuva de fogo (o dragao ja
	# esta sendo animado por ela).
	if fire_rain_state != "":
		return
	dragon_flight_time += delta
	boss_actor.sprite.position.y = sin(dragon_flight_time * 1.6) * 5.0
	var patrol_center: float = right_platform_x + right_platform_offset
	var patrol_range: float = min(right_platform_offset - 6.0, (world_width - right_platform_x) * 0.4)
	boss_actor.global_position.x = patrol_center + sin(dragon_flight_time * 0.5) * patrol_range

func _update_fire_rain(delta: float) -> void:
	match fire_rain_state:
		"":
			if slam_windup > 0.0:
				return
			fire_rain_timer -= delta
			if fire_rain_timer <= 0.0:
				fire_rain_state = "vanish"
				fire_rain_state_time = FIRE_RAIN_VANISH_TIME
				report_event("O DRAGAO ALCA VOO E SOME NO CEU!")
		"vanish":
			fire_rain_state_time -= delta
			boss_actor.sprite.modulate.a = clampf(fire_rain_state_time / FIRE_RAIN_VANISH_TIME, 0.0, 1.0)
			boss_actor.sprite.position.y -= 44.0 * delta
			if fire_rain_state_time <= 0.0:
				boss_actor.visible = false
				fire_rain_state = "raining"
				fire_rain_wave_index = 0
				fire_rain_wave_timer = 0.0
				report_event("CHUVA DE FOGO DO CEU — AFASTE-SE DO CENTRO!")
		"raining":
			fire_rain_wave_timer -= delta
			if fire_rain_wave_timer <= 0.0:
				_spawn_fire_wave(fire_rain_wave_index)
				fire_rain_wave_index += 1
				fire_rain_wave_timer = FIRE_RAIN_WAVE_GAP
				if fire_rain_wave_index >= FIRE_RAIN_WAVE_COUNT:
					fire_rain_state = "returning"
					fire_rain_state_time = FIRE_RAIN_RETURN_TIME
					boss_actor.visible = true
					boss_actor.sprite.modulate.a = 0.0
					boss_actor.sprite.position.y = -44.0
					boss_actor.global_position.x = right_platform_x + right_platform_offset
		"returning":
			fire_rain_state_time -= delta
			var t: float = 1.0 - clampf(fire_rain_state_time / FIRE_RAIN_RETURN_TIME, 0.0, 1.0)
			boss_actor.sprite.modulate.a = t
			boss_actor.sprite.position.y = lerp(-44.0, 0.0, t)
			if fire_rain_state_time <= 0.0:
				boss_actor.sprite.modulate.a = 1.0
				boss_actor.sprite.position.y = 0.0
				fire_rain_state = ""
				fire_rain_timer = FIRE_RAIN_INTERVAL
				report_event("O DRAGAO RETORNA!")

func _spawn_fire_wave(wave_index: int) -> void:
	# Onda 0 cai exatamente no centro da sala; as seguintes se espalham em
	# pares simetricos (esquerda/direita) cada vez mais perto dos cantos.
	var half_width: float = world_width * 0.5
	var step: float = half_width / float(FIRE_RAIN_WAVE_COUNT)
	var band_w: float = clampf(step + 6.0, 14.0, 60.0)
	var center_x: float = world_width * 0.5
	if wave_index == 0:
		_spawn_fire_impact(center_x, band_w)
		return
	var off: float = wave_index * step
	_spawn_fire_impact(clampf(center_x + off, band_w * 0.5, world_width - band_w * 0.5), band_w)
	_spawn_fire_impact(clampf(center_x - off, band_w * 0.5, world_width - band_w * 0.5), band_w)

func _spawn_fire_impact(center_x: float, band_w: float) -> void:
	var warn := ColorRect.new()
	warn.color = Color(1.0, 0.3, 0.1, 0.4)
	warn.position = Vector2(center_x - band_w * 0.5, -10.0)
	warn.size = Vector2(band_w, GROUND_TOP + 10.0)
	warn.z_index = 5
	world_layer.add_child(warn)
	get_tree().create_timer(FIRE_RAIN_WARN_TIME).timeout.connect(_resolve_fire_impact.bind(warn, center_x, band_w))

func _resolve_fire_impact(warn: ColorRect, center_x: float, band_w: float) -> void:
	if is_instance_valid(warn):
		warn.queue_free()
	for member in party_slots:
		if is_instance_valid(member) and member.alive:
			if absf(member.global_position.x - center_x) <= band_w * 0.5:
				member.take_damage(FIRE_RAIN_DAMAGE, boss_actor)
				var dir: float = signf(member.global_position.x - center_x)
				if dir == 0.0:
					dir = 1.0
				member.velocity = Vector2(dir * 160.0, -140.0)
	var scorch := ColorRect.new()
	scorch.color = Color(0.08, 0.05, 0.04, 0.55)
	scorch.position = Vector2(center_x - band_w * 0.5, GROUND_TOP - 2.0)
	scorch.size = Vector2(band_w, 4.0)
	scorch.z_index = -1
	world_layer.add_child(scorch)

# --- HUD ---------------------------------------------------------------------

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	if is_portrait:
		var refs := BossHudPortrait12.build_hud(canvas, "DRAGAO")
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

	var body_font: FontFile = load("res://assets/Fonts/Runtime/AoboshiOne-Regular.ttf")

	boss_name_label = Label.new()
	boss_name_label.text = "DRAGAO"
	boss_name_label.position = Vector2(boss_bar_pos.x, boss_bar_pos.y - 8.0)
	boss_name_label.size = Vector2(boss_bar_size.x, 8)
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.add_theme_font_override("font", body_font)
	boss_name_label.add_theme_font_size_override("font_size", 6)
	boss_name_label.add_theme_color_override("font_color", Color("ffb35c"))
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

	var title_font: FontFile = load("res://assets/Fonts/Runtime/AoboshiOne-Regular.ttf")

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
		objective_label.text = "derrote o Dragao — H interrompe o sopro — H da Heroina cria uma ponte"
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
	is_paused = not is_paused
	get_tree().paused = is_paused
	pause_layer.visible = is_paused

const PAUSE_INSTRUCTIONS := "OBJETIVO\nHa um VAO entre seu grupo e o DRAGAO — use a especial (H) da\nHEROINA DA PONTE perto do vao para construir uma travessia\ntemporaria (ela some apos alguns segundos). Cair no vao mata\no personagem ativo. Do outro lado, derrote o Dragao — de\ntempos em tempos ele inspira para um SOPRO DE FOGO em area\n(aviso na tela) — a especial de QUALQUER personagem durante\no aviso INTERROMPE o golpe e causa dano bonus. De tempos em\ntempos ele tambem SOME NO CEU e chove fogo, comecando no\ncentro da sala e se espalhando para os cantos — esse ataque\nNAO se interrompe, so se esquiva saindo da faixa avisada.\n\nCONTROLES\nA/D mover | ESPACO pular (2x no ar) | K dash\n1/2/3 trocar personagem | J atacar | H especial\nR reiniciar a fase | ESC pausar/continuar"

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

	var panel := KenneyUI12.make_panel(Vector2(268, 170), Color(0.06, 0.065, 0.09, 0.94))
	panel.position = Vector2(26, 6)
	pause_layer.add_child(panel)

	var title_font: FontFile = load("res://assets/Fonts/Runtime/AoboshiOne-Regular.ttf")
	var body_font: FontFile = load("res://assets/Fonts/Runtime/AoboshiOne-Regular.ttf")

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
	KenneyUI12.style_button(resume_btn, true, 8, Vector2(100, 18))
	resume_btn.pressed.connect(_toggle_pause)
	pause_layer.add_child(resume_btn)

	var back_btn := Button.new()
	back_btn.text = "VOLTAR A SELECAO"
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.position = Vector2(156, 150)
	KenneyUI12.style_button(back_btn, false, 8, Vector2(120, 18))
	back_btn.pressed.connect(_on_back_to_select_pressed)
	pause_layer.add_child(back_btn)

	pause_layer.visible = false

func _on_back_to_select_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(STAGE_SELECT_SCENE)
