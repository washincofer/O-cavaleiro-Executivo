extends Node2D

var controller: Node
var owner_actor: CharacterBody2D
var team := ""
var velocity := Vector2.ZERO
var damage := 1
var life := 2.0

func setup(p_controller: Node, p_owner: CharacterBody2D, direction: Vector2, tint: Color) -> void:
	controller = p_controller
	owner_actor = p_owner
	team = str(p_owner.team)
	velocity = direction.normalized() * 260.0
	modulate = tint
	queue_redraw()

func _physics_process(delta: float) -> void:
	var from := global_position
	var to := from + velocity * delta
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		queue_free()
		return
	global_position = to
	for actor in controller.actors:
		if is_instance_valid(actor) and actor != owner_actor and actor.team != team and actor.alive:
			if global_position.distance_to(actor.global_position) < 11.0:
				actor.take_damage(damage, owner_actor)
				queue_free()
				return
	life -= delta
	if life <= 0.0:
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 3.0, Color.WHITE)
	draw_line(Vector2(-7, 0), Vector2(1, 0), Color(1, 1, 1, 0.65), 2.0)
