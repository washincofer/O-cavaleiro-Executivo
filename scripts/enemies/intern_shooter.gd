extends "res://scripts/enemies/enemy_base.gd"

enum State {
    IDLE,
    ALERT,
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
@export var flee_distance := 82.0
@export var comfortable_distance := 126.0
@export var flee_speed := 72.0
@export var flee_acceleration := 600.0
@export var alert_duration := 0.22
@export var aim_duration := 0.78
@export var fire_pause := 0.10
@export var reload_duration := 0.72
@export var hit_stun_duration := 0.16

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

    apply_gravity(delta)

    match state:
        State.IDLE:
            _process_idle(delta)
        State.ALERT:
            _process_alert(delta)
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
    if _player_is_too_close():
        _set_state(State.FLEE)
    elif state_time_left <= 0.0:
        _set_state(State.AIM, aim_duration)

func _process_aim(delta: float) -> void:
    slow_horizontal(delta)
    _face_player()
    pressure_visual.visible = true
    state_time_left -= delta

    if _player_is_too_close():
        pressure_visual.visible = false
        _set_state(State.FLEE)
    elif state_time_left <= 0.0:
        shot_created = false
        _set_state(State.FIRE, fire_pause)

func _process_fire(delta: float) -> void:
    slow_horizontal(delta)
    pressure_visual.visible = false
    if not shot_created:
        _spawn_bolt()
        shot_created = true
    state_time_left -= delta
    if state_time_left <= 0.0:
        _set_state(State.RELOAD, reload_duration)

func _process_reload(delta: float) -> void:
    slow_horizontal(delta)
    _face_player()
    state_time_left -= delta
    if _player_is_too_close():
        _set_state(State.FLEE)
    elif state_time_left <= 0.0:
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
    velocity.x = move_toward(velocity.x, flee_direction * flee_speed, flee_acceleration * delta)

    var distance := absf(player.global_position.x - global_position.x)
    if distance >= comfortable_distance:
        _set_state(State.AIM, aim_duration)

func _process_hit(delta: float) -> void:
    pressure_visual.visible = false
    velocity.x = move_toward(velocity.x, 0.0, 440.0 * delta)
    state_time_left -= delta
    if state_time_left <= 0.0:
        if _player_is_too_close():
            _set_state(State.FLEE)
        else:
            _set_state(State.AIM, aim_duration)

func _spawn_bolt() -> void:
    if player == null:
        return
    var bolt = PROJECTILE_SCENE.instantiate()
    get_tree().current_scene.add_child(bolt)
    bolt.global_position = muzzle.global_position

    # The intern fires on a fixed horizontal line. The player's vertical
    # movement after (or during) the windup never bends the projectile.
    # This makes jumping a readable way to evade the shot and avoids
    # any homing-like impression.
    var shot_direction := Vector2(facing, 0.0)
    bolt.setup(shot_direction, self)

func _player_is_too_close() -> bool:
    if player == null:
        return false
    return absf(player.global_position.x - global_position.x) < flee_distance

func _can_detect_player() -> bool:
    if player == null:
        return false
    var dx := absf(player.global_position.x - global_position.x)
    var dy := absf(player.global_position.y - global_position.y)
    return dx <= detection_range and dy <= vertical_detection_tolerance

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
    state = new_state
    state_time_left = duration
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
