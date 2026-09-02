extends RefCounted
class_name CorporateUI12

## Kit de UI novo (dourado/azul, brasao "C") pedido pelo usuario com imagens
## de referencia — usado SO nas telas novas (Fase 00, Menu Principal, tela
## de Salvar/Carregar e Fase 01), nunca nas 5 fases de chefe ja existentes
## nem nas telas de selecao, que continuam com MedievalUI12 (o usuario ja
## pediu pra reverter um reskin completo antes; isolar o kit novo evita
## repetir esse problema).
##
## Diferente do MedievalUI12 (StyleBoxTexture 9-patch recortado de um botao
## generico), os botoes aqui sao StyleBoxFlat desenhados em codigo: toda a
## arte de referencia do kit vem com texto de exemplo already-baked-in nos
## proprios pixels ("Confirmar", "Protagonista", "Opção 1"...), entao nao
## existe um sprite de botao vazio pra recortar sem herdar aquele texto —
## StyleBoxFlat da a mesma linguagem visual (borda dourada, miolo azul
## marinho) pra qualquer texto/tamanho sem esse problema.
##
## Sem estado proprio (RefCounted + funcoes static) — chama-se
## `CorporateUI12.algo()` de qualquer lugar, sem autoload.

const DIALOGUE_PANEL_TEX := preload("res://assets/UI/Runtime/CorporateUI/dialogue_panel.png")
const HP_FRAME_PROTAGONIST_TEX := preload("res://assets/UI/Runtime/CorporateUI/hp_frame_protagonist.png")
const HP_FRAME_C1_TEX := preload("res://assets/UI/Runtime/CorporateUI/hp_frame_c1.png")
const HP_FRAME_C2_TEX := preload("res://assets/UI/Runtime/CorporateUI/hp_frame_c2.png")
const HP_FRAME_BOSS_TEX := preload("res://assets/UI/Runtime/CorporateUI/hp_frame_boss.png")

const GOLD := Color("d4af37")
const GOLD_DARK := Color("8a6d1f")
const NAVY := Color("14213d")
const NAVY_LIGHT := Color("1f3a63")
const CREAM := Color("f2e8cf")


## StyleBoxFlat dourado/azul pronto pra qualquer Button. `dark` troca o
## preenchimento por um azul mais escuro (uso secundario/cancelar), igual
## ao par claro/escuro que MedievalUI12.style_button ja oferece.
static func button_stylebox(dark: bool = false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = NAVY.darkened(0.25) if dark else NAVY_LIGHT
	sb.border_color = GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(6)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 3
	return sb


## Mesma assinatura de MedievalUI12.style_button, pro chamador poder trocar
## de kit sem mudar a forma de chamar.
static func style_button(btn: Button, dark: bool = false, font: Font = null, font_size: int = 0, font_color: Color = CREAM, size: Vector2 = Vector2.ZERO) -> void:
	var normal := button_stylebox(dark)
	var pressed := button_stylebox(dark)
	pressed.bg_color = pressed.bg_color.darkened(0.2)
	var hover := button_stylebox(dark)
	hover.bg_color = hover.bg_color.lightened(0.1)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", normal)
	btn.add_theme_stylebox_override("disabled", normal)
	if font:
		btn.add_theme_font_override("font", font)
	if font_size > 0:
		btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", font_color)
	btn.add_theme_color_override("font_disabled_color", font_color.darkened(0.4))
	if size != Vector2.ZERO:
		btn.set_deferred("size", size)


## Painel ornamentado (moldura dourada + faixa azul com brasao no topo,
## corpo em pergaminho) usado como fundo do balao de dialogo da Fase 00.
## 9-patch com margem generosa pra preservar os cantos/faixa sem esticar.
static func make_dialogue_panel() -> NinePatchRect:
	var panel := NinePatchRect.new()
	panel.texture = DIALOGUE_PANEL_TEX
	panel.patch_margin_left = 40
	panel.patch_margin_right = 40
	panel.patch_margin_top = 58
	panel.patch_margin_bottom = 24
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


## Moldura de HP ornamentada. `kind` e "protagonist", "c1", "c2" ou "boss" —
## a arte de cada uma ja vem com o retrato/selo certo (P/C1/C2/BOSS).
static func hp_frame_texture(kind: String) -> Texture2D:
	match kind:
		"c1":
			return HP_FRAME_C1_TEX
		"c2":
			return HP_FRAME_C2_TEX
		"boss":
			return HP_FRAME_BOSS_TEX
		_:
			return HP_FRAME_PROTAGONIST_TEX
