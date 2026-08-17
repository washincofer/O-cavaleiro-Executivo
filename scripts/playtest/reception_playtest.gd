extends Node2D

const Actor = preload("res://scripts/playtest/reception_actor.gd")
const Projectile = preload("res://scripts/playtest/reception_projectile.gd")

var room_state := "ROOM_IDLE"
var trigger_consumed := false
var exit_open := false
var completed := false
var active_enemies := 0
var pending_spawns := 4
var actors: Array[ReceptionActor] = []
var player: ReceptionActor
var actor_layer: Node2D
var projectile_layer: Node2D
var door_collision: CollisionShape2D
var door_visual: Polygon2D
var trigger_visual: Polygon2D
var state_label: Label
var objective_label: Label
var event_label: Label
var astar := AStarGrid2D.new()
var blockers: Array[Rect2] = []
var event_timeout := 0.0

func _ready() -> void:
	_build_navigation()
	_build_room()
	_spawn_party()
	_build_hud()
	_update_hud()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
		return
	if event_timeout > 0.0:
		event_timeout -= delta
		if event_timeout <= 0.0: event_label.text = ""
	if not trigger_consumed and is_instance_valid(player) and player.global_position.x >= 245.0:
		_start_encounter()
	if exit_open and is_instance_valid(player) and player.global_position.x > 925.0 and not completed:
		completed = true
		event_label.text = "PLAYTEST CONCLUIDO — pressione R para reiniciar"
		event_timeout = 9999.0
	_update_hud()

func _build_navigation() -> void:
	blockers = [
		Rect2(305, 105, 168, 58),
		Rect2(520, 94, 36, 70),
		Rect2(520, 310, 36, 70),
		Rect2(638, 58, 86, 92),
		Rect2(690, 250, 34, 170),
		Rect2(365, 335, 115, 30)
	]
	astar.region = Rect2i(0, 0, 60, 34)
	astar.cell_size = Vector2(16, 16)
	astar.offset = Vector2(8, 8)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	for rect in blockers:
		var grown := rect.grow(9.0)
		var from := Vector2i(floori(grown.position.x / 16.0), floori(grown.position.y / 16.0))
		var to := Vector2i(ceili(grown.end.x / 16.0), ceili(grown.end.y / 16.0))
		for x in range(from.x, to.x + 1):
			for y in range(from.y, to.y + 1):
				var cell := Vector2i(x, y)
				if astar.is_in_boundsv(cell): astar.set_point_solid(cell, true)

func _build_room() -> void:
	var background := Polygon2D.new()
	background.polygon = PackedVector2Array([Vector2(0, 24), Vector2(960, 24), Vector2(960, 540), Vector2(0, 540)])
	background.color = Color("202936")
	add_child(background)
	for x in range(0, 960, 32):
		for y in range(24, 540, 32):
			var tile := Polygon2D.new()
			tile.polygon = PackedVector2Array([Vector2(x + 1, y + 1), Vector2(x + 31, y + 1), Vector2(x + 31, y + 31), Vector2(x + 1, y + 31)])
			tile.color = Color("273544") if int((x + y) / 32.0) % 2 == 0 else Color("2b3948")
			add_child(tile)
	actor_layer = Node2D.new()
	actor_layer.name = "YSortWorld"
	actor_layer.y_sort_enabled = true
	add_child(actor_layer)
	projectile_layer = Node2D.new()
	projectile_layer.name = "Projectiles"
	add_child(projectile_layer)
	_add_walls()
	_add_obstacle("BALCAO", blockers[0], Color("6e563d"), true)
	_add_obstacle("PILAR A", blockers[1], Color("78838d"), true)
	_add_obstacle("PILAR B", blockers[2], Color("78838d"), true)
	_add_obstacle("ARQUIVO", blockers[3], Color("4f6573"), true)
	_add_obstacle("DIVISORIA / CHOKE", blockers[4], Color("495765"), true)
	_add_obstacle("BANCO (TIRO PASSA)", blockers[5], Color("7a6549"), false)
	_build_trigger()
	_build_exit()

func _add_walls() -> void:
	_add_obstacle("", Rect2(0, 24, 960, 16), Color("111820"), true)
	_add_obstacle("", Rect2(0, 524, 960, 16), Color("111820"), true)
	_add_obstacle("", Rect2(0, 24, 16, 516), Color("111820"), true)
	_add_obstacle("", Rect2(944, 24, 16, 205), Color("111820"), true)
	_add_obstacle("", Rect2(944, 335, 16, 205), Color("111820"), true)

func _add_obstacle(label_text: String, rect: Rect2, color: Color, blocks_projectile: bool) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1 if blocks_projectile else 4
	body.collision_mask = 0
	body.position = rect.get_center()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	var visual := Polygon2D.new()
	var half := rect.size * 0.5
	visual.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
	visual.color = color
	body.add_child(visual)
	if not label_text.is_empty():
		var label := Label.new()
		label.text = label_text
		label.position = Vector2(-rect.size.x * 0.5, -rect.size.y * 0.5 - 13)
		label.add_theme_font_size_override("font_size", 8)
		body.add_child(label)
	actor_layer.add_child(body)

func _build_trigger() -> void:
	trigger_visual = Polygon2D.new()
	trigger_visual.polygon = PackedVector2Array([Vector2(235, 42), Vector2(252, 42), Vector2(252, 522), Vector2(235, 522)])
	trigger_visual.color = Color(0.92, 0.72, 0.2, 0.18)
	add_child(trigger_visual)

func _build_exit() -> void:
	var door := StaticBody2D.new()
	door.name = "ExitDoor"
	door.collision_layer = 1
	door.position = Vector2(920, 282)
	door_collision = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(18, 106)
	door_collision.shape = shape
	door.add_child(door_collision)
	door_visual = Polygon2D.new()
	door_visual.polygon = PackedVector2Array([Vector2(-9, -53), Vector2(9, -53), Vector2(9, 53), Vector2(-9, 53)])
	door_visual.color = Color("a83d35")
	door.add_child(door_visual)
	actor_layer.add_child(door)

func _spawn_party() -> void:
	player = _spawn_actor("CAVALEIRO", "ally", "melee", Vector2(82, 272), true, Color("58a6ff"))
	var swordsman := _spawn_actor("ESPADACHIM", "ally", "melee", Vector2(52, 235), false, Color("66d17a"))
	swordsman.follow_slot = Vector2(-30, -34)
	var intern := _spawn_actor("ESTAGIARIO", "ally", "ranged", Vector2(48, 282), false, Color("f0c15a"))
	intern.follow_slot = Vector2(-38, 4)
	var coordinator := _spawn_actor("COORDENADOR", "ally", "coordinator", Vector2(55, 330), false, Color("b681e8"))
	coordinator.follow_slot = Vector2(-30, 38)
	var camera := Camera2D.new()
	camera.position = Vector2.ZERO
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 960
	camera.limit_bottom = 540
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	player.add_child(camera)

func _start_encounter() -> void:
	trigger_consumed = true
	room_state = "ROOM_COMBAT"
	trigger_visual.color = Color(0.9, 0.2, 0.16, 0.12)
	pending_spawns = 0
	_spawn_actor("MELEE A1", "enemy", "melee", Vector2(455, 245), false, Color("e34e48"))
	_spawn_actor("MELEE A2", "enemy", "melee", Vector2(468, 295), false, Color("e34e48"))
	_spawn_actor("ESTAGIARIO INIMIGO", "enemy", "ranged", Vector2(620, 205), false, Color("e58d3b"))
	_spawn_actor("COORDENADOR INIMIGO", "enemy", "coordinator", Vector2(795, 330), false, Color("d45ad8"))
	report_command("ENCOUNTER", "4 INIMIGOS: 3 MELEE + 1 RANGED")

func _spawn_actor(p_name: String, team: String, role: String, position: Vector2, is_player: bool, tint: Color) -> ReceptionActor:
	var actor: ReceptionActor = Actor.new()
	actor.setup(self, p_name, team, role, is_player, tint)
	actor.global_position = position
	actor.died.connect(_on_actor_died)
	actor_layer.add_child(actor)
	actors.append(actor)
	if team == "enemy": active_enemies += 1
	return actor

func _on_actor_died(actor: ReceptionActor) -> void:
	if actor.team == "enemy":
		active_enemies = maxi(0, active_enemies - 1)
		if room_state == "ROOM_COMBAT" and active_enemies == 0 and pending_spawns == 0:
			_complete_room()
	elif actor.is_player:
		event_label.text = "CAVALEIRO DERROTADO — pressione R para reiniciar"
		event_timeout = 9999.0
	actors.erase(actor)

func _complete_room() -> void:
	room_state = "ROOM_COMPLETE"
	exit_open = true
	door_collision.set_deferred("disabled", true)
	door_visual.color = Color("35b96b")
	report_command("ROOM_COMPLETE", "EXIT OPEN — atravesse a saida")

func closest_hostile(source: ReceptionActor) -> ReceptionActor:
	var result: ReceptionActor
	var best := INF
	for candidate in actors:
		if is_instance_valid(candidate) and candidate.alive and candidate.team != source.team:
			var distance := source.global_position.distance_squared_to(candidate.global_position)
			if distance < best:
				best = distance
				result = candidate
	return result

func request_navigation_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var from_cell := Vector2i(floori(from.x / 16.0), floori(from.y / 16.0))
	var to_cell := Vector2i(floori(to.x / 16.0), floori(to.y / 16.0))
	from_cell.x = clampi(from_cell.x, 0, 59)
	from_cell.y = clampi(from_cell.y, 0, 33)
	to_cell.x = clampi(to_cell.x, 0, 59)
	to_cell.y = clampi(to_cell.y, 0, 33)
	if astar.is_point_solid(from_cell): from_cell = _nearest_open(from_cell)
	if astar.is_point_solid(to_cell): to_cell = _nearest_open(to_cell)
	return astar.get_point_path(from_cell, to_cell, true)

func _nearest_open(origin: Vector2i) -> Vector2i:
	for radius in range(1, 8):
		for x in range(origin.x - radius, origin.x + radius + 1):
			for y in range(origin.y - radius, origin.y + radius + 1):
				var cell := Vector2i(x, y)
				if astar.is_in_boundsv(cell) and not astar.is_point_solid(cell): return cell
	return Vector2i(1, 1)

func spawn_projectile(owner_actor: ReceptionActor, position: Vector2, direction: Vector2, tint: Color) -> void:
	var projectile := Projectile.new()
	projectile.global_position = position
	projectile.setup(self, owner_actor, direction, tint)
	projectile_layer.add_child(projectile)

func invoke_pressure(source: ReceptionActor) -> void:
	for actor in actors:
		if is_instance_valid(actor) and actor.alive and actor.team != source.team and source.global_position.distance_to(actor.global_position) < 58.0:
			actor.take_damage(1, source)

func report_command(who: String, action: String) -> void:
	if event_label == null: return
	event_label.text = "%s: %s" % [who, action]
	event_timeout = 2.8

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := ColorRect.new()
	panel.color = Color(0.02, 0.025, 0.035, 0.9)
	panel.position = Vector2(0, 0)
	panel.size = Vector2(320, 36)
	canvas.add_child(panel)
	state_label = Label.new()
	state_label.position = Vector2(6, 2)
	state_label.add_theme_font_size_override("font_size", 9)
	panel.add_child(state_label)
	objective_label = Label.new()
	objective_label.position = Vector2(6, 16)
	objective_label.add_theme_font_size_override("font_size", 8)
	panel.add_child(objective_label)
	event_label = Label.new()
	event_label.position = Vector2(8, 158)
	event_label.add_theme_font_size_override("font_size", 9)
	event_label.add_theme_color_override("font_color", Color("ffe26f"))
	canvas.add_child(event_label)
	var help := Label.new()
	help.text = "WASD/SETAS mover | J atacar | K dash | R restart"
	help.position = Vector2(8, 145)
	help.add_theme_font_size_override("font_size", 7)
	canvas.add_child(help)

func _update_hud() -> void:
	if state_label == null: return
	state_label.text = "%s | inimigos %d | pendentes %d | saida %s" % [room_state, active_enemies, pending_spawns, "OPEN" if exit_open else "LOCKED"]
	if room_state == "ROOM_IDLE": objective_label.text = "Atravesse o ENCOUNTER TRIGGER amarelo"
	elif room_state == "ROOM_COMBAT": objective_label.text = "Derrote 3 melee + 1 ranged | Order/Invoke ativos"
	else: objective_label.text = "ROOM_COMPLETE: atravesse a porta verde"
