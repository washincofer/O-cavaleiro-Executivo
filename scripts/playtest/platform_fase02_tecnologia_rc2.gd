extends Node2D

## RC2 canonico — Fase 02: Tecnologia.
## Sem subchefe. Arte provisoria; mecanica desacoplada dos sprites.

const Actor = preload("res://scripts/playtest/platform_actor_12.gd")
const Projectile = preload("res://scripts/playtest/platform_projectile_12.gd")
const PICKUP_SCRIPT := preload("res://scripts/playtest/progression_pickup_12.gd")
const STAGE_SELECT_SCENE := "res://scenes/menu/stage_select_12.tscn"

const WORLD_WIDTH := 5200.0
const FLOOR_Y := 284.0
const DEATH_Y := 360.0
const BOSS_GATE_X := 4140.0
const TERMINAL_X := [4320.0, 4520.0, 4720.0]
const BOSS_COMBOS := [[1, 3], [2, 3]]
const REVIVE_X := [680.0, 1180.0, 1660.0, 2220.0, 2860.0, 3440.0, 3880.0]

const ROLE_TINT := {
	"cavaleiro_executivo": Color("d4af37"), "archer": Color("8fd67a"),
	"mage": Color("b48cff"), "warrior": Color("cfd6e0"), "fire_mage": Color("ff9a52"),
	"lightning_mage": Color("fff27a"), "wanderer": Color("7fe0d1"), "paladin": Color("e8e8f0"),
	"knight": Color("9fb0c9"), "bridge_heroine": Color("ffb0d0"),
	"almoxarifado": Color("ffb04a"), "protocolo": Color("6fcf9a"),
}

const ENEMY_LAYOUT := [
	[520.0, "TECNICO DE SUPORTE", "protocolo", 2],
	[760.0, "ANALISTA DE SERVICE DESK", "almoxarifado", 3],
	[1040.0, "TECNICO DE CAMPO", "protocolo", 3],
	[1280.0, "ANALISTA DE SISTEMAS", "almoxarifado", 4],
	[1560.0, "OPERADOR DE DATACENTER", "protocolo", 5],
	[1840.0, "ADMINISTRADOR DE SERVIDORES", "almoxarifado", 5],
	[2140.0, "ANALISTA DE REDES", "protocolo", 6],
	[2420.0, "ESPECIALISTA DE BACKUP", "almoxarifado", 6],
	[2720.0, "ANALISTA DE SEGURANCA", "protocolo", 7],
	[3020.0, "ENGENHEIRO DE REDES", "almoxarifado", 7],
	[3320.0, "ARQUITETO DE SISTEMAS", "protocolo", 8],
	[3620.0, "ESPECIALISTA DE INFRA", "almoxarifado", 8],
	[3900.0, "GUARDA DE GOVERNANCA", "protocolo", 9],
]

var actors: Array[Actor] = []
var enemies: Array[Actor] = []
var party_slots: Array[Actor] = []
var active_actor: Actor = null
var actor_layer: Node2D
var projectile_layer: Node2D
var world_layer: Node2D
var camera: Camera2D
var sir_carth: Actor
var boss_gate: StaticBody2D
var boss_gate_visual: ColorRect
var terminal_labels: Array[Label] = []
var terminal_areas: Array[Area2D] = []
var boss_started := false
var boss_completed := false
var boss_combo_index := 0
var boss_required: Array[int] = []
var boss_activated: Array[int] = []
var boss_vulnerable := false
var boss_vulnerability_left := 0.0
var boss_cycle_left := 0.0
var last_checkpoint_x := 80.0
var status_label: Label
var objective_label: Label
var coins_label: Label
var hp_bars: Array = []

func _ready() -> void:
	_build_world()
	_spawn_party()
	_spawn_enemies()
	_spawn_stage_items()
	_build_hud()
	_set_active_party_slot(0, false)
	_update_hud()

func _process(delta: float) -> void:
	_handle_party_selection()
	_check_falls()
	_update_camera()
	_check_checkpoints()
	_update_boss(delta)
	if Input.is_action_just_pressed("interact"):
		_try_activate_terminal()
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
		return false
	for member in party_slots:
		if is_instance_valid(member) and member.alive:
			member.set_controlled(false)
	active_actor = next_actor
	active_actor.set_controlled(true)
	if announce:
		report_event("CONTROLE -> %s" % active_actor.actor_name)
	return true

func _handoff_from_slot(dead_slot: int) -> void:
	for step in range(1, party_slots.size() + 1):
		var idx := (dead_slot + step) % party_slots.size()
		var candidate: Actor = party_slots[idx]
		if is_instance_valid(candidate) and candidate.alive:
			_set_active_party_slot(idx, false)
			return
	active_actor = null
	report_event("GAME OVER")

func get_active_actor() -> Actor:
	return active_actor

func activate_actor_action(actor: Actor) -> void:
	if actor != active_actor or not actor.alive:
		return
	if actor.is_ranged:
		actor.activate_ranged_attack()
	else:
		actor.melee_attack()

func activate_actor_special(actor: Actor) -> void:
	if actor == active_actor and actor.alive:
		actor.activate_special()

func melee_attack_from(source: Actor) -> bool:
	var victim := _nearest_enemy_in_range(source.global_position, 38.0, 30.0)
	if not is_instance_valid(victim):
		return false
	if victim == sir_carth and not boss_vulnerable:
		report_event("FIREWALL DE GOVERNANCA ATIVO")
		return false
	victim.take_damage(1, source)
	return true

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
			if enemy == sir_carth and not boss_vulnerable:
				report_event("FIREWALL DE GOVERNANCA ATIVO")
				return true
			enemy.take_damage(1, owner_actor)
			return true
	return false

func _nearest_enemy_in_range(origin: Vector2, max_x: float, max_y: float) -> Actor:
	var result: Actor = null
	var best := INF
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.alive:
			continue
		var d := enemy.global_position - origin
		if absf(d.x) <= max_x and absf(d.y) <= max_y and d.length_squared() < best:
			result = enemy
			best = d.length_squared()
	return result

func closest_alive_ally(_source = null) -> Actor:
	if is_instance_valid(active_actor) and active_actor.alive:
		return active_actor
	for member in party_slots:
		if is_instance_valid(member) and member.alive:
			return member
	return null

func has_floor_ahead(actor: Actor, direction: float, horizontal_distance := 14.0) -> bool:
	var from := actor.global_position + Vector2(signf(direction) * horizontal_distance, -3.0)
	var to := from + Vector2(0, 34)
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return not hit.is_empty()

func try_break_rubble(_actor: Actor) -> void:
	pass

func summon_bridge_from(_actor: Actor) -> void:
	pass

func fire_burst_from(actor: Actor) -> void:
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.alive:
			continue
		if enemy.global_position.distance_to(actor.global_position) <= 46.0:
			if enemy != sir_carth or boss_vulnerable:
				enemy.take_damage(1, actor)

func teleport_actor(actor: Actor, direction: float) -> void:
	actor.global_position.x = clampf(actor.global_position.x + direction * 180.0, 20.0, WORLD_WIDTH - 20.0)
	actor.velocity = Vector2.ZERO

func _build_world() -> void:
	world_layer = Node2D.new()
	world_layer.name = "World"
	add_child(world_layer)
	_add_floor(Rect2(0, FLOOR_Y, WORLD_WIDTH, 30))
	for rect in [Rect2(820, 238, 120, 12), Rect2(1460, 220, 140, 12), Rect2(2240, 236, 120, 12), Rect2(3140, 214, 150, 12), Rect2(3700, 238, 120, 12)]:
		_add_floor(rect, true)
	_add_sector(0, 980, "T01 — SERVICE DESK", Color("152338"))
	_add_sector(980, 1960, "T02 — DATACENTER", Color("122a34"))
	_add_sector(1960, 2940, "T03 — REDES & BACKUP", Color("17223a"))
	_add_sector(2940, 4140, "T04 — SEGURANCA & GOVERNANCA", Color("1e1f38"))
	_add_sector(4140, WORLD_WIDTH, "T05 — CONSELHO DE GOVERNANCA", Color("251a31"))
	boss_gate = _add_wall(BOSS_GATE_X)
	boss_gate_visual = ColorRect.new()
	boss_gate_visual.position = Vector2(BOSS_GATE_X - 4, 120)
	boss_gate_visual.size = Vector2(8, 164)
	boss_gate_visual.color = Color("7c4db8")
	world_layer.add_child(boss_gate_visual)
	_build_terminals()
	actor_layer = Node2D.new()
	actor_layer.name = "Actors"
	actor_layer.y_sort_enabled = true
	add_child(actor_layer)
	projectile_layer = Node2D.new()
	projectile_layer.name = "Projectiles"
	add_child(projectile_layer)
	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_right = int(WORLD_WIDTH)
	camera.limit_top = 0
	camera.limit_bottom = 360
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)
	camera.make_current()

func _add_sector(x0: float, x1: float, title: String, color: Color) -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(x0, 0)
	bg.size = Vector2(x1 - x0, FLOOR_Y)
	bg.color = color
	bg.z_index = -20
	world_layer.add_child(bg)
	var label := Label.new()
	label.text = title
	label.position = Vector2(x0 + 16, 16)
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color("8de7ff"))
	world_layer.add_child(label)
	for x in range(int(x0 + 80), int(x1 - 40), 160):
		var rack := ColorRect.new()
		rack.position = Vector2(x, 118)
		rack.size = Vector2(34, 120)
		rack.color = Color("26384b")
		world_layer.add_child(rack)
		for y in range(128, 226, 18):
			var led := ColorRect.new()
			led.position = Vector2(x + 6, y)
			led.size = Vector2(22, 3)
			led.color = Color("4bd1b8")
			world_layer.add_child(led)

func _add_floor(rect: Rect2, one_way := false) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.position = rect.get_center()
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	shape.one_way_collision = one_way
	body.add_child(shape)
	world_layer.add_child(body)
	var visual := ColorRect.new()
	visual.position = rect.position
	visual.size = rect.size
	visual.color = Color("3d5268")
	world_layer.add_child(visual)

func _add_wall(x: float) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.position = Vector2(x, 202)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(8, 164)
	shape.shape = rectangle
	body.add_child(shape)
	world_layer.add_child(body)
	return body

func _build_terminals() -> void:
	for i in range(3):
		var area := Area2D.new()
		area.position = Vector2(TERMINAL_X[i], FLOOR_Y - 18)
		area.collision_layer = 0
		area.collision_mask = 2
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 28
		shape.shape = circle
		area.add_child(shape)
		world_layer.add_child(area)
		terminal_areas.append(area)
		var panel := ColorRect.new()
		panel.position = area.position + Vector2(-12, -30)
		panel.size = Vector2(24, 30)
		panel.color = Color("315c78")
		world_layer.add_child(panel)
		var label := Label.new()
		label.text = "NODO %d" % (i + 1)
		label.position = area.position + Vector2(-20, -42)
		label.add_theme_font_size_override("font_size", 6)
		world_layer.add_child(label)
		terminal_labels.append(label)

func _spawn_party() -> void:
	var roles: Array[String] = PartySelection12.get_party_roles()
	for i in range(roles.size()):
		var role: String = roles[i]
		var display_name: String = Actor.DISPLAY_NAME.get(role, role.to_upper())
		var actor := _spawn_actor(display_name, "ally", role, Vector2(80 - i * 24, FLOOR_Y - 10), ROLE_TINT.get(role, Color.WHITE), i)
		actor.follow_offset_x = -36.0 - i * 30.0
		party_slots.append(actor)

func _spawn_enemies() -> void:
	for item in ENEMY_LAYOUT:
		var enemy := _spawn_actor(String(item[1]), "enemy", String(item[2]), Vector2(float(item[0]), FLOOR_Y - 12), Color("86d9ff"))
		enemy.max_hp = int(item[3])
		enemy.hp = enemy.max_hp
	sir_carth = _spawn_actor("SIR CARTH GENTRION", "enemy", "danelmo", Vector2(4930, FLOOR_Y - 30), Color("9270c9"))
	sir_carth.max_hp = 90
	sir_carth.hp = 90
	sir_carth.died.connect(_on_sir_carth_died)

func _spawn_actor(p_name: String, team: String, role: String, position: Vector2, tint: Color, party_slot := -1) -> Actor:
	var actor := Actor.new()
	actor_layer.add_child(actor)
	actor.global_position = position
	actor.setup(self, p_name, team, role, tint, party_slot)
	actor.died.connect(_on_actor_died)
	actors.append(actor)
	if team == "enemy":
		enemies.append(actor)
	return actor

func _spawn_stage_items() -> void:
	var candidates := REVIVE_X.duplicate()
	candidates.shuffle()
	var count := mini(Progression12.random_revive_scatter_count(), candidates.size())
	for i in range(count):
		_spawn_pickup(Vector2(float(candidates[i]), FLOOR_Y - 22), "revive_companion")
	_spawn_pickup(Vector2(3480, 190), "power_life")

func _spawn_pickup(pos: Vector2, kind: String) -> void:
	var pickup := Area2D.new()
	pickup.set_script(PICKUP_SCRIPT)
	pickup.set("kind", kind)
	pickup.set("amount", 1)
	actor_layer.add_child(pickup)
	pickup.global_position = pos

func _check_checkpoints() -> void:
	if not is_instance_valid(active_actor):
		return
	for x in [80.0, 1080.0, 2060.0, 3040.0, 4040.0]:
		if active_actor.global_position.x >= x and x > last_checkpoint_x:
			last_checkpoint_x = x
			report_event("CHECKPOINT")
	if active_actor.global_position.x >= BOSS_GATE_X - 80 and not boss_started:
		_start_boss()

func _start_boss() -> void:
	boss_started = true
	if is_instance_valid(boss_gate):
		boss_gate.queue_free()
	if is_instance_valid(boss_gate_visual):
		boss_gate_visual.queue_free()
	boss_combo_index = 0
	_begin_boss_cycle()
	report_event("SIR CARTH: FIREWALL DE GOVERNANCA ATIVO")

func _begin_boss_cycle() -> void:
	boss_vulnerable = false
	boss_activated.clear()
	boss_required.clear()
	for value in BOSS_COMBOS[boss_combo_index]:
		boss_required.append(int(value))
	boss_combo_index = (boss_combo_index + 1) % BOSS_COMBOS.size()
	boss_cycle_left = randf_range(5.0, 10.0)
	_update_terminal_labels()

func _try_activate_terminal() -> void:
	if not boss_started or boss_completed or boss_vulnerable or not is_instance_valid(active_actor):
		return
	for i in range(terminal_areas.size()):
		var node_id := i + 1
		if active_actor.global_position.distance_to(terminal_areas[i].global_position) > 42.0:
			continue
		if boss_required.has(node_id) and not boss_activated.has(node_id):
			boss_activated.append(node_id)
			report_event("NODO %d AUTORIZADO" % node_id)
			_update_terminal_labels()
			if boss_activated.size() >= boss_required.size():
				boss_vulnerable = true
				boss_vulnerability_left = randf_range(5.0, 10.0)
				report_event("FIREWALL ABERTO — ATAQUE SIR CARTH!")
		else:
			report_event("NODO %d FORA DA COMBINACAO" % node_id)
		return

func _update_boss(delta: float) -> void:
	if not boss_started or boss_completed or not is_instance_valid(sir_carth) or not sir_carth.alive:
		return
	if boss_vulnerable:
		boss_vulnerability_left -= delta
		if boss_vulnerability_left <= 0.0:
			_begin_boss_cycle()
			report_event("FIREWALL REATIVADO")
	else:
		boss_cycle_left -= delta
		if boss_cycle_left <= 0.0:
			_begin_boss_cycle()
			report_event("PROTOCOLO ALTERADO — NOVA COMBINACAO")

func _update_terminal_labels() -> void:
	for i in range(terminal_labels.size()):
		var node_id := i + 1
		var state := "LOCK"
		if boss_activated.has(node_id):
			state = "OK"
		elif boss_required.has(node_id):
			state = "ATIVO"
		terminal_labels[i].text = "NODO %d [%s]" % [node_id, state]

func _on_actor_died(actor: Actor) -> void:
	if actor.team == "enemy":
		return
	if actor == active_actor:
		_handoff_from_slot(actor.party_slot)

func _on_sir_carth_died(_actor: Actor) -> void:
	boss_completed = true
	Progression12.grant_first_clear_reward("fase02_tecnologia")
	SaveSystem12.save_game()
	report_event("SIR CARTH GENTRION DERROTADO — TECNOLOGIA LIBERADA")
	await get_tree().create_timer(2.2).timeout
	get_tree().change_scene_to_file(STAGE_SELECT_SCENE)

func _check_falls() -> void:
	for actor in actors:
		if not is_instance_valid(actor) or not actor.alive or actor.global_position.y <= DEATH_Y:
			continue
		if actor.team == "ally":
			actor.global_position = Vector2(last_checkpoint_x, FLOOR_Y - 10)
			actor.velocity = Vector2.ZERO
		else:
			actor.force_kill()

func _update_camera() -> void:
	if is_instance_valid(active_actor):
		camera.global_position = Vector2(clampf(active_actor.global_position.x, 160, WORLD_WIDTH - 160), 205)

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := ColorRect.new()
	panel.position = Vector2(0, 0)
	panel.size = Vector2(320, 28)
	panel.color = Color(0.02, 0.03, 0.07, 0.72)
	canvas.add_child(panel)
	objective_label = Label.new()
	objective_label.position = Vector2(6, 2)
	objective_label.add_theme_font_size_override("font_size", 7)
	panel.add_child(objective_label)
	status_label = Label.new()
	status_label.position = Vector2(6, 12)
	status_label.add_theme_font_size_override("font_size", 6)
	panel.add_child(status_label)
	coins_label = Label.new()
	coins_label.position = Vector2(230, 3)
	coins_label.add_theme_font_size_override("font_size", 7)
	panel.add_child(coins_label)
	hp_bars = PartyHpBars12.build(canvas, party_slots, 34.0, Callable(self, "_role_tint"))

func _role_tint(role: String) -> Color:
	return ROLE_TINT.get(role, Color("ffe26f"))

func _update_hud() -> void:
	if is_instance_valid(objective_label):
		if boss_started and not boss_completed:
			objective_label.text = "CHEFE: ative nodos %s" % str(boss_required)
		else:
			objective_label.text = "FASE 02 — TECNOLOGIA | avance ate Sir Carth"
	if is_instance_valid(coins_label):
		coins_label.text = "$ %d" % Progression12.coins
	if not hp_bars.is_empty():
		PartyHpBars12.update(hp_bars, active_actor)

func report_event(message: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = message
