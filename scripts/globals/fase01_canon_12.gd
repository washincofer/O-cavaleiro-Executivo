extends Node

## RC2 canonico — Fase 01 = Operacoes & Logistica completa.
## A antiga entrada separada "Docas do Armazem" e apenas material/trecho
## interno desta mesma fase e deixa de ser uma fase independente no fluxo.
##
## Esta camada injeta os inimigos comuns na cena continua existente sem
## reescrever o controller ja testado (L01-L11, Estevao L06, Grossmanobra L11).

const FASE01_SCENE := "res://scenes/playtest/platform_fase01_operacoes_12.tscn"
const STAGE_SELECT_SCENE := "res://scenes/menu/stage_select_12.tscn"
const DOCAS_PREVIEW := "res://assets/Backgrounds/Runtime/FaseLogistica/l01_docas_recebimento.png"
const PICKUP_SCRIPT := preload("res://scripts/playtest/progression_pickup_12.gd")

# x, nome, role visual, HP efetivo.
# HP segue o canon economico: <3=5 moedas; 3-4=10; 5-7=30; 8-9=50.
# L06 (Estevao) e L11 (Grossmanobra) ficam sem inimigos comuns adicionais.
const ENEMY_LAYOUT := [
	[520.0,  "AUXILIAR DE RECEBIMENTO", "almoxarifado", 2],
	[920.0,  "CONFERENTE",              "protocolo",     3],
	[1160.0, "AUXILIAR DE TRIAGEM",     "almoxarifado", 3],
	[1460.0, "CONFERENTE SENIOR",       "protocolo",     4],
	[1740.0, "OPERADOR DE ARMAZEM",     "almoxarifado", 5],
	[2260.0, "OPERADOR DE CARGA",       "almoxarifado", 5],
	[2780.0, "AUXILIAR DE OPERACOES",   "protocolo",     6],
	[3040.0, "ENCARREGADO DE OPERACOES", "almoxarifado", 7],
	[3900.0, "GUARDA DO NUCLEO",        "protocolo",     5],
	[4200.0, "GUARDA DE RETENCAO",      "almoxarifado", 6],
	[4820.0, "OPERADOR DE EXPEDICAO",   "almoxarifado", 8],
	[5260.0, "GUARDA DA DOCA CENTRAL",  "protocolo",     9],
]

const REVIVE_SAFE_X := [680.0, 1320.0, 1880.0, 2460.0, 2980.0, 4040.0, 4680.0, 5440.0]
const FLOOR_Y := 284.0

var handled_scene_id: int = 0
var stage_select_cleaned_id: int = 0

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var path := scene.scene_file_path
	var sid := scene.get_instance_id()
	if path == FASE01_SCENE and handled_scene_id != sid:
		handled_scene_id = sid
		call_deferred("_configure_fase01", scene)
	elif path == STAGE_SELECT_SCENE and stage_select_cleaned_id != sid:
		stage_select_cleaned_id = sid
		call_deferred("_hide_legacy_docas_tile", scene)

func _configure_fase01(controller: Node) -> void:
	if not is_instance_valid(controller) or not controller.has_method("_spawn_actor"):
		return
	for item in ENEMY_LAYOUT:
		var x := float(item[0])
		var name := String(item[1])
		var role := String(item[2])
		var hp := int(item[3])
		var enemy = controller.call("_spawn_actor", name, "enemy", role, Vector2(x, FLOOR_Y - 12.0), Color.WHITE, -1)
		if is_instance_valid(enemy):
			enemy.set("max_hp", hp)
			enemy.set("hp", hp)

	# Canon: 2-5 Reviver Companion espalhados aleatoriamente por fase.
	var candidates := REVIVE_SAFE_X.duplicate()
	candidates.shuffle()
	var amount := Progression12.random_revive_scatter_count()
	for i in range(mini(amount, candidates.size())):
		_spawn_revive(controller, float(candidates[i]))

	# Primeira conclusao da Fase 01 concede 500 moedas uma unica vez.
	var danelmo := _find_actor_by_role(controller, "danelmo")
	if is_instance_valid(danelmo):
		var cb := Callable(self, "_on_danelmo_died")
		if not danelmo.is_connected("died", cb):
			danelmo.connect("died", cb)

func _spawn_revive(controller: Node, x: float) -> void:
	var parent: Node = controller.get_node_or_null("Actors")
	if parent == null:
		parent = controller
	var pickup := Area2D.new()
	pickup.set_script(PICKUP_SCRIPT)
	pickup.set("kind", "revive_companion")
	pickup.set("amount", 1)
	parent.add_child(pickup)
	pickup.global_position = Vector2(x, FLOOR_Y - 20.0)

func _find_actor_by_role(root: Node, role: String) -> Node:
	var value = root.get("role")
	if value != null and String(value) == role:
		return root
	for child in root.get_children():
		if child is Node:
			var found := _find_actor_by_role(child, role)
			if found != null:
				return found
	return null

func _on_danelmo_died(_actor: Node) -> void:
	Progression12.grant_first_clear_reward("fase01_operacoes_logistica")

func _hide_legacy_docas_tile(root: Node) -> void:
	# O tile existente e identificado pela TextureRect de preview. Na UI atual,
	# border + inner + button sao adicionados em sequencia ao mesmo parent.
	for node in _all_descendants(root):
		if node is TextureRect and node.texture != null and node.texture.resource_path == DOCAS_PREVIEW:
			var button := node.get_parent()
			if button is Button:
				button.disabled = true
				button.visible = false
				var p := button.get_parent()
				var idx := button.get_index()
				if idx >= 2:
					var inner := p.get_child(idx - 1)
					var border := p.get_child(idx - 2)
					if inner is CanvasItem:
						inner.visible = false
					if border is CanvasItem:
						border.visible = false
				return

func _all_descendants(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child in root.get_children():
		if child is Node:
			out.append(child)
			out.append_array(_all_descendants(child))
	return out
