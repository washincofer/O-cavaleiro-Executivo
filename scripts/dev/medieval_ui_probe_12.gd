extends Control

## Sprint 16 dev-only probe: renderiza o painel de madeira e botoes claro/
## escuro do MedievalUI12 em alguns tamanhos (nativo e esticado) pra
## conferir visualmente que o 9-patch dos botoes nao distorce os cantos e
## que o painel escala sem esticar a corrente. Nao faz parte do fluxo
## publicado.

func _ready() -> void:
	custom_minimum_size = Vector2(320, 180)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("2a2f3a")
	add_child(bg)

	var panel := MedievalUI12.make_panel()
	panel.position = Vector2(8, 8)
	panel.size = Vector2(71, 92)
	add_child(panel)

	var panel_small := MedievalUI12.make_panel()
	panel_small.position = Vector2(90, 8)
	panel_small.size = Vector2(36, 46)
	add_child(panel_small)

	var sizes := [Vector2(60, 24), Vector2(20, 16)]
	for i in range(sizes.size()):
		var btn_light := Button.new()
		btn_light.text = "OK"
		btn_light.position = Vector2(140, 8 + i * 36)
		btn_light.focus_mode = Control.FOCUS_NONE
		MedievalUI12.style_button(btn_light, false, null, 0, Color("f4e7c9"), sizes[i])
		add_child(btn_light)

		var btn_dark := Button.new()
		btn_dark.text = "OK"
		btn_dark.position = Vector2(140 + sizes[i].x + 10, 8 + i * 36)
		btn_dark.focus_mode = Control.FOCUS_NONE
		MedievalUI12.style_button(btn_dark, true, null, 0, Color("f4e7c9"), sizes[i])
		add_child(btn_dark)

	var wide_btn := Button.new()
	wide_btn.text = "COMECAR"
	wide_btn.position = Vector2(140, 80)
	wide_btn.focus_mode = Control.FOCUS_NONE
	MedievalUI12.style_button(wide_btn, true, null, 0, Color("f4e7c9"), Vector2(128, 28))
	add_child(wide_btn)

	var icon_names := ["gear", "speaker", "speaker_mute", "lock", "check", "x"]
	for i in range(icon_names.size()):
		var icon := TextureRect.new()
		icon.texture = MedievalUI12.icon_texture(icon_names[i])
		icon.position = Vector2(8 + i * 20, 120)
		icon.size = Vector2(14, 16)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(icon)

	print("PROBE medieval_ui ready")
