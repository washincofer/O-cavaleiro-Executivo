extends Area2D

@export var speed := 170.0
@export var damage := 15
@export var lifetime := 2.6
@export var knockback_x := 54.0
@export var knockback_y := -18.0
@export var sweep_half_height := 2.0
@export var sweep_front_extent := 5.0

var direction := Vector2.RIGHT
var owner_enemy: Node

func _ready() -> void:
    area_entered.connect(_on_area_entered)
    body_entered.connect(_on_body_entered)
    _update_visual_orientation()

func _physics_process(delta: float) -> void:
    var travel := direction.normalized() * speed * delta
    var start_position := global_position
    var end_position := start_position + travel

    # Continuous collision sweep aligned to the actual trajectory. Three rays
    # cover the bolt thickness perpendicular to motion, while the front extent
    # is projected along the travel direction. This works for horizontal and
    # diagonal shots and prevents tunneling through thin platforms.
    var travel_direction := direction.normalized()
    var perpendicular := Vector2(-travel_direction.y, travel_direction.x)
    var side_offsets := [-sweep_half_height, 0.0, sweep_half_height]
    for side_offset in side_offsets:
        var front_offset := travel_direction * sweep_front_extent + perpendicular * side_offset
        var hit := _raycast_world(start_position + front_offset, end_position + front_offset)
        if not hit.is_empty():
            _resolve_sweep_hit(hit, start_position)
            return

    global_position = end_position
    lifetime -= delta
    if lifetime <= 0.0:
        queue_free()

func _raycast_world(from: Vector2, to: Vector2) -> Dictionary:
    var query := PhysicsRayQueryParameters2D.create(from, to)
    query.collision_mask = 1
    query.collide_with_bodies = true
    query.collide_with_areas = false

    if owner_enemy is CollisionObject2D:
        query.exclude = [owner_enemy.get_rid()]

    return get_world_2d().direct_space_state.intersect_ray(query)

func _resolve_sweep_hit(hit: Dictionary, fallback_position: Vector2) -> void:
    var collider: Object = hit.get("collider")
    global_position = hit.get("position", fallback_position)

    if collider is Node and collider.is_in_group("player") and collider.has_method("take_damage"):
        var horizontal_sign := signf(direction.x)
        collider.take_damage(damage, Vector2(horizontal_sign * knockback_x, knockback_y))

    # Anything on the world/body collision layer blocks the projectile.
    # This includes floors, platforms, doors, boundaries, TileMap collision
    # bodies and other solid bodies. Non-player bodies simply absorb the bolt.
    queue_free()

func setup(new_direction: Vector2, source: Node = null) -> void:
    direction = new_direction.normalized()
    if direction.length_squared() <= 0.0001:
        direction = Vector2.RIGHT
    owner_enemy = source
    if is_node_ready():
        _update_visual_orientation()

func _update_visual_orientation() -> void:
    rotation = direction.angle()

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
    if body.is_in_group("player") and body.has_method("take_damage"):
        var horizontal_sign := signf(direction.x)
        body.take_damage(damage, Vector2(horizontal_sign * knockback_x, knockback_y))
    queue_free()
