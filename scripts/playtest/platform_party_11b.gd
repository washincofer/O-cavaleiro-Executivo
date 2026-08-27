extends Node2D

const Actor = preload("res://scripts/playtest/platform_actor_11b.gd")
const Bolt = preload("res://scripts/playtest/platform_bolt_11b.gd")

const WORLD_WIDTH := 1200.0
const DEATH_Y := 360.0

var actors: Array = []
var enemies: Array = []
var party_slots: Array = []
var active_actor
var active_party_slot := 0
var active_enemies := 0

var world_layer: Node2D
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

	if not completed and is_instance_valid(active_actor) and active_actor.alive and active_actor.global_position.x >= 1130.0:
		completed = true
		report_event("PLAYTEST 11B CONCLUIDO — pressione R para reiniciar")

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

	var next_actor = party_slots[slot]
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
		var candidate_slot := (dead_slot + step) % party_slots.size()
		var candidate = party_slots[candidate_slot]
		if is_instance_valid(candidate) and candidate.alive:
			_set_active_party_slot(candidate_slot, false)
			report_event("AUTO HANDOFF -> %d %s" % [candidate_slot + 1, candidate.actor_name])
			return

	active_actor = null
	game_over = true
	report_event("GAME OVER — todos os membros foram derrotados")

func get_active_actor():
	return active_actor

func activate_actor_action(actor) -> void:
	if actor != active_actor or not actor.alive:
		return

	if actor.is_player:
		if actor.hero_melee():
			report_event("CAVALEIRO: ATAQUE")
		return

	if actor.role == "guard":
		if actor.begin_guard():
			report_event("ESPADACHIM: GUARDA 1.25s")
		else:
			report_event("ESPADACHIM: habilidade em recarga")
		return

	if actor.role == "crossbow":
		if actor.fire_crossbow():
			report_event("ESTAGIARIO: DISPARO DE BESTA")
		else:
			report_event("ESTAGIARIO: habilidade em recarga")

func hero_melee_attack(source) -> bool:
	var victim = _nearest_enemy_in_range(source.global_position, 38.0, 30.0)
	if is_instance_valid(victim):
		victim.take_damage(1, source)
		return true
	return false

func spawn_party_bolt(owner_actor, direction: Vector2) -> void:
	var bolt = Bolt.new()
	projectile_layer.add_child(bolt)
	bolt.global_position = owner_actor.global_position + Vector2(owner_actor.facing * 13.0, -8.0)
	bolt.setup(self, owner_actor, direction)

func try_bolt_hit(bolt, owner_actor) -> bool:
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.alive:
			continue
		if bolt.global_position.distance_to(enemy.global_position + Vector2(0, -7)) <= 15.0:
			enemy.take_damage(1, owner_actor)
			return true
	return false

func _nearest_enemy_in_range(origin: Vector2, max_x: float, max_y: float):
	var result = null
	var best := INF
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.alive:
			continue
		var delta := enemy.global_position - origin
		if absf(delta.x) <= max_x and absf(delta.y) <= max_y:
			var d := delta.length_squared()
			if d < best:
				best = d
				result = enemy
	return result

func closest_alive_ally(_source = null):
	var result = null
	var best := INF
	for member in party_slots:
		if not is_instance_valid(member) or not member.alive:
			continue
		if _source == null:
			return member
		var d := _source.global_position.distance_squared_to(member.global_position)
		if d < best:
			best = d
			result = member
	return result

func _check_falls() -> void:
	for actor in actors:
		if is_instance_valid(actor) and actor.alive and actor.global_position.y > DEATH_Y:
			actor.force_kill()

func _on_actor_died(actor) -> void:
	if actor.team == "enemy":
		active_enemies = maxi(0, active_enemies - 1)
		report_event("INIMIGO DERROTADO — restam %d" % active_enemies)
		return

	var was_active := actor == active_actor
	var dead_slot := actor.party_slot
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
	var target_x := clampf(active_actor.global_position.x, 160.0, WORLD_WIDTH - 160.0)
	camera.global_position = Vector2(target_x, 205.0)

func _build_world() -> void:
	world_layer = Node2D.new()
	world_layer.name = "World"
	add_child(world_layer)

	var sky := Polygon2D.new()
	sky.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(WORLD_WIDTH, 0),
		Vector2(WORLD_WIDTH, 360), Vector2(0, 360)
	])
	sky.color = Color("1b2430")
	world_layer.add_child(sky)

	_add_platform(Rect2(0, 284, 350, 32), Color("51606c"))
	_add_platform(Rect2(430, 284, 300, 32), Color("51606c"))
	_add_platform(Rect2(815, 284, 385, 32), Color("51606c"))

	_add_platform(Rect2(165, 226, 135, 14), Color("6b7883"))
	_add_platform(Rect2(500, 208, 150, 14), Color("6b7883"))
	_add_platform(Rect2(875, 228, 145, 14), Color("6b7883"))

	_add_platform(Rect2(-12, 0, 12, 360), Color("111820"))
	_add_platform(Rect2(WORLD_WIDTH, 0, 12, 360), Color("111820"))

	_add_gap_marker(350, 430)
	_add_gap_marker(730, 815)

	var exit_flag := Label.new()
	exit_flag.text = "SAIDA 11B"
	exit_flag.position = Vector2(1100, 246)
	exit_flag.add_theme_font_size_override("font_size", 9)
	world_layer.add_child(exit_flag)

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

func _add_platform(rect: Rect2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = rect.get_center()

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)

	var visual := Polygon2D.new()
	var half := rect.size * 0.5
	visual.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y)
	])
	visual.color = color
	body.add_child(visual)
	world_layer.add_child(body)

func _add_gap_marker(from_x: float, to_x: float) -> void:
	var label := Label.new()
	label.text = "QUEDA = MORTE"
	label.position = Vector2(from_x + 5.0, 322.0)
	label.add_theme_font_size_override("font_size", 6)
	label.add_theme_color_override("font_color", Color("ff6b6b"))
	world_layer.add_child(label)

func _spawn_party() -> void:
	var hero = _spawn_actor("CAVALEIRO", "ally", "hero", Vector2(80, 250), true, Color("58a6ff"), 0)
	hero.follow_offset_x = -34.0

	var guard = _spawn_actor("ESPADACHIM", "ally", "guard", Vector2(48, 250), false, Color("66d17a"), 1)
	guard.follow_offset_x = -38.0

	var crossbow = _spawn_actor("ESTAGIARIO", "ally", "crossbow", Vector2(25, 250), false, Color("f0c15a"), 2)
	crossbow.follow_offset_x = -62.0

	party_slots = [hero, guard, crossbow]

func _spawn_enemies() -> void:
	_spawn_actor("INIMIGO A", "enemy", "enemy", Vector2(535, 250), false, Color("e34e48"))
	_spawn_actor("INIMIGO B", "enemy", "enemy", Vector2(945, 195), false, Color("e34e48"))
	_spawn_actor("INIMIGO C", "enemy", "enemy", Vector2(1030, 250), false, Color("e58d3b"))

func _spawn_actor(
	p_name: String,
	team: String,
	role: String,
	position: Vector2,
	is_player: bool,
	tint: Color,
	party_slot := -1
):
	var actor = Actor.new()
	actor_layer.add_child(actor)
	actor.global_position = position
	actor.setup(self, p_name, team, role, is_player, tint, party_slot)
	actor.died.connect(_on_actor_died)
	actors.append(actor)
	if team == "enemy":
		enemies.append(actor)
		active_enemies += 1
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
	help.text = "1/2/3 trocar | A/D mover | ESPACO pular | J acao | K correr | R restart"
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
		state_label.text = "SPRINT 11B OK | R reinicia"
	else:
		state_label.text = "PLATAFORMA 2D | inimigos %d" % active_enemies

	var parts: Array[String] = []
	for i in range(party_slots.size()):
		var member = party_slots[i]
		if not is_instance_valid(member):
			continue
		var marker := ">" if member == active_actor and member.alive else " "
		var status := "X" if not member.alive else str(member.hp)
		parts.append("%s%d:%s[%s]" % [marker, i + 1, member.actor_name, status])
	party_label.text = " | ".join(parts)

	if is_instance_valid(active_actor) and active_actor.alive:
		if active_actor.is_player:
			action_label.text = "J: ataque do Cavaleiro"
		elif active_actor.role == "guard":
			action_label.text = "J: GUARDA (defesa manual)"
		else:
			action_label.text = "J: BESTA (disparo manual)"
	else:
		action_label.text = "sem personagem ativo"

	objective_label.text = "Teste: plataforma + troca + queda/morte + auto handoff 1>2>3>1"
