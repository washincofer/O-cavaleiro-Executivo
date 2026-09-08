extends RefCounted
class_name PartyHpBars12

## Barras verticais estilo Mega Man X.
## RC2: como o canon passou a usar 60-100 HP, cada bloco visual representa
## 5 HP. Assim a barra vai de 12 a 20 blocos sem estourar a tela.

const HP_PER_SEGMENT := 5
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

static func build(canvas: CanvasLayer, party_slots: Array, top_y: float, tint_for: Callable) -> Array:
	var bars: Array = []
	var y := top_y
	for member in party_slots:
		if not is_instance_valid(member):
			continue
		var max_hp: int = max(member.max_hp, 1)
		var segment_count := maxi(1, ceili(float(max_hp) / float(HP_PER_SEGMENT)))
		var inner_h: float = float(segment_count) * SEGMENT_H + float(segment_count - 1) * SEGMENT_GAP
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
		for i in range(segment_count):
			var seg := ColorRect.new()
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
			"tint": tint,
		})
		y += outer_size.y + 8.0 + BAR_GAP

	return bars

static func update(bars: Array, active_actor: PlatformPartyActor12) -> void:
	for entry in bars:
		var member: PlatformPartyActor12 = entry["member"]
		if not is_instance_valid(member):
			continue
		var segments: Array = entry["segments"]
		var tint: Color = entry.get("tint", Color("ffe26f"))
		for i in range(segments.size()):
			var seg: ColorRect = segments[i]
			var threshold := i * HP_PER_SEGMENT
			seg.color = tint if member.alive and member.hp > threshold else EMPTY_COLOR

		var border: ColorRect = entry["border"]
		border.color = BORDER_COLOR_ACTIVE if member == active_actor and member.alive else BORDER_COLOR_IDLE

		var label: Label = entry["label"]
		label.add_theme_color_override("font_color", LABEL_COLOR_ALIVE if member.alive else LABEL_COLOR_DEAD)