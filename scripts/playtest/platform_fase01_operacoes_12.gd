extends Node2D

## Fase 01 - Operacoes & Logistica (pedido do usuario, mapa de referencia
## "mapa tecnico / greybox" com 11 salas L01-L11 + area secreta L08).
## Modelada em cima de platform_party_12.gd (mundo largo continuo, camera
## com WORLD_WIDTH, party seguidora/handoff, HUD, pause) em vez dos
## platform_boss_*_12.gd (arena unica) porque o mapa de referencia e um
## corredor horizontal longo, nao uma sala compacta.
##
## O mapa original mede cada sala em "telas" (~1 largura de camera = 320px)
## somando ~40 telas no total; a propria legenda do mapa autoriza ajustar
## distancias/alturas na producao ("OBS: elementos representam layout
## conceitual"). Comprimido aqui para ~20 telas (WORLD_WIDTH=6320) mantendo
## a ORDEM e a mecânica de cada sala, os checkpoints, o subchefe (L06), o
## chefe final (L11) e as duas rotas opcionais (L08 secreta / L09 caixa
## pesada) — sem exigir precisao de pulo extrema, igual o mapa pede.
##
## Mecanicas novas (todas aqui, sem tocar platform_actor_12.gd alem do
## necessario pros 2 novos papeis jogaveis/especial): caixa empurravel leve
## (qualquer um) e pesada (so quem tem o papel "almoxarifado" no grupo),
## elevador de carga e gancho/vagonete (plataformas StaticBody2D movidas a
## mao em _physics_process, com "carona" manual de quem estiver em cima —
## mais simples e previsivel que depender de AnimatableBody2D+sincronismo
## de fisica pra um projeto deste porte) e esteira transportadora (nudge de
## velocidade horizontal em quem estiver parado em cima).

const Actor = preload("res://scripts/playtest/platform_actor_12.gd")
const Projectile = preload("res://scripts/playtest/platform_projectile_12.gd")
const PauseWatcher = preload("res://scripts/playtest/pause_watcher_12.gd")
const TouchControls = preload("res://scenes/playtest/touch_controls_12.tscn")
const STAGE_SELECT_SCENE := "res://scenes/menu/stage_select_12.tscn"
const VICTORY_CUTSCENE_SCENE := "res://scenes/menu/victory_cutscene_12.tscn"

const WORLD_WIDTH := 6320.0
const DEATH_Y := 360.0
## Camera fica centrada em y=205 (mesmo padrao de platform_party_12.gd),
## entao em paisagem (altura 180) a faixa visivel vai de y=115 a y=295 —
## FLOOR_Y precisa ficar dentro disso (284, igual ao chao da Caverna) ou o
## personagem fica cortado pela borda inferior da tela.
const FLOOR_Y := 284.0

var is_portrait := false
var camera_half_width := 160.0

const WAREHOUSE_BG_PATH := "res://assets/Environment/Warehouse/Runtime/warehouse_bg.png"
const CRATE_LIGHT_TEX := preload("res://assets/Environment/Warehouse/Runtime/crate_light.png")
const CRATE_HEAVY_TEX := preload("res://assets/Environment/Warehouse/Runtime/crate_heavy.png")
const CONVEYOR_TEX := preload("res://assets/Environment/Warehouse/Runtime/conveyor_tile.png")
const ELEVATOR_TEX := preload("res://assets/Environment/Warehouse/Runtime/elevator_platform.png")
const HOOK_TEX := preload("res://assets/Environment/Warehouse/Runtime/hook_cart.png")
const TERMINAL_TEX := preload("res://assets/Environment/Warehouse/Runtime/terminal.png")
const CHECKPOINT_TEX := preload("res://assets/Environment/Warehouse/Runtime/checkpoint_beacon.png")

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
var cooldown_bars: Array = []
var event_timeout := 0.0
var completed := false
var game_over := false

var pause_layer: CanvasLayer
var is_paused := false

var last_checkpoint_x := 60.0
const CHECKPOINT_XS := [60.0, 1280.0, 3200.0, 4400.0, 5680.0]

# --- Crates ---
var crates: Array[StaticBody2D] = []
const CRATE_PUSH_SPEED := 34.0

# --- Moving platforms (elevador L04 / gancho L05) ---
var elevator_body: StaticBody2D
var elevator_t := 0.0
const ELEVATOR_X := 2010.0
const ELEVATOR_TOP_Y := 180.0
const ELEVATOR_BOTTOM_Y := 284.0
const ELEVATOR_PERIOD := 4.6

var hook_body: StaticBody2D
var hook_t := 0.0
const HOOK_Y := 180.0
const HOOK_LEFT_X := 2600.0
const HOOK_RIGHT_X := 3080.0
const HOOK_PERIOD := 5.2

# --- Esteiras (conveyors): retangulos world-space + velocidade ---
var conveyor_zones: Array = []

# --- Subchefe / chefe ---
var especialista: Actor
var especialista_wall: StaticBody2D
var danelmo: Actor
var boss_reward_given := false

# --- Companion secreto L08 ---
var protocolo_area: Area2D
var protocolo_claimed := false

func _ready() -> void:
	is_portrait = DeviceLayout12.is_portrait
	camera_half_width = 90.0 if is_portrait else 160.0
	_build_world()
	_spawn_party()
	_spawn_enemies()
	_build_hud()
	_build_pause_menu()
	_build_pause_watcher()
	_set_active_party_slot(0, false)
	_update_hud()


func _physics_process(delta: float) -> void:
	if game_over or is_paused:
		return
	_update_moving_platforms(delta)
	_update_conveyors(delta)
	_update_crates(delta)


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
	_check_checkpoints()
	_check_secret_companion()
	_enforce_especialista_gate()

	if event_timeout > 0.0:
		event_timeout -= delta
		if event_timeout <= 0.0 and is_instance_valid(event_label):
			event_label.text = ""

	_update_hud()


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
	report_event("%s: ESPECIAL" % actor.actor_name)


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


# --- No-ops pra papeis cujo mecanismo de cenario nao existe nesta fase
# (mesmo padrao ja usado nas fases de boss sem entulho/vao pra Heroina da
# Ponte) — evita erro de chamada quando o jogador escala um papel "livre"
# fora do trio novo desta fase.
func try_break_rubble(_actor: Actor) -> void:
	pass


func summon_bridge_from(_actor: Actor) -> void:
	pass


func fire_burst_from(actor: Actor) -> void:
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.alive:
			if enemy.global_position.distance_to(actor.global_position) <= 46.0:
				enemy.take_damage(1, actor)


func teleport_actor(actor: Actor, direction: float) -> void:
	var distance := 240.0
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


func _check_falls() -> void:
	for actor in actors:
		if not is_instance_valid(actor) or not actor.alive or actor.global_position.y <= DEATH_Y:
			continue
		if actor.team == "ally":
			if actor.is_controlled:
				# Fase muito mais longa que a Caverna — cair volta pro
				# ultimo checkpoint em vez de matar o grupo inteiro
				# (o mapa de referencia pede "nenhum salto obrigatorio com
				# precisao extrema").
				_respawn_party_at_checkpoint()
				report_event("QUEDA — voltando ao ultimo checkpoint")
				return
			else:
				_rescue_inactive_ally(actor)
		else:
			actor.force_kill()


func _respawn_party_at_checkpoint() -> void:
	var y := FLOOR_Y - 8.0
	if last_checkpoint_x > ELEVATOR_X and last_checkpoint_x < HOOK_RIGHT_X + 60.0:
		y = ELEVATOR_TOP_Y - 8.0
	for i in range(party_slots.size()):
		var member: Actor = party_slots[i]
		if is_instance_valid(member) and member.alive:
			member.global_position = Vector2(last_checkpoint_x + i * 14.0, y)
			member.velocity = Vector2.ZERO


func _rescue_inactive_ally(actor: Actor) -> void:
	if not is_instance_valid(active_actor) or not active_actor.alive:
		return
	var preferred_x: float = clampf(active_actor.global_position.x + actor.follow_offset_x, 18.0, WORLD_WIDTH - 18.0)
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


func _on_actor_died(actor: Actor) -> void:
	if actor.team == "enemy":
		active_enemies = maxi(0, active_enemies - 1)
		report_event("%s DERROTADO" % actor.actor_name)
		if actor == especialista and is_instance_valid(especialista_wall):
			especialista_wall.queue_free()
			report_event("ESPECIALISTA DERROTADO — CAMINHO LIBERADO")
		if actor == danelmo:
			_handle_victory_reward()
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


func _handle_victory_reward() -> void:
	if boss_reward_given:
		return
	boss_reward_given = true
	completed = true
	SaveSystem12.save_game()
	PartySelection12.unlock_role("almoxarifado")
	report_event("DANELMO GROSSMANOBRA DERROTADO — Rapaz do Almoxarifado se junta ao grupo!")
	await get_tree().create_timer(2.6).timeout
	PartySelection12.last_unlocked_role = "almoxarifado"
	get_tree().change_scene_to_file(VICTORY_CUTSCENE_SCENE)


func _alive_party_count() -> int:
	var count := 0
	for member in party_slots:
		if is_instance_valid(member) and member.alive:
			count += 1
	return count


func _update_camera() -> void:
	if not is_instance_valid(camera) or not is_instance_valid(active_actor):
		return
	var target_x: float = clampf(active_actor.global_position.x, camera_half_width, WORLD_WIDTH - camera_half_width)
	camera.global_position = Vector2(target_x, 205)


func report_event(message: String) -> void:
	if is_instance_valid(event_label):
		event_label.text = message
	event_timeout = 3.2


# ============================================================
# MUNDO
# ============================================================

func _build_world() -> void:
	world_layer = Node2D.new()
	world_layer.name = "World"
	add_child(world_layer)

	_add_background()

	# Chao continuo (L01-L03, L06-L11) — as unicas quebras reais sao o poco
	# do elevador (L04) e o vao do gancho (L05), onde o chao alto some de
	# proposito pra obrigar o uso da mecanica nova.
	_add_platform(Rect2(0, FLOOR_Y, ELEVATOR_X - 4.0, 30), false)
	_add_platform(Rect2(HOOK_RIGHT_X + 60.0, FLOOR_Y, WORLD_WIDTH - (HOOK_RIGHT_X + 60.0), 30), false)

	_build_l01()
	_build_l02()
	_build_l03()
	_build_l04_l05()
	_build_l06()
	_build_l07_l08()
	_build_l09()
	_build_l10()
	_build_l11()

	_add_wall_collision(Rect2(-12, 0, 12, DEATH_Y))
	_add_wall_collision(Rect2(WORLD_WIDTH, 0, 12, DEATH_Y))

	actor_layer = Node2D.new()
	actor_layer.name = "Actors"
	actor_layer.y_sort_enabled = true
	add_child(actor_layer)

	projectile_layer = Node2D.new()
	projectile_layer.name = "Projectiles"
	add_child(projectile_layer)

	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(WORLD_WIDTH)
	camera.limit_bottom = 360
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.enabled = true
	camera.global_position = Vector2(camera_half_width, 205)
	add_child(camera)


func _add_background() -> void:
	var bg_tex: Texture2D = load(WAREHOUSE_BG_PATH)
	var bg_w: float = bg_tex.get_width()
	var copies: int = int(ceil(WORLD_WIDTH / bg_w)) + 1
	for i in range(copies):
		var spr := Sprite2D.new()
		spr.texture = bg_tex
		spr.centered = false
		spr.position = Vector2(float(i) * bg_w, -30.0)
		spr.z_index = -10
		world_layer.add_child(spr)


func _add_platform(rect: Rect2, one_way: bool) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = rect.get_center()
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	shape.shape = rs
	if one_way:
		shape.one_way_collision = true
	body.add_child(shape)
	world_layer.add_child(body)
	_draw_platform_visual(rect, one_way)


func _draw_platform_visual(rect: Rect2, one_way: bool) -> void:
	var visual := ColorRect.new()
	visual.position = rect.position
	visual.size = rect.size
	visual.color = Color("5ca0b4") if one_way else Color("484f5c")
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_layer.add_child(visual)
	var rim := ColorRect.new()
	rim.position = rect.position
	rim.size = Vector2(rect.size.x, 3)
	rim.color = Color("e6b41e") if one_way else Color("707888")
	rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_layer.add_child(rim)


func _add_wall_collision(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = rect.get_center()
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	shape.shape = rs
	body.add_child(shape)
	world_layer.add_child(body)


func _add_gap_marker(x: float) -> void:
	var label := Label.new()
	label.text = "QUEDA = VOLTA AO CHECKPOINT"
	label.position = Vector2(x, 322.0)
	label.add_theme_font_size_override("font_size", 6)
	label.add_theme_color_override("font_color", Color("ff9b6b"))
	world_layer.add_child(label)


func _add_room_label(x: float, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.position = Vector2(x, 6.0)
	label.add_theme_font_size_override("font_size", 7)
	label.add_theme_color_override("font_color", Color("ffe26f"))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 3)
	world_layer.add_child(label)


func _add_checkpoint(x: float) -> void:
	var area := Area2D.new()
	area.position = Vector2(x, FLOOR_Y - 16.0)
	area.collision_layer = 0
	area.collision_mask = 2
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(20, 40)
	shape.shape = rs
	area.add_child(shape)
	var spr := Sprite2D.new()
	spr.texture = CHECKPOINT_TEX
	area.add_child(spr)
	world_layer.add_child(area)
	area.set_meta("checkpoint_x", x)
	area.body_entered.connect(func(_body): _on_checkpoint_reached(area))


func _on_checkpoint_reached(area: Area2D) -> void:
	var x: float = area.get_meta("checkpoint_x")
	# Enquanto o especialista (L06) estiver vivo, nenhum checkpoint alem do
	# portao pode ser registrado — mesmo defesa da trava logica em
	# _enforce_especialista_gate(), evitando o HUD mostrar um checkpoint
	# "a frente" que o proprio grupo nao pode fisicamente ter alcancado.
	if is_instance_valid(especialista) and especialista.alive and is_instance_valid(especialista_wall):
		x = minf(x, especialista_wall.position.x - 8.0)
	if x > last_checkpoint_x:
		last_checkpoint_x = x
		report_event("CHECKPOINT ALCANCADO")


func _check_checkpoints() -> void:
	pass # deteccao feita via Area2D.body_entered (_on_checkpoint_reached)


func _add_terminal(x: float, y: float, flavor: String) -> void:
	var area := Area2D.new()
	area.position = Vector2(x, y)
	area.collision_layer = 0
	area.collision_mask = 2
	var shape := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 24.0
	shape.shape = cs
	area.add_child(shape)
	var spr := Sprite2D.new()
	spr.texture = TERMINAL_TEX
	spr.offset = Vector2(0, -14)
	area.add_child(spr)
	world_layer.add_child(area)
	area.body_entered.connect(func(_body): report_event(flavor))


func _add_crate(x: float, y: float, heavy: bool) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector2(x, y)
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	var crate_size: float = 32.0 if heavy else 28.0
	rs.size = Vector2(crate_size, crate_size)
	shape.shape = rs
	body.add_child(shape)
	var spr := Sprite2D.new()
	spr.texture = CRATE_HEAVY_TEX if heavy else CRATE_LIGHT_TEX
	body.add_child(spr)
	world_layer.add_child(body)
	body.set_meta("heavy", heavy)
	body.set_meta("half_w", rs.size.x * 0.5)
	crates.append(body)
	return body


func _add_conveyor(rect: Rect2, dir: float) -> void:
	_add_platform(Rect2(rect.position.x, rect.position.y, rect.size.x, rect.size.y), false)
	var speed: float = rect.size.x
	conveyor_zones.append({"rect": Rect2(rect.position.x, rect.position.y - 12.0, rect.size.x, 14.0), "speed": 44.0 * dir})
	var strip_count: int = int(rect.size.x / 32.0)
	for i in range(strip_count):
		var spr := Sprite2D.new()
		spr.texture = CONVEYOR_TEX
		spr.centered = false
		spr.position = Vector2(rect.position.x + i * 32.0, rect.position.y - 10.0)
		spr.flip_h = dir < 0.0
		world_layer.add_child(spr)


# ============================================================
# SALAS L01-L11 (mapa de referencia comprimido, mesma ordem/mecanica)
# ============================================================

func _build_l01() -> void:
	_add_room_label(10, "L01 — DOCAS DE RECEBIMENTO")
	# Teto baixo + caixa leve bloqueando: so passa empurrando a caixa (nao
	# da pra pular por cima, o teto barra o pulo). Vao de ~32px entre chao
	# (FLOOR_Y) e a base do teto — da pra andar por baixo, nao pra pular.
	_add_platform(Rect2(280, FLOOR_Y - 46.0, 120, 14), false)
	_add_crate(320, FLOOR_Y - 14.0, false)
	var hint := Label.new()
	hint.text = "EMPURRE A CAIXA >>"
	hint.position = Vector2(270, FLOOR_Y - 64.0)
	hint.add_theme_font_size_override("font_size", 6)
	hint.add_theme_color_override("font_color", Color("ffe26f"))
	world_layer.add_child(hint)

	_add_conveyor(Rect2(460, FLOOR_Y, 150, 6), 1.0)
	_add_terminal(560, FLOOR_Y - 24.0, "TERMINAL: \"Docas de Recebimento — valide a mercadoria antes de liberar.\"")


func _build_l02() -> void:
	_add_room_label(660, "L02 — TRIAGEM DE MERCADORIAS")
	_add_platform(Rect2(760, 250, 90, 14), true)
	_add_platform(Rect2(980, 250, 90, 14), true)
	_add_conveyor(Rect2(1080, FLOOR_Y, 150, 6), -1.0)
	_add_terminal(820, FLOOR_Y - 24.0, "TERMINAL: \"Triagem concluida — siga para conferencia.\"")
	_add_checkpoint(1280.0)


func _build_l03() -> void:
	_add_room_label(1300, "L03 — SEPARACAO E CONFERENCIA")
	_add_platform(Rect2(1420, 258, 80, 14), true)
	_add_platform(Rect2(1560, 226, 80, 14), true)
	_add_platform(Rect2(1700, 258, 80, 14), true)
	_add_terminal(1500, FLOOR_Y - 24.0, "TERMINAL: \"Separacao e conferencia — lotes conferidos.\"")
	_add_conveyor(Rect2(1800, FLOOR_Y, 100, 6), 1.0)


func _build_l04_l05() -> void:
	_add_room_label(1940, "L04 — ARMAZENAGEM VERTICAL")
	# Sem chao em y=FLOOR_Y daqui ate o fim do L05 (ver _build_world) — so o
	# elevador (L04) e o gancho (L05) atravessam.
	elevator_body = StaticBody2D.new()
	elevator_body.collision_layer = 1
	elevator_body.collision_mask = 0
	elevator_body.position = Vector2(ELEVATOR_X, ELEVATOR_BOTTOM_Y)
	var elev_shape := CollisionShape2D.new()
	var elev_rs := RectangleShape2D.new()
	elev_rs.size = Vector2(56, 10)
	elev_shape.shape = elev_rs
	elev_shape.one_way_collision = true
	elevator_body.add_child(elev_shape)
	var elev_spr := Sprite2D.new()
	elev_spr.texture = ELEVATOR_TEX
	elevator_body.add_child(elev_spr)
	world_layer.add_child(elevator_body)

	_add_platform(Rect2(2020, ELEVATOR_TOP_Y - 4.0, 540, 10), true)
	_add_room_label(2560, "L05 — OPERACOES INTERNAS")

	hook_body = StaticBody2D.new()
	hook_body.collision_layer = 1
	hook_body.collision_mask = 0
	hook_body.position = Vector2(HOOK_LEFT_X, HOOK_Y + 30.0)
	var hook_shape := CollisionShape2D.new()
	var hook_rs := RectangleShape2D.new()
	hook_rs.size = Vector2(52, 14)
	hook_shape.shape = hook_rs
	hook_shape.one_way_collision = true
	hook_body.add_child(hook_shape)
	var hook_spr := Sprite2D.new()
	hook_spr.texture = HOOK_TEX
	hook_spr.offset = Vector2(-26, -44)
	hook_body.add_child(hook_spr)
	world_layer.add_child(hook_body)

	_add_terminal(2100, ELEVATOR_TOP_Y - 24.0, "TERMINAL: \"Armazenagem vertical — use o elevador de carga.\"")
	_add_gap_marker(ELEVATOR_X + 40.0)

	# Escada de plataformas descendo de volta ao chao normal depois do
	# gancho, ate o checkpoint em x=3200 (inicio do L06).
	_add_platform(Rect2(HOOK_RIGHT_X + 10.0, 220, 70, 12), true)
	_add_platform(Rect2(HOOK_RIGHT_X + 90.0, 260, 70, 12), true)
	_add_checkpoint(3200.0)


func _build_l06() -> void:
	_add_room_label(3220, "L06 — ARENA DO ESPECIALISTA")
	especialista_wall = StaticBody2D.new()
	especialista_wall.collision_layer = 1
	especialista_wall.collision_mask = 0
	especialista_wall.position = Vector2(3740, 200)
	var wall_shape := CollisionShape2D.new()
	var wall_rs := RectangleShape2D.new()
	wall_rs.size = Vector2(10, 200)
	wall_shape.shape = wall_rs
	especialista_wall.add_child(wall_shape)
	world_layer.add_child(especialista_wall)
	var wall_visual := ColorRect.new()
	wall_visual.position = Vector2(3735, 100)
	wall_visual.size = Vector2(10, 200)
	wall_visual.color = Color(0.75, 0.2, 0.2, 0.85)
	world_layer.add_child(wall_visual)
	especialista_wall.set_meta("visual", wall_visual)


func _build_l07_l08() -> void:
	_add_room_label(3780, "L07 — NUCLEO DO ARMAZEM")
	_add_terminal(3900, FLOOR_Y - 24.0, "TERMINAL: \"Nucleo do armazem — rotas de revisita liberadas.\"")
	_add_conveyor(Rect2(4020, FLOOR_Y, 120, 6), -1.0)

	# Caminho secreto pra L08 (companion "Protocolo"): 2 degraus curtos ate
	# uma plataforma alta escondida atras do rotulo da sala — pulo duplo
	# comum alcanca, sem precisao extrema.
	_add_platform(Rect2(3980, 260, 60, 12), true)
	_add_platform(Rect2(4080, 210, 90, 12), true)
	var alcove := Label.new()
	alcove.text = "L08 — AREA SECRETA (PROTOCOLO)"
	alcove.position = Vector2(4080, 190)
	alcove.add_theme_font_size_override("font_size", 6)
	alcove.add_theme_color_override("font_color", Color("ff9be0"))
	world_layer.add_child(alcove)

	protocolo_area = Area2D.new()
	protocolo_area.position = Vector2(4125, 196)
	protocolo_area.collision_layer = 0
	protocolo_area.collision_mask = 2
	var pshape := CollisionShape2D.new()
	var pcs := CircleShape2D.new()
	pcs.radius = 16.0
	pshape.shape = pcs
	protocolo_area.add_child(pshape)
	var pspr := Sprite2D.new()
	pspr.texture = CHECKPOINT_TEX
	pspr.modulate = Color("ff9be0")
	protocolo_area.add_child(pspr)
	world_layer.add_child(protocolo_area)

	_add_checkpoint(4400.0)


func _build_l09() -> void:
	_add_room_label(4420, "L09 — EXPEDICAO PESADA")
	# Caixa pesada bloqueia um atalho baixo (opcional); o desvio por cima
	# (plataforma one-way) sempre disponivel, sem exigir o Almoxarifado —
	# so quem ja tem o companion consegue abrir o atalho por baixo.
	_add_platform(Rect2(4600, 268, 140, 12), true)
	_add_crate(4640, FLOOR_Y - 16.0, true)
	var hint := Label.new()
	hint.text = "ATALHO (requer Almoxarifado) ou desvie por cima"
	hint.position = Vector2(4560, 250)
	hint.add_theme_font_size_override("font_size", 6)
	hint.add_theme_color_override("font_color", Color("ffb45c"))
	world_layer.add_child(hint)
	_add_terminal(4850, FLOOR_Y - 24.0, "TERMINAL: \"Expedicao pesada — equipamentos de risco elevado.\"")


func _build_l10() -> void:
	_add_room_label(5060, "L10 — DOCA CENTRAL")
	_add_terminal(5200, FLOOR_Y - 24.0, "TERMINAL: \"Doca central — ultima verificacao antes da area do chefe.\"")
	_add_platform(Rect2(5380, 254, 90, 14), true)
	_add_checkpoint(5680.0)


func _build_l11() -> void:
	_add_room_label(5700, "L11 — ARENA DE DANELMO GROSSMANOBRA")
	_add_platform(Rect2(5900, 254, 80, 14), true)
	_add_platform(Rect2(6100, 254, 80, 14), true)


# ============================================================
# PARTY / INIMIGOS
# ============================================================

const ROLE_TINT := {
	"cavaleiro_executivo": Color("d4af37"),
	"warrior": Color("cfd6e0"),
	"archer": Color("8fd67a"),
	"mage": Color("b48cff"),
	"fire_mage": Color("ff9a52"),
	"lightning_mage": Color("fff27a"),
	"wanderer": Color("7fe0d1"),
	"paladin": Color("e8e8f0"),
	"knight": Color("9fb0c9"),
	"bridge_heroine": Color("ffb0d0"),
	"almoxarifado": Color("ffb04a"),
	"protocolo": Color("6fcf9a"),
}

const SLOT_SPAWN_X := [80.0, 55.0, 30.0]
const SLOT_FOLLOW_OFFSET := [-36.0, -36.0, -72.0]

func _role_tint(role: String) -> Color:
	return ROLE_TINT.get(role, Color("ffe26f"))

const ROLE_OBJECTIVE_LINE := {
	"cavaleiro_executivo": "corpo a corpo (Estocada)",
	"warrior": "corpo a corpo (Estocada)",
	"protocolo": "corpo a corpo (Estocada)",
	"fire_mage": "corpo a corpo com Rajada de Fogo",
	"paladin": "corpo a corpo com Rajada de Fogo",
	"archer": "a distancia (Tiro Perfurante)",
	"lightning_mage": "a distancia (Tiro Perfurante)",
	"almoxarifado": "a distancia (Arremesso Perfurante)",
	"mage": "Teleporte",
	"wanderer": "Teleporte",
	"knight": "corpo a corpo (Escudo)",
	"bridge_heroine": "corpo a corpo",
}

func _spawn_party() -> void:
	var roles: Array[String] = PartySelection12.get_party_roles()
	party_slots = []
	for i in range(roles.size()):
		var role: String = roles[i]
		var display_name: String = Actor.DISPLAY_NAME.get(role, role.to_upper())
		var tint: Color = _role_tint(role)
		var actor := _spawn_actor(display_name, "ally", role, Vector2(SLOT_SPAWN_X[i], FLOOR_Y - 10.0), tint, i)
		actor.follow_offset_x = SLOT_FOLLOW_OFFSET[i]
		party_slots.append(actor)


func _spawn_enemies() -> void:
	especialista = _spawn_actor("ESPECIALISTA DE SEGURANCA", "enemy", "especialista", Vector2(3480, FLOOR_Y - 20.0), Color("6fa8ff"))
	danelmo = _spawn_actor("DANELMO GROSSMANOBRA", "enemy", "danelmo", Vector2(6000, FLOOR_Y - 30.0), Color("b03040"))


func _has_role_in_party(role: String) -> bool:
	for member in party_slots:
		if is_instance_valid(member) and member.alive and member.role == role:
			return true
	return false


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


# ============================================================
# MECANICAS: elevador/gancho, esteiras, caixas, area secreta
# ============================================================

func _update_moving_platforms(delta: float) -> void:
	if is_instance_valid(elevator_body):
		elevator_t += delta
		var phase: float = fmod(elevator_t, ELEVATOR_PERIOD) / ELEVATOR_PERIOD
		var ping: float = 1.0 - absf(phase * 2.0 - 1.0) # 0 -> 1 -> 0
		var new_y: float = lerpf(ELEVATOR_BOTTOM_Y, ELEVATOR_TOP_Y, ping)
		var dy: float = new_y - elevator_body.position.y
		elevator_body.position.y = new_y
		_carry_riders(elevator_body, Vector2(0, dy), 30.0)

	if is_instance_valid(hook_body):
		hook_t += delta
		var phase2: float = fmod(hook_t, HOOK_PERIOD) / HOOK_PERIOD
		var ping2: float = 1.0 - absf(phase2 * 2.0 - 1.0)
		var new_x: float = lerpf(HOOK_LEFT_X, HOOK_RIGHT_X, ping2)
		var dx: float = new_x - hook_body.position.x
		hook_body.position.x = new_x
		_carry_riders(hook_body, Vector2(dx, 0), 28.0)


func _carry_riders(platform: StaticBody2D, delta_move: Vector2, half_w: float) -> void:
	for actor in actors:
		if not is_instance_valid(actor) or not actor.alive:
			continue
		var rel: Vector2 = actor.global_position - platform.position
		if absf(rel.x) <= half_w and rel.y < 0.0 and rel.y > -20.0:
			actor.global_position += delta_move


func _update_conveyors(_delta: float) -> void:
	for actor in actors:
		if not is_instance_valid(actor) or not actor.alive or not actor.is_on_floor():
			continue
		for zone in conveyor_zones:
			var rect: Rect2 = zone["rect"]
			if rect.has_point(actor.global_position):
				actor.global_position.x += zone["speed"] * get_physics_process_delta_time()
				break


func _update_crates(delta: float) -> void:
	if not is_instance_valid(active_actor) or not active_actor.alive:
		return
	# Nao usa active_actor.velocity.x aqui: move_and_slide() zera a
	# velocidade no eixo bloqueado assim que o ator encosta na caixa (Godot
	# 4 sobrescreve `velocity` com o resultado pos-colisao), entao ler a
	# velocidade DEPOIS da colisao sempre daria ~0 bem na hora que importa
	# — um impasse. A intencao de empurrar vem direto do input.
	if not active_actor.is_on_floor():
		return
	var push_dir: float = Input.get_axis("move_left", "move_right")
	if absf(push_dir) < 0.1:
		return
	for crate in crates:
		if not is_instance_valid(crate):
			continue
		var heavy: bool = crate.get_meta("heavy")
		if heavy and not (is_instance_valid(active_actor) and active_actor.role == "almoxarifado"):
			continue
		var half_w: float = crate.get_meta("half_w")
		var rel: Vector2 = active_actor.global_position - crate.position
		if absf(rel.y) > 20.0:
			continue
		# So empurra quando o ator esta encostado no lado de onde vem o
		# movimento (evita "puxar" a caixa ao se afastar dela).
		if push_dir > 0.0 and rel.x < 0.0 and rel.x > -half_w - 10.0:
			if _crate_path_clear(crate, half_w, 1.0):
				crate.position.x += CRATE_PUSH_SPEED * delta
		elif push_dir < 0.0 and rel.x > 0.0 and rel.x < half_w + 10.0:
			if _crate_path_clear(crate, half_w, -1.0):
				crate.position.x -= CRATE_PUSH_SPEED * delta


## Uma StaticBody2D reposicionada por script (como a caixa) nao participa
## de resolucao de colisao — sem checar antes, ela atravessaria paredes e o
## bloqueio do L06 direto (foi exatamente o bug encontrado em teste: a
## caixa empurrada sem parar arrastava o grupo por cima da parede do
## especialista). Raycast curto na direcao do empurrao barra isso.
func _crate_path_clear(crate: StaticBody2D, half_w: float, direction: float) -> bool:
	var from: Vector2 = crate.global_position + Vector2(direction * (half_w + 1.0), 0.0)
	var to: Vector2 = from + Vector2(direction * (CRATE_PUSH_SPEED * 0.15 + 2.0), 0.0)
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [crate.get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty()


func _check_secret_companion() -> void:
	if protocolo_claimed or not is_instance_valid(protocolo_area) or not is_instance_valid(active_actor):
		return
	if active_actor.global_position.distance_to(protocolo_area.global_position) <= 18.0:
		protocolo_claimed = true
		PartySelection12.unlock_role("protocolo")
		SaveSystem12.save_game()
		report_event("SEGREDO ENCONTRADO — Rapaz do Protocolo se junta ao grupo!")


## Trava logica (alem da parede fisica) do portao do L06: nenhum membro do
## grupo passa de especialista_wall.position.x enquanto o especialista
## estiver vivo. Confirmado em teste que so a colisao fisica nao bastava —
## qualquer teleporte direto (resgate de follower apos queda, respawn no
## checkpoint) contorna `move_and_slide()` (Godot nao resolve colisao pra
## atribuicoes diretas de `global_position`), entao mesmo uma parede solida
## podia ser furada indiretamente. Clamp aqui garante o bloqueio sempre,
## nao importa qual caminho de codigo moveu o ator.
func _enforce_especialista_gate() -> void:
	if not is_instance_valid(especialista) or not especialista.alive:
		return
	if not is_instance_valid(especialista_wall):
		return
	var gate_x: float = especialista_wall.position.x - 8.0
	for actor in party_slots:
		if is_instance_valid(actor) and actor.alive and actor.global_position.x > gate_x:
			actor.global_position.x = gate_x
			if actor.velocity.x > 0.0:
				actor.velocity.x = 0.0


# ============================================================
# HUD / PAUSA
# ============================================================

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	if is_portrait:
		_build_hud_portrait(canvas)
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
	cooldown_bars = AbilityCooldownHud12.build(canvas, hp_bars)

	canvas.add_child(TouchControls.instantiate())


func _build_hud_portrait(canvas: CanvasLayer) -> void:
	var panel := ColorRect.new()
	panel.position = Vector2(0, 0)
	panel.size = Vector2(180, 30)
	panel.color = Color(0.02, 0.025, 0.035, 0.55)
	canvas.add_child(panel)

	party_label = Label.new()
	party_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	party_label.add_theme_font_size_override("font_size", 6)
	party_label.add_theme_color_override("font_color", Color("ffe26f"))
	party_label.position = Vector2(4, 0)
	party_label.custom_minimum_size = Vector2(172, 12)
	party_label.size = Vector2(172, 12)
	panel.add_child(party_label)

	objective_label = Label.new()
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	objective_label.add_theme_font_size_override("font_size", 5)
	objective_label.position = Vector2(4, 13)
	objective_label.custom_minimum_size = Vector2(172, 16)
	objective_label.size = Vector2(172, 16)
	panel.add_child(objective_label)

	var title_font: FontFile = load("res://assets/Fonts/Runtime/MedievalScrollOfWisdom.ttf")

	state_label = Label.new()
	state_label.position = Vector2(0, 150)
	state_label.size = Vector2(180, 30)
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_label.add_theme_font_override("font", title_font)
	state_label.add_theme_font_size_override("font_size", 12)
	state_label.add_theme_color_override("font_color", Color("ffe26f"))
	state_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	state_label.add_theme_constant_override("outline_size", 4)
	canvas.add_child(state_label)

	var help := Label.new()
	help.text = "ESC: pausar e ver instrucoes"
	help.position = Vector2(5, 296)
	help.add_theme_font_size_override("font_size", 6)
	canvas.add_child(help)

	event_label = Label.new()
	event_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	event_label.add_theme_font_size_override("font_size", 6)
	event_label.add_theme_color_override("font_color", Color("ffe26f"))
	event_label.position = Vector2(4, 32)
	event_label.custom_minimum_size = Vector2(172, 20)
	event_label.size = Vector2(172, 20)
	canvas.add_child(event_label)

	hp_bars = PartyHpBars12.build(canvas, party_slots, 34.0, _role_tint)
	cooldown_bars = AbilityCooldownHud12.build(canvas, hp_bars)

	canvas.add_child(TouchControls.instantiate())


func _update_hud() -> void:
	if not is_instance_valid(state_label):
		return

	if game_over:
		state_label.text = "GAME OVER — R reinicia"
	elif completed:
		state_label.text = "FASE CONCLUIDA — R reinicia"
	else:
		state_label.text = ""

	PartyHpBars12.update(hp_bars, active_actor)
	AbilityCooldownHud12.update(cooldown_bars)

	var parts: Array[String] = []
	for i in range(party_slots.size()):
		var member: Actor = party_slots[i]
		if not is_instance_valid(member):
			continue
		var marker := ">" if member == active_actor and member.alive else " "
		parts.append("%s%d:%s" % [marker, i + 1, member.actor_name])
	party_label.text = " | ".join(parts)

	var esp_status := "derrotado" if (is_instance_valid(especialista) and not especialista.alive) else "ativo"
	objective_label.text = "checkpoint x=%d | especialista %s | chefe %s" % [int(last_checkpoint_x), esp_status, ("derrotado" if boss_reward_given else "ativo")]


func _build_pause_watcher() -> void:
	var watcher := PauseWatcher.new()
	watcher.toggle_requested.connect(_toggle_pause)
	add_child(watcher)


func _toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	pause_layer.visible = is_paused


func _build_pause_menu() -> void:
	var objective_lines: Array[String] = []
	for member in party_slots:
		if is_instance_valid(member):
			objective_lines.append("%s: %s" % [member.actor_name, ROLE_OBJECTIVE_LINE.get(member.role, "")])
	var instructions_text := "OBJETIVO\nAtravesse as 11 salas da Operacoes & Logistica: empurre caixas,\nuse o elevador de carga e o gancho, desvie das esteiras e derrote\no Especialista de Seguranca e o chefe Danelmo Grossmanobra.\n%s\n\nCONTROLES\nA/D mover | ESPACO pular (2x no ar) | K dash\n1/2/3 trocar personagem | J atacar | H especial\nR reiniciar a fase | ESC pausar/continuar" % "\n".join(objective_lines)

	if is_portrait:
		pause_layer = BossHudPortrait12.build_pause_menu(instructions_text, _toggle_pause, _on_back_to_select_pressed)
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
	instructions.text = instructions_text
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
