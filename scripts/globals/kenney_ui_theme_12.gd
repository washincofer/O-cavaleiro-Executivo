extends RefCounted
class_name KenneyUI12

## Reskin pos-16 (pedido do usuario, com imagem de referencia + zip do pack
## Kenney "Fantasy UI Borders"): paineis escuros com moldura branca em
## cantos-colchete, botao "Accept quest" solido branco com a mesma moldura,
## divisores com ponta de diamante, tipografia Aoboshi One — substitui
## MedievalUI12 (madeira/pergaminho) em toda a UI do jogo.
##
## `panel_fill.png`/`panel_border.png` sao o par casado
## `PNG/Double/Panel/panel-002.png` + `Border/panel-border-002.png` do pack:
## fill.png e um preenchimento solido branco (webbed com os recortes dos
## colchetes, pensado pra ser tingido via `modulate`); border.png e so o
## contorno (centro transparente), pensado pra ficar por cima em branco puro
## como acento. Medido por pixel (nao suposto): moldura simetrica nos 4
## lados com margem de 28px num tile de 96x96.
const PANEL_FILL_TEX := preload("res://assets/UI/Runtime/KenneyBorders/panel_fill.png")
const PANEL_BORDER_TEX := preload("res://assets/UI/Runtime/KenneyBorders/panel_border.png")
const DIVIDER_TEX := preload("res://assets/UI/Runtime/KenneyBorders/divider.png")
const FONT_PATH := "res://assets/Fonts/Runtime/AoboshiOne-Regular.ttf"

const MARGIN := 28

# Variante reduzida (36x36, moldura de 10px — mesma proporcao 28/96 da
# textura original) pro chrome pequeno: a este jogo roda a 320x180/180x320,
# a maioria dos botoes/etiquetas tem so 10-30px de altura, bem menor que os
# 2x28=56px que a moldura em tamanho cheio precisa pra nao "estourar" pra
# fora da caixa (NinePatchRect nao recorta os cantos quando a caixa e menor
# que a margem) — usada por `make_panel_small()`/`style_button()`.
const SMALL_PANEL_FILL_TEX := preload("res://assets/UI/Runtime/KenneyBorders/panel_fill_small.png")
const SMALL_PANEL_BORDER_TEX := preload("res://assets/UI/Runtime/KenneyBorders/panel_border_small.png")
const SMALL_MARGIN := 10

const PANEL_TINT := Color(0.08, 0.09, 0.12, 0.88)
const TEXT_COLOR := Color("f4ecd8")
const ACCENT_COLOR := Color("ffe26f")
const BUTTON_DARK_TEXT := Color("1c1c22")

static func font() -> FontFile:
	return load(FONT_PATH)

## Painel escuro com moldura branca em colchetes (fundo de dialogo, HUD,
## menu de pausa etc). `tint` sobrescreve a cor de preenchimento padrao.
## Escolhe automaticamente a variante de moldura (cheia ou pequena) pelo
## menor lado do painel, pra moldura nunca "estourar" pra fora da caixa.
static func make_panel(size: Vector2, tint: Color = PANEL_TINT) -> Control:
	var use_small: bool = min(size.x, size.y) < 56.0
	var fill_tex := SMALL_PANEL_FILL_TEX if use_small else PANEL_FILL_TEX
	var border_tex := SMALL_PANEL_BORDER_TEX if use_small else PANEL_BORDER_TEX
	var margin: int = SMALL_MARGIN if use_small else MARGIN

	var holder := Control.new()
	holder.custom_minimum_size = size
	holder.size = size
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var fill := NinePatchRect.new()
	fill.texture = fill_tex
	fill.modulate = tint
	fill.patch_margin_left = margin
	fill.patch_margin_right = margin
	fill.patch_margin_top = margin
	fill.patch_margin_bottom = margin
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.size = size
	holder.add_child(fill)

	var border := NinePatchRect.new()
	border.texture = border_tex
	border.modulate = Color.WHITE
	border.patch_margin_left = margin
	border.patch_margin_right = margin
	border.patch_margin_top = margin
	border.patch_margin_bottom = margin
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.size = size
	holder.add_child(border)

	return holder

## Botao "Accept quest": preenchimento solido branco + moldura em colchetes,
## texto escuro. `primary = false` gera a variante fantasma (so a moldura,
## sem preenchimento, texto claro) usada pra acoes secundarias.
static func style_button(btn: Button, primary: bool = true, font_size: int = 10, size: Vector2 = Vector2.ZERO) -> void:
	btn.add_theme_font_override("font", font())
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", BUTTON_DARK_TEXT if primary else TEXT_COLOR)
	btn.add_theme_color_override("font_hover_color", BUTTON_DARK_TEXT if primary else ACCENT_COLOR)
	btn.add_theme_color_override("font_pressed_color", BUTTON_DARK_TEXT if primary else ACCENT_COLOR)

	var normal := StyleBoxTexture.new()
	normal.texture = SMALL_PANEL_FILL_TEX if primary else SMALL_PANEL_BORDER_TEX
	normal.modulate_color = Color.WHITE if primary else Color(1, 1, 1, 0.85)
	normal.texture_margin_left = SMALL_MARGIN
	normal.texture_margin_right = SMALL_MARGIN
	normal.texture_margin_top = SMALL_MARGIN
	normal.texture_margin_bottom = SMALL_MARGIN

	var hover := StyleBoxTexture.new()
	hover.texture = normal.texture
	hover.modulate_color = Color("ffe26f") if primary else Color(1, 1, 1, 1)
	hover.texture_margin_left = SMALL_MARGIN
	hover.texture_margin_right = SMALL_MARGIN
	hover.texture_margin_top = SMALL_MARGIN
	hover.texture_margin_bottom = SMALL_MARGIN

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	# size por ultimo — StyleBoxTexture com texture_margin so entra no calculo
	# de minimum_size depois de atribuido ao Button, entao setar antes evita
	# o Control ficar "preso" num minimum_size inflado.
	if size != Vector2.ZERO:
		btn.custom_minimum_size = size
		btn.size = size

## Linha divisora com ponta de diamante ao centro (duas metades espelhadas),
## do jeito que aparece na imagem de referencia entre secoes de texto.
static func make_divider(width: float) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(width, 18)
	holder.size = Vector2(width, 18)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var half_w := width * 0.5

	var left := TextureRect.new()
	left.texture = DIVIDER_TEX
	left.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	left.stretch_mode = TextureRect.STRETCH_SCALE
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.position = Vector2(0, 0)
	left.size = Vector2(half_w, 18)
	holder.add_child(left)

	var right := TextureRect.new()
	right.texture = DIVIDER_TEX
	right.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	right.stretch_mode = TextureRect.STRETCH_SCALE
	right.flip_h = true
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.position = Vector2(half_w, 0)
	right.size = Vector2(half_w, 18)
	holder.add_child(right)

	return holder

## Label com a tipografia nova (titulo ou corpo — Aoboshi One serve pros
## dois papeis na imagem de referencia, so muda o tamanho/cor).
static func style_label(lbl: Label, font_size: int = 8, color: Color = TEXT_COLOR) -> void:
	lbl.add_theme_font_override("font", font())
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
