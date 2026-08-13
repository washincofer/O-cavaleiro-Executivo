extends CharacterBody2D

@export var max_health := 30
@export var gravity := 700.0
@export var max_fall_speed := 320.0

@onready var body_visual: Polygon2D = $Body
@onready var health_label: Label = $HealthLabel

var health := 30

func _ready() -> void:
    health = max_health
    _update_label()

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)

    velocity.x = move_toward(velocity.x, 0.0, 320.0 * delta)
    move_and_slide()

func take_damage(amount: int, knockback := Vector2.ZERO) -> void:
    health = maxi(0, health - amount)
    velocity = knockback
    body_visual.modulate = Color(1.0, 0.7, 0.7, 1.0)
    _update_label()
    _restore_body_color_later()

    if health <= 0:
        health_label.text = "APROVADO"
        await get_tree().create_timer(0.12).timeout
        queue_free()

func _update_label() -> void:
    health_label.text = "DUMMY %d/%d" % [health, max_health]

func _restore_body_color_later() -> void:
    await get_tree().create_timer(0.08).timeout
    if is_instance_valid(body_visual):
        body_visual.modulate = Color.WHITE
