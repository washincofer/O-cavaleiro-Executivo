class_name PlatformPartyProjectile12
extends Area2D

## Sprint 12: projetil de longo alcance do trio.
## "arrow" usa o sprite real da flecha (Huntress 2); "orb" e um projetil
## magico desenhado (a Wizard Pack nao inclui um sprite de feitico solto).

const ARROW_TEXTURE := preload("res://assets/Characters/Archer/Runtime/Arrow/Move.png")
const PIERCE_TEXTURE := preload("res://assets/Characters/Archer/Runtime/Arrow/Static.png")

var controller: Node
var owner_actor
var direction := Vector2.RIGHT
var kind := "arrow"
var speed := 260.0
var life := 1.4

var sprite: AnimatedSprite2D

func setup(p_controller: Node, p_owner, p_direction: Vector2, p_kind: String) -> void:
	controller = p_controller
	owner_actor = p_owner
	direction = p_direction.normalized()
	kind = p_kind
	collision_layer = 0
	collision_mask = 0

	if kind == "arrow":
		speed = 260.0
		var frames := SpriteFrames.new()
		frames.remove_animation("default")
		frames.add_animation("fly")
		frames.set_animation_loop("fly", true)
		frames.set_animation_speed("fly", 14.0)
		for i in range(2):
			var atlas := AtlasTexture.new()
			atlas.atlas = ARROW_TEXTURE
			atlas.region = Rect2(i * 24, 0, 24, 5)
			frames.add_frame("fly", atlas)
		sprite = AnimatedSprite2D.new()
		sprite.sprite_frames = frames
		sprite.play("fly")
		sprite.flip_h = direction.x < 0.0
		add_child(sprite)
	elif kind == "pierce_arrow":
		# Tiro perfurante da Arqueira: atravessa a barreira magica (layer 2)
		# que bloqueia flechas/orbes comuns — ver _hits_world.
		speed = 300.0
		var frames := SpriteFrames.new()
		frames.remove_animation("default")
		frames.add_animation("fly")
		frames.set_animation_loop("fly", true)
		frames.set_animation_speed("fly", 1.0)
		var atlas := AtlasTexture.new()
		atlas.atlas = PIERCE_TEXTURE
		atlas.region = Rect2(0, 0, 24, 5)
		frames.add_frame("fly", atlas)
		sprite = AnimatedSprite2D.new()
		sprite.sprite_frames = frames
		sprite.play("fly")
		sprite.flip_h = direction.x < 0.0
		sprite.scale = Vector2(1.4, 1.4)
		sprite.modulate = Color(0.6, 1.0, 1.0)
		add_child(sprite)
	else:
		speed = 220.0

	queue_redraw()

func _physics_process(delta: float) -> void:
	var next_position: Vector2 = global_position + direction * speed * delta

	if _hits_world(next_position):
		queue_free()
		return

	global_position = next_position
	life -= delta

	if controller.try_projectile_hit(self, owner_actor):
		queue_free()
		return

	if life <= 0.0:
		queue_free()

func _hits_world(next_position: Vector2) -> bool:
	# Barreiras magicas (layer 2, bit valor 2) bloqueiam flecha/orbe comuns
	# mas nao o tiro perfurante — ele so enxerga terreno solido (layer 1).
	var mask := 1 if kind == "pierce_arrow" else 3
	var query := PhysicsRayQueryParameters2D.create(global_position, next_position, mask)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return not hit.is_empty()

func _draw() -> void:
	if kind != "orb":
		return
	draw_circle(Vector2.ZERO, 4.0, Color(0.55, 0.35, 0.95, 0.35))
	draw_circle(Vector2.ZERO, 2.4, Color(0.8, 0.65, 1.0))
	draw_circle(Vector2.ZERO, 1.1, Color(1.0, 1.0, 1.0))
