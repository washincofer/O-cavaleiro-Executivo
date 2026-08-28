extends RefCounted
class_name BossHudPortrait12

## Sprint 16: HUD e menu de pausa em retrato compartilhados pelas 5 salas de
## boss (platform_boss_12.gd + os 4 clones) — o "chrome" (barra de topo,
## nome/vida do boss, aviso de estado, texto de evento, controles touch,
## painel de pausa com instrucoes/botoes) e identico entre elas, so o nome
## do boss e o texto de instrucoes mudam; duplicar isso 5x em retrato (alem
## das 5 versoes paisagem ja existentes) seria um risco real de um arquivo
## ficar desatualizado depois de um ajuste nos outros. A geometria do MUNDO
## (chao/vao/spawn) continua por arquivo — aqui e so o HUD/pausa.
##
## Quem chama guarda as referencias devolvidas nas MESMAS variaveis de
## instancia que o layout paisagem ja usa (`state_label`, `party_label`,
## etc.) — `_update_hud()`/`_toggle_pause()` do controller nao mudam nada,
## so operam em cima de referencias construidas por caminhos diferentes.

const TouchControls := preload("res://scenes/playtest/touch_controls_12.tscn")

const BOSS_BAR_POS := Vector2(10, 30)
const BOSS_BAR_SIZE := Vector2(160, 10)


## Monta a barra superior (grupo/objetivo), nome+vida do boss, aviso de
## estado central, dica de ESC, texto de evento e os controles touch, tudo
## dentro do `canvas` (CanvasLayer) passado. Devolve um Dictionary com as
## referencias que o controller guarda em suas proprias variaveis.
static func build_hud(canvas: CanvasLayer, boss_display_name: String) -> Dictionary:
	var refs := {}

	var panel := ColorRect.new()
	panel.position = Vector2(0, 0)
	panel.size = Vector2(180, 24)
	panel.color = Color(0.02, 0.025, 0.035, 0.55)
	canvas.add_child(panel)

	var party_label := Label.new()
	party_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	party_label.add_theme_font_size_override("font_size", 6)
	party_label.add_theme_color_override("font_color", Color("ffe26f"))
	# size por ultimo (autowrap+fonte antes de entrar na tree pode inflar o
	# minimum_size e o Control nao encolhe sozinho depois).
	party_label.position = Vector2(4, 0)
	party_label.custom_minimum_size = Vector2(172, 12)
	party_label.size = Vector2(172, 12)
	panel.add_child(party_label)
	refs["party_label"] = party_label

	var objective_label := Label.new()
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	objective_label.add_theme_font_size_override("font_size", 5)
	objective_label.position = Vector2(4, 13)
	objective_label.custom_minimum_size = Vector2(172, 10)
	objective_label.size = Vector2(172, 10)
	panel.add_child(objective_label)
	refs["objective_label"] = objective_label

	var body_font: FontFile = load("res://assets/Fonts/Runtime/MedievalSharp-Book.ttf")

	var boss_name_label := Label.new()
	boss_name_label.text = boss_display_name
	boss_name_label.position = Vector2(BOSS_BAR_POS.x, BOSS_BAR_POS.y - 9.0)
	boss_name_label.size = Vector2(BOSS_BAR_SIZE.x, 8)
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.add_theme_font_override("font", body_font)
	boss_name_label.add_theme_font_size_override("font_size", 6)
	boss_name_label.add_theme_color_override("font_color", Color("e8b3a0"))
	canvas.add_child(boss_name_label)
	refs["boss_name_label"] = boss_name_label

	var boss_bar_bg := NinePatchRect.new()
	boss_bar_bg.texture = preload("res://assets/UI/Runtime/MedievalFree/health_bar.png")
	boss_bar_bg.position = BOSS_BAR_POS
	boss_bar_bg.size = BOSS_BAR_SIZE
	boss_bar_bg.patch_margin_left = 6
	boss_bar_bg.patch_margin_right = 6
	boss_bar_bg.patch_margin_top = 2
	boss_bar_bg.patch_margin_bottom = 2
	canvas.add_child(boss_bar_bg)
	refs["boss_bar_bg"] = boss_bar_bg

	var boss_bar_empty := ColorRect.new()
	boss_bar_empty.color = Color("2c1a1c")
	canvas.add_child(boss_bar_empty)
	refs["boss_bar_empty"] = boss_bar_empty

	var title_font: FontFile = load("res://assets/Fonts/Runtime/MedievalScrollOfWisdom.ttf")

	var state_label := Label.new()
	state_label.position = Vector2(0, 150)
	state_label.size = Vector2(180, 30)
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_label.add_theme_font_override("font", title_font)
	state_label.add_theme_font_size_override("font_size", 12)
	state_label.add_theme_color_override("font_color", Color("ffe26f"))
	state_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	state_label.add_theme_constant_override("outline_size", 4)
	canvas.add_child(state_label)
	refs["state_label"] = state_label

	var help := Label.new()
	help.text = "ESC: pausar e ver instrucoes"
	help.position = Vector2(5, 296)
	help.add_theme_font_size_override("font_size", 6)
	canvas.add_child(help)

	var event_label := Label.new()
	event_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	event_label.add_theme_font_size_override("font_size", 6)
	event_label.add_theme_color_override("font_color", Color("ffe26f"))
	event_label.position = Vector2(4, 46)
	event_label.custom_minimum_size = Vector2(172, 20)
	event_label.size = Vector2(172, 20)
	canvas.add_child(event_label)
	refs["event_label"] = event_label

	canvas.add_child(TouchControls.instantiate())

	refs["boss_bar_pos"] = BOSS_BAR_POS
	refs["boss_bar_size"] = BOSS_BAR_SIZE
	return refs


## Monta o CanvasLayer de pausa completo (fundo escurecido, painel,
## titulo, instrucoes, botoes CONTINUAR/VOLTAR A SELECAO com skin Medieval
## Free). Quem chama conecta os callables e guarda o CanvasLayer devolvido
## na sua propria `pause_layer`.
static func build_pause_menu(instructions_text: String, on_resume: Callable, on_back: Callable) -> CanvasLayer:
	var pause_layer := CanvasLayer.new()
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_layer.layer = 10

	var dim := ColorRect.new()
	dim.position = Vector2(0, 0)
	dim.size = Vector2(180, 320)
	dim.color = Color(0, 0, 0, 0.72)
	pause_layer.add_child(dim)

	var panel := ColorRect.new()
	panel.position = Vector2(6, 10)
	panel.size = Vector2(168, 300)
	panel.color = Color("1b2028")
	pause_layer.add_child(panel)

	var title_font: FontFile = load("res://assets/Fonts/Runtime/MedievalScrollOfWisdom.ttf")
	var body_font: FontFile = load("res://assets/Fonts/Runtime/MedievalSharp-Book.ttf")

	var title := Label.new()
	title.text = "PAUSADO"
	title.position = Vector2(6, 14)
	title.size = Vector2(168, 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", title_font)
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color("ffe26f"))
	pause_layer.add_child(title)

	var instructions := Label.new()
	instructions.text = instructions_text
	instructions.add_theme_font_override("font", body_font)
	# Coluna mais estreita que a paisagem precisa de mais quebras de linha
	# pro mesmo texto — fonte menor (5 em vez de 6) compensa a altura extra.
	instructions.add_theme_font_size_override("font_size", 5)
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD
	# size por ultimo — autowrap + fonte antes de entrar na tree infla o
	# minimum_size, e o Control nao encolhe sozinho depois (mesma armadilha
	# de loading_screen_12.gd).
	instructions.position = Vector2(12, 32)
	instructions.custom_minimum_size = Vector2(156, 220)
	instructions.size = Vector2(156, 220)
	pause_layer.add_child(instructions)

	var resume_btn := Button.new()
	resume_btn.text = "CONTINUAR"
	resume_btn.focus_mode = Control.FOCUS_NONE
	resume_btn.position = Vector2(24, 258)
	MedievalUI12.style_button(resume_btn, false, body_font, 8, Color("2a1a0f"), Vector2(132, 20))
	resume_btn.pressed.connect(on_resume)
	pause_layer.add_child(resume_btn)

	var back_btn := Button.new()
	back_btn.text = "VOLTAR A SELECAO"
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.position = Vector2(24, 284)
	MedievalUI12.style_button(back_btn, true, body_font, 7, Color("f4e7c9"), Vector2(132, 18))
	back_btn.pressed.connect(on_back)
	pause_layer.add_child(back_btn)

	pause_layer.visible = false
	return pause_layer
