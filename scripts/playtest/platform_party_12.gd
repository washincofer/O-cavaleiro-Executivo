extends Node2D

## Sprint 12: integra os packs de asset reais (Wizard Pack, Huntress 2,
## Medieval Warrior Pack 3, Monsters Creatures Fantasy 2, Pixel Cave Tileset)
## no trio jogavel Guerreiro / Arqueira / Maga e nos inimigos Rato / Gosma.
##
## Deriva da 11C (mundo, party, camera, seguidores protegidos, auto handoff)
## mas remove a mecanica de escada (nao fazia parte do kit do trio) e troca
## a plataforma central "inacancavel" por uma plataforma normal, ja que nao
## ha mais um companion utilitario dedicado a ela.

const Actor = preload("res://scripts/playtest/platform_actor_12.gd")
const Projectile = preload("res://scripts/playtest/platform_projectile_12.gd")
const PauseWatcher = preload("res://scripts/playtest/pause_watcher_12.gd")
const Switch = preload("res://scripts/playtest/platform_switch_12.gd")
const TouchControls = preload("res://scenes/playtest/touch_controls_12.tscn")
const STAGE_SELECT_SCENE := "res://scenes/menu/stage_select_12.tscn"

const WORLD_WIDTH := 1320.0
const DEATH_Y := 360.0

## Sprint 16: retrato so estreita o recorte horizontal da camera (WORLD_WIDTH
## e toda a geometria/distancias de pulo continuam intocadas — ja calibradas
## e testadas, ex.: o vao 3 de 220px so e cruzavel pelo teleporte da Maga por
## causa dessa distancia especifica). O fundo (`_add_background`) ja usa um
## ColorRect de ceu bem maior que a area jogavel (-50 a DEATH_Y+100=460), sem
## precisar do "sky fill" usado nas salas de boss — a camera so revela mais
## desse ceu ja existente. Camera Y fica fixo em 205.0 nos dois modos.
var is_portrait := false
var camera_half_width := 160.0

const CAVE_TILE_PATH := "res://assets/Environment/Cave/Runtime/cave_tileset.png"
const MOUNTAIN_PATH := "res://assets/Environment/Cave/Runtime/bg_mountains.png"
const TREES_PATH := "res://assets/Environment/Cave/Runtime/trees.png"
const CAVE_TILE_SIZE := Vector2i(16, 16)
const GROUND_RIM_COORD := Vector2i(4, 4)

var actors: Array[Actor] = []
var enemies: Array[Actor] = []
var party_slots: Array[Actor] = []
var active_actor: Actor = null
var active_party_slot := 0
var active_enemies := 0
var total_enemies := 0

var world_layer: Node2D
var cave_tileset: TileSet
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

var gate_switch: Switch
var gate_body: StaticBody2D
var gate_visual: ColorRect
var gate_open := false

var rubble_body: StaticBody2D
var rubble_visual: ColorRect
var rubble_broken := false

var ward_body: StaticBody2D
var ward_visual: ColorRect

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

	if event_timeout > 0.0:
		event_timeout -= delta
		if event_timeout <= 0.0 and is_instance_valid(event_label):
			event_label.text = ""

	if not completed and active_enemies <= 0 and total_enemies > 0:
		completed = true
		report_event("AREA LIMPA — trio venceu todos os inimigos")

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
	match actor.role:
		"warrior":
			report_event("%s: ESTOCADA" % actor.actor_name)
		"archer", "lightning_mage":
			report_event("%s: TIRO PERFURANTE" % actor.actor_name)
		"mage", "wanderer":
			report_event("%s: CONJURANDO TELEPORTE" % actor.actor_name)
		"fire_mage":
			report_event("%s: RAJADA DE FOGO" % actor.actor_name)

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

	if is_instance_valid(gate_switch) and not gate_switch.is_active and projectile.kind == "pierce_arrow":
		if projectile.global_position.distance_to(gate_switch.global_position) <= 13.0:
			gate_switch.activate()
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
		report_event("%s DERROTADO — restam %d" % [actor.actor_name, active_enemies])
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
	var target_x: float = clampf(active_actor.global_position.x, camera_half_width, WORLD_WIDTH - camera_half_width)
	camera.global_position = Vector2(target_x, 205.0)

func _build_world() -> void:
	world_layer = Node2D.new()
	world_layer.name = "World"
	add_child(world_layer)

	cave_tileset = _build_cave_tileset()

	_add_background()

	# Chao principal: A (0-375) -> vao 1 -> B (415-760) -> vao 2 (com o
	# puzzle do interruptor) -> C1 (800-950) -> vao 3, LARGO DEMAIS para o
	# pulo duplo (so o teleporte da Maga atravessa) -> C2 (1170-1320, area final).
	_add_platform(Rect2(0, 284, 375, 32), false)
	_add_platform(Rect2(415, 284, 345, 32), false)
	_add_platform(Rect2(800, 284, 150, 32), false)
	_add_platform(Rect2(1170, 284, 150, 32), false)

	# Plataformas elevadas: todas ao alcance do salto normal (sem a escada da 11C).
	_add_platform(Rect2(150, 250, 135, 14), true)
	_add_platform(Rect2(500, 250, 175, 14), true)
	_add_platform(Rect2(1220, 250, 90, 14), true)

	_add_decorations()
	_spawn_puzzle()

	_add_wall_collision(Rect2(-12, 0, 12, DEATH_Y))
	_add_wall_collision(Rect2(WORLD_WIDTH, 0, 12, DEATH_Y))

	_add_gap_marker(375, 415)
	_add_gap_marker(760, 800)
	_add_gap_marker(950, 1170)

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

func _build_cave_tileset() -> TileSet:
	var tex: Texture2D = load(CAVE_TILE_PATH)
	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = CAVE_TILE_SIZE
	source.create_tile(GROUND_RIM_COORD)
	var tile_set := TileSet.new()
	tile_set.tile_size = CAVE_TILE_SIZE
	tile_set.add_source(source, 0)
	return tile_set

func _add_background() -> void:
	var sky := ColorRect.new()
	sky.position = Vector2(-50, -50)
	sky.size = Vector2(WORLD_WIDTH + 100, DEATH_Y + 100)
	sky.color = Color("6fa8dc")
	sky.z_index = -10
	world_layer.add_child(sky)

	var moon := Polygon2D.new()
	moon.color = Color(0.88, 0.92, 0.98, 0.6)
	var pts := PackedVector2Array()
	for i in range(24):
		var a: float = TAU * float(i) / 24.0
		pts.append(Vector2(cos(a), sin(a)) * 30.0)
	moon.polygon = pts
	moon.position = Vector2(220, 150)
	moon.z_index = -9
	world_layer.add_child(moon)

	# bg_mountains.png tem bordas esquerda/direita identicas (confirmado
	# pixel a pixel), entao encostar copias lado a lado forma um horizonte
	# continuo sem costura visivel.
	var mountain_tex: Texture2D = load(MOUNTAIN_PATH)
	var mountain_w: float = mountain_tex.get_width()
	var copies: int = int(ceil((WORLD_WIDTH + mountain_w * 2.0) / mountain_w))
	for i in range(-1, copies):
		var spr := Sprite2D.new()
		spr.texture = mountain_tex
		spr.centered = false
		spr.position = Vector2(float(i) * mountain_w, 130.0)
		spr.z_index = -8
		world_layer.add_child(spr)

func _add_platform(rect: Rect2, one_way: bool) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = rect.get_center()

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.one_way_collision = one_way
	if one_way:
		collision.one_way_collision_margin = 6.0
	body.add_child(collision)
	world_layer.add_child(body)

	_draw_platform_visual(rect)

func _draw_platform_visual(rect: Rect2) -> void:
	# O TileMapLayer e posicionado exatamente no topo-esquerda do retangulo
	# de colisao (em vez de encaixar num grid global de 16px), entao a
	# celula (0,0) sempre alinha com a superficie real onde o personagem
	# pisa — sem isso, plataformas fora do grid global faziam o chao visual
	# comecar alguns pixels ACIMA da colisao, dando a impressao de que os
	# personagens afundavam no chao.
	var rim_h := 16.0
	var body_h: float = rect.size.y - rim_h
	if body_h > 0.0:
		var body_visual := ColorRect.new()
		body_visual.position = Vector2(rect.position.x, rect.position.y + rim_h)
		body_visual.size = Vector2(rect.size.x, body_h)
		body_visual.color = Color("241c17")
		body_visual.z_index = -1
		world_layer.add_child(body_visual)

	var rim_layer := TileMapLayer.new()
	rim_layer.tile_set = cave_tileset
	rim_layer.position = rect.position
	rim_layer.z_index = -1
	world_layer.add_child(rim_layer)
	var cols: int = int(ceil(rect.size.x / 16.0))
	for gx in range(cols):
		rim_layer.set_cell(Vector2i(gx, 0), 0, GROUND_RIM_COORD)

func _add_decorations() -> void:
	# trees.png NAO e um grid uniforme — cada arvore tem uma largura propria
	# (a copa varia bastante entre variantes). Os retangulos abaixo foram
	# extraidos por componente conexo (alpha > 0) da folha original, entao
	# cada arvore fica completa (sem metade cortada na borda de uma celula
	# de grid que nao corresponde ao desenho real).
	var trees_tex: Texture2D = load(TREES_PATH)
	var spots: Array = [
		{"pos": Vector2(55, 284), "rect": Rect2(8, 4, 44, 60), "scale": 0.55},
		{"pos": Vector2(345, 284), "rect": Rect2(70, 2, 53, 62), "scale": 0.5},
		{"pos": Vector2(560, 250), "rect": Rect2(518, 66, 53, 62), "scale": 0.45},
		{"pos": Vector2(870, 284), "rect": Rect2(70, 258, 53, 62), "scale": 0.5},
		{"pos": Vector2(1290, 284), "rect": Rect2(456, 260, 44, 60), "scale": 0.55},
	]
	for spot in spots:
		var region: Rect2 = spot["rect"]
		var atlas := AtlasTexture.new()
		atlas.atlas = trees_tex
		atlas.region = region
		var spr := Sprite2D.new()
		spr.texture = atlas
		spr.centered = true
		spr.offset = Vector2(0, -region.size.y * 0.5)
		var s: float = spot["scale"]
		spr.scale = Vector2(s, s)
		spr.position = spot["pos"]
		spr.z_index = -1
		world_layer.add_child(spr)

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

func _add_gap_marker(from_x: float, to_x: float) -> void:
	var label := Label.new()
	label.text = "QUEDA = MORTE"
	label.position = Vector2(from_x + 5.0, 322.0)
	label.add_theme_font_size_override("font_size", 6)
	label.add_theme_color_override("font_color", Color("ff6b6b"))
	world_layer.add_child(label)

const ROLE_TINT := {
	"cavaleiro_executivo": Color("d4af37"),
	"warrior": Color("cfd6e0"),
	"archer": Color("8fd67a"),
	"mage": Color("b48cff"),
	"fire_mage": Color("ff9a52"),
	"lightning_mage": Color("fff27a"),
	"wanderer": Color("7fe0d1"),
}

const SLOT_SPAWN_X := [140.0, 105.0, 70.0]
const SLOT_FOLLOW_OFFSET := [-36.0, -36.0, -72.0]

func _role_tint(role: String) -> Color:
	return ROLE_TINT.get(role, Color("ffe26f"))

const ROLE_OBJECTIVE_LINE := {
	"cavaleiro_executivo": "quebra o entulho (Estocada)",
	"warrior": "quebra o entulho (Estocada)",
	"fire_mage": "quebra o entulho (Rajada de Fogo)",
	"archer": "atravessa a barreira magica (Tiro Perfurante)",
	"lightning_mage": "atravessa a barreira magica (Tiro Perfurante)",
	"mage": "cruza o vao largo demais para o pulo (Teleporte)",
	"wanderer": "cruza o vao largo demais para o pulo (Teleporte)",
}

func _spawn_party() -> void:
	var roles: Array[String] = PartySelection12.get_party_roles()
	party_slots = []
	for i in range(roles.size()):
		var role: String = roles[i]
		var display_name: String = Actor.DISPLAY_NAME.get(role, role.to_upper())
		var tint: Color = ROLE_TINT.get(role, Color.WHITE)
		var actor := _spawn_actor(display_name, "ally", role, Vector2(SLOT_SPAWN_X[i], 250), tint, i)
		actor.follow_offset_x = SLOT_FOLLOW_OFFSET[i]
		party_slots.append(actor)

func _spawn_enemies() -> void:
	_spawn_actor("RATO", "enemy", "rat", Vector2(680, 250), Color("d9d3c7"))

	# Desafio: a Gosma que guarda a area final (alem do vao largo) e mais
	# resistente que um inimigo comum.
	var boss: Actor = _spawn_actor("GOSMA REAL", "enemy", "slime", Vector2(1250, 250), Color("8fe06a"))
	boss.max_hp = 6
	boss.hp = 6

func _spawn_puzzle() -> void:
	# Provacao do trio — cada obstaculo so cede a habilidade especial (tecla
	# H) de UM personagem especifico:
	#
	# 1) ENTULHO sobre a plataforma B: bloqueia a passagem a pe e o ataque
	#    normal (melee/projetil) e so e destruido pela Estocada do Guerreiro.
	# 2) BARREIRA MAGICA + interruptor no vao 2: a barreira (layer 2) para
	#    flecha/orbe comuns mas nao o Tiro Perfurante da Arqueira — so ele
	#    alcanca o interruptor e abre o portao para a plataforma C1.
	# 3) VAO LARGO (950-1170) alem da C1: mais largo que o alcance do pulo
	#    duplo (mesmo com dash); so o Teleporte da Maga atravessa ate a C2,
	#    onde a GOSMA REAL espera.
	_spawn_rubble()
	_spawn_ward_and_switch()
	_spawn_gate()

func _spawn_rubble() -> void:
	var rect := Rect2(700, 194, 30, 90)
	rubble_body = StaticBody2D.new()
	rubble_body.collision_layer = 1
	rubble_body.collision_mask = 0
	rubble_body.position = rect.get_center()
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	shape.shape = rs
	rubble_body.add_child(shape)
	world_layer.add_child(rubble_body)

	rubble_visual = ColorRect.new()
	rubble_visual.position = rect.position
	rubble_visual.size = rect.size
	rubble_visual.color = Color("4a3d33")
	world_layer.add_child(rubble_visual)

	var label := Label.new()
	label.text = "ENTULHO"
	label.position = Vector2(rect.position.x - 8.0, rect.position.y - 10.0)
	label.add_theme_font_size_override("font_size", 6)
	label.add_theme_color_override("font_color", Color("d9c9a8"))
	world_layer.add_child(label)

func try_break_rubble(actor: Actor) -> void:
	if rubble_broken or not is_instance_valid(rubble_body):
		return
	# O entulho e alto e fino (bloqueia de ponta a ponta); comparar so o
	# eixo X evita o erro de medir distancia ate o CENTRO do bloco enquanto
	# o personagem corre rente ao chao, bem abaixo desse centro.
	if absf(actor.global_position.x - rubble_body.global_position.x) <= 25.0:
		rubble_broken = true
		report_event("ENTULHO DESTRUIDO PELA ESTOCADA")
		rubble_body.queue_free()
		if is_instance_valid(rubble_visual):
			rubble_visual.queue_free()

func fire_burst_from(actor: Actor) -> void:
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.alive:
			if enemy.global_position.distance_to(actor.global_position) <= 46.0:
				enemy.take_damage(1, actor)
	try_break_rubble(actor)

func _spawn_ward_and_switch() -> void:
	ward_body = StaticBody2D.new()
	# Layer 3 (bit 4) — dedicada, separada da layer 2 (bit 2) usada pelos
	# Actors. Antes as duas coisas dividiam a layer 2, entao o raycast de
	# flecha/orbe (mask incluindo bit 2 pra enxergar a barreira) tambem
	# enxergava qualquer personagem aliado no caminho e parava nele, como
	# se fosse parede — a magia dos magos "era bloqueada" por companheiros.
	ward_body.collision_layer = 4
	ward_body.collision_mask = 0
	ward_body.position = Vector2(772, 240)
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(6, 160)
	shape.shape = rs
	ward_body.add_child(shape)
	world_layer.add_child(ward_body)

	ward_visual = ColorRect.new()
	ward_visual.position = Vector2(769, 160)
	ward_visual.size = Vector2(6, 160)
	ward_visual.color = Color(0.45, 0.85, 0.95, 0.5)
	world_layer.add_child(ward_visual)

	gate_switch = Switch.new()
	gate_switch.global_position = Vector2(786, 268)
	gate_switch.activated.connect(_on_switch_activated)
	world_layer.add_child(gate_switch)

func _spawn_gate() -> void:
	gate_body = StaticBody2D.new()
	gate_body.collision_layer = 1
	gate_body.collision_mask = 0
	gate_body.position = Vector2(804, 240)
	var gate_shape := CollisionShape2D.new()
	var gate_rect := RectangleShape2D.new()
	gate_rect.size = Vector2(8, 152)
	gate_shape.shape = gate_rect
	gate_body.add_child(gate_shape)
	world_layer.add_child(gate_body)

	gate_visual = ColorRect.new()
	gate_visual.position = Vector2(800, 164)
	gate_visual.size = Vector2(8, 152)
	gate_visual.color = Color(0.56, 0.4, 0.85, 0.85)
	world_layer.add_child(gate_visual)

func _on_switch_activated() -> void:
	gate_open = true
	report_event("INTERRUPTOR ATIVADO — PORTAO ABERTO")
	if is_instance_valid(gate_body):
		gate_body.queue_free()
	if is_instance_valid(gate_visual):
		gate_visual.queue_free()

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

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	if is_portrait:
		_build_hud_portrait(canvas)
		return

	# HUD compacto e semitransparente: so 2 linhas finas no topo, para o
	# cenario ficar visivel por tras. Instrucoes completas ficam no menu
	# de pausa (ESC).
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
	# Sem boss nesta fase — chrome proprio em vez do BossHudPortrait12
	# compartilhado (que exige nome/barra de boss). Mesmo padrao visual
	# (painel superior, state_label central, event_label, TouchControls).
	var panel := ColorRect.new()
	panel.position = Vector2(0, 0)
	panel.size = Vector2(180, 30)
	panel.color = Color(0.02, 0.025, 0.035, 0.55)
	canvas.add_child(panel)

	party_label = Label.new()
	party_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	party_label.add_theme_font_size_override("font_size", 6)
	party_label.add_theme_color_override("font_color", Color("ffe26f"))
	# size por ultimo (autowrap+fonte antes de entrar na tree pode inflar o
	# minimum_size e o Control nao encolhe sozinho depois).
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
		state_label.text = "AREA LIMPA — R reinicia"
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

	var rubble_status := "OK" if rubble_broken else "intacto"
	var gate_status := "aberto" if gate_open else "fechado"
	objective_label.text = "inimigos %d/%d | entulho %s | portao %s" % [active_enemies, total_enemies, rubble_status, gate_status]

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
			objective_lines.append("%s %s" % [member.actor_name, ROLE_OBJECTIVE_LINE.get(member.role, "")])
	var instructions_text := "OBJETIVO\nDerrote os inimigos e supere 3 provas — cada uma so cede a\nhabilidade especial (H) de UM personagem do seu grupo:\n%s\n\nCONTROLES\nA/D mover | ESPACO pular (2x no ar) | K dash\n1/2/3 trocar personagem | J atacar | H especial\nR reiniciar a fase | ESC pausar/continuar" % "\n".join(objective_lines)

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
