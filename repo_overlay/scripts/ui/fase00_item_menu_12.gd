extends Control
class_name Fase00ItemMenu12

## Tela de seleção de itens ao apertar Esc.
## Deve abrir como overlay pausando a Fase 00.

const BG_COLOR := Color(0, 0, 0, 0.55)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		visible = not visible
		get_tree().paused = visible
		if visible:
			grab_focus()

func build_placeholder() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.22
	panel.anchor_top = 0.14
	panel.anchor_right = 0.78
	panel.anchor_bottom = 0.86
	add_child(panel)

	var vb := VBoxContainer.new()
	panel.add_child(vb)

	var title := Label.new()
	title.text = "Seleção de Itens"
	vb.add_child(title)

	for item_name in ["Power Life", "Reviver Companion", "1 Vida", "E-Tank"]:
		var hb := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = item_name
		hb.add_child(name_label)
		var qty := Label.new()
		qty.text = "x0"
		hb.add_child(qty)
		vb.add_child(hb)
