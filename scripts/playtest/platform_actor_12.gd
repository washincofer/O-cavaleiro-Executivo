class_name PlatformPartyActor12
extends CharacterBody2D

## Sprint 12: ator com visual real (AnimatedSprite2D) para o trio
## Guerreiro / Arqueira / Maga e para os inimigos Rato / Gosma.
## Substitui o corpo desenhado a mao da 11C mantendo a mesma arquitetura
## de movimento, seguidores e protecao de queda.

signal died(actor)

const ROLE_ANIM := {
	"warrior": {
		"idle": {"path": "res://assets/Characters/Warrior/Runtime/Idle.png", "fw": 135, "fh": 135, "count": 10, "fps": 8.0, "loop": true},
		"move": {"path": "res://assets/Characters/Warrior/Runtime/Run.png", "fw": 135, "fh": 135, "count": 6, "fps": 12.0, "loop": true},
		"attack": {"path": "res://assets/Characters/Warrior/Runtime/Attack1.png", "fw": 135, "fh": 135, "count": 4, "fps": 12.0, "loop": false},
		"special": {"path": "res://assets/Characters/Warrior/Runtime/Attack2.png", "fw": 135, "fh": 135, "count": 4, "fps": 16.0, "loop": false},
		"hurt": {"path": "res://assets/Characters/Warrior/Runtime/GetHit.png", "fw": 135, "fh": 135, "count": 3, "fps": 12.0, "loop": false},
		"death": {"path": "res://assets/Characters/Warrior/Runtime/Death.png", "fw": 135, "fh": 135, "count": 9, "fps": 10.0, "loop": false},
		"jump": {"path": "res://assets/Characters/Warrior/Runtime/Jump.png", "fw": 135, "fh": 135, "count": 2, "fps": 6.0, "loop": false},
		"fall": {"path": "res://assets/Characters/Warrior/Runtime/Fall.png", "fw": 135, "fh": 135, "count": 2, "fps": 6.0, "loop": true},
	},
	"archer": {
		"idle": {"path": "res://assets/Characters/Archer/Runtime/Idle.png", "fw": 100, "fh": 100, "count": 10, "fps": 8.0, "loop": true},
		"move": {"path": "res://assets/Characters/Archer/Runtime/Run.png", "fw": 100, "fh": 100, "count": 8, "fps": 12.0, "loop": true},
		"attack": {"path": "res://assets/Characters/Archer/Runtime/Attack1.png", "fw": 100, "fh": 100, "count": 6, "fps": 14.0, "loop": false},
		"hurt": {"path": "res://assets/Characters/Archer/Runtime/GetHit.png", "fw": 100, "fh": 100, "count": 3, "fps": 12.0, "loop": false},
		"death": {"path": "res://assets/Characters/Archer/Runtime/Death.png", "fw": 100, "fh": 100, "count": 10, "fps": 10.0, "loop": false},
		"jump": {"path": "res://assets/Characters/Archer/Runtime/Jump.png", "fw": 100, "fh": 100, "count": 2, "fps": 6.0, "loop": false},
		"fall": {"path": "res://assets/Characters/Archer/Runtime/Fall.png", "fw": 100, "fh": 100, "count": 2, "fps": 6.0, "loop": true},
	},
	"mage": {
		"idle": {"path": "res://assets/Characters/Mage/Runtime/Idle.png", "fw": 231, "fh": 190, "count": 6, "fps": 6.0, "loop": true},
		"move": {"path": "res://assets/Characters/Mage/Runtime/Run.png", "fw": 231, "fh": 190, "count": 8, "fps": 10.0, "loop": true},
		"attack": {"path": "res://assets/Characters/Mage/Runtime/Attack1.png", "fw": 231, "fh": 190, "count": 8, "fps": 12.0, "loop": false},
		"special": {"path": "res://assets/Characters/Mage/Runtime/Attack2.png", "fw": 231, "fh": 190, "count": 8, "fps": 14.0, "loop": false},
		"hurt": {"path": "res://assets/Characters/Mage/Runtime/GetHit.png", "fw": 231, "fh": 190, "count": 4, "fps": 12.0, "loop": false},
		"death": {"path": "res://assets/Characters/Mage/Runtime/Death.png", "fw": 231, "fh": 190, "count": 7, "fps": 8.0, "loop": false},
		"jump": {"path": "res://assets/Characters/Mage/Runtime/Jump.png", "fw": 231, "fh": 190, "count": 2, "fps": 6.0, "loop": false},
		"fall": {"path": "res://assets/Characters/Mage/Runtime/Fall.png", "fw": 231, "fh": 190, "count": 2, "fps": 6.0, "loop": true},
	},
	"slime": {
		"idle": {"path": "res://assets/Enemies/Slime/Runtime/Idle.png", "fw": 156, "fh": 156, "count": 14, "fps": 8.0, "loop": true},
		"move": {"path": "res://assets/Enemies/Slime/Runtime/Walk.png", "fw": 156, "fh": 156, "count": 6, "fps": 8.0, "loop": true},
		"attack": {"path": "res://assets/Enemies/Slime/Runtime/Attack.png", "fw": 156, "fh": 156, "count": 19, "fps": 16.0, "loop": false},
		"hurt": {"path": "res://assets/Enemies/Slime/Runtime/Hurt.png", "fw": 156, "fh": 156, "count": 3, "fps": 12.0, "loop": false},
		"death": {"path": "res://assets/Enemies/Slime/Runtime/Death.png", "fw": 156, "fh": 156, "count": 11, "fps": 10.0, "loop": false},
	},
	"rat": {
		"idle": {"path": "res://assets/Enemies/Rat/Runtime/Idle.png", "fw": 70, "fh": 70, "count": 10, "fps": 8.0, "loop": true},
		"move": {"path": "res://assets/Enemies/Rat/Runtime/Run.png", "fw": 70, "fh": 70, "count": 8, "fps": 12.0, "loop": true},
		"attack": {"path": "res://assets/Enemies/Rat/Runtime/Attack.png", "fw": 70, "fh": 70, "count": 12, "fps": 14.0, "loop": false},
		"hurt": {"path": "res://assets/Enemies/Rat/Runtime/Hurt.png", "fw": 70, "fh": 70, "count": 3, "fps": 12.0, "loop": false},
		"death": {"path": "res://assets/Enemies/Rat/Runtime/Death.png", "fw": 70, "fh": 70, "count": 6, "fps": 10.0, "loop": false},
	},
}

# scale, sprite offset (raw pixel space) and capsule collision tuned from the
# alpha-channel bounding box of each pack's idle frame (feet position / width),
# so every role's feet line up with the CharacterBody2D origin (y = 0).
const ROLE_BODY := {
	"warrior": {"scale": 0.842, "offset": Vector2(0.5, -18.5), "radius": 6.0, "height": 26.0, "shape_y": -15.0, "speed": 92.0, "max_hp": 5, "ranged": false},
	"archer": {"scale": 0.889, "offset": Vector2(-1.0, -17.0), "radius": 5.0, "height": 26.0, "shape_y": -15.0, "speed": 96.0, "max_hp": 4, "ranged": true},
	"mage": {"scale": 0.372, "offset": Vector2(5.0, -46.0), "radius": 6.0, "height": 28.0, "shape_y": -16.0, "speed": 84.0, "max_hp": 4, "ranged": true},
	"slime": {"scale": 1.0, "offset": Vector2(0.0, -9.0), "radius": 7.0, "height": 14.0, "shape_y": -8.0, "speed": 46.0, "max_hp": 3, "ranged": false},
	"rat": {"scale": 0.9, "offset": Vector2(0.0, -10.0), "radius": 6.0, "height": 16.0, "shape_y": -9.0, "speed": 58.0, "max_hp": 3, "ranged": false},
}

const DISPLAY_NAME := {
	"warrior": "GUERREIRO",
	"archer": "ARQUEIRA",
	"mage": "MAGA",
	"slime": "GOSMA",
	"rat": "RATO",
}

var controller: Node
var actor_name := "Actor"
var team := "ally"
var role := "warrior"
var is_controlled := false
var party_slot := -1
var alive := true

var max_hp := 4
var hp := 4
var speed := 92.0
var jump_velocity := -245.0
var jumps_used := 0
var max_jumps := 2
var gravity := 760.0
var max_fall_speed := 420.0
var facing := 1.0
var follow_offset_x := -30.0
var is_ranged := false

var attack_cooldown := 0.0
var attack_cooldown_max := 0.45
var attack_lock_timer := 0.0
var hurt_lock_timer := 0.0
var edge_turn_timer := 0.0
var edge_turn_direction := 0.0

# Habilidade especial (tecla H) — cada papel tem uma mecanica propria:
# Guerreiro = Estocada (dash que quebra entulho), Arqueira = Tiro
# Perfurante (atravessa parede de energia), Maga = Teleporte (cruza vaos
# largos demais para o pulo duplo).
var special_cooldown := 0.0
var special_cooldown_max := 1.4
var charge_timer := 0.0
var charge_speed := 320.0
var charge_direction := 1.0

var sprite: AnimatedSprite2D
var nameplate: Label

func setup(
	p_controller: Node,
	p_name: String,
	p_team: String,
	p_role: String,
	p_tint: Color,
	p_party_slot := -1
) -> void:
	controller = p_controller
	actor_name = p_name
	team = p_team
	role = p_role
	party_slot = p_party_slot

	var body_cfg: Dictionary = ROLE_BODY[role]
	var body_speed: float = body_cfg["speed"]
	speed = body_speed
	var body_hp: int = body_cfg["max_hp"]
	max_hp = body_hp
	hp = max_hp
	is_ranged = body_cfg["ranged"]

	collision_layer = 2
	# Layer 8 mantida livre para futuras interacoes exclusivas de inimigos.
	collision_mask = 1

	var capsule := CapsuleShape2D.new()
	var body_radius: float = body_cfg["radius"]
	var body_height: float = body_cfg["height"]
	capsule.radius = body_radius
	capsule.height = body_height
	var shape := CollisionShape2D.new()
	shape.shape = capsule
	var body_shape_y: float = body_cfg["shape_y"]
	shape.position = Vector2(0, body_shape_y)
	add_child(shape)

	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = _build_sprite_frames(role)
	var body_scale: float = body_cfg["scale"]
	sprite.scale = Vector2(body_scale, body_scale)
	sprite.offset = body_cfg["offset"]
	sprite.animation = "idle"
	sprite.play("idle")
	sprite.animation_finished.connect(_on_animation_finished)
	add_child(sprite)

	nameplate = Label.new()
	nameplate.text = actor_name
	nameplate.position = Vector2(-25, body_shape_y - body_height * 0.5 - 16.0)
	nameplate.add_theme_font_size_override("font_size", 6)
	nameplate.add_theme_color_override("font_color", p_tint)
	add_child(nameplate)
	queue_redraw()

static func _build_sprite_frames(p_role: String) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var anim_cfg: Dictionary = ROLE_ANIM[p_role]
	for anim_name in anim_cfg.keys():
		var a: Dictionary = anim_cfg[anim_name]
		var tex: Texture2D = load(a["path"])
		var fw: int = a["fw"]
		var fh: int = a["fh"]
		var count: int = a["count"]
		var fps: float = a["fps"]
		var loop: bool = a["loop"]
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, loop)
		frames.set_animation_speed(anim_name, fps)
		for i in range(count):
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(i * fw, 0, fw, fh)
			frames.add_frame(anim_name, atlas)
	return frames

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
	attack_lock_timer = maxf(0.0, attack_lock_timer - delta)
	hurt_lock_timer = maxf(0.0, hurt_lock_timer - delta)
	edge_turn_timer = maxf(0.0, edge_turn_timer - delta)
	special_cooldown = maxf(0.0, special_cooldown - delta)
	charge_timer = maxf(0.0, charge_timer - delta)

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
	if is_on_floor():
		jumps_used = 0
	_update_animation()
	queue_redraw()

func _controlled_tick() -> void:
	if charge_timer > 0.0:
		velocity.x = charge_direction * charge_speed
		controller.try_break_rubble(self)
		if Input.is_action_just_pressed("jump") and jumps_used < max_jumps:
			velocity.y = jump_velocity
			jumps_used += 1
		return

	var axis := Input.get_axis("move_left", "move_right")
	if axis != 0.0:
		facing = signf(axis)
	var multiplier := 1.55 if Input.is_action_pressed("dash") else 1.0
	velocity.x = axis * speed * multiplier

	if Input.is_action_just_pressed("jump") and jumps_used < max_jumps:
		velocity.y = jump_velocity
		jumps_used += 1
		if is_instance_valid(sprite) and sprite.sprite_frames.has_animation("jump"):
			sprite.play("jump")

	if Input.is_action_just_pressed("attack"):
		controller.activate_actor_action(self)

	if Input.is_action_just_pressed("special"):
		controller.activate_actor_special(self)

func _follow_tick() -> void:
	var leader: Node = controller.get_active_actor()
	if not is_instance_valid(leader) or not leader.alive or leader == self:
		velocity.x = 0.0
		return

	var desired_x: float = leader.global_position.x + follow_offset_x
	var delta_x: float = desired_x - global_position.x

	if absf(delta_x) > 18.0:
		facing = signf(delta_x)
		velocity.x = facing * speed * 0.92

		if is_on_floor() and not controller.has_floor_ahead(self, facing, 14.0):
			if controller.has_floor_ahead(self, facing, 54.0):
				velocity.x = facing * speed * 1.05
				velocity.y = jump_velocity
			else:
				velocity.x = 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, 20.0)

	if leader.global_position.y < global_position.y - 25.0 and is_on_floor():
		velocity.y = jump_velocity

func _enemy_tick() -> void:
	if edge_turn_timer > 0.0:
		facing = edge_turn_direction
		velocity.x = facing * speed * 0.50
		return

	var target: Node = controller.closest_alive_ally(self)
	if not is_instance_valid(target):
		velocity.x = 0.0
		return

	var dx: float = target.global_position.x - global_position.x
	var dy: float = absf(target.global_position.y - global_position.y)

	if absf(dx) <= 22.0 and dy <= 28.0:
		velocity.x = 0.0
		if attack_cooldown <= 0.0:
			_play_attack()
			target.take_damage(1, self)
			attack_cooldown = attack_cooldown_max
	else:
		facing = signf(dx) if dx != 0.0 else facing

		if is_on_floor() and not controller.has_floor_ahead(self, facing, 14.0):
			edge_turn_direction = -facing
			edge_turn_timer = 0.55
			facing = edge_turn_direction
			velocity.x = facing * speed * 0.50
			return

		velocity.x = facing * speed * 0.62

func activate_ranged_attack() -> bool:
	if not alive or not is_ranged or attack_cooldown > 0.0:
		return false
	attack_cooldown = attack_cooldown_max
	_play_attack()
	var kind := "arrow" if role == "archer" else "orb"
	controller.spawn_party_projectile(self, Vector2(facing, 0.0), kind)
	return true

func melee_attack() -> bool:
	if not alive or is_ranged or attack_cooldown > 0.0:
		return false
	attack_cooldown = attack_cooldown_max
	_play_attack()
	return controller.melee_attack_from(self)

func activate_special() -> bool:
	if not alive or special_cooldown > 0.0 or charge_timer > 0.0:
		return false
	match role:
		"warrior":
			return _start_charge()
		"archer":
			return _fire_piercing_shot()
		"mage":
			return _cast_teleport()
	return false

func _start_charge() -> bool:
	special_cooldown = special_cooldown_max
	charge_timer = 0.22
	charge_direction = facing
	attack_lock_timer = charge_timer
	if is_instance_valid(sprite) and sprite.sprite_frames.has_animation("special"):
		sprite.play("special")
	return true

func _fire_piercing_shot() -> bool:
	special_cooldown = special_cooldown_max
	attack_lock_timer = 0.2
	if is_instance_valid(sprite) and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
	controller.spawn_party_projectile(self, Vector2(facing, 0.0), "pierce_arrow")
	return true

func _cast_teleport() -> bool:
	special_cooldown = special_cooldown_max
	attack_lock_timer = 0.35
	if is_instance_valid(sprite) and sprite.sprite_frames.has_animation("special"):
		sprite.play("special")
	controller.teleport_actor(self, facing)
	return true

func _play_attack() -> void:
	attack_lock_timer = attack_cooldown_max
	if is_instance_valid(sprite) and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")

func take_damage(amount: int, source = null) -> void:
	if not alive:
		return

	# Apenas o aliado controlado participa do risco de combate; seguidores
	# inativos ficam protegidos ate serem selecionados.
	if team == "ally" and not is_controlled:
		return
	if source != null and source.team == team:
		return

	hp = maxi(0, hp - amount)
	hurt_lock_timer = 0.28
	if is_instance_valid(sprite):
		if sprite.sprite_frames.has_animation("hurt"):
			sprite.play("hurt")
		sprite.modulate = Color(1.0, 0.45, 0.45)
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
	set_physics_process(false)
	queue_redraw()
	if is_instance_valid(sprite) and sprite.sprite_frames.has_animation("death"):
		sprite.modulate = Color(1, 1, 1)
		sprite.play("death")
	else:
		visible = false
	died.emit(self)

func _on_animation_finished() -> void:
	if not is_instance_valid(sprite):
		return
	if not alive:
		if sprite.animation == "death":
			visible = false
		return
	if sprite.animation == "hurt":
		sprite.modulate = Color(1, 1, 1)

func _update_animation() -> void:
	if not is_instance_valid(sprite) or not alive:
		return
	sprite.flip_h = facing < 0.0

	if attack_lock_timer > 0.0 or hurt_lock_timer > 0.0:
		return

	var frames := sprite.sprite_frames
	if not is_on_floor() and frames.has_animation("jump") and frames.has_animation("fall"):
		if velocity.y < 0.0:
			if sprite.animation != "jump":
				sprite.play("jump")
		else:
			if sprite.animation != "fall":
				sprite.play("fall")
		return

	if absf(velocity.x) > 6.0:
		if sprite.animation != "move":
			sprite.play("move")
	else:
		if sprite.animation != "idle":
			sprite.play("idle")

func _draw() -> void:
	if not alive:
		return

	if is_controlled and team == "ally":
		draw_arc(Vector2(0, -3), 12.0, 0.0, TAU, 28, Color("ffe26f"), 1.5)

	var ratio := float(hp) / float(max_hp)
	var bar_y: float = ROLE_BODY[role]["shape_y"] - float(ROLE_BODY[role]["height"]) * 0.5 - 6.0
	draw_rect(Rect2(-10, bar_y, 20, 3), Color(0.12, 0.12, 0.12))
	draw_rect(
		Rect2(-10, bar_y, 20 * ratio, 3),
		Color(0.3, 0.9, 0.4) if team == "ally" else Color(0.95, 0.25, 0.2)
	)
