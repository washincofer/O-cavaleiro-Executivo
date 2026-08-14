extends "res://scripts/enemies/enemy_base.gd"

enum State {
    IDLE,
    ALERT,
    APPROACH,
    AIM,
    FIRE,
    RELOAD,
    FLEE,
    HIT,
    DEAD
}

const STATE_NAMES := [
    "IDLE",
    "ALERTA",
    "SEGUIR",
    "MIRAR",
    "DISPARAR",
    "RECARREGAR",
    "FUGIR",
    "HIT",
    "MORTO"
]

const PROJECTILE_SCENE := preload("res://scenes/enemies/pneumatic_bolt.tscn")

@export_group("Intern AI")
@export var detection_range := 235.0
@export var vertical_detection_tolerance := 90.0
@export var pursuit_range := 310.0
@export var pursuit_vertical_tolerance := 125.0
@export var max_shoot_distance := 170.0
@export var flee_distance := 82.0
@export var comfortable_distance := 126.0
@export var approach_speed := 58.0
@export var approach_acceleration := 520.0
@export var flee_speed := 72.0
@export var flee_acceleration := 600.0
@export var alert_duration := 0.22
@export var aim_duration := 0.78
@export var fire_pause := 0.10
@export var reload_duration := 0.72
@export var hit_stun_duration := 0.16
@export var flee_jump_velocity := 235.0
@export var flee_obstacle_check_distance := 12.0
@export var flee_failed_attack_delay := 0.24
@export var cornered_aim_duration := 0.48

@onready var weapon: Node2D = $Weapon
@onready var muzzle: Marker2D = $Weapon/Muzzle
@onready var debug_label: Label = $DebugLabel
@onready var health_label: Label = $HealthLabel
@onready var pressure_visual: CanvasItem = $Weapon/Pressure

var player: CharacterBody2D
var state := State.IDLE
var state_time_left := 0.0
var facing := -1.0
var shot_created := false
var flee_jump_used := false
var flee_blocked_time := 0.0
var flee_attempt_origin_x := 0.0
var cornered_shot := false

func _ready() -> void:
    super._ready()
    health_changed.connect(_on_health_changed)
    _on_health_changed(health, max_health)
    pressure_visual.visible = false
    _set_state(State.IDLE)
    call_deferred("_resolve_player")

func _physics_process(delta: float) -> void:
    if is_dead:
        state = State.DEAD
        pressure_visual.visible = false
        slow_horizontal(delta)
        apply_gravity(delta)
        move_and_slide()
        _update_debug_label()
        return

    if player == null or not is_instance_valid(player):
        _resolve_player()

    # Once engaged, enemies may pursue farther than their initial detection
    # range. If the player leaves the pursuit leash completely, they stop.
    if state != State.IDLE and state != State.DEAD and not _can_pursue_player():
        _set_state(State.IDLE)

    apply_gravity(delta)

    match state:
        State.IDLE:
            _process_idle(delta)
        State.ALERT:
            _process_alert(delta)
        State.APPROACH:
            _process_approach(delta)
        State.AIM:
            _process_aim(delta)
        State.FIRE:
            _process_fire(delta)
        State.RELOAD:
            _process_reload(delta)
        State.FLEE:
            _process_flee(delta)
        State.HIT:
            _process_hit(delta)

    move_and_slide()
    _update_debug_label()

func _process_idle(delta: float) -> void:
    slow_horizontal(delta)
    if _can_detect_player():
        _face_player()
        _set_state(State.ALERT, alert_duration)

func _process_alert(delta: float) -> void:
    slow_horizontal(delta)
    _face_player()
    state_time_left -= delta
    if state_time_left <= 0.0:
        _choose_distance_state()

func _process_approach(delta: float) -> void:
    if player == null:
        slow_horizontal(delta)
        return

    _face_player()
    var distance := _horizontal_distance_to_player()

    if distance < flee_distance:
        _set_state(State.FLEE)
        return
    if distance <= max_shoot_distance:
        _set_state(State.AIM, aim_duration)
        return

    velocity.x = move_toward(velocity.x, facing * approach_speed, approach_acceleration * delta)

func _process_aim(delta: float) -> void:
    slow_horizontal(delta)
    _face_player()
    pressure_visual.visible = true

    # Normal behaviour prefers escape when the player is too close. A
    # cornered intern is allowed to finish one desperate shot instead of
    # oscillating forever between FLEE and AIM.
    if not cornered_shot:
        if _player_is_too_close():
            pressure_visual.visible = false
            _set_state(State.FLEE)
            return
        if _player_is_too_far_to_shoot():
            pressure_visual.visible = false
            _set_state(State.APPROACH)
            return
    elif not _can_pursue_player():
        cornered_shot = false
        pressure_visual.visible = false
        _set_state(State.IDLE)
        return

    state_time_left -= delta
    if state_time_left <= 0.0:
        shot_created = false
        _set_state(State.FIRE, fire_pause)

func _process_fire(delta: float) -> void:
    slow_horizontal(delta)
    pressure_visual.visible = false

    # Re-check range at the exact firing moment. A normal shot is cancelled if
    # the player leaves the firing band. A cornered/desperate shot is allowed
    # at close range because escape has already failed.
    if not cornered_shot:
        if _player_is_too_far_to_shoot():
            _set_state(State.APPROACH)
            return
        if _player_is_too_close():
            _set_state(State.FLEE)
            return

    if not shot_created:
        _spawn_bolt()
        shot_created = true
    state_time_left -= delta
    if state_time_left <= 0.0:
        cornered_shot = false
        _set_state(State.RELOAD, reload_duration)

func _process_reload(delta: float) -> void:
    slow_horizontal(delta)
    _face_player()

    if _player_is_too_close():
        _set_state(State.FLEE)
        return
    if _player_is_too_far_to_shoot():
        _set_state(State.APPROACH)
        return

    state_time_left -= delta
    if state_time_left <= 0.0:
        _set_state(State.AIM, aim_duration)

func _process_flee(delta: float) -> void:
    if player == null:
        slow_horizontal(delta)
        return

    var dx := global_position.x - player.global_position.x
    if absf(dx) > 1.0:
        facing = signf(-dx)
        _update_facing_visuals()

    var flee_direction := signf(dx)
    if flee_direction == 0.0:
        flee_direction = 1.0

    # If a solid body blocks the escape route, the intern gets one jump
    # attempt. This lets him hop onto/over low reception platforms instead of
    # running forever against their side.
    var blocked_ahead := _solid_in_flee_path(flee_direction)
    if blocked_ahead:
        if is_on_floor() and not flee_jump_used:
            velocity.y = -flee_jump_velocity
            flee_jump_used = true
            flee_blocked_time = 0.0
        elif is_on_floor() and flee_jump_used:
            flee_blocked_time += delta
            if flee_blocked_time >= flee_failed_attack_delay:
                cornered_shot = true
                _set_state(State.AIM, cornered_aim_duration)
                return
    else:
        flee_blocked_time = 0.0

    velocity.x = move_toward(velocity.x, flee_direction * flee_speed, flee_acceleration * delta)

    # Once meaningful horizontal progress has been made, a future obstacle may
    # receive another jump attempt.
    if absf(global_position.x - flee_attempt_origin_x) >= 34.0:
        flee_jump_used = false
        flee_attempt_origin_x = global_position.x

    var distance := _horizontal_distance_to_player()
    if distance >= comfortable_distance:
        if distance > max_shoot_distance:
            _set_state(State.APPROACH)
        else:
            _set_state(State.AIM, aim_duration)


func _solid_in_flee_path(flee_direction: float) -> bool:
    # test_move uses the intern's real CharacterBody2D collider and all current
    # collision exceptions/masks, so the player is ignored but level geometry
    # (platforms, walls, doors) is detected reliably.
    var motion := Vector2(flee_direction * flee_obstacle_check_distance, 0.0)
    return test_move(global_transform, motion)

func _process_hit(delta: float) -> void:
    pressure_visual.visible = false
    velocity.x = move_toward(velocity.x, 0.0, 440.0 * delta)
    state_time_left -= delta
    if state_time_left <= 0.0:
        _choose_distance_state()

func _choose_distance_state() -> void:
    if player == null:
        _set_state(State.IDLE)
        return
    if _player_is_too_close():
        _set_state(State.FLEE)
    elif _player_is_too_far_to_shoot():
        _set_state(State.APPROACH)
    else:
        _set_state(State.AIM, aim_duration)

func _spawn_bolt() -> void:
    if player == null:
        return
    var bolt = PROJECTILE_SCENE.instantiate()
    get_tree().current_scene.add_child(bolt)
    bolt.global_position = muzzle.global_position

    # Snapshot aim: the bolt points to the player's position at the exact
    # firing moment. After launch, that vector is frozen: the projectile may
    # travel up or down, but it never curves or homes toward later movement.
    var shot_direction := (player.global_position - muzzle.global_position).normalized()
    if shot_direction.length_squared() <= 0.0001:
        shot_direction = Vector2(facing, 0.0)
    bolt.setup(shot_direction, self)

func _horizontal_distance_to_player() -> float:
    if player == null:
        return INF
    return absf(player.global_position.x - global_position.x)

func _player_is_too_close() -> bool:
    return _horizontal_distance_to_player() < flee_distance

func _player_is_too_far_to_shoot() -> bool:
    if player == null:
        return true
    var dx := _horizontal_distance_to_player()
    var dy := absf(player.global_position.y - global_position.y)
    return dx > max_shoot_distance or dy > vertical_detection_tolerance

func _can_detect_player() -> bool:
    if player == null:
        return false
    var dx := _horizontal_distance_to_player()
    var dy := absf(player.global_position.y - global_position.y)
    return dx <= detection_range and dy <= vertical_detection_tolerance

func _can_pursue_player() -> bool:
    if player == null:
        return false
    var dx := _horizontal_distance_to_player()
    var dy := absf(player.global_position.y - global_position.y)
    return dx <= pursuit_range and dy <= pursuit_vertical_tolerance

func _face_player() -> void:
    if player == null:
        return
    var dx := player.global_position.x - global_position.x
    if absf(dx) < 1.0:
        return
    facing = signf(dx)
    _update_facing_visuals()

func _update_facing_visuals() -> void:
    weapon.scale.x = facing

func _set_state(new_state: int, duration := 0.0) -> void:
    var previous_state := state
    state = new_state
    state_time_left = duration

    if state == State.FLEE and previous_state != State.FLEE:
        flee_jump_used = false
        flee_blocked_time = 0.0
        flee_attempt_origin_x = global_position.x
        cornered_shot = false
    elif state != State.AIM and state != State.FIRE:
        cornered_shot = false

    if state != State.AIM:
        pressure_visual.visible = false
    _update_debug_label()

func _on_damaged(_amount: int, _knockback: Vector2) -> void:
    pressure_visual.visible = false
    _set_state(State.HIT, hit_stun_duration)

func _die() -> void:
    _set_state(State.DEAD)
    super._die()

func _resolve_player() -> void:
    player = get_tree().get_first_node_in_group("player") as CharacterBody2D

func _on_health_changed(current_health: int, maximum_health: int) -> void:
    if health_label != null:
        health_label.text = "EST %d/%d" % [current_health, maximum_health]

func _update_debug_label() -> void:
    if debug_label == null:
        return
    var state_index := clampi(state, 0, STATE_NAMES.size() - 1)
    debug_label.text = STATE_NAMES[state_index]
