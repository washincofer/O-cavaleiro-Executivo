extends RefCounted
class_name AbilityCooldownHud12

## HUD nova pedida pelo usuario (imagem de referencia de uma barra de
## cooldown ornamentada) — ate agora `special_cooldown`/`special_cooldown_max`
## (platform_actor_12.gd) eram só timers internos, sem nenhuma
## representação visual. Segue o mesmo padrão de "slot por integrante do
## grupo" de PartyHpBars12 (build()/update(), Array de Dictionary com as
## referencias), pra plugar ao lado de cada barra de vida vertical sem
## duplicar layout.
##
## Deliberadamente feita com ColorRect simples (não a textura ornamentada
## de CorporateUI12) — a barra de vida do grupo já é minúscula (5px de
## largura por segmento); a arte ornamentada de referência, reduzida a essa
## escala, vira um borrão ilegível. Fica reservada pra HUDs com mais espaço
## de tela (Fase 00 solo, por exemplo). Isso também mantém a HUD das 5 fases
## de chefe já existentes visualmente como estava — só ganha uma barrinha
## nova, sem repintar o que já existe.

const BAR_W := 16.0
const BAR_H := 2.0
const BORDER_COLOR := Color(1, 1, 1, 0.4)
const BG_COLOR := Color(0.05, 0.05, 0.07, 0.9)
const READY_COLOR := Color("6fd3ff")
const CHARGING_COLOR := Color(0.3, 0.55, 0.65, 0.9)

## Monta uma barrinha por entrada de `hp_bars` — o Array de Dictionary que
## `PartyHpBars12.build()` acabou de devolver (chamar logo em seguida, no
## mesmo lugar). Reaproveita `entry["border"]` de cada barra de vida pra se
## posicionar coladinha à direita dela, sem o chamador precisar recalcular
## nenhuma coordenada. Devolve a lista que `update()` precisa.
static func build(canvas: CanvasLayer, hp_bars: Array) -> Array:
	var bars: Array = []
	for hp_entry in hp_bars:
		var member = hp_entry["member"]
		if not is_instance_valid(member):
			continue
		var hp_border: ColorRect = hp_entry["border"]
		var pos := hp_border.position + Vector2(hp_border.size.x + 3.0, 0.0)

		var border := ColorRect.new()
		border.position = pos
		border.size = Vector2(BAR_W + 2.0, BAR_H + 2.0)
		border.color = BORDER_COLOR
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(border)

		var bg := ColorRect.new()
		bg.position = border.position + Vector2(1, 1)
		bg.size = Vector2(BAR_W, BAR_H)
		bg.color = BG_COLOR
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(bg)

		var fill := ColorRect.new()
		fill.position = bg.position
		fill.size = Vector2(BAR_W, BAR_H)
		fill.color = READY_COLOR
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(fill)

		bars.append({"member": member, "bg": bg, "fill": fill})
	return bars


## Chamado todo frame junto de PartyHpBars12.update(): a barra enche da
## esquerda pra direita conforme `special_cooldown` esfria, ficando cheia
## (READY_COLOR) quando a habilidade está pronta pra usar de novo.
static func update(bars: Array) -> void:
	for entry in bars:
		var member = entry["member"]
		if not is_instance_valid(member):
			continue
		var fill: ColorRect = entry["fill"]
		var bg: ColorRect = entry["bg"]
		var max_cd: float = maxf(member.special_cooldown_max, 0.001)
		var ratio: float = 1.0 - clampf(member.special_cooldown / max_cd, 0.0, 1.0)
		fill.size = Vector2(bg.size.x * ratio, bg.size.y)
		fill.color = READY_COLOR if ratio >= 1.0 else CHARGING_COLOR
		fill.visible = member.alive
		bg.visible = member.alive
