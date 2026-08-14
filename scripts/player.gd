extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)

@export_group("Movement")
@export var move_speed := 95.0
@export var acceleration := 900.0
@export var friction := 1100.0
@export var jump_velocity := -210.0
@export var gravity := 700.0
@export var max_fall_speed := 320.0
@export var dash_speed := 230.0
@export var dash_duration := 0.12
@export var dash_cooldown := 0.35

@export_group("Combat")
@export var max_health := 100
@export var attack_damage := 10
@export var attack_total_duration := 0.28
@export var attack_active_start := 0.07
@export var attack_active_end := 0.16
@export var attack_cooldown := 0.22
@export var invulnerability_duration := 0.45

@onready var body_visual: AnimatedSprite2D = $Sprite
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_visual: Polygon2D = $AttackHitbox/Visual

var health := 100
var facing := 1.0
var dash_time_left := 0.0
var dash_cooldown_left := 0.0
var attack_time_left := 0.0
var attack_cooldown_left := 0.0
var invulnerability_left := 0.0
var hit_targets: Dictionary = {}

func _ready() -> void:
    health = max_health
    attack_visual.visible = false
    body_visual.play("idle")
    health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
    dash_cooldown_left = maxf(0.0, dash_cooldown_left - delta)
    attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
    invulnerability_left = maxf(0.0, invulnerability_left - delta)

    _update_attack(delta)

    if dash_time_left > 0.0:
        dash_time_left -= delta
        velocity.x = facing * dash_speed
        velocity.y = 0.0
        _update_animation()
        move_and_slide()
        return

    if not is_on_floor():
        velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)

    var input_axis := Input.get_axis("move_left", "move_right")
    if input_axis != 0.0:
        facing = signf(input_axis)
        velocity.x = move_toward(velocity.x, input_axis * move_speed, acceleration * delta)
        _update_facing()
    else:
        velocity.x = move_toward(velocity.x, 0.0, friction * delta)

    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity

    if Input.is_action_just_pressed("dash") and dash_cooldown_left <= 0.0:
        dash_time_left = dash_duration
        dash_cooldown_left = dash_cooldown

    if Input.is_action_just_pressed("attack") and attack_cooldown_left <= 0.0 and attack_time_left <= 0.0:
        _start_attack()

    if Input.is_action_just_pressed("restart"):
        get_tree().reload_current_scene()

    _update_animation()
    move_and_slide()

func _start_attack() -> void:
    attack_time_left = attack_total_duration
    attack_cooldown_left = attack_cooldown
    hit_targets.clear()

func _update_attack(delta: float) -> void:
    if attack_time_left <= 0.0:
        attack_visual.visible = false
        return

    attack_time_left = maxf(0.0, attack_time_left - delta)
    var elapsed := attack_total_duration - attack_time_left
    var is_active := elapsed >= attack_active_start and elapsed <= attack_active_end
    attack_visual.visible = is_active

    if is_active:
        _apply_attack_hits()

func _apply_attack_hits() -> void:
    for area in attack_hitbox.get_overlapping_areas():
        var target := area.get_parent()
        if target == null or target == self or not target.has_method("take_damage"):
            continue

        var target_id := target.get_instance_id()
        if hit_targets.has(target_id):
            continue

        hit_targets[target_id] = true
        var knockback := Vector2(facing * 70.0, -30.0)
        target.take_damage(attack_damage, knockback)

func _update_facing() -> void:
    attack_hitbox.position.x = facing * 18.0
    body_visual.flip_h = facing < 0.0

func _update_animation() -> void:
    # Sprint 8B: every animation is authored facing right; flip_h mirrors to the left.
    body_visual.flip_h = facing < 0.0

    if dash_time_left > 0.0:
        body_visual.play("dash")
        return
    if attack_time_left > 0.0:
        body_visual.play("attack")
        return
    if not is_on_floor():
        if velocity.y < -35.0:
            body_visual.play("jump")
        elif absf(velocity.y) <= 35.0:
            body_visual.play("apex")
        else:
            body_visual.play("fall")
    elif absf(velocity.x) > 8.0:
        body_visual.play("run")
    else:
        body_visual.play("idle")

func take_damage(amount: int, knockback := Vector2.ZERO) -> void:
    if invulnerability_left > 0.0:
        return

    health = maxi(0, health - amount)
    invulnerability_left = invulnerability_duration
    velocity += knockback
    body_visual.modulate = Color(1.0, 0.65, 0.65, 1.0)
    health_changed.emit(health, max_health)
    _restore_body_color_later()

    if health <= 0:
        get_tree().reload_current_scene()

func _restore_body_color_later() -> void:
    await get_tree().create_timer(0.08).timeout
    if is_instance_valid(body_visual):
        body_visual.modulate = Color.WHITE
