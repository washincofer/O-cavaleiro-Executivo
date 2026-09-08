extends Area2D

## Pickup funcional e provisoriamente desenhado por codigo.
## A arte final pode substituir o desenho sem alterar as regras canonicas.

var kind: String = "coin"
var amount: int = 0
var collected := false
var bob_time := 0.0
var origin_y := 0.0

func setup(p_kind: String, p_amount: int = 0) -> void:
	kind = p_kind
	amount = p_amount

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	origin_y = position.y
	queue_redraw()

func _process(delta: float) -> void:
	bob_time += delta
	position.y = origin_y + sin(bob_time * 4.0) * 2.0
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if collected or body == null:
		return
	if not ("team" in body) or String(body.team) != "ally":
		return
	collected = true
	match kind:
		"coin":
			Progression12.add_coins(amount)
		"heal_low", "heal_medium", "heal_high":
			Progression12.apply_heal_to_actor(body, Progression12.health_amount_for_kind(kind))
		"power_life":
			if "role" in body and Progression12.apply_power_life(String(body.role)):
				body.max_hp = Progression12.get_role_max_hp(String(body.role))
				body.hp = mini(int(body.max_hp), int(body.hp) + Progression12.POWER_LIFE_STEP)
		"revive_companion":
			Progression12.add_revive_companion_item()
		"extra_life":
			Progression12.add_extra_life_item()
	SaveSystem12.save_game()
	queue_free()

func _draw() -> void:
	match kind:
		"coin":
			draw_circle(Vector2.ZERO, 6.0, Color("f4c542"))
			draw_circle(Vector2.ZERO, 3.0, Color("fff0a0"), false, 1.0)
		"heal_low":
			draw_circle(Vector2.ZERO, 5.0, Color("6ed96e"))
		"heal_medium":
			draw_circle(Vector2.ZERO, 7.0, Color("52b96b"))
		"heal_high":
			draw_circle(Vector2.ZERO, 9.0, Color("33a85c"))
		"power_life":
			draw_circle(Vector2.ZERO, 9.0, Color("d93d6f"))
			draw_string(ThemeDB.fallback_font, Vector2(-4, 4), "+", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		"revive_companion":
			draw_rect(Rect2(-7, -7, 14, 14), Color("6aa7ff"))
			draw_string(ThemeDB.fallback_font, Vector2(-4, 4), "R", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
		"extra_life":
			draw_rect(Rect2(-7, -7, 14, 14), Color("e4e4e4"))
			draw_string(ThemeDB.fallback_font, Vector2(-4, 4), "1", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("202020"))
