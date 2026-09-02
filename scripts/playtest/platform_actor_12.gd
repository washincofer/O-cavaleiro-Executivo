class_name PlatformPartyActor12
extends CharacterBody2D

## Sprint 12: ator com visual real (AnimatedSprite2D) para o trio
## Guerreiro / Arqueira / Maga e para os inimigos Rato / Gosma.
## Substitui o corpo desenhado a mao da 11C mantendo a mesma arquitetura
## de movimento, seguidores e protecao de queda.

signal died(actor)

const HEALTH_BAR_TEX := preload("res://assets/UI/Runtime/MedievalFree/health_bar.png")
const NAMEPLATE_FONT := preload("res://assets/Fonts/Runtime/MedievalSharp-Book.ttf")
const HitEffect := preload("res://scenes/playtest/hit_effect_12.tscn")

const ROLE_ANIM := {
	"warrior": {
		"idle": {"path": "res://assets/Characters/Warrior/Runtime/Idle.png", "fw": 135, "fh": 135, "count": 10, "fps": 8.0, "loop": true},
		"move": {"path": "res://assets/Characters/Warrior/Runtime/Run.png", "fw": 135, "fh": 135, "count": 6, "fps": 12.0, "loop": true},
		"attack": {"path": "res://assets/Characters/Warrior/Runtime/Attack1.png", "fw": 135, "fh": 135, "count": 4, "fps": 12.0, "loop": false},
		"special": {"path": "res://assets/Characters/Warrior/Runtime/Attack2.png", "fw": 135, "fh": 135, "count": 4, "fps": 16.0, "loop": false},
		"hurt": {"path": "res://assets/Characters/Warrior/Runtime/GetHit.png", "fw": 135, "fh": 135, "count": 3, "fps": 12.0, "loop": false},
		"death": {"path": "res://assets/Characters/Warrior/Runtime/Death.png", "fw": 135, "fh": 135, "count": 9, "fps": 10.0, "loop": false},
		"jump": {"path": "res://assets/Characters/Warrior/Runtime/Jump.png", "fw": 135, "fh": 135, "count": 2, "fps": 6.0, "loop": false},
		"fall": {"path": "res://assets/Characters/Warrior/Runtime/Fall.png", "fw": 135, "fh": 135, "count": 2, "fps": 6.0, "loop": true},
	},
	"archer": {
		"idle": {"path": "res://assets/Characters/Archer/Runtime/Idle.png", "fw": 100, "fh": 100, "count": 10, "fps": 8.0, "loop": true},
		"move": {"path": "res://assets/Characters/Archer/Runtime/Run.png", "fw": 100, "fh": 100, "count": 8, "fps": 12.0, "loop": true},
		"attack": {"path": "res://assets/Characters/Archer/Runtime/Attack1.png", "fw": 100, "fh": 100, "count": 6, "fps": 14.0, "loop": false},
		"hurt": {"path": "res://assets/Characters/Archer/Runtime/GetHit.png", "fw": 100, "fh": 100, "count": 3, "fps": 12.0, "loop": false},
		"death": {"path": "res://assets/Characters/Archer/Runtime/Death.png", "fw": 100, "fh": 100, "count": 10, "fps": 10.0, "loop": false},
		"jump": {"path": "res://assets/Characters/Archer/Runtime/Jump.png", "fw": 100, "fh": 100, "count": 2, "fps": 6.0, "loop": false},
		"fall": {"path": "res://assets/Characters/Archer/Runtime/Fall.png", "fw": 100, "fh": 100, "count": 2, "fps": 6.0, "loop": true},
	},
	"mage": {
		"idle": {"path": "res://assets/Characters/Mage/Runtime/Idle.png", "fw": 231, "fh": 190, "count": 6, "fps": 6.0, "loop": true},
		"move": {"path": "res://assets/Characters/Mage/Runtime/Run.png", "fw": 231, "fh": 190, "count": 8, "fps": 10.0, "loop": true},
		"attack": {"path": "res://assets/Characters/Mage/Runtime/Attack1.png", "fw": 231, "fh": 190, "count": 8, "fps": 12.0, "loop": false},
		"special": {"path": "res://assets/Characters/Mage/Runtime/Attack2.png", "fw": 231, "fh": 190, "count": 8, "fps": 14.0, "loop": false},
		"hurt": {"path": "res://assets/Characters/Mage/Runtime/GetHit.png", "fw": 231, "fh": 190, "count": 4, "fps": 12.0, "loop": false},
		"death": {"path": "res://assets/Characters/Mage/Runtime/Death.png", "fw": 231, "fh": 190, "count": 7, "fps": 8.0, "loop": false},
		"jump": {"path": "res://assets/Characters/Mage/Runtime/Jump.png", "fw": 231, "fh": 190, "count": 2, "fps": 6.0, "loop": false},
		"fall": {"path": "res://assets/Characters/Mage/Runtime/Fall.png", "fw": 231, "fh": 190, "count": 2, "fps": 6.0, "loop": true},
	},
	"fire_mage": {
		"idle": {"path": "res://assets/Characters/FireMage/Runtime/Idle.png", "fw": 128, "fh": 128, "count": 7, "fps": 8.0, "loop": true},
		"move": {"path": "res://assets/Characters/FireMage/Runtime/Run.png", "fw": 128, "fh": 128, "count": 8, "fps": 12.0, "loop": true},
		"attack": {"path": "res://assets/Characters/FireMage/Runtime/Fireball.png", "fw": 128, "fh": 128, "count": 8, "fps": 12.0, "loop": false},
		"special": {"path": "res://assets/Characters/FireMage/Runtime/FlameJet.png", "fw": 128, "fh": 128, "count": 14, "fps": 18.0, "loop": false},
		"hurt": {"path": "res://assets/Characters/FireMage/Runtime/Hurt.png", "fw": 128, "fh": 128, "count": 3, "fps": 12.0, "loop": false},
		"death": {"path": "res://assets/Characters/FireMage/Runtime/Dead.png", "fw": 128, "fh": 128, "count": 6, "fps": 10.0, "loop": false},
		"jump": {"path": "res://assets/Characters/FireMage/Runtime/Jump.png", "fw": 128, "fh": 128, "count": 9, "fps": 8.0, "loop": false},
		"fall": {"path": "res://assets/Characters/FireMage/Runtime/Jump.png", "fw": 128, "fh": 128, "count": 9, "fps": 8.0, "loop": true},
	},
	"lightning_mage": {
		"idle": {"path": "res://assets/Characters/LightningMage/Runtime/Idle.png", "fw": 128, "fh": 128, "count": 7, "fps": 8.0, "loop": true},
		"move": {"path": "res://assets/Characters/LightningMage/Runtime/Run.png", "fw": 128, "fh": 128, "count": 8, "fps": 12.0, "loop": true},
		"attack": {"path": "res://assets/Characters/LightningMage/Runtime/LightBall.png", "fw": 128, "fh": 128, "count": 7, "fps": 12.0, "loop": false},
		"special": {"path": "res://assets/Characters/LightningMage/Runtime/LightCharge.png", "fw": 128, "fh": 128, "count": 13, "fps": 18.0, "loop": false},
		"hurt": {"path": "res://assets/Characters/LightningMage/Runtime/Hurt.png", "fw": 128, "fh": 128, "count": 3, "fps": 12.0, "loop": false},
		"death": {"path": "res://assets/Characters/LightningMage/Runtime/Dead.png", "fw": 128, "fh": 128, "count": 5, "fps": 10.0, "loop": false},
		"jump": {"path": "res://assets/Characters/LightningMage/Runtime/Jump.png", "fw": 128, "fh": 128, "count": 8, "fps": 8.0, "loop": false},
		"fall": {"path": "res://assets/Characters/LightningMage/Runtime/Jump.png", "fw": 128, "fh": 128, "count": 8, "fps": 8.0, "loop": true},
	},
	"wanderer": {
		"idle": {"path": "res://assets/Characters/Wanderer/Runtime/Idle.png", "fw": 128, "fh": 128, "count": 8, "fps": 8.0, "loop": true},
		"move": {"path": "res://assets/Characters/Wanderer/Runtime/Run.png", "fw": 128, "fh": 128, "count": 8, "fps": 12.0, "loop": true},
		"attack": {"path": "res://assets/Characters/Wanderer/Runtime/MagicArrow.png", "fw": 128, "fh": 128, "count": 6, "fps": 12.0, "loop": false},
		"special": {"path": "res://assets/Characters/Wanderer/Runtime/Attack2.png", "fw": 128, "fh": 128, "count": 9, "fps": 14.0, "loop": false},
		"hurt": {"path": "res://assets/Characters/Wanderer/Runtime/Hurt.png", "fw": 128, "fh": 128, "count": 4, "fps": 12.0, "loop": false},
		"death": {"path": "res://assets/Characters/Wanderer/Runtime/Dead.png", "fw": 128, "fh": 128, "count": 4, "fps": 10.0, "loop": false},
		"jump": {"path": "res://assets/Characters/Wanderer/Runtime/Jump.png", "fw": 128, "fh": 128, "count": 8, "fps": 8.0, "loop": false},
		"fall": {"path": "res://assets/Characters/Wanderer/Runtime/Jump.png", "fw": 128, "fh": 128, "count": 8, "fps": 8.0, "loop": true},
	},
	# Cavaleiro Executivo: arte propria do usuario. Sem Hurt/Death fornecidos
	# (mesmo caso ja tratado sem problemas pelo Ogro/Cavaleiro-Knight).
	# Ataque.png/Estocada.png (pedido do usuario: sprites dedicados no lugar
	# do reaproveitamento de Agachando/Correndo) vieram como folha unica
	# 2172x724 com 6 poses num grid UNIFORME (confirmado visualmente com
	# linhas de grade sobrepostas — cada 1/6 da largura cai exatamente nas
	# bordas de cada pose, so a ponta da espada cruza levemente a celula
	# vizinha em alguns quadros, aceitavel) — redimensionada pra 60px de
	# altura (180x60 final, 30px por quadro) pra bater com a mesma altura
	# de canvas de Parado.png/Correndo.png e usar o mesmo ROLE_BODY.scale.
	"cavaleiro_executivo": {
		"idle": {"path": "res://assets/Characters/CavaleiroExecutivo/Runtime/Parado.png", "fps": 6.0, "loop": true, "rects": [Rect2(0,0,48,60), Rect2(48,0,47,60), Rect2(95,0,45,60), Rect2(140,0,46,60), Rect2(186,0,50,60)]},
		"move": {"path": "res://assets/Characters/CavaleiroExecutivo/Runtime/Andando.png", "fps": 12.0, "loop": true, "rects": [Rect2(0,0,53,57), Rect2(53,0,50,57), Rect2(103,0,51,57), Rect2(154,0,55,57), Rect2(209,0,56,57), Rect2(265,0,55,57), Rect2(320,0,56,57), Rect2(376,0,57,57), Rect2(433,0,113,57)]},
		"attack": {"path": "res://assets/Characters/CavaleiroExecutivo/Runtime/Ataque.png", "fps": 14.0, "loop": false, "rects": [Rect2(0,0,30,60), Rect2(30,0,30,60), Rect2(60,0,30,60), Rect2(90,0,30,60), Rect2(120,0,30,60), Rect2(150,0,30,60)]},
		# fps alto de proposito: a Estocada (warrior/knight/cavaleiro_executivo)
		# trava a animacao por so 0.22s (`_start_charge()`, mesmo tempo da
		# arrancada em si — nao mudado aqui pra nao alterar o alcance/balance
		# ja calibrado pros outros papeis) — 6 quadros precisam caber nesse
		# tempo (~27fps) pra nao serem cortados no meio pelo retorno a idle/move.
		"special": {"path": "res://assets/Characters/CavaleiroExecutivo/Runtime/Estocada.png", "fps": 27.0, "loop": false, "rects": [Rect2(0,0,30,60), Rect2(30,0,30,60), Rect2(60,0,30,60), Rect2(90,0,30,60), Rect2(120,0,30,60), Rect2(150,0,30,60)]},
		"jump": {"path": "res://assets/Characters/CavaleiroExecutivo/Runtime/Pulo.png", "fps": 8.0, "loop": false, "rects": [Rect2(0,0,77,83), Rect2(77,0,75,83), Rect2(152,0,82,83), Rect2(234,0,74,83)]},
		"fall": {"path": "res://assets/Characters/CavaleiroExecutivo/Runtime/Caindo.png", "fps": 6.0, "loop": true, "rects": [Rect2(0,0,80,75), Rect2(80,0,69,75), Rect2(149,0,80,75)]},
	},
	# Paladino e Cavaleiro sao personagens livres (selecionaveis so nas fases
	# de boss, fora do sistema de categorias da Caverna) — cada um reaproveita
	# uma mecanica ja existente (Rajada/Estocada) na tecla especial, sem
	# depender de logica nova no boss.
	"paladin": {
		"idle": {"path": "res://assets/Characters/Paladin/Runtime/Idle.png", "fw": 128, "fh": 128, "count": 27, "fps": 10.0, "loop": true},
		"move": {"path": "res://assets/Characters/Paladin/Runtime/Walk.png", "fw": 128, "fh": 128, "count": 10, "fps": 12.0, "loop": true},
		"attack": {"path": "res://assets/Characters/Paladin/Runtime/Attack.png", "fw": 128, "fh": 128, "count": 30, "fps": 16.0, "loop": false},
		"special": {"path": "res://assets/Characters/Paladin/Runtime/Attack2.png", "fw": 160, "fh": 128, "count": 24, "fps": 10.0, "loop": false},
		"hurt": {"path": "res://assets/Characters/Paladin/Runtime/Hurt.png", "fw": 128, "fh": 128, "count": 12, "fps": 14.0, "loop": false},
		"death": {"path": "res://assets/Characters/Paladin/Runtime/Death.png", "fw": 128, "fh": 128, "count": 30, "fps": 8.0, "loop": false},
		"jump": {"path": "res://assets/Characters/Paladin/Runtime/Jump.png", "fw": 128, "fh": 128, "count": 13, "fps": 10.0, "loop": false},
		"fall": {"path": "res://assets/Characters/Paladin/Runtime/Jump.png", "fw": 128, "fh": 128, "count": 13, "fps": 10.0, "loop": true},
	},
	# Bridge Heroine (Gothicvania, Legacy Collection): so trouxe Idle/Run/
	# Attack/Jump (sem Hurt/Death, mesmo caso ja tratado sem problemas pelo
	# Cavaleiro/Ogro). Sem "special" propria — reaproveita o proprio ataque
	# (ver ROLE_TAG/activate_special no controller de cada fase de boss).
	"bridge_heroine": {
		"idle": {"path": "res://assets/Characters/BridgeHeroine/Runtime/Idle.png", "fw": 128, "fh": 64, "count": 4, "fps": 8.0, "loop": true},
		"move": {"path": "res://assets/Characters/BridgeHeroine/Runtime/Run.png", "fw": 128, "fh": 64, "count": 7, "fps": 12.0, "loop": true},
		"attack": {"path": "res://assets/Characters/BridgeHeroine/Runtime/Attack.png", "fw": 128, "fh": 64, "count": 5, "fps": 14.0, "loop": false},
		"jump": {"path": "res://assets/Characters/BridgeHeroine/Runtime/Jump.png", "fw": 128, "fh": 64, "count": 4, "fps": 8.0, "loop": false},
	},
	"knight": {
		"idle": {"path": "res://assets/Characters/Knight/Runtime/Idle.png", "fw": 64, "fh": 64, "count": 15, "fps": 8.0, "loop": true},
		"move": {"path": "res://assets/Characters/Knight/Runtime/Run.png", "fw": 96, "fh": 64, "count": 8, "fps": 12.0, "loop": true},
		"attack": {"path": "res://assets/Characters/Knight/Runtime/Attack.png", "fw": 144, "fh": 64, "count": 22, "fps": 18.0, "loop": false},
		"special": {"path": "res://assets/Characters/Knight/Runtime/Shield.png", "fw": 96, "fh": 64, "count": 7, "fps": 10.0, "loop": false},
		"death": {"path": "res://assets/Characters/Knight/Runtime/Death.png", "fw": 96, "fh": 64, "count": 15, "fps": 10.0, "loop": false},
		"jump": {"path": "res://assets/Characters/Knight/Runtime/Jump.png", "fw": 144, "fh": 64, "count": 15, "fps": 10.0, "loop": false},
		"fall": {"path": "res://assets/Characters/Knight/Runtime/Jump.png", "fw": 144, "fh": 64, "count": 15, "fps": 10.0, "loop": true},
	},
	"slime": {
		"idle": {"path": "res://assets/Enemies/Slime/Runtime/Idle.png", "fw": 156, "fh": 156, "count": 14, "fps": 8.0, "loop": true},
		"move": {"path": "res://assets/Enemies/Slime/Runtime/Walk.png", "fw": 156, "fh": 156, "count": 6, "fps": 8.0, "loop": true},
		"attack": {"path": "res://assets/Enemies/Slime/Runtime/Attack.png", "fw": 156, "fh": 156, "count": 19, "fps": 16.0, "loop": false},
		"hurt": {"path": "res://assets/Enemies/Slime/Runtime/Hurt.png", "fw": 156, "fh": 156, "count": 3, "fps": 12.0, "loop": false},
		"death": {"path": "res://assets/Enemies/Slime/Runtime/Death.png", "fw": 156, "fh": 156, "count": 11, "fps": 10.0, "loop": false},
	},
	"necromancer": {
		"idle": {"path": "res://assets/Enemies/Necromancer/Runtime/Idle.png", "fw": 96, "fh": 96, "count": 40, "fps": 10.0, "loop": true},
		"move": {"path": "res://assets/Enemies/Necromancer/Runtime/Walk.png", "fw": 96, "fh": 96, "count": 10, "fps": 10.0, "loop": true},
		"attack": {"path": "res://assets/Enemies/Necromancer/Runtime/Attack.png", "fw": 128, "fh": 128, "count": 30, "fps": 15.0, "loop": false},
		"hurt": {"path": "res://assets/Enemies/Necromancer/Runtime/Hurt.png", "fw": 96, "fh": 96, "count": 9, "fps": 14.0, "loop": false},
		"death": {"path": "res://assets/Enemies/Necromancer/Runtime/Death.png", "fw": 96, "fh": 96, "count": 40, "fps": 12.0, "loop": false},
	},
	"rat": {
		"idle": {"path": "res://assets/Enemies/Rat/Runtime/Idle.png", "fw": 70, "fh": 70, "count": 10, "fps": 8.0, "loop": true},
		"move": {"path": "res://assets/Enemies/Rat/Runtime/Run.png", "fw": 70, "fh": 70, "count": 8, "fps": 12.0, "loop": true},
		"attack": {"path": "res://assets/Enemies/Rat/Runtime/Attack.png", "fw": 70, "fh": 70, "count": 12, "fps": 14.0, "loop": false},
		"hurt": {"path": "res://assets/Enemies/Rat/Runtime/Hurt.png", "fw": 70, "fh": 70, "count": 3, "fps": 12.0, "loop": false},
		"death": {"path": "res://assets/Enemies/Rat/Runtime/Death.png", "fw": 70, "fh": 70, "count": 6, "fps": 10.0, "loop": false},
	},
	"satyr": {
		"idle": {"path": "res://assets/Enemies/Satyr/Runtime/Idle.png", "fw": 32, "fh": 32, "count": 6, "fps": 8.0, "loop": true},
		"move": {"path": "res://assets/Enemies/Satyr/Runtime/Walk.png", "fw": 32, "fh": 32, "count": 8, "fps": 10.0, "loop": true},
		"attack": {"path": "res://assets/Enemies/Satyr/Runtime/Attack.png", "fw": 32, "fh": 32, "count": 7, "fps": 12.0, "loop": false},
		"hurt": {"path": "res://assets/Enemies/Satyr/Runtime/Hurt.png", "fw": 32, "fh": 32, "count": 4, "fps": 14.0, "loop": false},
		"death": {"path": "res://assets/Enemies/Satyr/Runtime/Death.png", "fw": 32, "fh": 32, "count": 10, "fps": 10.0, "loop": false},
	},
	# Pack Gothicvania (Legacy Collection) so trouxe Idle/Walk/Attack para o
	# Ogro (sem Hurt/Death) — o mesmo caso ja tratado sem problemas pelo
	# Cavaleiro (sem "hurt") e por `_die()` (sem "death" ele so fica invisivel).
	"ogre": {
		"idle": {"path": "res://assets/Enemies/Ogre/Runtime/Idle.png", "fw": 144, "fh": 80, "count": 4, "fps": 6.0, "loop": true},
		"move": {"path": "res://assets/Enemies/Ogre/Runtime/Walk.png", "fw": 144, "fh": 80, "count": 6, "fps": 8.0, "loop": true},
		"attack": {"path": "res://assets/Enemies/Ogre/Runtime/Attack.png", "fw": 144, "fh": 80, "count": 7, "fps": 10.0, "loop": false},
	},
	# Morcego (Monsters Creatures Fantasy 2): nao anda, so voa — "idle" e
	# "move" reaproveitam a mesma folha (Fly.png), e o offset visual (ver
	# ROLE_BODY) flutua o sprite bem acima da origem fisica, na mesma tecnica
	# ja usada pelos magos do grupo (offset negativo grande) para dar a
	# ilusao de estar no ar mesmo com a origem "presa" ao chao.
	"bat": {
		"idle": {"path": "res://assets/Enemies/Bat/Runtime/Fly.png", "fw": 87, "fh": 87, "count": 11, "fps": 14.0, "loop": true},
		"move": {"path": "res://assets/Enemies/Bat/Runtime/Fly.png", "fw": 87, "fh": 87, "count": 11, "fps": 14.0, "loop": true},
		"attack": {"path": "res://assets/Enemies/Bat/Runtime/Attack.png", "fw": 87, "fh": 87, "count": 11, "fps": 16.0, "loop": false},
		"hurt": {"path": "res://assets/Enemies/Bat/Runtime/Hurt.png", "fw": 87, "fh": 87, "count": 3, "fps": 14.0, "loop": false},
		"death": {"path": "res://assets/Enemies/Bat/Runtime/Death.png", "fw": 87, "fh": 87, "count": 4, "fps": 10.0, "loop": false},
	},
	# Pack Gothicvania "Grotto-escape-2-boss-dragon" (Legacy Collection) so
	# trouxe Idle e Breath (sopro de fogo, usado como "attack") — sem Walk/
	# Hurt/Death, mesmo caso ja tratado sem problemas pelo Ogro/`_die()`; o
	# Dragao guarda o tesouro parado, entao nem precisaria de "move" mesmo.
	"dragon": {
		"idle": {"path": "res://assets/Enemies/Dragon/Runtime/Idle.png", "fw": 144, "fh": 64, "count": 6, "fps": 8.0, "loop": true},
		"move": {"path": "res://assets/Enemies/Dragon/Runtime/Idle.png", "fw": 144, "fh": 64, "count": 6, "fps": 8.0, "loop": true},
		"attack": {"path": "res://assets/Enemies/Dragon/Runtime/Breath.png", "fw": 144, "fh": 64, "count": 7, "fps": 10.0, "loop": false},
	},
	# Fase 01 (Operacoes & Logistica): companions/inimigos com arte gerada
	# (pedido do usuario) — sheets simples de 2 quadros (idle/move/attack),
	# mesmo padrao "minimo aceitavel" ja usado por ogre/dragon (sem
	# hurt/death/jump/fall — `_update_animation`/`_die` ja toleram a falta).
	"almoxarifado": {
		"idle": {"path": "res://assets/Characters/Almoxarifado/Runtime/Idle.png", "fw": 80, "fh": 112, "count": 2, "fps": 3.0, "loop": true},
		"move": {"path": "res://assets/Characters/Almoxarifado/Runtime/Walk.png", "fw": 80, "fh": 112, "count": 2, "fps": 6.0, "loop": true},
		"attack": {"path": "res://assets/Characters/Almoxarifado/Runtime/Attack.png", "fw": 80, "fh": 112, "count": 2, "fps": 10.0, "loop": false},
	},
	"protocolo": {
		"idle": {"path": "res://assets/Characters/Protocolo/Runtime/Idle.png", "fw": 80, "fh": 112, "count": 2, "fps": 3.0, "loop": true},
		"move": {"path": "res://assets/Characters/Protocolo/Runtime/Walk.png", "fw": 80, "fh": 112, "count": 2, "fps": 6.0, "loop": true},
		"attack": {"path": "res://assets/Characters/Protocolo/Runtime/Attack.png", "fw": 80, "fh": 112, "count": 2, "fps": 10.0, "loop": false},
	},
	"especialista": {
		"idle": {"path": "res://assets/Enemies/Especialista/Runtime/Idle.png", "fw": 80, "fh": 112, "count": 2, "fps": 3.0, "loop": true},
		"move": {"path": "res://assets/Enemies/Especialista/Runtime/Walk.png", "fw": 80, "fh": 112, "count": 2, "fps": 6.0, "loop": true},
		"attack": {"path": "res://assets/Enemies/Especialista/Runtime/Attack.png", "fw": 80, "fh": 112, "count": 2, "fps": 10.0, "loop": false},
	},
	"danelmo": {
		"idle": {"path": "res://assets/Enemies/Danelmo/Runtime/Idle.png", "fw": 120, "fh": 168, "count": 2, "fps": 3.0, "loop": true},
		"move": {"path": "res://assets/Enemies/Danelmo/Runtime/Walk.png", "fw": 120, "fh": 168, "count": 2, "fps": 6.0, "loop": true},
		"attack": {"path": "res://assets/Enemies/Danelmo/Runtime/Attack.png", "fw": 120, "fh": 168, "count": 2, "fps": 8.0, "loop": false},
	},
}

# scale, sprite offset (raw pixel space) and capsule collision tuned from the
# alpha-channel bounding box of each pack's idle frame (feet position / width),
# so every role's feet line up with the CharacterBody2D origin (y = 0).
const ROLE_BODY := {
	"warrior": {"scale": 0.842, "offset": Vector2(0.5, -18.5), "radius": 6.0, "height": 26.0, "shape_y": -15.0, "speed": 92.0, "max_hp": 5, "ranged": false},
	# Altura visual alvo ~32px (mesmo padrao do trio base) medida via bbox
	# alfa das folhas idle/move/attack/special (57-60px de altura antes da
	# escala) — capsula de colisao igual a do Guerreiro (mesmo porte).
	"cavaleiro_executivo": {"scale": 0.552, "offset": Vector2(0.0, -29.4), "radius": 6.0, "height": 26.0, "shape_y": -15.0, "speed": 92.0, "max_hp": 6, "ranged": false},
	"archer": {"scale": 0.889, "offset": Vector2(-1.0, -17.0), "radius": 5.0, "height": 26.0, "shape_y": -15.0, "speed": 96.0, "max_hp": 4, "ranged": true},
	"mage": {"scale": 0.372, "offset": Vector2(5.0, -46.0), "radius": 6.0, "height": 28.0, "shape_y": -16.0, "speed": 84.0, "max_hp": 4, "ranged": true},
	"fire_mage": {"scale": 0.485, "offset": Vector2(14.0, -64.0), "radius": 6.0, "height": 28.0, "shape_y": -16.0, "speed": 84.0, "max_hp": 4, "ranged": true},
	"lightning_mage": {"scale": 0.390, "offset": Vector2(26.0, -64.0), "radius": 6.0, "height": 28.0, "shape_y": -16.0, "speed": 84.0, "max_hp": 4, "ranged": true},
	"wanderer": {"scale": 0.485, "offset": Vector2(0.0, -64.0), "radius": 6.0, "height": 28.0, "shape_y": -16.0, "speed": 84.0, "max_hp": 4, "ranged": true},
	# scale de paladin/knight/bridge_heroine media original (1.3/1.4/1.25)
	# renderizava 42-51px de altura real (bbox alfa medido), bem maior que
	# os ~32px de warrior/archer/mage — corrigido pra bater no mesmo alvo
	# visual. offset.y NAO muda: o alinhamento dos pes ao chao (y=0) e
	# resultado de offset+(pixel-frame/2)=0, que e independente da escala
	# (0 * qualquer_escala = 0), entao continua correto nos 3 casos.
	"paladin": {"scale": 0.865, "offset": Vector2(2.5, 0.0), "radius": 7.0, "height": 28.0, "shape_y": -16.0, "speed": 90.0, "max_hp": 6, "ranged": false},
	"knight": {"scale": 1.067, "offset": Vector2(-3.0, -12.0), "radius": 6.0, "height": 26.0, "shape_y": -15.0, "speed": 90.0, "max_hp": 5, "ranged": false},
	"bridge_heroine": {"scale": 0.8, "offset": Vector2(0.0, -32.0), "radius": 6.0, "height": 26.0, "shape_y": -15.0, "speed": 94.0, "max_hp": 5, "ranged": false},
	"slime": {"scale": 1.0, "offset": Vector2(0.0, -9.0), "radius": 7.0, "height": 14.0, "shape_y": -8.0, "speed": 46.0, "max_hp": 3, "ranged": false},
	"rat": {"scale": 0.9, "offset": Vector2(0.0, -10.0), "radius": 6.0, "height": 16.0, "shape_y": -9.0, "speed": 58.0, "max_hp": 3, "ranged": false},
	"necromancer": {"scale": 1.75, "offset": Vector2(-4.0, -16.0), "radius": 10.0, "height": 48.0, "shape_y": -28.0, "speed": 26.0, "max_hp": 60, "ranged": false},
	# Pedido do usuario: Satyr precisa ficar MENOR que os personagens
	# jogaveis (~32px de altura visual), nao maior — visual reduzido de
	# ~90px (scale 4.5, bbox alfa ~20px * 4.5) para ~24px (scale 1.2). O
	# raio de acerto de magia (`try_projectile_hit`, 15.0 fixo a partir do
	# centro do inimigo) NAO depende do tamanho visual/capsula, entao
	# continua acertando normalmente — nao precisa de ajuste a parte.
	"satyr": {"scale": 1.2, "offset": Vector2(2.0, -11.0), "radius": 7.0, "height": 22.0, "shape_y": -13.0, "speed": 34.0, "max_hp": 55, "ranged": false},
	"ogre": {"scale": 1.5, "offset": Vector2(10.0, -40.0), "radius": 11.0, "height": 44.0, "shape_y": -25.0, "speed": 22.0, "max_hp": 58, "ranged": false},
	"bat": {"scale": 2.4, "offset": Vector2(-3.5, -25.0), "radius": 10.0, "height": 30.0, "shape_y": -16.0, "speed": 50.0, "max_hp": 50, "ranged": false},
	"dragon": {"scale": 2.2, "offset": Vector2(-23.5, -32.0), "radius": 14.0, "height": 46.0, "shape_y": -26.0, "speed": 0.0, "max_hp": 65, "ranged": false},
	# Fase 01: sheets geradas em canvas 40x56 (2x/3x export) — pes no pixel
	# 96 (2x) / 144 (3x) de 112/168 de altura total, centro em 56/84;
	# offset.y = -(pes-centro) alinha o pe ao chao (y=0), igual ao resto.
	"almoxarifado": {"scale": 0.34, "offset": Vector2(0.0, -40.0), "radius": 6.0, "height": 26.0, "shape_y": -15.0, "speed": 90.0, "max_hp": 6, "ranged": false},
	"protocolo": {"scale": 0.34, "offset": Vector2(0.0, -40.0), "radius": 6.0, "height": 26.0, "shape_y": -15.0, "speed": 90.0, "max_hp": 5, "ranged": false},
	"especialista": {"scale": 0.5, "offset": Vector2(0.0, -40.0), "radius": 8.0, "height": 32.0, "shape_y": -18.0, "speed": 42.0, "max_hp": 32, "ranged": false},
	"danelmo": {"scale": 0.9, "offset": Vector2(0.0, -60.0), "radius": 11.0, "height": 44.0, "shape_y": -25.0, "speed": 24.0, "max_hp": 75, "ranged": false},
}

# Tinta permanente do sprite por role (multiplicada sobre a textura); a
# maioria fica branca (sem alterar as cores originais do pack) — so entra
# aqui quando um role reaproveita a arte de outro e precisa de diferenciacao
# visual (ex.: um inimigo comum reaproveitado em escala maior como boss).
const ROLE_MODULATE := {}

const DISPLAY_NAME := {
	"cavaleiro_executivo": "CAVALEIRO EXECUTIVO",
	"warrior": "GUERREIRO",
	"archer": "ARQUEIRA",
	"mage": "MAGA",
	"fire_mage": "MAGO DE FOGO",
	"lightning_mage": "MAGO DO RAIO",
	"wanderer": "MAGO ANDARILHO",
	"paladin": "PALADINO",
	"knight": "CAVALEIRO",
	"bridge_heroine": "HEROINA DA PONTE",
	"slime": "GOSMA",
	"rat": "RATO",
	"necromancer": "NECROMANTE",
	"satyr": "SATYR",
	"ogre": "OGRO",
	"bat": "MORCEGO",
	"dragon": "DRAGAO",
	"almoxarifado": "RAPAZ DO ALMOXARIFADO",
	"protocolo": "RAPAZ DO PROTOCOLO",
	"especialista": "ESPECIALISTA DE SEGURANCA",
	"danelmo": "DANELMO GROSSMANOBRA",
}

# A maioria dos packs desenha o personagem de frente pra DIREITA (facing=1
# sem flip); esses inimigos vieram do lado oposto (rosto/arma/cauda
# apontando pra ESQUERDA no frame-fonte, confirmado visualmente comparando
# lado a lado com o Morcego, que fica correto sem essa lista) — sem isso
# eles "andam de costas" (flip_h sai invertido em relacao ao sentido real
# do movimento). O Satyr NAO entra aqui — reportado pelo usuario andando
# de costas (corpo virado pro lado oposto ao movimento) quando estava
# nesta lista; o frame-fonte dele na verdade ja olha pra DIREITA por
# padrao, confirmado visualmente (o rosto/olhos ficam do lado errado ao
# perseguir o grupo pra esquerda com a entrada antiga).
const ROLE_FACES_LEFT := {
	"necromancer": true,
	"ogre": true,
	"dragon": true,
}

const RANGED_PROJECTILE_KIND := {
	"archer": "arrow",
	"mage": "orb",
	"fire_mage": "fire_orb",
	"lightning_mage": "lightning_orb",
	"wanderer": "arcane_orb",
}

var controller: Node
var actor_name := "Actor"
var team := "ally"
var role := "warrior"
var is_controlled := false
var party_slot := -1
var alive := true

var max_hp := 4
var hp := 4
var speed := 92.0
var jump_velocity := -245.0
var jumps_used := 0
var max_jumps := 2
var gravity := 760.0
var max_fall_speed := 420.0
var facing := 1.0
var follow_offset_x := -30.0
# Deixa o controller da fase tomar o controle total do movimento (ex.: o
# Satyr durante a investida em platform_boss_forest_12.gd) sem brigar com
# `_enemy_tick()` sobrescrevendo velocity.x na perseguicao padrao a cada
# tick de fisica.
var ai_suspended := false
var is_ranged := false

var attack_cooldown := 0.0
var attack_cooldown_max := 0.45
var attack_lock_timer := 0.0
var hurt_lock_timer := 0.0
var edge_turn_timer := 0.0
var edge_turn_direction := 0.0

# Habilidade especial (tecla H) — cada papel tem uma mecanica propria:
# Guerreiro = Estocada (dash que quebra entulho), Arqueira = Tiro
# Perfurante (atravessa parede de energia), Maga = Teleporte (cruza vaos
# largos demais para o pulo duplo).
var special_cooldown := 0.0
var special_cooldown_max := 1.4
var charge_timer := 0.0
var charge_speed := 320.0
var charge_direction := 1.0

var sprite: AnimatedSprite2D
var nameplate: Label
var base_modulate := Color(1, 1, 1)

func setup(
	p_controller: Node,
	p_name: String,
	p_team: String,
	p_role: String,
	p_tint: Color,
	p_party_slot := -1
) -> void:
	controller = p_controller
	actor_name = p_name
	team = p_team
	role = p_role
	party_slot = p_party_slot

	var body_cfg: Dictionary = ROLE_BODY[role]
	var body_speed: float = body_cfg["speed"]
	speed = body_speed
	var body_hp: int = body_cfg["max_hp"]
	max_hp = body_hp
	hp = max_hp
	is_ranged = body_cfg["ranged"]

	collision_layer = 2
	# Layer 8 mantida livre para futuras interacoes exclusivas de inimigos.
	collision_mask = 1

	var capsule := CapsuleShape2D.new()
	var body_radius: float = body_cfg["radius"]
	var body_height: float = body_cfg["height"]
	capsule.radius = body_radius
	capsule.height = body_height
	var shape := CollisionShape2D.new()
	shape.shape = capsule
	var body_shape_y: float = body_cfg["shape_y"]
	shape.position = Vector2(0, body_shape_y)
	add_child(shape)

	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = _build_sprite_frames(role)
	var body_scale: float = body_cfg["scale"]
	sprite.scale = Vector2(body_scale, body_scale)
	sprite.offset = body_cfg["offset"]
	base_modulate = ROLE_MODULATE.get(role, Color(1, 1, 1))
	sprite.modulate = base_modulate
	sprite.animation = "idle"
	sprite.play("idle")
	sprite.animation_finished.connect(_on_animation_finished)
	add_child(sprite)

	nameplate = Label.new()
	nameplate.text = actor_name
	nameplate.position = Vector2(-25, body_shape_y - body_height * 0.5 - 16.0)
	nameplate.size = Vector2(50, 8)
	nameplate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nameplate.add_theme_font_override("font", NAMEPLATE_FONT)
	nameplate.add_theme_font_size_override("font_size", 6)
	nameplate.add_theme_color_override("font_color", p_tint)
	nameplate.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	nameplate.add_theme_constant_override("outline_size", 2)
	add_child(nameplate)
	queue_redraw()

static func _build_sprite_frames(p_role: String) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var anim_cfg: Dictionary = ROLE_ANIM[p_role]
	for anim_name in anim_cfg.keys():
		var a: Dictionary = anim_cfg[anim_name]
		var tex: Texture2D = load(a["path"])
		var fps: float = a["fps"]
		var loop: bool = a["loop"]
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, loop)
		frames.set_animation_speed(anim_name, fps)
		if a.has("rects"):
			# Folhas com largura de quadro irregular (ex.: Cavaleiro
			# Executivo, arte propria sem grid fixo) — cada quadro usa seu
			# proprio Rect2 exato em vez de um grid fw*count uniforme.
			for rect in a["rects"]:
				var atlas := AtlasTexture.new()
				atlas.atlas = tex
				atlas.region = rect
				frames.add_frame(anim_name, atlas)
		else:
			var fw: int = a["fw"]
			var fh: int = a["fh"]
			var count: int = a["count"]
			for i in range(count):
				var atlas := AtlasTexture.new()
				atlas.atlas = tex
				atlas.region = Rect2(i * fw, 0, fw, fh)
				frames.add_frame(anim_name, atlas)
	return frames

func set_controlled(value: bool) -> void:
	if not alive:
		return
	is_controlled = value
	velocity.x = 0.0
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not alive:
		return

	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	attack_lock_timer = maxf(0.0, attack_lock_timer - delta)
	hurt_lock_timer = maxf(0.0, hurt_lock_timer - delta)
	edge_turn_timer = maxf(0.0, edge_turn_timer - delta)
	special_cooldown = maxf(0.0, special_cooldown - delta)
	charge_timer = maxf(0.0, charge_timer - delta)

	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)

	if team == "ally":
		if is_controlled:
			_controlled_tick()
		else:
			_follow_tick()
	else:
		_enemy_tick()

	move_and_slide()
	if is_on_floor():
		jumps_used = 0
	_update_animation()
	queue_redraw()

func _controlled_tick() -> void:
	if charge_timer > 0.0:
		velocity.x = charge_direction * charge_speed
		controller.try_break_rubble(self)
		if Input.is_action_just_pressed("jump") and jumps_used < max_jumps:
			velocity.y = jump_velocity
			jumps_used += 1
		return

	var axis := Input.get_axis("move_left", "move_right")
	if axis != 0.0:
		facing = signf(axis)
	var multiplier := 1.55 if Input.is_action_pressed("dash") else 1.0
	velocity.x = axis * speed * multiplier

	if Input.is_action_just_pressed("jump") and jumps_used < max_jumps:
		velocity.y = jump_velocity
		jumps_used += 1
		if is_instance_valid(sprite) and sprite.sprite_frames.has_animation("jump"):
			sprite.play("jump")

	if Input.is_action_just_pressed("attack"):
		controller.activate_actor_action(self)

	if Input.is_action_just_pressed("special"):
		controller.activate_actor_special(self)

func _follow_tick() -> void:
	var leader: Node = controller.get_active_actor()
	if not is_instance_valid(leader) or not leader.alive or leader == self:
		velocity.x = 0.0
		return

	var desired_x: float = leader.global_position.x + follow_offset_x
	var delta_x: float = desired_x - global_position.x

	if absf(delta_x) > 18.0:
		facing = signf(delta_x)
		velocity.x = facing * speed * 0.92

		if is_on_floor() and not controller.has_floor_ahead(self, facing, 14.0):
			if controller.has_floor_ahead(self, facing, 54.0):
				velocity.x = facing * speed * 1.05
				velocity.y = jump_velocity
			else:
				velocity.x = 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, 20.0)

	if leader.global_position.y < global_position.y - 25.0 and is_on_floor():
		velocity.y = jump_velocity

func _enemy_tick() -> void:
	if ai_suspended:
		velocity.x = 0.0
		return
	if edge_turn_timer > 0.0:
		facing = edge_turn_direction
		velocity.x = facing * speed * 0.50
		return

	var target: Node = controller.closest_alive_ally(self)
	if not is_instance_valid(target):
		velocity.x = 0.0
		return

	var dx: float = target.global_position.x - global_position.x
	var dy: float = absf(target.global_position.y - global_position.y)

	if absf(dx) <= 22.0 and dy <= 28.0:
		velocity.x = 0.0
		if attack_cooldown <= 0.0:
			_play_attack()
			target.take_damage(1, self)
			attack_cooldown = attack_cooldown_max
	else:
		facing = signf(dx) if dx != 0.0 else facing

		if is_on_floor() and not controller.has_floor_ahead(self, facing, 14.0):
			edge_turn_direction = -facing
			edge_turn_timer = 0.55
			facing = edge_turn_direction
			velocity.x = facing * speed * 0.50
			return

		velocity.x = facing * speed * 0.62

func activate_ranged_attack() -> bool:
	if not alive or not is_ranged or attack_cooldown > 0.0:
		return false
	attack_cooldown = attack_cooldown_max
	_play_attack()
	var kind: String = RANGED_PROJECTILE_KIND.get(role, "orb")
	controller.spawn_party_projectile(self, Vector2(facing, 0.0), kind)
	return true

func melee_attack() -> bool:
	if not alive or is_ranged or attack_cooldown > 0.0:
		return false
	attack_cooldown = attack_cooldown_max
	_play_attack()
	return controller.melee_attack_from(self)

func activate_special() -> bool:
	if not alive or special_cooldown > 0.0 or charge_timer > 0.0:
		return false
	match role:
		"warrior", "knight", "cavaleiro_executivo", "protocolo":
			return _start_charge()
		"fire_mage", "paladin":
			return _cast_fire_burst()
		"archer", "lightning_mage", "almoxarifado":
			return _fire_piercing_shot()
		"mage", "wanderer":
			return _cast_teleport()
		"bridge_heroine":
			return _summon_bridge()
	return false

func _summon_bridge() -> bool:
	# Mecanica exclusiva da Heroina da Ponte (Sprint 15): invoca uma
	# plataforma temporaria a frente dela. So o Covil do Tesouro (unica fase
	# com um vao real para isso) implementa `summon_bridge_from` de verdade;
	# as demais fases o tem como no-op inofensivo (mesmo padrao usado por
	# `try_break_rubble` nas fases de boss sem entulho).
	special_cooldown = special_cooldown_max
	attack_lock_timer = 0.4
	if is_instance_valid(sprite) and sprite.sprite_frames.has_animation("special"):
		sprite.play("special")
	controller.summon_bridge_from(self)
	return true

func _start_charge() -> bool:
	special_cooldown = special_cooldown_max
	charge_timer = 0.22
	charge_direction = facing
	attack_lock_timer = charge_timer
	if is_instance_valid(sprite) and sprite.sprite_frames.has_animation("special"):
		sprite.play("special")
	return true

func _cast_fire_burst() -> bool:
	special_cooldown = special_cooldown_max
	attack_lock_timer = 0.55
	if is_instance_valid(sprite) and sprite.sprite_frames.has_animation("special"):
		sprite.play("special")
	controller.fire_burst_from(self)
	return true

func _fire_piercing_shot() -> bool:
	special_cooldown = special_cooldown_max
	attack_lock_timer = 0.2
	var anim_name := "attack"
	if is_instance_valid(sprite) and sprite.sprite_frames.has_animation("special"):
		anim_name = "special"
	if is_instance_valid(sprite) and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	controller.spawn_party_projectile(self, Vector2(facing, 0.0), "pierce_arrow")
	return true

func _cast_teleport() -> bool:
	special_cooldown = special_cooldown_max
	attack_lock_timer = 0.35
	if is_instance_valid(sprite) and sprite.sprite_frames.has_animation("special"):
		sprite.play("special")
	controller.teleport_actor(self, facing)
	return true

func _play_attack() -> void:
	attack_lock_timer = attack_cooldown_max
	if is_instance_valid(sprite) and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")

func take_damage(amount: int, source = null) -> void:
	if not alive:
		return

	# Apenas o aliado controlado participa do risco de combate; seguidores
	# inativos ficam protegidos ate serem selecionados.
	if team == "ally" and not is_controlled:
		return
	if source != null and source.team == team:
		return

	hp = maxi(0, hp - amount)
	hurt_lock_timer = 0.28
	if is_instance_valid(sprite):
		if sprite.sprite_frames.has_animation("hurt"):
			sprite.play("hurt")
		sprite.modulate = base_modulate * Color(1.0, 0.45, 0.45)
	_spawn_hit_effect()
	if hp <= 0:
		_die()

func _spawn_hit_effect() -> void:
	var parent := get_parent()
	if not is_instance_valid(parent):
		return
	var fx := HitEffect.instantiate()
	parent.add_child(fx)
	var shape_y: float = ROLE_BODY.get(role, {}).get("shape_y", -15.0)
	fx.global_position = global_position + Vector2(0.0, shape_y)

func force_kill() -> void:
	if not alive:
		return
	hp = 0
	_die()

func _die() -> void:
	alive = false
	is_controlled = false
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	queue_redraw()
	if is_instance_valid(sprite) and sprite.sprite_frames.has_animation("death"):
		sprite.modulate = base_modulate
		sprite.play("death")
	else:
		visible = false
	died.emit(self)

func _on_animation_finished() -> void:
	if not is_instance_valid(sprite):
		return
	if not alive:
		if sprite.animation == "death":
			visible = false
		return
	if sprite.animation == "hurt":
		sprite.modulate = base_modulate

func _update_animation() -> void:
	if not is_instance_valid(sprite) or not alive:
		return
	var faces_left: bool = ROLE_FACES_LEFT.get(role, false)
	sprite.flip_h = (facing < 0.0) != faces_left

	if attack_lock_timer > 0.0 or hurt_lock_timer > 0.0:
		return

	var frames := sprite.sprite_frames
	if not is_on_floor() and frames.has_animation("jump") and frames.has_animation("fall"):
		if velocity.y < 0.0:
			if sprite.animation != "jump":
				sprite.play("jump")
		else:
			if sprite.animation != "fall":
				sprite.play("fall")
		return

	if absf(velocity.x) > 6.0:
		if sprite.animation != "move":
			sprite.play("move")
	else:
		if sprite.animation != "idle":
			sprite.play("idle")

func _draw() -> void:
	if not alive:
		return

	if is_controlled and team == "ally":
		draw_arc(Vector2(0, -3), 12.0, 0.0, TAU, 28, Color("ffe26f"), 1.5)

	if team == "ally":
		# Pedido do usuario: a barrinha flutuante em cima da cabeca ficou
		# redundante pros personagens jogaveis depois que o grupo ganhou os
		# medidores verticais fixos na borda esquerda (PartyHpBars12) —
		# inimigos/bosses continuam mostrando a propria aqui.
		return

	var ratio := float(hp) / float(max_hp)
	var bar_y: float = ROLE_BODY[role]["shape_y"] - float(ROLE_BODY[role]["height"]) * 0.5 - 8.0
	var bar_w := 24.0
	var bar_h := 5.0
	var bar_rect := Rect2(-bar_w * 0.5, bar_y, bar_w, bar_h)
	draw_texture_rect(HEALTH_BAR_TEX, bar_rect, false)

	# health_bar.png ja vem 100% cheia (sem variante vazia no pack) — em vez
	# de recortar o preenchimento, cobrimos a fatia NAO preenchida com a
	# mesma cor escura do fundo do proprio sprite, "esvaziando" da direita
	# para a esquerda conforme o HP cai.
	var inset_x := bar_w * 0.09
	var inset_y := bar_h * 0.143
	var interior_w: float = bar_w - inset_x * 2.0
	var interior_h: float = bar_h - inset_y * 2.0
	var empty_w: float = interior_w * (1.0 - ratio)
	if empty_w > 0.0:
		draw_rect(
			Rect2(bar_rect.position.x + inset_x + (interior_w - empty_w), bar_rect.position.y + inset_y, empty_w, interior_h),
			Color("2c1a1c")
		)
