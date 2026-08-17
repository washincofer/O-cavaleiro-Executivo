class_name ReceptionActor
extends CharacterBody2D

signal died(actor: ReceptionActor)

var controller: Node
var actor_name := "Actor"
var team := "ally"
var role := "melee"
var is_player := false
var alive := true
var hp := 4
var max_hp := 4
var speed := 78.0
var damage := 1
var follow_slot := Vector2.ZERO
var attack_cooldown := 0.0
var path_timer := 0.0
var command_timer := 3.0
var command_phase := 0
var command_flash := 0.0
var path: PackedVector2Array = PackedVector2Array()
var target: ReceptionActor
var facing := Vector2.RIGHT
var tint := Color.WHITE
var buff_timer := 0.0

func setup(p_controller: Node, p_name: String, p_team: String, p_role: String, p_player: bool, p_tint: Color) -> void:
	controller = p_controller
	actor_name = p_name
	team = p_team
	role = p_role
	is_player = p_player
	tint = p_tint
	max_hp = 7 if is_player else (5 if role == "coordinator" else 4)
	hp = max_hp
	if role == "ranged": speed = 67.0
	if role == "coordinator": speed = 61.0
	collision_layer = 2
	collision_mask = 1 | 4
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 7.0
	capsule.height = 20.0
	shape.shape = capsule
	shape.position = Vector2(0, -7)
	add_child(shape)
	var nameplate := Label.new()
	nameplate.text = actor_name
	nameplate.position = Vector2(-24, 10)
	nameplate.add_theme_font_size_override("font_size", 6)
	nameplate.add_theme_color_override("font_color", tint)
	add_child(nameplate)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not alive: return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	path_timer -= delta
	command_flash = maxf(0.0, command_flash - delta)
	buff_timer = maxf(0.0, buff_timer - delta)
	if is_player:
		_player_tick()
	else:
		_ai_tick(delta)
	move_and_slide()
	global_position.x = clampf(global_position.x, 18.0, 942.0)
	global_position.y = clampf(global_position.y, 42.0, 518.0)
	queue_redraw()

func _player_tick() -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input.length_squared() > 0.01: facing = input.normalized()
	velocity = input * speed * (1.75 if Input.is_action_pressed("dash") else 1.0)
	if Input.is_action_just_pressed("attack"): _attack_nearest(true)

func _ai_tick(delta: float) -> void:
	if controller.room_state == "ROOM_IDLE" and team == "ally":
		_follow_player(delta)
		return
	target = controller.closest_hostile(self)
	if target == null:
		if team == "ally": _follow_player(delta)
		else: velocity = Vector2.ZERO
		return
	var distance := global_position.distance_to(target.global_position)
	var desired_range := 92.0 if role == "ranged" else (24.0 if role == "coordinator" else 22.0)
	if role == "coordinator":
		command_timer -= delta
		if command_timer <= 0.0:
			_run_command()
	if distance <= desired_range:
		velocity = Vector2.ZERO
		facing = global_position.direction_to(target.global_position)
		if role == "ranged": _shoot_target()
		else: _attack_nearest(false)
	else:
		_move_toward_point(target.global_position)

func _follow_player(_delta: float) -> void:
	var leader: ReceptionActor = controller.player
	if not is_instance_valid(leader): return
	var destination := leader.global_position + follow_slot
	if global_position.distance_to(destination) > 18.0:
		_move_toward_point(destination)
	else:
		velocity = Vector2.ZERO

func _move_toward_point(destination: Vector2) -> void:
	if path_timer <= 0.0:
		path = controller.request_navigation_path(global_position, destination)
		path_timer = 0.28
	while path.size() > 0 and global_position.distance_to(path[0]) < 9.0:
		path.remove_at(0)
	var waypoint := destination if path.is_empty() else path[0]
	var direction := global_position.direction_to(waypoint)
	for other in controller.actors:
		if is_instance_valid(other) and other != self and other.alive:
			var d := global_position.distance_to(other.global_position)
			if d < 20.0 and d > 0.1: direction += other.global_position.direction_to(global_position) * (20.0 - d) / 20.0
	direction = direction.normalized()
	if direction.length_squared() > 0.01: facing = direction
	velocity = direction * speed * (1.25 if buff_timer > 0.0 else 1.0)

func _attack_nearest(player_attack: bool) -> void:
	if attack_cooldown > 0.0: return
	var victim: ReceptionActor = controller.closest_hostile(self)
	if victim != null and global_position.distance_to(victim.global_position) <= (34.0 if player_attack else 25.0):
		victim.take_damage(damage + (1 if buff_timer > 0.0 else 0), self)
		facing = global_position.direction_to(victim.global_position)
		attack_cooldown = 0.48
		command_flash = 0.12

func _shoot_target() -> void:
	if attack_cooldown > 0.0 or target == null: return
	controller.spawn_projectile(self, global_position + facing * 12.0, facing, tint)
	attack_cooldown = 1.05 if role == "ranged" else 1.35

func _run_command() -> void:
	command_timer = 4.4
	command_phase = 1 - command_phase
	command_flash = 0.8
	if command_phase == 0:
		for actor in controller.actors:
			if is_instance_valid(actor) and actor.alive and actor.team == team and global_position.distance_to(actor.global_position) < 125.0:
				actor.buff_timer = 2.5
		controller.report_command(actor_name, "ORDER")
	else:
		hp = mini(max_hp, hp + 1)
		controller.invoke_pressure(self)
		controller.report_command(actor_name, "INVOKE")

func take_damage(amount: int, source: ReceptionActor) -> void:
	if not alive or source == self or source.team == team: return
	hp -= amount
	command_flash = 0.18
	if hp <= 0:
		alive = false
		velocity = Vector2.ZERO
		died.emit(self)
		queue_free()

func _draw() -> void:
	var body_color := tint
	if command_flash > 0.0: body_color = Color.WHITE
	draw_circle(Vector2(0, -8), 9.0, Color(0.06, 0.07, 0.09, 1))
	draw_circle(Vector2(0, -8), 7.0, body_color)
	draw_line(Vector2(0, -3), Vector2(0, 7), body_color, 7.0)
	draw_line(Vector2.ZERO, facing * 13.0, Color.WHITE, 2.0)
	if role == "ranged": draw_line(Vector2(-7, -2), Vector2(7, 2), Color(0.75, 0.5, 0.18), 3.0)
	if role == "coordinator": draw_arc(Vector2(0, -8), 11.0, 0, TAU, 20, Color(0.72, 0.35, 0.95), 2.0)
	if role == "coordinator" and command_flash > 0.0:
		var command_color := Color("55d9ff") if command_phase == 0 else Color("f34dce")
		draw_arc(Vector2(0, -8), 16.0 + command_flash * 8.0, 0, TAU, 28, command_color, 3.0)
	var ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(-10, -22, 20, 3), Color(0.12, 0.12, 0.12))
	draw_rect(Rect2(-10, -22, 20 * ratio, 3), Color(0.3, 0.9, 0.4) if team == "ally" else Color(0.95, 0.25, 0.2))
