extends Node2D

## Sprint 14: controles virtuais para touch/mobile. Cada botao usa
## TouchScreenButton com `visibility_mode = VISIBILITY_TOUCHSCREEN_ONLY`,
## que o proprio Godot esconde automaticamente quando nao ha touchscreen
## disponivel (desktop/mouse) — nao precisa de deteccao manual de
## plataforma. O `action` de cada botao aponta direto para as acoes do
## InputMap ja usadas pelo teclado (move_left/move_right/jump/attack/
## special/dash/ui_cancel), entao platform_actor_12.gd e o pause_watcher
## funcionam sem nenhuma mudanca.
##
## Icones: pack "Controller Icons" (Casper Gaming / arte de Fauster),
## recortados em assets/UI/Runtime/TouchControls/.

const ICON_DIR := "res://assets/UI/Runtime/TouchControls/"

const BUTTONS := [
	{"name": "left", "action": "move_left", "pos": Vector2(16, 150), "scale": 1.15},
	{"name": "right", "action": "move_right", "pos": Vector2(50, 150), "scale": 1.15},
	{"name": "jump", "action": "jump", "pos": Vector2(258, 108), "scale": 1.15},
	{"name": "attack", "action": "attack", "pos": Vector2(294, 108), "scale": 1.15},
	{"name": "special", "action": "special", "pos": Vector2(258, 144), "scale": 1.15},
	{"name": "dash", "action": "dash", "pos": Vector2(294, 144), "scale": 1.15},
	{"name": "pause", "action": "ui_cancel", "pos": Vector2(302, 12), "scale": 0.85},
]

func _ready() -> void:
	for cfg in BUTTONS:
		_build_button(cfg)

func _build_button(cfg: Dictionary) -> void:
	var button := TouchScreenButton.new()
	button.texture_normal = load(ICON_DIR + cfg["name"] + "_normal.png")
	button.texture_pressed = load(ICON_DIR + cfg["name"] + "_pressed.png")
	button.action = cfg["action"]
	button.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
	button.position = cfg["pos"]
	var s: float = cfg["scale"]
	button.scale = Vector2(s, s)
	add_child(button)
