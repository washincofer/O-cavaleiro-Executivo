extends Node

## Escuta ESC mesmo com a arvore pausada (o resto do jogo usa o modo de
## processo padrao, que congela normalmente quando a SceneTree pausa).

signal toggle_requested

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_requested.emit()
		get_viewport().set_input_as_handled()
