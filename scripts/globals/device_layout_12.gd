extends Node

## Sprint 16: autoload que decide se o jogo roda em retrato (celular em
## pe) ou paisagem (o padrao usado ate aqui), comparando so altura x
## largura da janela/canvas atual — sem checar touch, porque
## `TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY` ja esconde os
## controles touch sozinho em quem nao tem touch; misturar os dois so
## criaria um caso estranho (desktop estreito sem touch ficando preso no
## layout paisagem apertado).
##
## Aplica a resolucao base certa (`content_scale_size`) antes da primeira
## cena (`company_intro_12`) rodar seu `_ready()` — autoloads rodam antes
## da cena principal, entao isso e seguro sem corrida.
##
## Como este projeto so tem export Web (sem preset Android/iOS — o
## `window/handheld/orientation` do project.godot e inerte aqui), girar o
## aparelho ou redimensionar a janela do navegador e um evento comum, nao
## excecao: reescuta `size_changed` e reemite `layout_changed` quando a
## ORIENTACAO muda de verdade (nao qualquer resize) para as telas de menu
## se realimentarem. Fases jogaveis leem `is_portrait` uma unica vez no
## `_ready()` e ignoram giros no meio da partida ate `R`/trocar de fase —
## decisao deliberada (ver PLANO da Sprint 16): refazer layout no meio de
## uma luta sem perder HP/estado do puzzle e um problema bem maior que
## este autoload deveria resolver sozinho.

signal layout_changed

const LANDSCAPE_SIZE := Vector2i(320, 180)
const PORTRAIT_SIZE := Vector2i(180, 320)

var is_portrait: bool = false

func _ready() -> void:
	_update_layout(true)
	get_window().size_changed.connect(_on_window_size_changed)

func _on_window_size_changed() -> void:
	_update_layout(false)

func _update_layout(is_boot: bool) -> void:
	var win := get_window()
	var size: Vector2i = win.size
	var next_is_portrait: bool = size.y > size.x
	if not is_boot and next_is_portrait == is_portrait:
		return
	is_portrait = next_is_portrait
	win.content_scale_size = PORTRAIT_SIZE if is_portrait else LANDSCAPE_SIZE
	if not is_boot:
		layout_changed.emit()
