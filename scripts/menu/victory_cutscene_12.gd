extends Control

## Sprint 15: tela curta mostrada logo apos vencer o boss de uma fase que
## libera um personagem novo (`PartySelection12.stage_reward_role`), antes de
## voltar a selecao de fase. O controller da fase ja chamou `unlock_role` e
## guardou o resultado em `PartySelection12.last_unlocked_role` antes de
## trocar para esta cena — fases sem recompensa (Caverna/Ruinas) nunca
## chegam aqui, o `completed`/vitoria delas continua levando direto de volta
## a selecao como antes.
##
## Sprint 16: `_build_landscape()` e o layout original (320x180, geometria
## intocada) com uma irma `_build_portrait()` (180x320) escolhida uma vez em
## `_ready()` — a tela ja era essencialmente uma pilha vertical, entao o
## retrato so redistribui os mesmos elementos com mais espaco. O botao
## CONTINUAR ganha o skin Medieval Free (MedievalUI12) nos dois modos.

const Actor = preload("res://scripts/playtest/platform_actor_12.gd")
const TITLE_FONT_PATH := "res://assets/Fonts/Runtime/AoboshiOne-Regular.ttf"
const BODY_FONT_PATH := "res://assets/Fonts/Runtime/AoboshiOne-Regular.ttf"
const STAGE_SELECT_SCENE := "res://scenes/menu/stage_select_12.tscn"

const PORTRAIT_PATH := {
	"paladin": "res://assets/UI/Runtime/Portraits/paladin.png",
	"knight": "res://assets/UI/Runtime/Portraits/knight.png",
	"bridge_heroine": "res://assets/UI/Runtime/Portraits/bridge_heroine.png",
}

var changed_scene := false

func _ready() -> void:
	if DeviceLayout12.is_portrait:
		custom_minimum_size = Vector2(180, 320)
		_build_portrait()
	else:
		custom_minimum_size = Vector2(320, 180)
		_build_landscape()

func _build_landscape() -> void:
	var role: String = PartySelection12.last_unlocked_role
	var title_font: FontFile = load(TITLE_FONT_PATH)
	var body_font: FontFile = load(BODY_FONT_PATH)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("0a0e16")
	add_child(bg)

	var banner := Label.new()
	banner.text = "NOVO PERSONAGEM DESBLOQUEADO!"
	banner.position = Vector2(0, 28)
	banner.size = Vector2(320, 16)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_override("font", title_font)
	banner.add_theme_font_size_override("font_size", 13)
	banner.add_theme_color_override("font_color", Color("ffd23f"))
	banner.add_theme_color_override("font_outline_color", Color("241a05"))
	banner.add_theme_constant_override("outline_size", 3)
	banner.modulate = Color(1, 1, 1, 0)
	add_child(banner)

	var frame := ColorRect.new()
	frame.position = Vector2(120, 54)
	frame.size = Vector2(80, 60)
	frame.color = Color("3a4258")
	add_child(frame)

	var frame_inner := ColorRect.new()
	frame_inner.position = Vector2(123, 57)
	frame_inner.size = Vector2(74, 54)
	frame_inner.color = Color("11141c")
	add_child(frame_inner)

	var portrait := TextureRect.new()
	portrait.position = Vector2(126, 60)
	portrait.size = Vector2(68, 48)
	portrait.pivot_offset = Vector2(34, 24)
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if PORTRAIT_PATH.has(role):
		portrait.texture = load(PORTRAIT_PATH[role])
	portrait.scale = Vector2(0.2, 0.2)
	add_child(portrait)

	var name_label := Label.new()
	name_label.text = Actor.DISPLAY_NAME.get(role, role.to_upper())
	name_label.position = Vector2(0, 120)
	name_label.size = Vector2(320, 14)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_override("font", title_font)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color("e8e2d0"))
	name_label.modulate = Color(1, 1, 1, 0)
	add_child(name_label)

	var hint := Label.new()
	hint.text = "agora disponivel na selecao de personagens das fases de chefe"
	hint.position = Vector2(0, 138)
	hint.size = Vector2(320, 10)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_override("font", body_font)
	hint.add_theme_font_size_override("font_size", 6)
	hint.add_theme_color_override("font_color", Color("8fa6c9"))
	add_child(hint)

	var continue_button := Button.new()
	continue_button.text = "CONTINUAR"
	continue_button.focus_mode = Control.FOCUS_NONE
	continue_button.position = Vector2(120, 156)
	KenneyUI12.style_button(continue_button, false, 8, Vector2(80, 18))
	continue_button.pressed.connect(_go_to_stage_select)
	add_child(continue_button)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(banner, "modulate:a", 1.0, 0.3)
	tween.tween_property(portrait, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.2)
	tween.tween_property(name_label, "modulate:a", 1.0, 0.3).set_delay(0.5)

func _build_portrait() -> void:
	var role: String = PartySelection12.last_unlocked_role
	var title_font: FontFile = load(TITLE_FONT_PATH)
	var body_font: FontFile = load(BODY_FONT_PATH)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("0a0e16")
	add_child(bg)

	var banner := Label.new()
	banner.text = "NOVO PERSONAGEM\nDESBLOQUEADO!"
	banner.position = Vector2(0, 36)
	banner.size = Vector2(180, 32)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_override("font", title_font)
	banner.add_theme_font_size_override("font_size", 13)
	banner.add_theme_color_override("font_color", Color("ffd23f"))
	banner.add_theme_color_override("font_outline_color", Color("241a05"))
	banner.add_theme_constant_override("outline_size", 3)
	banner.modulate = Color(1, 1, 1, 0)
	add_child(banner)

	var frame := ColorRect.new()
	frame.position = Vector2(50, 96)
	frame.size = Vector2(80, 60)
	frame.color = Color("3a4258")
	add_child(frame)

	var frame_inner := ColorRect.new()
	frame_inner.position = Vector2(53, 99)
	frame_inner.size = Vector2(74, 54)
	frame_inner.color = Color("11141c")
	add_child(frame_inner)

	var portrait := TextureRect.new()
	portrait.position = Vector2(56, 102)
	portrait.size = Vector2(68, 48)
	portrait.pivot_offset = Vector2(34, 24)
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if PORTRAIT_PATH.has(role):
		portrait.texture = load(PORTRAIT_PATH[role])
	portrait.scale = Vector2(0.2, 0.2)
	add_child(portrait)

	var name_label := Label.new()
	name_label.text = Actor.DISPLAY_NAME.get(role, role.to_upper())
	name_label.position = Vector2(0, 168)
	name_label.size = Vector2(180, 16)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_override("font", title_font)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color("e8e2d0"))
	name_label.modulate = Color(1, 1, 1, 0)
	add_child(name_label)

	var hint := Label.new()
	hint.text = "agora disponivel na selecao de personagens das fases de chefe"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint.add_theme_font_override("font", body_font)
	hint.add_theme_font_size_override("font_size", 7)
	hint.add_theme_color_override("font_color", Color("8fa6c9"))
	# size por ultimo (mesma armadilha do loading_screen_12.gd: autowrap +
	# fonte antes de entrar na tree infla o minimum_size, e o Control nao
	# encolhe sozinho depois).
	hint.position = Vector2(4, 194)
	hint.custom_minimum_size = Vector2(172, 32)
	hint.size = Vector2(172, 32)
	add_child(hint)

	var continue_button := Button.new()
	continue_button.text = "CONTINUAR"
	continue_button.focus_mode = Control.FOCUS_NONE
	continue_button.position = Vector2(50, 268)
	KenneyUI12.style_button(continue_button, false, 8, Vector2(80, 24))
	continue_button.pressed.connect(_go_to_stage_select)
	add_child(continue_button)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(banner, "modulate:a", 1.0, 0.3)
	tween.tween_property(portrait, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.2)
	tween.tween_property(name_label, "modulate:a", 1.0, 0.3).set_delay(0.5)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_go_to_stage_select()

func _go_to_stage_select() -> void:
	if changed_scene:
		return
	changed_scene = true
	PartySelection12.last_unlocked_role = ""
	get_tree().change_scene_to_file(STAGE_SELECT_SCENE)
