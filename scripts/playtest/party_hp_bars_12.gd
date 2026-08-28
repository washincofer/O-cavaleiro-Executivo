extends RefCounted
class_name PartyHpBars12

## Pedido do usuario com imagem de referencia (Mega Man X): barras de vida
## verticais coladas na borda esquerda da tela, uma por integrante do grupo
## (em vez do texto "nome[hp]" na faixa superior e da barrinha flutuante em
## cima da cabeca de cada um, que continua existindo so pra combate visual
## rapido). Cada barra e "segmentada" (1 bloco = 1 ponto de vida, igual ao
## medidor do X), com moldura branca e uma letra do papel embaixo. O membro
## atualmente controlado ganha moldura em destaque (ACCENT_COLOR); os
## outros ficam em branco apagado; um membro morto fica com a barra vazia e
## a letra escurecida.

const SEGMENT_W := 5.0
const SEGMENT_H := 3.0
const SEGMENT_GAP := 1.0
const BAR_PAD := 1.0
const BAR_GAP := 7.0
const BORDER_COLOR_ACTIVE := Color("ffe26f")
const BORDER_COLOR_IDLE := Color(1, 1, 1, 0.55)
const BG_COLOR := Color(0.05, 0.05, 0.07, 0.9)
const EMPTY_COLOR := Color(0.18, 0.18, 0.2, 0.9)
const LABEL_COLOR_ALIVE := Color("f4ecd8")
const LABEL_COLOR_DEAD := Color(0.4, 0.4, 0.42, 0.8)

## Monta as barras (uma por slot valido de `party_slots`) dentro do
## `canvas`, empilhadas a partir de `top_y` na borda esquerda. `tint_for`
## e um Callable(role: String) -> Color usado pra colorir os segmentos
## cheios com a mesma cor de identidade do papel (ROLE_TINT de cada fase).
## Devolve a lista de referencias que `update()` precisa a cada frame.
static func build(canvas: CanvasLayer, party_slots: Array, top_y: float, tint_for: Callable) -> Array:
	var bars: Array = []
	var y := top_y
	for member in party_slots:
		if not is_instance_valid(member):
			continue
		var max_hp: int = max(member.max_hp, 1)
		var inner_h: float = float(max_hp) * SEGMENT_H + float(max_hp - 1) * SEGMENT_GAP
		var inner_w: float = SEGMENT_W
		var outer_size := Vector2(inner_w + BAR_PAD * 2.0, inner_h + BAR_PAD * 2.0)

		var border := ColorRect.new()
		border.position = Vector2(4, y)
		border.size = outer_size
		border.color = BORDER_COLOR_IDLE
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(border)

		var bg := ColorRect.new()
		bg.position = border.position + Vector2(BAR_PAD, BAR_PAD)
		bg.size = Vector2(inner_w, inner_h)
		bg.color = BG_COLOR
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(bg)

		var tint: Color = tint_for.call(member.role) if tint_for.is_valid() else Color("ffe26f")
		var segments: Array = []
		for i in range(max_hp):
			var seg := ColorRect.new()
			# segmento 0 = base da barra (empilha de baixo pra cima, igual ao
			# medidor do X esvaziando de cima quando toma dano).
			var seg_y: float = bg.position.y + inner_h - float(i + 1) * SEGMENT_H - float(i) * SEGMENT_GAP
			seg.position = Vector2(bg.position.x, seg_y)
			seg.size = Vector2(inner_w, SEGMENT_H)
			seg.color = tint
			seg.mouse_filter = Control.MOUSE_FILTER_IGNORE
			canvas.add_child(seg)
			segments.append(seg)

		var label := Label.new()
		label.text = member.actor_name.substr(0, 1)
		label.add_theme_font_size_override("font_size", 6)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", LABEL_COLOR_ALIVE)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		label.add_theme_constant_override("outline_size", 2)
		label.position = Vector2(border.position.x - 2.0, border.position.y + outer_size.y + 1.0)
		label.custom_minimum_size = Vector2(outer_size.x + 4.0, 8)
		label.size = Vector2(outer_size.x + 4.0, 8)
		canvas.add_child(label)

		bars.append({
			"member": member,
			"border": border,
			"segments": segments,
			"label": label,
		})
		y += outer_size.y + 8.0 + BAR_GAP

	return bars

## Chamado todo frame (junto do resto de `_update_hud()`): acende/apaga
## segmentos conforme o HP atual e realca a moldura do membro ativo.
static func update(bars: Array, active_actor: PlatformPartyActor12) -> void:
	for entry in bars:
		var member: PlatformPartyActor12 = entry["member"]
		if not is_instance_valid(member):
			continue
		var segments: Array = entry["segments"]
		for i in range(segments.size()):
			var seg: ColorRect = segments[i]
			seg.visible = member.alive and i < member.hp
			if not seg.visible:
				seg.color = EMPTY_COLOR
				seg.visible = true

		var border: ColorRect = entry["border"]
		border.color = BORDER_COLOR_ACTIVE if member == active_actor and member.alive else BORDER_COLOR_IDLE

		var label: Label = entry["label"]
		label.add_theme_color_override("font_color", LABEL_COLOR_ALIVE if member.alive else LABEL_COLOR_DEAD)
