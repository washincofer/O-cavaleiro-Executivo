extends Area2D

@export var speed := 170.0
@export var damage := 15
@export var lifetime := 2.6
@export var knockback_x := 54.0
@export var knockback_y := -18.0

var direction := Vector2.RIGHT
var owner_enemy: Node
var launched := false

func _ready() -> void:
    area_entered.connect(_on_area_entered)
    body_entered.connect(_on_body_entered)
    _update_visual_orientation()

func setup(new_direction: Vector2, source: Node = null) -> void:
    direction = new_direction.normalized()
    if direction.length_squared() <= 0.0001:
        direction = Vector2.RIGHT
    owner_enemy = source
    launched = true
    if is_node_ready():
        _update_visual_orientation()

func _physics_process(delta: float) -> void:
    # The projectile only starts moving after setup() supplies the frozen aim
    # vector. It never recalculates direction, so it cannot home toward the
    # player after launch.
    if not launched:
        return

    var start_position := global_position
    var end_position := start_position + direction * speed * delta

    # Sweep the entire segment travelled this physics frame. At the current
    # speed this is enough to prevent tunnelling through reception platforms,
    # floors, doors, walls and other StaticBody2D/CharacterBody2D colliders.
    var hit := _raycast_body(start_position, end_position)
    if not hit.is_empty():
        _resolve_body_hit(hit, start_position)
        return

    global_position = end_position

    lifetime -= delta
    if lifetime <= 0.0:
        queue_free()

func _raycast_body(from: Vector2, to: Vector2) -> Dictionary:
    var query := PhysicsRayQueryParameters2D.create(from, to)
    query.collision_mask = 1
    query.collide_with_bodies = true
    query.collide_with_areas = false

    if owner_enemy is CollisionObject2D:
        query.exclude = [owner_enemy.get_rid()]

    return get_world_2d().direct_space_state.intersect_ray(query)

func _resolve_body_hit(hit: Dictionary, fallback_position: Vector2) -> void:
    var collider: Object = hit.get("collider")
    global_position = hit.get("position", fallback_position)

    if collider is Node and collider.is_in_group("player") and collider.has_method("take_damage"):
        _damage_player(collider)

    # Every physical world body absorbs the bolt. The projectile never passes
    # through a platform or wall after a sweep collision.
    queue_free()

func _damage_player(target: Node) -> void:
    var horizontal_sign := signf(direction.x)
    if horizontal_sign == 0.0:
        horizontal_sign = 1.0
    target.take_damage(damage, Vector2(horizontal_sign * knockback_x, knockback_y))

func _update_visual_orientation() -> void:
    rotation = direction.angle()

func _on_area_entered(area: Area2D) -> void:
    if not launched:
        return
    var target := area.get_parent()
    if target == null or target == owner_enemy:
        return
    if target.has_method("take_damage") and target.is_in_group("player"):
        _damage_player(target)
        queue_free()

func _on_body_entered(body: Node) -> void:
    if not launched or body == owner_enemy:
        return
    if body.is_in_group("player") and body.has_method("take_damage"):
        _damage_player(body)
    # StaticBody2D platforms/walls/doors and any other solid body absorb it.
    queue_free()
