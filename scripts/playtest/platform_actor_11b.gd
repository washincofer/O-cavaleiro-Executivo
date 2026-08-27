class_name PlatformPartyActor
extends CharacterBody2D

signal died(actor)

var controller: Node
var actor_name := "Actor"
var team := "ally"
var role := "hero"
var is_player := false
var is_controlled := false
var party_slot := -1
var alive := true

var max_hp := 4
var hp := 4
var speed := 92.0
var jump_velocity := -245.0
var gravity := 760.0
var max_fall_speed := 420.0
var facing := 1.0
var follow_offset_x := -30.0

var attack_cooldown := 0.0
var ability_cooldown := 0.0
var guard_timer := 0.0
var flash_timer := 0.0
var edge_turn_timer := 0.0
var edge_turn_direction := 0.0
var tint := Color.WHITE

func setup(
	p_controller: Node,
	p_name: String,
	p_team: String,
	p_role: String,
	p_player: bool,
	p_tint: Color,
	p_party_slot := -1
) -> void:
	controller = p_controller
	actor_name = p_name
	team = p_team
	role = p_role
	is_player = p_player
	tint = p_tint
	party_slot = p_party_slot

	max_hp = 5 if is_player else 4
	if team == "enemy":
		max_hp = 3
	hp = max_hp

	if role == "crossbow":
		speed = 86.0
	elif role == "guard":
		speed = 88.0

	collision_layer = 2
	collision_mask = 1

	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 6.0
	capsule.height = 22.0
	shape.shape = capsule
	shape.position = Vector2(0, -7)
	add_child(shape)

	var nameplate := Label.new()
	nameplate.text = actor_name
	nameplate.position = Vector2(-25, -31)
	nameplate.add_theme_font_size_override("font_size", 6)
	nameplate.add_theme_color_override("font_color", tint)
	add_child(nameplate)
	queue_redraw()

func set_controlled(value: bool) -> void:
	if not alive:
		return
	is_controlled = value
	velocity.x = 0.0
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not alive:
		return

	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	ability_cooldown = maxf(0.0, ability_cooldown - delta)
	guard_timer = maxf(0.0, guard_timer - delta)
	flash_timer = maxf(0.0, flash_timer - delta)
	edge_turn_timer = maxf(0.0, edge_turn_timer - delta)

	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)

	if team == "ally":
		if is_controlled:
			_controlled_tick()
		else:
			_follow_tick()
	else:
		_enemy_tick()

	move_and_slide()
	queue_redraw()

func _controlled_tick() -> void:
	var axis := Input.get_axis("move_left", "move_right")
	if axis != 0.0:
		facing = signf(axis)
	var multiplier := 1.55 if Input.is_action_pressed("dash") else 1.0
	velocity.x = axis * speed * multiplier

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	if Input.is_action_just_pressed("attack"):
		controller.activate_actor_action(self)

func _follow_tick() -> void:
	var leader = controller.get_active_actor()
	if not is_instance_valid(leader) or not leader.alive or leader == self:
		velocity.x = 0.0
		return

	var desired_x: float = leader.global_position.x + follow_offset_x
	var delta_x: float = desired_x - global_position.x

	if absf(delta_x) > 18.0:
		facing = signf(delta_x)
		velocity.x = facing * speed * 0.92
		# Seguidor pula um vao ao acompanhar o personagem ativo, em vez de cair nele.
		if is_on_floor() and not controller.has_floor_ahead(self, facing, 14.0):
			velocity.y = jump_velocity
	else:
		velocity.x = move_toward(velocity.x, 0.0, 20.0)

	if leader.global_position.y < global_position.y - 25.0 and is_on_floor():
		velocity.y = jump_velocity

func _enemy_tick() -> void:
	# Depois de detectar uma borda fatal, afasta-se por alguns instantes antes de retomar a perseguicao.
	if edge_turn_timer > 0.0:
		facing = edge_turn_direction
		velocity.x = facing * speed * 0.50
		return

	var target = controller.closest_alive_ally(self)
	if not is_instance_valid(target):
		velocity.x = 0.0
		return

	var dx: float = target.global_position.x - global_position.x
	var dy: float = absf(target.global_position.y - global_position.y)

	if absf(dx) <= 24.0 and dy <= 30.0:
		velocity.x = 0.0
		if attack_cooldown <= 0.0:
			target.take_damage(1, self)
			attack_cooldown = 0.9
			flash_timer = 0.12
	else:
		facing = signf(dx) if dx != 0.0 else facing

		# Inimigo terrestre nao caminha voluntariamente para uma queda fatal.
		# Ele ainda pode morrer por queda se outra mecanica o empurrar no futuro.
		if is_on_floor() and not controller.has_floor_ahead(self, facing, 14.0):
			edge_turn_direction = -facing
			edge_turn_timer = 0.55
			facing = edge_turn_direction
			velocity.x = facing * speed * 0.50
			return

		velocity.x = facing * speed * 0.62
		if target.global_position.y < global_position.y - 30.0 and is_on_floor():
			velocity.y = jump_velocity * 0.88

func begin_guard() -> bool:
	if not alive or role != "guard" or ability_cooldown > 0.0:
		return false
	guard_timer = 1.25
	ability_cooldown = 2.2
	flash_timer = 0.18
	return true

func fire_crossbow() -> bool:
	if not alive or role != "crossbow" or ability_cooldown > 0.0:
		return false
	ability_cooldown = 0.85
	flash_timer = 0.12
	controller.spawn_party_bolt(self, Vector2(facing, 0.0))
	return true

func hero_melee() -> bool:
	if not alive or not is_player or attack_cooldown > 0.0:
		return false
	attack_cooldown = 0.42
	flash_timer = 0.12
	return controller.hero_melee_attack(self)

func take_damage(amount: int, source = null) -> void:
	if not alive:
		return
	if guard_timer > 0.0 and team == "ally":
		flash_timer = 0.16
		if is_instance_valid(controller):
			controller.report_event("%s: GUARDA BLOQUEOU DANO" % actor_name)
		return
	if source != null and source.team == team:
		return

	hp = maxi(0, hp - amount)
	flash_timer = 0.18
	if hp <= 0:
		_die()

func force_kill() -> void:
	if not alive:
		return
	hp = 0
	_die()

func _die() -> void:
	alive = false
	is_controlled = false
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	visible = false
	set_physics_process(false)
	died.emit(self)

func _draw() -> void:
	if not alive:
		return

	if is_controlled and team == "ally":
		draw_arc(Vector2(0, -7), 13.0, 0.0, TAU, 28, Color("ffe26f"), 2.5)

	if guard_timer > 0.0:
		var guard_angle := 0.0 if facing > 0.0 else PI
		var guard_center := Vector2(facing * 7.0, -7.0)
		draw_arc(guard_center, 10.0, guard_angle - 1.05, guard_angle + 1.05, 24, Color("71d7ff"), 3.0)

	var body_color := Color.WHITE if flash_timer > 0.0 else tint
	draw_circle(Vector2(0, -11), 6.0, Color(0.06, 0.07, 0.09))
	draw_circle(Vector2(0, -11), 4.5, body_color)
	draw_line(Vector2(0, -6), Vector2(0, 5), body_color, 6.0)
	draw_line(Vector2.ZERO, Vector2(facing * 11.0, -2.0), Color.WHITE, 2.0)

	if role == "crossbow":
		draw_line(Vector2(-facing * 5.0, -3.0), Vector2(facing * 5.0, 1.0), Color("d9a441"), 2.5)
	elif role == "guard":
		var shield_angle := 0.0 if facing > 0.0 else PI
		draw_arc(Vector2(facing * 6.0, -1.0), 5.0, shield_angle - 1.2, shield_angle + 1.2, 12, Color("a9c6d8"), 2.0)

	var ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(-10, -25, 20, 3), Color(0.12, 0.12, 0.12))
	draw_rect(
		Rect2(-10, -25, 20 * ratio, 3),
		Color(0.3, 0.9, 0.4) if team == "ally" else Color(0.95, 0.25, 0.2)
	)
