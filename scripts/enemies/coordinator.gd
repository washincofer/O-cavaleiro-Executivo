extends "res://scripts/enemies/enemy_base.gd"

enum State {
    IDLE,
    ALERT,
    ADVANCE,
    WINDUP,
    ACTIVE,
    RECOVERY,
    DEAD
}

const STATE_NAMES := [
    "IDLE",
    "ALERTA",
    "AVANCAR",
    "PREPARAR",
    "ESMAGAR",
    "RECUPERAR",
    "MORTO"
]

@export_group("Coordinator AI")
@export var detection_range := 210.0
@export var vertical_detection_tolerance := 70.0
@export var pursuit_range := 310.0
@export var pursuit_vertical_tolerance := 115.0
@export var advance_speed := 46.0
@export var advance_acceleration := 360.0
@export var attack_range := 43.0
@export var alert_duration := 0.32
@export var windup_duration := 0.86
@export var active_duration := 0.16
@export var recovery_duration := 1.02

@export_group("Coordinator Combat")
@export var attack_damage := 35
@export var attack_knockback_x := 120.0
@export var attack_knockback_y := -54.0
@export var received_knockback_multiplier := 0.16

@onready var weapon: Node2D = $Weapon
@onready var pressure_visual: CanvasItem = $Weapon/Pressure
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_visual: CanvasItem = $AttackHitbox/Visual
@onready var debug_label: Label = $DebugLabel
@onready var health_label: Label = $HealthLabel

var player: CharacterBody2D
var state := State.IDLE
var state_time_left := 0.0
var facing := -1.0
var locked_attack_facing := -1.0
var attack_connected := false

func _ready() -> void:
    super._ready()
    pressure_visual.visible = false
    attack_visual.visible = false
    health_changed.connect(_on_health_changed)
    _on_health_changed(health, max_health)
    _set_state(State.IDLE)
    call_deferred("_resolve_player")

func _physics_process(delta: float) -> void:
    if is_dead:
        state = State.DEAD
        pressure_visual.visible = false
        attack_visual.visible = false
        slow_horizontal(delta)
        apply_gravity(delta)
        move_and_slide()
        _update_debug_label()
        return

    if player == null or not is_instance_valid(player):
        _resolve_player()

    if state != State.IDLE and state != State.DEAD and not _can_pursue_player():
        _set_state(State.IDLE)

    apply_gravity(delta)

    match state:
        State.IDLE:
            _process_idle(delta)
        State.ALERT:
            _process_alert(delta)
        State.ADVANCE:
            _process_advance(delta)
        State.WINDUP:
            _process_windup(delta)
        State.ACTIVE:
            _process_active(delta)
        State.RECOVERY:
            _process_recovery(delta)

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
        _set_state(State.ADVANCE)

func _process_advance(delta: float) -> void:
    if player == null:
        slow_horizontal(delta)
        return

    _face_player()
    var horizontal_distance := absf(player.global_position.x - global_position.x)
    var vertical_distance := absf(player.global_position.y - global_position.y)

    if horizontal_distance <= attack_range and vertical_distance <= 40.0:
        locked_attack_facing = facing
        _set_state(State.WINDUP, windup_duration)
        return

    velocity.x = move_toward(velocity.x, facing * advance_speed, advance_acceleration * delta)

func _process_windup(delta: float) -> void:
    slow_horizontal(delta)
    facing = locked_attack_facing
    _update_facing_visuals()
    pressure_visual.visible = true
    state_time_left -= delta
    if state_time_left <= 0.0:
        pressure_visual.visible = false
        attack_connected = false
        _set_state(State.ACTIVE, active_duration)

func _process_active(delta: float) -> void:
    pressure_visual.visible = false
    attack_visual.visible = true
    velocity.x = locked_attack_facing * 34.0
    _apply_attack_hit()
    state_time_left -= delta
    if state_time_left <= 0.0:
        attack_visual.visible = false
        _set_state(State.RECOVERY, recovery_duration)

func _process_recovery(delta: float) -> void:
    pressure_visual.visible = false
    slow_horizontal(delta)
    state_time_left -= delta
    if state_time_left <= 0.0:
        _set_state(State.ADVANCE)

func _apply_attack_hit() -> void:
    if attack_connected:
        return

    for area in attack_hitbox.get_overlapping_areas():
        var target := area.get_parent()
        if target == null or not target.has_method("take_damage"):
            continue
        if not target.is_in_group("player"):
            continue

        attack_connected = true
        target.take_damage(
            attack_damage,
            Vector2(locked_attack_facing * attack_knockback_x, attack_knockback_y)
        )
        break

func take_damage(amount: int, knockback := Vector2.ZERO) -> void:
    var reduced_knockback := knockback * received_knockback_multiplier
    super.take_damage(amount, reduced_knockback)

func _on_damaged(_amount: int, _knockback: Vector2) -> void:
    # Super-armadura simples do prototipo: ataques comuns causam dano e flash,
    # mas nao cancelam preparacao, golpe ou recuperacao.
    pass

func _can_detect_player() -> bool:
    if player == null:
        return false
    var dx := absf(player.global_position.x - global_position.x)
    var dy := absf(player.global_position.y - global_position.y)
    return dx <= detection_range and dy <= vertical_detection_tolerance

func _can_pursue_player() -> bool:
    if player == null:
        return false
    var dx := absf(player.global_position.x - global_position.x)
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
    attack_hitbox.position.x = facing * 23.0

func _set_state(new_state: int, duration := 0.0) -> void:
    state = new_state
    state_time_left = duration
    if state != State.WINDUP:
        pressure_visual.visible = false
    if state != State.ACTIVE:
        attack_visual.visible = false
    _update_debug_label()

func _die() -> void:
    pressure_visual.visible = false
    attack_visual.visible = false
    _set_state(State.DEAD)
    super._die()

func _resolve_player() -> void:
    player = get_tree().get_first_node_in_group("player") as CharacterBody2D

func _on_health_changed(current_health: int, maximum_health: int) -> void:
    if health_label != null:
        health_label.text = "COORD %d/%d" % [current_health, maximum_health]

func _update_debug_label() -> void:
    if debug_label == null:
        return
    var state_index := clampi(state, 0, STATE_NAMES.size() - 1)
    debug_label.text = STATE_NAMES[state_index]
