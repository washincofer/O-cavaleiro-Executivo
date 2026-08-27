class_name PlatformPartyBolt11C
extends Area2D

var controller: Node
var owner_actor
var direction := Vector2.RIGHT
var speed := 280.0
var life := 1.8

func setup(p_controller: Node, p_owner, p_direction: Vector2) -> void:
	controller = p_controller
	owner_actor = p_owner
	direction = p_direction.normalized()
	collision_layer = 0
	collision_mask = 0
	queue_redraw()

func _physics_process(delta: float) -> void:
	var next_position := global_position + direction * speed * delta

	# 11B.1: raycast entre a posicao atual e a proxima evita atravessar
	# chao, paredes e plataformas mesmo com o projetil rapido.
	if _hits_world(next_position):
		queue_free()
		return

	global_position = next_position
	life -= delta

	if controller.try_bolt_hit(self, owner_actor):
		queue_free()
		return

	if life <= 0.0:
		queue_free()

func _hits_world(next_position: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, next_position, 1)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return not hit.is_empty()

func _draw() -> void:
	draw_line(Vector2(-5, 0), Vector2(5, 0), Color("f0c15a"), 2.0)
