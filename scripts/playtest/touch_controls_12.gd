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
##
## Sprint 16: cada botao ganhou um `pos_portrait` ao lado do `pos` (paisagem,
## 320x180) — em retrato (180x320) os botoes de movimento ficam embaixo a
## esquerda e os de acao num cluster 2x2 embaixo a direita, ambos mais perto
## da borda inferior (tela mais alta, polegares alcancam melhor perto da
## base); o botao de pausa continua no canto superior, so que o direito
## agora cabe nos 180px de largura.
##
## Antes deste redesenho, no celular a fase inteira aparecia espremida numa
## faixa fina com tarjas pretas em cima/embaixo — os controles ficavam
## naquela area preta, nunca em cima do jogo. Agora que o jogo preenche a
## tela toda em retrato, nao existe mais essa area morta — colocar os
## botoes soltos direto por cima do chao/plataformas ficou pior (encobrem
## o jogo de verdade). A barra inferior escura abaixo recria o mesmo efeito
## visual (um "chao preto" dedicado so aos controles, igual a barra do HUD
## no topo) sem depender de letterboxing real.
const ICON_DIR := "res://assets/UI/Runtime/TouchControls/"
const TRAY_TOP_PORTRAIT := 200.0

const BUTTONS := [
	{"name": "left", "action": "move_left", "pos": Vector2(16, 150), "pos_portrait": Vector2(10, 260), "scale": 1.15},
	{"name": "right", "action": "move_right", "pos": Vector2(50, 150), "pos_portrait": Vector2(54, 260), "scale": 1.15},
	{"name": "jump", "action": "jump", "pos": Vector2(258, 108), "pos_portrait": Vector2(98, 220), "scale": 1.15},
	{"name": "attack", "action": "attack", "pos": Vector2(294, 108), "pos_portrait": Vector2(140, 220), "scale": 1.15},
	{"name": "special", "action": "special", "pos": Vector2(258, 144), "pos_portrait": Vector2(98, 262), "scale": 1.15},
	{"name": "dash", "action": "dash", "pos": Vector2(294, 144), "pos_portrait": Vector2(140, 262), "scale": 1.15},
	{"name": "pause", "action": "ui_cancel", "pos": Vector2(302, 12), "pos_portrait": Vector2(140, 8), "scale": 0.85},
]

func _ready() -> void:
	var is_portrait: bool = DeviceLayout12.is_portrait
	if is_portrait:
		var tray := ColorRect.new()
		tray.position = Vector2(0, TRAY_TOP_PORTRAIT)
		tray.size = Vector2(180, 320.0 - TRAY_TOP_PORTRAIT)
		# Mesmo tom/opacidade da barra do HUD no topo (0.55) — o suficiente
		# para separar visualmente os controles do mundo sem esconder por
		# completo o personagem ativo, que fica perto do chao (perto da
		# borda inferior) na maior parte do tempo.
		tray.color = Color(0.02, 0.025, 0.035, 0.55)
		tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tray)
	for cfg in BUTTONS:
		_build_button(cfg, is_portrait)

func _build_button(cfg: Dictionary, is_portrait: bool) -> void:
	var button := TouchScreenButton.new()
	button.texture_normal = load(ICON_DIR + cfg["name"] + "_normal.png")
	button.texture_pressed = load(ICON_DIR + cfg["name"] + "_pressed.png")
	button.action = cfg["action"]
	button.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
	button.position = cfg["pos_portrait"] if is_portrait else cfg["pos"]
	var s: float = cfg["scale"]
	button.scale = Vector2(s, s)
	add_child(button)
