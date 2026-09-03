class_name DocasPlayer12
extends CharacterBody2D

## Fase nova "Docas do Armazem" (pacote de backgrounds l01..l11 do usuario,
## mesma escala nativa 1672x941 da Fase 00). Reusa o movimento base de
## `Fase00Player12` e adiciona escada vertical (W/S), pedido explicito do
## usuario: "e so para subir escada verticalmente, as diagonais nao
## precisa, igual jogo do Mario, o pulo continua como esta" — ou seja, o
## pulo nao muda em nada; a escada e um modo a parte que trava o movimento
## horizontal enquanto ativo.

const SPRITE_SCALE := 0.552 * 4.0
const SPRITE_OFFSET := Vector2(0.0, -29.4)

var max_speed := 245.0
var ground_acceleration := 1850.0
var air_acceleration := 1050.0
var ground_deceleration := 2300.0
var jump_velocity := -535.0
var gravity := 1560.0
var max_fall_speed := 880.0
var coyote_time := 0.11
var jump_buffer := 0.12
var jump_cut_multiplier := 0.48
var climb_speed := 190.0
var respawn_position := Vector2.ZERO
var input_enabled := true

var _coyote_left := 0.0
var _jump_buffer_left := 0.0
var _was_jump_pressed := false
var facing := 1.0
var on_ladder := false
var current_ladder: Rect2

var sprite: AnimatedSprite2D


func _ready() -> void:
	respawn_position = global_position
	floor_stop_on_slope = true
	floor_max_angle = deg_to_rad(50.0)

	var capsule := CapsuleShape2D.new()
	capsule.radius = 12.0
	capsule.height = 56.0
	var shape := CollisionShape2D.new()
	shape.shape = capsule
	shape.position = Vector2(0, -28)
	add_child(shape)

	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = PlatformPartyActor12._build_sprite_frames("cavaleiro_executivo")
	sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	sprite.offset = SPRITE_OFFSET
	sprite.animation = "idle"
	sprite.play("idle")
	add_child(sprite)


func _physics_process(delta: float) -> void:
	var axis := Input.get_axis("move_left", "move_right") if input_enabled else 0.0
	var climb_axis := 0.0
	if input_enabled:
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			climb_axis -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			climb_axis += 1.0

	var feet := global_position
	var touching_ladder = _ladder_at(feet)

	if on_ladder:
		# Escada e so vertical (sem diagonal, pedido do usuario): sair da
		# escada ao andar pros lados ou pular; travessa continua livre.
		if not touching_ladder or absf(axis) > 0.35 or (input_enabled and Input.is_action_just_pressed("jump")):
			on_ladder = false
		else:
			velocity = Vector2(0.0, climb_axis * climb_speed)
			global_position.x = current_ladder.position.x + current_ladder.size.x * 0.5
			move_and_slide()
			_update_animation()
			return
	elif touching_ladder != null and absf(climb_axis) > 0.01:
		on_ladder = true
		current_ladder = touching_ladder
		velocity = Vector2.ZERO
		return

	if absf(axis) > 0.01:
		facing = signf(axis)
		var accel := ground_acceleration if is_on_floor() else air_acceleration
		velocity.x = move_toward(velocity.x, axis * max_speed, accel * delta)
	else:
		var decel := ground_deceleration if is_on_floor() else air_acceleration * 0.35
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)

	if is_on_floor():
		_coyote_left = coyote_time
	else:
		_coyote_left = maxf(0.0, _coyote_left - delta)
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)

	if input_enabled and Input.is_action_just_pressed("jump"):
		_jump_buffer_left = jump_buffer
	else:
		_jump_buffer_left = maxf(0.0, _jump_buffer_left - delta)

	if _jump_buffer_left > 0.0 and _coyote_left > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_left = 0.0
		_coyote_left = 0.0

	var jump_pressed := input_enabled and Input.is_action_pressed("jump")
	if _was_jump_pressed and not jump_pressed and velocity.y < -90.0:
		velocity.y *= jump_cut_multiplier
	_was_jump_pressed = jump_pressed

	move_and_slide()
	_update_animation()


func _ladder_at(feet: Vector2) -> Variant:
	for ladder in get_meta("ladders", []):
		var r: Rect2 = ladder
		if feet.x >= r.position.x - 6.0 and feet.x <= r.position.x + r.size.x + 6.0 \
				and feet.y >= r.position.y and feet.y <= r.position.y + r.size.y + 4.0:
			return r
	return null


func _update_animation() -> void:
	sprite.flip_h = facing < 0.0
	var moving := is_on_floor() and absf(velocity.x) > 12.0
	var target := "move" if moving else "idle"
	if on_ladder:
		target = "idle"
	if sprite.animation != target:
		sprite.animation = target
		sprite.play(target)
