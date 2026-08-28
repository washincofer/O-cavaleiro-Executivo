extends RefCounted
class_name MedievalUI12

## Sprint 16: helper compartilhado de skin do pack Medieval Free (recortado
## de MediavelFree.png em scripts/dev/ na sessao de extracao) — painel de
## madeira pendurado, botoes arredondados (claro/escuro) e icones planos.
## Usado tanto no layout paisagem quanto no retrato dos 5 menus e do HUD/
## pausa de cada fase, no lugar dos ColorRect/StyleBoxFlat lisos herdados
## das sprints anteriores. Sem estado proprio (RefCounted + funcoes static),
## nao precisa de autoload — chama-se `MedievalUI12.algo()` de qualquer
## lugar.

const PANEL_TEX := preload("res://assets/UI/Runtime/MedievalFree/panel.png")
const BUTTON_LIGHT_TEX := preload("res://assets/UI/Runtime/MedievalFree/button_light.png")
const BUTTON_DARK_TEX := preload("res://assets/UI/Runtime/MedievalFree/button_dark.png")

const ICON_DIR := "res://assets/UI/Runtime/MedievalFree/"

# Margem do 9-patch dos botoes: a moldura escura arredondada do sprite tem
# ~4px de espessura em cada lado (17x16 original) — manter essa margem fixa
# ao esticar preserva os cantos arredondados em qualquer tamanho de botao.
const BUTTON_MARGIN := 4


## StyleBoxTexture pronto pra qualquer Button, esticando so o miolo do
## sprite (9-patch) e preservando a moldura/cantos arredondados.
static func button_stylebox(dark: bool = false) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = BUTTON_DARK_TEX if dark else BUTTON_LIGHT_TEX
	sb.texture_margin_left = BUTTON_MARGIN
	sb.texture_margin_right = BUTTON_MARGIN
	sb.texture_margin_top = BUTTON_MARGIN
	sb.texture_margin_bottom = BUTTON_MARGIN
	return sb


## Aplica a moldura Medieval Free num Button existente (normal/hover/
## pressed/focus todos com a mesma StyleBoxTexture — o pack nao tem um
## sprite de "pressionado" separado pros botoes em branco) e, opcionalmente,
## a fonte/cor de texto.
##
## `size`, se informado, e aplicado via `set_deferred` de proposito: setar
## `btn.size` na hora, mesmo depois do texto/fonte/tema, nao e confiavel —
## o Button recalcula seu minimum_size durante a resolucao do tema (as
## vezes passando por um valor maior transitorio antes de assentar no
## definitivo) e o Control nunca encolhe sozinho abaixo do maior valor ja
## visto. Adiar pro fim do frame garante que o tamanho final seja aplicado
## depois que tudo (tema, fonte, entrada na tree) ja assentou.
static func style_button(btn: Button, dark: bool = false, font: Font = null, font_size: int = 0, font_color: Color = Color("f4e7c9"), size: Vector2 = Vector2.ZERO) -> void:
	var sb := button_stylebox(dark)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus", sb)
	btn.add_theme_stylebox_override("disabled", sb)
	if font:
		btn.add_theme_font_override("font", font)
	if font_size > 0:
		btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", font_color)
	btn.add_theme_color_override("font_disabled_color", font_color.darkened(0.4))
	if size != Vector2.ZERO:
		btn.set_deferred("size", size)


## Painel de madeira pendurado (fundo de dialogo/titulo), em tamanho nativo
## (71x92) escalado uniformemente — nao e 9-patch porque a corrente no topo
## nao pode ser esticada sem distorcer; quem usa deve escolher um tamanho
## que caiba numa area proxima da proporcao 71:92 (mais alto que largo).
static func make_panel() -> TextureRect:
	var panel := TextureRect.new()
	panel.texture = PANEL_TEX
	panel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


## Icones planos (icon_check.png, icon_gear.png, etc) pra toggles/HUD —
## carregados sob demanda (poucos usos por tela, nao justifica preload de
## todos os 12 de antemao).
static func icon_texture(icon_name: String) -> Texture2D:
	return load("%sicon_%s.png" % [ICON_DIR, icon_name])
