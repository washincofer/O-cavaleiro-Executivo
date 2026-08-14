extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal died

@export_group("Base Enemy")
@export var max_health := 30
@export var gravity := 700.0
@export var max_fall_speed := 320.0
@export var ground_friction := 900.0
@export var death_delay := 0.18

@onready var body_visual: CanvasItem = get_node_or_null("Body")
@onready var hurtbox: Area2D = get_node_or_null("Hurtbox")

var health := 30
var is_dead := false

func _ready() -> void:
    health = max_health
    health_changed.emit(health, max_health)
    call_deferred("_disable_player_body_collision")

func _disable_player_body_collision() -> void:
    # Player and enemies may overlap for combat, but should never behave as
    # physical platforms for one another. Damage still comes from hitboxes.
    var player_body := get_tree().get_first_node_in_group("player") as PhysicsBody2D
    if player_body == null:
        return
    add_collision_exception_with(player_body)
    player_body.add_collision_exception_with(self)

func apply_gravity(delta: float) -> void:
    if not is_on_floor():
        velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)

func slow_horizontal(delta: float) -> void:
    velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)

func take_damage(amount: int, knockback := Vector2.ZERO) -> void:
    if is_dead:
        return

    health = maxi(0, health - amount)
    velocity = knockback
    health_changed.emit(health, max_health)
    _flash_hit()

    if health <= 0:
        _die()
    else:
        _on_damaged(amount, knockback)

func _on_damaged(_amount: int, _knockback: Vector2) -> void:
    pass

func _die() -> void:
    if is_dead:
        return

    is_dead = true
    collision_layer = 0
    collision_mask = 0
    if hurtbox != null:
        hurtbox.collision_layer = 0
        hurtbox.collision_mask = 0
        hurtbox.monitorable = false
    died.emit()
    _finish_death_later()

func _finish_death_later() -> void:
    await get_tree().create_timer(death_delay).timeout
    if is_instance_valid(self):
        queue_free()

func _flash_hit() -> void:
    if body_visual == null:
        return
    body_visual.modulate = Color(1.0, 0.62, 0.62, 1.0)
    _restore_body_color_later()

func _restore_body_color_later() -> void:
    await get_tree().create_timer(0.08).timeout
    if is_instance_valid(body_visual) and not is_dead:
        body_visual.modulate = Color.WHITE
