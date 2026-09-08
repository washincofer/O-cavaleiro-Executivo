class_name Fase00Player12
extends CharacterBody2D

## Protagonista canonico da Fase 00.
## Usa o Cavaleiro Executivo definitivo (gravata vermelha) ja versionado em
## assets/Characters/CavaleiroExecutivo/Runtime e reaproveita o mesmo SpriteFrames
## do PlatformPartyActor12 para manter identidade visual entre as fases.

const ROLE := "cavaleiro_executivo"
const SPRITE_SCALE := 0.552 * 4.0
const SPRITE_OFFSET := Vector2(0.0, -29.4)
const FALL_RECOVERY_Y := 980.0

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

func _physics_process(delta: float) -> void:
	if global_position.y > FALL_RECOVERY_Y:
		global_position = respawn_position
		velocity = Vector2.ZERO
		return

	var axis := Input.get_axis("move_left", "move_right") if input_enabled else 0.0
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

	if input_enabled and Input.is_action_just_pressed("attack"):
		_attack_visual_left = 0.24
	_attack_visual_left = maxf(0.0, _attack_visual_left - delta)

	move_and_slide()
	_update_animation()

func _update_animation() -> void:
	if not is_instance_valid(sprite):
		return
	sprite.flip_h = facing < 0.0
	var target := "idle"
	if _attack_visual_left > 0.0 and sprite.sprite_frames.has_animation("attack"):
		target = "attack"
	elif not is_on_floor():
		if velocity.y < 0.0 and sprite.sprite_frames.has_animation("jump"):
			target = "jump"
		elif sprite.sprite_frames.has_animation("fall"):
			target = "fall"
	elif absf(velocity.x) > 12.0:
		target = "move"
	if sprite.animation != target:
		sprite.animation = target
		sprite.play(target)
