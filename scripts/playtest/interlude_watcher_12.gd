extends Node

## Node auxiliar PROCESS_MODE_ALWAYS que escuta qualquer clique/tecla/toque
## mesmo com a SceneTree pausada — mesmo padrao de pause_watcher_12.gd, so
## que reagindo a QUALQUER input (nao so ui_cancel). Usado pelos dialogos de
## "interlude" no meio de uma luta de boss (troca de fase, pedido do
## usuario: NECROMANTE tem a vida dividida em 3 partes, cada uma terminando
## num dialogo estilo visual novel que pausa o jogo).

signal advance_requested

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	var advance := false
	if event is InputEventKey and event.pressed and not event.echo:
		advance = true
	elif event is InputEventMouseButton and event.pressed:
		advance = true
	elif event is InputEventScreenTouch and event.pressed:
		advance = true
	if advance:
		advance_requested.emit()
		get_viewport().set_input_as_handled()
