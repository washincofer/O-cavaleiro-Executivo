extends Node

## RC2 canonico — reaproveita o antigo tile runtime de Docas como Fase 02.
## A constante STAGES original fica intocada para reduzir risco de regressao
## na UI; em runtime o botao e reconectado para a cena oficial de Tecnologia.

const STAGE_SELECT_SCENE := "res://scenes/menu/stage_select_12.tscn"
const CHARACTER_SELECT_SCENE := "res://scenes/menu/character_select_12.tscn"
const TECHNOLOGY_SCENE := "res://scenes/playtest/platform_fase02_tecnologia_12.tscn"
const LEGACY_DOCAS_PREVIEW := "res://assets/Backgrounds/Runtime/FaseLogistica/l01_docas_recebimento.png"

var handled_id := 0

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path != STAGE_SELECT_SCENE:
		return
	var sid := scene.get_instance_id()
	if handled_id == sid:
		return
	handled_id = sid
	call_deferred("_repurpose_tile", scene)

func _repurpose_tile(root: Node) -> void:
	await get_tree().process_frame
	for node in _all_descendants(root):
		if node is TextureRect and node.texture != null and node.texture.resource_path == LEGACY_DOCAS_PREVIEW:
			var button := node.get_parent()
			if not (button is Button):
				continue
			button.visible = true
			button.disabled = false
			# Fase01Canon ocultou border/inner do tile legado; restaura os dois.
			var parent := button.get_parent()
			var idx := button.get_index()
			if idx >= 2:
				for n in [parent.get_child(idx - 2), parent.get_child(idx - 1)]:
					if n is CanvasItem:
						n.visible = true
			# Remove callbacks do indice antigo (Docas) e liga Tecnologia.
			for conn in button.get_signal_connection_list("pressed"):
				button.disconnect("pressed", conn["callable"])
			button.pressed.connect(_start_tecnologia)
			for conn in button.get_signal_connection_list("mouse_entered"):
				button.disconnect("mouse_entered", conn["callable"])
			button.mouse_entered.connect(_preview_tecnologia.bind(root, node))
			node.modulate = Color(0.55, 0.92, 1.0, 1.0)
			return

func _preview_tecnologia(root: Node, icon: TextureRect) -> void:
	var preview_label = root.get("preview_label")
	var preview_rect = root.get("preview_rect")
	if preview_label is Label:
		preview_label.text = "TECNOLOGIA"
	if preview_rect is TextureRect and icon.texture != null:
		preview_rect.texture = icon.texture
		preview_rect.modulate = Color(0.55, 0.92, 1.0, 1.0)

func _start_tecnologia() -> void:
	PartySelection12.target_scene = TECHNOLOGY_SCENE
	PartySelection12.loading_title = "CARREGANDO TECNOLOGIA..."
	PartySelection12.selection_mode = PartySelection12.MODE_FREE
	PartySelection12.stage_reward_role = ""
	PartySelection12.required_role = ""
	PartySelection12.pending_dialogue_id = ""
	PartySelection12.pending_dialogue_bg = ""
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)

func _all_descendants(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child in root.get_children():
		if child is Node:
			out.append(child)
			out.append_array(_all_descendants(child))
	return out
