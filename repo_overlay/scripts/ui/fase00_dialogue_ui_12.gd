extends CanvasLayer
class_name Fase00DialogueUi12

## Usa:
## - speech_bubble.png para falas curtas
## - dialogue_panel.png para textos longos

const BUBBLE_TEX := preload("res://assets/UI/Runtime/CorporateUI/speech_bubble.png")
const PANEL_TEX := preload("res://assets/UI/Runtime/CorporateUI/dialogue_panel.png")

func make_short_dialogue(text: String) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	root.offset_left = 80
	root.offset_right = -80
	root.offset_top = -210
	root.offset_bottom = -30

	var bubble := TextureRect.new()
	bubble.texture = BUBBLE_TEX
	bubble.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bubble.stretch_mode = TextureRect.STRETCH_SCALE
	bubble.anchor_right = 1.0
	bubble.anchor_bottom = 1.0
	root.add_child(bubble)

	var label := RichTextLabel.new()
	label.bbcode_enabled = false
	label.fit_content = false
	label.scroll_active = false
	label.anchor_left = 0.08
	label.anchor_top = 0.18
	label.anchor_right = 0.92
	label.anchor_bottom = 0.82
	label.text = text
	root.add_child(label)
	return root

func make_long_dialogue(text: String) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	root.offset_left = 36
	root.offset_right = -36
	root.offset_top = -300
	root.offset_bottom = -24

	var panel := NinePatchRect.new()
	panel.texture = PANEL_TEX
	panel.patch_margin_left = 40
	panel.patch_margin_right = 40
	panel.patch_margin_top = 58
	panel.patch_margin_bottom = 24
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	root.add_child(panel)

	var label := RichTextLabel.new()
	label.bbcode_enabled = false
	label.scroll_active = false
	label.anchor_left = 0.06
	label.anchor_top = 0.18
	label.anchor_right = 0.94
	label.anchor_bottom = 0.86
	label.text = text
	root.add_child(label)
	return root
