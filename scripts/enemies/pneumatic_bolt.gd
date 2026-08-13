extends Area2D

@export var speed := 170.0
@export var damage := 15
@export var lifetime := 2.6
@export var knockback_x := 54.0
@export var knockback_y := -18.0

var direction := Vector2.RIGHT
var owner_enemy: Node

func _ready() -> void:
    area_entered.connect(_on_area_entered)
    body_entered.connect(_on_body_entered)
    scale.x = -1.0 if direction.x < 0.0 else 1.0

func _physics_process(delta: float) -> void:
    global_position += direction.normalized() * speed * delta
    lifetime -= delta
    if lifetime <= 0.0:
        queue_free()

func setup(new_direction: Vector2, source: Node = null) -> void:
    direction = new_direction.normalized()
    owner_enemy = source

func _on_area_entered(area: Area2D) -> void:
    var target := area.get_parent()
    if target == null or target == owner_enemy:
        return
    if target.has_method("take_damage") and target.is_in_group("player"):
        var horizontal_sign := signf(direction.x)
        target.take_damage(damage, Vector2(horizontal_sign * knockback_x, knockback_y))
        queue_free()

func _on_body_entered(body: Node) -> void:
    if body == owner_enemy:
        return
    if body is StaticBody2D:
        queue_free()
