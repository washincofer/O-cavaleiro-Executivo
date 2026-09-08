extends CanvasLayer
class_name Fase00HudOverlay12

## HUD pedida:
## - HP no canto superior esquerdo
## - Cooldown no topo central

const HP_TEX := preload("res://assets/UI/Runtime/CorporateUI/hp_frame_protagonist.png")
const COOLDOWN_TEX := preload("res://assets/UI/Runtime/CorporateUI/cooldown_frame.png")

func _ready() -> void:
	var hp := TextureRect.new()
	hp.texture = HP_TEX
	hp.anchor_left = 0.0
	hp.anchor_top = 0.0
	hp.anchor_right = 0.0
	hp.anchor_bottom = 0.0
	hp.position = Vector2(18, 18)
	hp.custom_minimum_size = Vector2(280, 84)
	add_child(hp)

	var cd := TextureRect.new()
	cd.texture = COOLDOWN_TEX
	cd.anchor_left = 0.5
	cd.anchor_right = 0.5
	cd.anchor_top = 0.0
	cd.anchor_bottom = 0.0
	cd.position = Vector2(-110, 18)
	cd.custom_minimum_size = Vector2(220, 74)
	add_child(cd)
