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
    var start_position := global_position
    var end_position := start_position + direction.normalized() * speed * delta

    # Continuous sweep between the current and next position. This prevents
    # the bolt from skipping thin StaticBody2D colliders between physics frames.
    var query := PhysicsRayQueryParameters2D.create(start_position, end_position)
    query.collision_mask = 1
    query.collide_with_bodies = true
    query.collide_with_areas = false

    if owner_enemy is CollisionObject2D:
        query.exclude = [owner_enemy.get_rid()]

    var hit := get_world_2d().direct_space_state.intersect_ray(query)
    if not hit.is_empty():
        var collider: Object = hit.get("collider")
        if collider is StaticBody2D:
            global_position = hit.get("position", start_position)
            queue_free()
            return
        if collider is Node and collider.is_in_group("player") and collider.has_method("take_damage"):
            var horizontal_sign := signf(direction.x)
            collider.take_damage(damage, Vector2(horizontal_sign * knockback_x, knockback_y))
            global_position = hit.get("position", start_position)
            queue_free()
            return

    global_position = end_position
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
