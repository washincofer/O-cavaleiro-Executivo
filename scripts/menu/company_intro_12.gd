extends Control

## Sprint 13: intro da empresa (video de abertura) antes da tela de selecao
## de fase. Toca uma unica vez ao abrir o jogo (run/main_scene), com opcao
## de pular via qualquer tecla/clique.
##
## Sprint 16: `_build_landscape()`/`_build_portrait()` (320x180/180x320,
## escolhida uma vez em `_ready()` via DeviceLayout12.is_portrait) — o botao
## PULAR usa o skin Kenney (KenneyUI12) nos dois modos.
##
## Pos-16 (pedido do usuario: "o video ainda esta dando zoom e ficando
## bugado, era literalmente so rodar o video como um youtube da vida"):
## no export Web o VideoStreamPlayer nativo do Godot decodifica Ogg Theora
## via software no thread principal do WASM — sob a carga do resto do jogo
## carregado junto, os frames chegavam corrompidos (zoom/blur progressivo
## crescente, confirmado comparando screenshots da execucao real contra os
## frames crus extraidos do .ogv com ffmpeg, que mostravam a cena correta
## sem nenhum zoom). Fix: no Web, em vez do player do Godot, injeta uma tag
## <video> HTML5 nativa (assets/Video/Runtime/company_intro.mp4, H.264,
## copiado solto pra dist/ por build_web.sh — nao empacotado no .pck) por
## cima do canvas via JavaScriptBridge — o MESMO caminho de decodificacao
## por hardware que qualquer video de um site (inclusive o Youtube) usa.
## Fora do Web (editor/nativo, sem JavaScriptBridge funcional) continua
## usando o VideoStreamPlayer original como fallback.

const VIDEO_PATH := "res://assets/Video/Runtime/company_intro.ogv"
# Duas fontes (<source> com fallback automatico do proprio navegador) —
# builds de Chromium open-source (ex.: o Chromium do Playwright usado nos
# testes desta sessao) nao trazem o decoder H.264 licenciado e falham com
# DEMUXER_ERROR_NO_SUPPORTED_STREAMS no .mp4 sozinho; VP9/Opus (.webm) e
# codec livre, sempre disponivel. Chrome/Firefox/Safari/Edge de verdade
# suportam os dois — a ordem so decide qual o navegador tenta primeiro.
const WEB_VIDEO_URL_WEBM := "company_intro.webm"
const WEB_VIDEO_URL_MP4 := "company_intro.mp4"
const STAGE_SELECT_SCENE := "res://scenes/menu/stage_select_12.tscn"
const BODY_FONT_PATH := "res://assets/Fonts/Runtime/AoboshiOne-Regular.ttf"
const VIDEO_ASPECT := 320.0 / 180.0

var player: VideoStreamPlayer
var changed_scene := false
var use_web_video := false
var web_video_started := false
var web_ended_callback: JavaScriptObject

func _ready() -> void:
	use_web_video = OS.has_feature("web")

	if DeviceLayout12.is_portrait:
		custom_minimum_size = Vector2(180, 320)
		_build_portrait()
	else:
		custom_minimum_size = Vector2(320, 180)
		_build_landscape()

	if use_web_video:
		_start_web_video()

func _build_landscape() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("000000")
	add_child(bg)

	if not use_web_video:
		player = VideoStreamPlayer.new()
		player.stream = load(VIDEO_PATH)
		player.position = Vector2(0, 0)
		player.size = Vector2(320, 180)
		player.expand = true
		player.autoplay = true
		player.finished.connect(_go_to_stage_select)
		add_child(player)

	var skip_hint := Label.new()
	skip_hint.text = "clique ou aperte qualquer tecla para pular"
	skip_hint.position = Vector2(0, 168)
	skip_hint.size = Vector2(320, 10)
	skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_hint.add_theme_font_override("font", load(BODY_FONT_PATH))
	skip_hint.add_theme_font_size_override("font_size", 6)
	skip_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	add_child(skip_hint)

	_build_skip_button(Vector2(240, 4), Vector2(72, 16))

func _build_portrait() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("000000")
	add_child(bg)

	# Video mantem o aspecto 16:9 nativo (letterboxed dentro do canvas
	# 180x320) em vez de esticar pra um retangulo 9:16 e distorcer a
	# imagem — largura cheia (180), altura calculada, centralizado.
	var video_h := 180.0 / VIDEO_ASPECT
	var video_y := (320.0 - video_h) * 0.5

	if not use_web_video:
		player = VideoStreamPlayer.new()
		player.stream = load(VIDEO_PATH)
		player.position = Vector2(0, video_y)
		player.size = Vector2(180, video_h)
		player.expand = true
		player.autoplay = true
		player.finished.connect(_go_to_stage_select)
		add_child(player)

	var skip_hint := Label.new()
	skip_hint.text = "clique ou aperte qualquer tecla para pular"
	skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	skip_hint.add_theme_font_override("font", load(BODY_FONT_PATH))
	skip_hint.add_theme_font_size_override("font_size", 7)
	skip_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	# size por ultimo — mesma armadilha do loading_screen_12.gd (autowrap +
	# fonte antes de entrar na tree infla o minimum_size, e o Control nao
	# encolhe sozinho depois).
	skip_hint.position = Vector2(4, video_y + video_h + 12)
	skip_hint.custom_minimum_size = Vector2(172, 20)
	skip_hint.size = Vector2(172, 20)
	add_child(skip_hint)

	_build_skip_button(Vector2(50, video_y - 24), Vector2(80, 18))

func _build_skip_button(pos: Vector2, size: Vector2) -> void:
	# Botao real (Control) alem da deteccao generica de tecla/clique/toque
	# em _unhandled_input — em touchscreens um Button nativo responde de
	# forma mais confiavel que checar o tipo do evento bruto durante a
	# reproducao do video.
	var skip_button := Button.new()
	skip_button.text = "PULAR >>"
	skip_button.focus_mode = Control.FOCUS_NONE
	skip_button.position = pos
	KenneyUI12.style_button(skip_button, false, 7, size)
	skip_button.pressed.connect(_go_to_stage_select)
	add_child(skip_button)

## Injeta uma tag <video> HTML5 por cima do canvas via JavaScriptBridge — o
## navegador decodifica H.264 por hardware, contornando o decoder Theora por
## software do Godot que ficava visivelmente corrompido no export Web sob
## carga (o bug de "zoom" reportado). Cobre a tela toda com letterbox
## (object-fit: contain) igual a um player de video comum.
func _start_web_video() -> void:
	web_ended_callback = JavaScriptBridge.create_callback(_on_web_video_ended)
	var window_obj: JavaScriptObject = JavaScriptBridge.get_interface("window")
	window_obj.__godot_intro_video_ended = web_ended_callback

	var js := """
	(function() {
		var old = document.getElementById('godot-intro-video');
		if (old) { old.remove(); }
		var v = document.createElement('video');
		v.id = 'godot-intro-video';
		var srcWebm = document.createElement('source');
		srcWebm.src = '%s';
		srcWebm.type = 'video/webm';
		v.appendChild(srcWebm);
		var srcMp4 = document.createElement('source');
		srcMp4.src = '%s';
		srcMp4.type = 'video/mp4';
		v.appendChild(srcMp4);
		v.autoplay = true;
		v.controls = false;
		v.playsInline = true;
		v.setAttribute('webkit-playsinline', 'true');
		v.style.position = 'fixed';
		v.style.top = '0';
		v.style.left = '0';
		v.style.width = '100vw';
		v.style.height = '100vh';
		v.style.objectFit = 'contain';
		v.style.background = '#000000';
		v.style.zIndex = '99999';
		document.body.appendChild(v);
		window.__godot_intro_video_el = v;
		var finish = function() { window.__godot_intro_video_ended(); };
		v.addEventListener('ended', finish);
		v.addEventListener('error', finish);
		v.load();
		var playPromise = v.play();
		if (playPromise !== undefined) {
			playPromise.catch(function() {
				// Autoplay com som bloqueado pelo navegador — tenta mudo
				// (mesma politica que qualquer site de video segue).
				v.muted = true;
				v.play().catch(finish);
			});
		}
	})();
	""" % [WEB_VIDEO_URL_WEBM, WEB_VIDEO_URL_MP4]
	JavaScriptBridge.eval(js, true)
	web_video_started = true

func _on_web_video_ended(_args: Array) -> void:
	_go_to_stage_select()

func _stop_web_video() -> void:
	if not web_video_started:
		return
	web_video_started = false
	JavaScriptBridge.eval("""
	(function() {
		var v = window.__godot_intro_video_el;
		if (v) { v.pause(); v.remove(); window.__godot_intro_video_el = null; }
	})();
	""", true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_go_to_stage_select()
	elif event is InputEventMouseButton and event.pressed:
		_go_to_stage_select()
	elif event is InputEventScreenTouch and event.pressed:
		_go_to_stage_select()

func _go_to_stage_select() -> void:
	if changed_scene:
		return
	changed_scene = true
	_stop_web_video()
	get_tree().change_scene_to_file(STAGE_SELECT_SCENE)
