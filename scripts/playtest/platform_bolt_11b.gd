class_name PlatformPartyBolt
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
	position += direction * speed * delta
	life -= delta
	if controller.try_bolt_hit(self, owner_actor):
		queue_free()
		return
	if life <= 0.0:
		queue_free()

func _draw() -> void:
	draw_line(Vector2(-5, 0), Vector2(5, 0), Color("f0c15a"), 2.0)
