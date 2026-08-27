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

const WORLD_WIDTH := 1200.0
const DEATH_Y := 360.0

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
var action_label: Label
var objective_label: Label
var event_label: Label
var event_timeout := 0.0
var completed := false
var game_over := false

func _ready() -> void:
	_build_world()
	_spawn_party()
	_spawn_enemies()
	_build_hud()
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
	var target_x: float = clampf(active_actor.global_position.x, 160.0, WORLD_WIDTH - 160.0)
	camera.global_position = Vector2(target_x, 205.0)

func _build_world() -> void:
	world_layer = Node2D.new()
	world_layer.name = "World"
	add_child(world_layer)

	cave_tileset = _build_cave_tileset()

	_add_background()

	# Chao principal em 3 blocos, com vaos que exigem salto (mantido da 11B.1).
	_add_platform(Rect2(0, 284, 375, 32), false)
	_add_platform(Rect2(415, 284, 345, 32), false)
	_add_platform(Rect2(800, 284, 400, 32), false)

	# Plataformas elevadas: todas ao alcance do salto normal (sem a escada da 11C).
	_add_platform(Rect2(150, 250, 135, 14), true)
	_add_platform(Rect2(500, 250, 175, 14), true)
	_add_platform(Rect2(885, 250, 145, 14), true)

	_add_decorations()

	_add_wall_collision(Rect2(-12, 0, 12, DEATH_Y))
	_add_wall_collision(Rect2(WORLD_WIDTH, 0, 12, DEATH_Y))

	_add_gap_marker(375, 415)
	_add_gap_marker(760, 800)

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
	camera.global_position = Vector2(160, 205)
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
	var trees_tex: Texture2D = load(TREES_PATH)
	var cell_w := 96
	var cell_h := 64
	var spots: Array = [
		{"pos": Vector2(55, 284), "cell": Vector2i(4, 0), "scale": 0.55},
		{"pos": Vector2(345, 284), "cell": Vector2i(8, 3), "scale": 0.5},
		{"pos": Vector2(560, 250), "cell": Vector2i(4, 3), "scale": 0.45},
		{"pos": Vector2(1075, 284), "cell": Vector2i(8, 0), "scale": 0.55},
	]
	for spot in spots:
		var cell: Vector2i = spot["cell"]
		var atlas := AtlasTexture.new()
		atlas.atlas = trees_tex
		atlas.region = Rect2(cell.x * cell_w, cell.y * cell_h, cell_w, cell_h)
		var spr := Sprite2D.new()
		spr.texture = atlas
		spr.centered = true
		spr.offset = Vector2(0, -30)
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

func _spawn_party() -> void:
	var warrior := _spawn_actor("GUERREIRO", "ally", "warrior", Vector2(140, 250), Color("cfd6e0"), 0)
	warrior.follow_offset_x = -36.0

	var archer := _spawn_actor("ARQUEIRA", "ally", "archer", Vector2(105, 250), Color("8fd67a"), 1)
	archer.follow_offset_x = -36.0

	var mage := _spawn_actor("MAGA", "ally", "mage", Vector2(70, 250), Color("b48cff"), 2)
	mage.follow_offset_x = -72.0

	party_slots = [warrior, archer, mage]

func _spawn_enemies() -> void:
	_spawn_actor("RATO", "enemy", "rat", Vector2(680, 250), Color("d9d3c7"))
	_spawn_actor("GOSMA", "enemy", "slime", Vector2(980, 250), Color("8fe06a"))

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

	var panel := ColorRect.new()
	panel.position = Vector2(0, 0)
	panel.size = Vector2(320, 50)
	panel.color = Color(0.02, 0.025, 0.035, 0.92)
	canvas.add_child(panel)

	state_label = Label.new()
	state_label.position = Vector2(5, 2)
	state_label.add_theme_font_size_override("font_size", 7)
	panel.add_child(state_label)

	party_label = Label.new()
	party_label.position = Vector2(5, 14)
	party_label.add_theme_font_size_override("font_size", 7)
	party_label.add_theme_color_override("font_color", Color("ffe26f"))
	panel.add_child(party_label)

	action_label = Label.new()
	action_label.position = Vector2(5, 26)
	action_label.add_theme_font_size_override("font_size", 7)
	panel.add_child(action_label)

	objective_label = Label.new()
	objective_label.position = Vector2(5, 38)
	objective_label.add_theme_font_size_override("font_size", 6)
	panel.add_child(objective_label)

	var help := Label.new()
	help.text = "1/2/3 trocar | A/D mover | ESPACO pular | J atacar | K dash | R restart"
	help.position = Vector2(5, 157)
	help.add_theme_font_size_override("font_size", 6)
	canvas.add_child(help)

	event_label = Label.new()
	event_label.position = Vector2(6, 144)
	event_label.add_theme_font_size_override("font_size", 7)
	event_label.add_theme_color_override("font_color", Color("ffe26f"))
	canvas.add_child(event_label)

func _update_hud() -> void:
	if not is_instance_valid(state_label):
		return

	if game_over:
		state_label.text = "GAME OVER | R reinicia"
	elif completed:
		state_label.text = "SPRINT 12 OK | R reinicia"
	else:
		state_label.text = "12 CAVERNA | inimigos %d/%d" % [active_enemies, total_enemies]

	var parts: Array[String] = []
	for i in range(party_slots.size()):
		var member: Actor = party_slots[i]
		if not is_instance_valid(member):
			continue
		var marker := ">" if member == active_actor and member.alive else " "
		var status := "X" if not member.alive else str(member.hp)
		parts.append("%s%d:%s[%s]" % [marker, i + 1, member.actor_name, status])
	party_label.text = " | ".join(parts)

	if is_instance_valid(active_actor) and active_actor.alive:
		if active_actor.is_ranged:
			action_label.text = "J: ataque a distancia de %s" % active_actor.actor_name
		else:
			action_label.text = "J: ataque corpo a corpo de %s" % active_actor.actor_name
	else:
		action_label.text = "sem personagem ativo"

	objective_label.text = "12: derrote os inimigos da caverna — %d/%d restantes" % [active_enemies, total_enemies]
