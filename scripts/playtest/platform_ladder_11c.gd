class_name PlatformLadder11C
extends Node2D

var controller: Node
var owner_actor
var ladder_height := 112.0
var ladder_width := 16.0
var enemy_blocker: StaticBody2D

func setup(p_controller: Node, p_owner, floor_position: Vector2, p_height := 112.0) -> void:
	controller = p_controller
	owner_actor = p_owner
	ladder_height = p_height
	global_position = floor_position

	# Colisao exclusiva de inimigos. Aliados nao usam esta layer no mask.
	enemy_blocker = StaticBody2D.new()
	enemy_blocker.name = "LadderEnemyBlocker"
	enemy_blocker.add_to_group("ladder_enemy_blocker")
	enemy_blocker.collision_layer = 8
	enemy_blocker.collision_mask = 0
	enemy_blocker.position = Vector2(0.0, -ladder_height * 0.5)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12.0, ladder_height)
	collision.shape = shape
	enemy_blocker.add_child(collision)
	add_child(enemy_blocker)
	queue_redraw()

func top_y() -> float:
	return global_position.y - ladder_height

func contains_actor(actor) -> bool:
	if not is_instance_valid(actor):
		return false
	var p := actor.global_position
	return absf(p.x - global_position.x) <= 17.0 and p.y >= top_y() - 14.0 and p.y <= global_position.y + 10.0

func _draw() -> void:
	var top := -ladder_height
	var rail_color := Color("d2a45f")
	var rung_color := Color("e8c57d")
	draw_line(Vector2(-7.0, 0.0), Vector2(-7.0, top), rail_color, 3.0)
	draw_line(Vector2(7.0, 0.0), Vector2(7.0, top), rail_color, 3.0)
	var y := -8.0
	while y > top + 4.0:
		draw_line(Vector2(-7.0, y), Vector2(7.0, y), rung_color, 2.0)
		y -= 12.0
