class_name Fase00Player12
extends CharacterBody2D

## Protagonista canonico da Fase 00.
## Controles oficiais desta fase:
## - A / D: movimento horizontal
## - W: salto (Space continua aceito como apoio)
## - S: comando de baixo / postura baixa
## - J: ataque
## - H: habilidade (Estocada)
## - F1: exibe/oculta colisoes de debug
##
## Usa o Cavaleiro Executivo definitivo (gravata vermelha), reaproveitando
## os SpriteFrames canonicos de PlatformPartyActor12 para manter identidade
## visual entre Prologo, Fase 01 e Fase 02.

const ROLE := "cavaleiro_executivo"
const SPRITE_SCALE := 0.552 * 4.0
const SPRITE_OFFSET := Vector2(0.0, -29.4)
const FALL_RECOVERY_Y := 980.0
const ATTACK_VISUAL_TIME := 0.24
const SPECIAL_VISUAL_TIME := 0.24
const SPECIAL_COOLDOWN := 1.20
const SPECIAL_DASH_SPEED := 430.0

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
var respawn_position := Vector2.ZERO
var input_enabled := true

var _coyote_left := 0.0
var _jump_buffer_left := 0.0
var _was_jump_pressed := false
var _attack_visual_left := 0.0
var _special_visual_left := 0.0
var _special_cooldown_left := 0.0
var _special_dash_left := 0.0
var _down_pressed := false
var facing := 1.0
var sprite: AnimatedSprite2D

func _ready() -> void:
	respawn_position = global_position
	floor_stop_on_slope = true
	floor_max_angle = deg_to_rad(50.0)
	collision_layer = 2
	collision_mask = 1

	var capsule := CapsuleShape2D.new()
	capsule.radius = 12.0
	capsule.height = 56.0
	var shape := CollisionShape2D.new()
	shape.shape = capsule
	shape.position = Vector2(0, -28)
	add_child(shape)

	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = PlatformPartyActor12._build_sprite_frames(ROLE)
	sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	sprite.offset = SPRITE_OFFSET
	sprite.z_index = 10
	sprite.animation = "idle"
	sprite.play("idle")
	add_child(sprite)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1 or event.physical_keycode == KEY_F1:
			get_tree().debug_collisions_hint = not get_tree().debug_collisions_hint
			get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if global_position.y > FALL_RECOVERY_Y:
		global_position = respawn_position
		velocity = Vector2.ZERO
		return

	_attack_visual_left = maxf(0.0, _attack_visual_left - delta)
	_special_visual_left = maxf(0.0, _special_visual_left - delta)
	_special_cooldown_left = maxf(0.0, _special_cooldown_left - delta)
	_special_dash_left = maxf(0.0, _special_dash_left - delta)

	var axis := Input.get_axis("move_left", "move_right") if input_enabled else 0.0
	_down_pressed = input_enabled and Input.is_action_pressed("move_down")

	if _special_dash_left > 0.0:
		velocity.x = facing * SPECIAL_DASH_SPEED
	elif absf(axis) > 0.01:
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

	# W e o comando canonico de salto na Fase 00. Space continua aceito
	# para nao quebrar o habito dos builds anteriores.
	var jump_just_pressed := input_enabled and (
		Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("jump")
	)
	if jump_just_pressed:
		_jump_buffer_left = jump_buffer
	else:
		_jump_buffer_left = maxf(0.0, _jump_buffer_left - delta)

	if _jump_buffer_left > 0.0 and _coyote_left > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_left = 0.0
		_coyote_left = 0.0

	var jump_pressed := input_enabled and (
		Input.is_action_pressed("move_up") or Input.is_action_pressed("jump")
	)
	if _was_jump_pressed and not jump_pressed and velocity.y < -90.0:
		velocity.y *= jump_cut_multiplier
	_was_jump_pressed = jump_pressed

	# J — ataque. Na Fase 00 nao ha inimigos; o comando valida a animacao
	# canonica e deixa o input pronto para as fases de combate.
	if input_enabled and Input.is_action_just_pressed("attack") and _special_visual_left <= 0.0:
		_attack_visual_left = ATTACK_VISUAL_TIME

	# H — habilidade do Cavaleiro: Estocada curta. Mantem a identidade do
	# protagonista sem introduzir combate no Prologo.
	if input_enabled and Input.is_action_just_pressed("special") and _special_cooldown_left <= 0.0:
		_special_cooldown_left = SPECIAL_COOLDOWN
		_special_visual_left = SPECIAL_VISUAL_TIME
		_special_dash_left = SPECIAL_VISUAL_TIME
		_attack_visual_left = 0.0

	move_and_slide()
	_update_animation()

func _update_animation() -> void:
	if not is_instance_valid(sprite):
		return
	sprite.flip_h = facing < 0.0
	var target := "idle"

	if _special_visual_left > 0.0 and sprite.sprite_frames.has_animation("special"):
		target = "special"
	elif _attack_visual_left > 0.0 and sprite.sprite_frames.has_animation("attack"):
		target = "attack"
	elif not is_on_floor():
		if velocity.y < 0.0 and sprite.sprite_frames.has_animation("jump"):
			target = "jump"
		elif sprite.sprite_frames.has_animation("fall"):
			target = "fall"
	elif absf(velocity.x) > 12.0:
		target = "move"
	elif _down_pressed:
		# Ainda nao existe animacao "crouch" no ROLE_ANIM canonico. Mantem
		# idle em vez de trocar para placeholder ou distorcer a sprite.
		target = "idle"

	if sprite.animation != target:
		sprite.animation = target
		sprite.play(target)
