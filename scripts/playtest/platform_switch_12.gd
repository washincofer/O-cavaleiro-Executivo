class_name PlatformSwitch12
extends Node2D

## Sprint 12: interruptor do puzzle do portao. Fica suspenso sobre o vao,
## fora de alcance do ataque corpo a corpo — so um projetil (flecha da
## Arqueira ou orbe da Maga) o alcanca.

signal activated

var is_active := false
var pulse := 0.0

func activate() -> void:
	if is_active:
		return
	is_active = true
	activated.emit()

func _process(delta: float) -> void:
	pulse += delta * 5.0
	queue_redraw()

func _draw() -> void:
	var base_color: Color = Color("6fff8f") if is_active else Color("6fd6ff")
	var glow: float = 4.0 + sin(pulse) * 1.2
	draw_circle(Vector2.ZERO, glow + 4.0, Color(base_color.r, base_color.g, base_color.b, 0.25))
	draw_circle(Vector2.ZERO, glow, base_color)
	draw_circle(Vector2.ZERO, glow * 0.4, Color.WHITE)
