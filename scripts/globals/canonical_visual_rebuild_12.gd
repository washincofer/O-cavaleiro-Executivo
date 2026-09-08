extends Node

## Reconstrucao visual canonica RC2.
## Mantem a logica de gameplay dos controllers e corrige apresentacao em runtime:
## - Fase 00: NPCs interativos em posicoes seguras + patrulha curta ida/volta.
## - Fase 01: restaura os 11 backgrounds canônicos da Logistica.
## - Fase 02: mapa visual tematico funcional ate os backgrounds finais entrarem no Git.
## - Todas as fases de party: HUD canonica de HP + cooldown do ativo.
## - Sprites: garante visibilidade/z-order do protagonista e inimigos.

const FASE00 := "res://scenes/playtest/platform_fase00_12.tscn"
const FASE01 := "res://scenes/playtest/platform_fase01_operacoes_12.tscn"
const FASE02 := "res://scenes/playtest/platform_fase02_tecnologia_12.tscn"
const LOG_BG := "res://assets/Backgrounds/Runtime/FaseLogistica/"

const LOG_BACKGROUNDS := [
	"l01_docas_recebimento.png",
	"l02_triagem.png",
	"l03_separacao_conferencia.png",
	"l04_armazenagem_vertical.png",
	"l05_linha_operacoes.png",
	"l06_arena_estevao.png",
	"l07_nucleo_armazem.png",
	"l08_deposito_retencao.png",
	"l09_expedicao_pesada.png",
	"l10_doca_central.png",
	"l11_doca_grossmanobra.png",
]

var configured_scene_id := 0
var fase00_room_id := 0
var hud_layer: CanvasLayer
var hp_title: Label
var hp_bar: ProgressBar
var hp_text: Label
var cooldown_bar: ProgressBar
var cooldown_text: Label
var coins_text: Label

func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var sid := scene.get_instance_id()
	if sid != configured_scene_id:
		configured_scene_id = sid
		fase00_room_id = 0
		_destroy_hud()
		call_deferred("_configure_scene", scene)

	if scene.scene_file_path == FASE00:
		_configure_fase00_room_if_needed(scene)
		_update_npc_patrol(scene, delta)
	else:
		_update_canonical_hud(scene)
		_ensure_actor_sprites_visible(scene)

func _configure_scene(scene: Node) -> void:
	if not is_instance_valid(scene):
		return
	match scene.scene_file_path:
		FASE00:
			_configure_fase00_room_if_needed(scene)
		FASE01:
			_restore_fase01_backgrounds(scene)
			_build_canonical_hud(scene)
			_ensure_actor_sprites_visible(scene)
		FASE02:
			_build_fase02_backdrop(scene)
			_build_canonical_hud(scene)
			_ensure_actor_sprites_visible(scene)

# -----------------------------------------------------------------------------
# FASE 00 — NPCs e seguranca visual
# -----------------------------------------------------------------------------
func _configure_fase00_room_if_needed(scene: Node) -> void:
	var room := _find_room_root(scene)
	if room == null:
		return
	var rid := room.get_instance_id()
	if rid == fase00_room_id:
		return
	fase00_room_id = rid
	call_deferred("_setup_fase00_npcs", room)

func _find_room_root(root: Node) -> Node2D:
	for child in root.get_children():
		if child is Node2D and String(child.name).begins_with("Room_R00"):
			return child
	return null

func _setup_fase00_npcs(room: Node2D) -> void:
	if not is_instance_valid(room):
		return
	var floor_y := _fase00_floor_for_room(String(room.name))
	for node in _all_descendants(room):
		if not node is Sprite2D:
			continue
		var sprite := node as Sprite2D
		if sprite.texture == null:
			continue
		var path := sprite.texture.resource_path
		if not path.contains("Fase00NPCs/Runtime/"):
			continue
		# Decor de fundo continua estatico. NPC interativo usa standee centralizado.
		if path.get_file().begins_with("decor_"):
			continue
		sprite.z_index = 4
		sprite.position.y = floor_y - 64.0
		# Evita NPC colado em porta/marker e cria vida na recepcao sem bloquear rota.
		var preferred_x := sprite.position.x
		if path.contains("recepcionista"):
			preferred_x += 75.0
		elif path.contains("rh_standee"):
			preferred_x += 65.0
		elif path.contains("colega_standee"):
			preferred_x += 45.0
		sprite.position.x = clampf(preferred_x, 180.0, 1490.0)
		sprite.set_meta("patrol_base_x", sprite.position.x)
		sprite.set_meta("patrol_phase", randf_range(0.0, TAU))
		sprite.set_meta("patrol_range", 46.0)

func _fase00_floor_for_room(room_name: String) -> float:
	if room_name.contains("R00-02"):
		return 645.0
	if room_name.contains("R00-03"):
		return 718.0
	if room_name.contains("R00-04"):
		return 765.0
	return 770.0

func _update_npc_patrol(scene: Node, delta: float) -> void:
	var room := _find_room_root(scene)
	if room == null:
		return
	for node in _all_descendants(room):
		if not node is Sprite2D or not node.has_meta("patrol_base_x"):
			continue
		var sprite := node as Sprite2D
		var phase := float(sprite.get_meta("patrol_phase")) + delta * 0.65
		var base_x := float(sprite.get_meta("patrol_base_x"))
		var range_x := float(sprite.get_meta("patrol_range"))
		sprite.position.x = base_x + sin(phase) * range_x
		sprite.flip_h = cos(phase) < 0.0
		sprite.set_meta("patrol_phase", phase)

# -----------------------------------------------------------------------------
# FASE 01 — mapas reais L01-L11
# -----------------------------------------------------------------------------
func _restore_fase01_backgrounds(scene: Node) -> void:
	if scene.get_node_or_null("CanonicalLogisticsBackgrounds") != null:
		return
	# Fundo generico antigo fica oculto para nao competir com as artes por sala.
	for node in _all_descendants(scene):
		if node is Sprite2D and node.texture != null:
			var p := node.texture.resource_path
			if p.contains("Environment/Warehouse/Runtime/warehouse_bg"):
				node.visible = false

	var layer := Node2D.new()
	layer.name = "CanonicalLogisticsBackgrounds"
	layer.z_index = -100
	scene.add_child(layer)
	var world_width := 6320.0
	var section_w := world_width / float(LOG_BACKGROUNDS.size())
	for i in range(LOG_BACKGROUNDS.size()):
		var path := LOG_BG + LOG_BACKGROUNDS[i]
		if not ResourceLoader.exists(path):
			continue
		var tex: Texture2D = load(path)
		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.centered = false
		sprite.position = Vector2(section_w * i, 0)
		var uniform := section_w / float(tex.get_width())
		sprite.scale = Vector2(uniform, uniform)
		sprite.z_index = -100
		layer.add_child(sprite)
		# Escurece levemente para personagens/HUD permanecerem legiveis.
		sprite.modulate = Color(0.84, 0.84, 0.84, 1.0)

# -----------------------------------------------------------------------------
# FASE 02 — mapa visual tematico enquanto os fundos finais nao estao no Git
# -----------------------------------------------------------------------------
func _build_fase02_backdrop(scene: Node) -> void:
	if scene.get_node_or_null("CanonicalTechnologyMap") != null:
		return
	var map := Node2D.new()
	map.name = "CanonicalTechnologyMap"
	map.z_index = -80
	scene.add_child(map)
	var sectors := [
		[0.0, 980.0, Color("101827")],
		[980.0, 1960.0, Color("0d2028")],
		[1960.0, 2940.0, Color("111b2d")],
		[2940.0, 4140.0, Color("17172a")],
		[4140.0, 5200.0, Color("211526")],
	]
	for data in sectors:
		var x0 := float(data[0])
		var x1 := float(data[1])
		var bg := ColorRect.new()
		bg.position = Vector2(x0, 0)
		bg.size = Vector2(x1 - x0, 284)
		bg.color = data[2]
		bg.z_index = -80
		map.add_child(bg)
		# racks, cabos e paineis criam leitura de mapa real, nao tela vazia.
		for x in range(int(x0 + 70), int(x1 - 40), 150):
			var rack := ColorRect.new()
			rack.position = Vector2(x, 92)
			rack.size = Vector2(48, 146)
			rack.color = Color("263749")
			rack.z_index = -79
			map.add_child(rack)
			for y in range(106, 222, 20):
				var led := ColorRect.new()
				led.position = Vector2(x + 8, y)
				led.size = Vector2(32, 4)
				led.color = Color("5bc8b6")
				led.z_index = -78
				map.add_child(led)
	# Faixa de piso/cabeamento visual acima da colisao real do controller.
	var cable := ColorRect.new()
	cable.position = Vector2(0, 268)
	cable.size = Vector2(5200, 16)
	cable.color = Color("26384e")
	cable.z_index = -77
	map.add_child(cable)

# -----------------------------------------------------------------------------
# SPRITES — protagonista e inimigos
# -----------------------------------------------------------------------------
func _ensure_actor_sprites_visible(scene: Node) -> void:
	for node in _all_descendants(scene):
		var team = node.get("team")
		var role = node.get("role")
		if team == null or role == null:
			continue
		var sprite = node.get("sprite")
		if sprite is AnimatedSprite2D:
			sprite.visible = true
			sprite.z_index = 10
			sprite.modulate.a = 1.0
			# Protagonista canonico com gravata vermelha: usa o asset CavaleiroExecutivo
			# ja mapeado pelo PlatformActor; aqui corrigimos somente a leitura/tamanho.
			if String(role) == "cavaleiro_executivo":
				sprite.scale = Vector2.ONE
				node.scale = Vector2.ONE

# -----------------------------------------------------------------------------
# HUD canonica de HP + cooldown
# -----------------------------------------------------------------------------
func _build_canonical_hud(scene: Node) -> void:
	if is_instance_valid(hud_layer):
		return
	hud_layer = CanvasLayer.new()
	hud_layer.name = "CanonicalHUD12"
	hud_layer.layer = 90
	scene.add_child(hud_layer)

	var panel := ColorRect.new()
	panel.position = Vector2(8, 8)
	panel.size = Vector2(146, 58)
	panel.color = Color(0.03, 0.04, 0.07, 0.88)
	hud_layer.add_child(panel)

	hp_title = Label.new()
	hp_title.position = Vector2(14, 10)
	hp_title.size = Vector2(134, 12)
	hp_title.add_theme_font_size_override("font_size", 7)
	hp_title.text = "HP"
	hud_layer.add_child(hp_title)

	hp_bar = ProgressBar.new()
	hp_bar.position = Vector2(14, 23)
	hp_bar.size = Vector2(100, 9)
	hp_bar.show_percentage = false
	hud_layer.add_child(hp_bar)

	hp_text = Label.new()
	hp_text.position = Vector2(116, 20)
	hp_text.size = Vector2(35, 14)
	hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_text.add_theme_font_size_override("font_size", 7)
	hud_layer.add_child(hp_text)

	cooldown_bar = ProgressBar.new()
	cooldown_bar.position = Vector2(14, 40)
	cooldown_bar.size = Vector2(100, 8)
	cooldown_bar.min_value = 0
	cooldown_bar.max_value = 1
	cooldown_bar.show_percentage = false
	hud_layer.add_child(cooldown_bar)

	cooldown_text = Label.new()
	cooldown_text.position = Vector2(116, 36)
	cooldown_text.size = Vector2(35, 14)
	cooldown_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cooldown_text.add_theme_font_size_override("font_size", 7)
	hud_layer.add_child(cooldown_text)

	coins_text = Label.new()
	coins_text.position = Vector2(14, 51)
	coins_text.size = Vector2(132, 10)
	coins_text.add_theme_font_size_override("font_size", 7)
	hud_layer.add_child(coins_text)

func _update_canonical_hud(scene: Node) -> void:
	if not is_instance_valid(hud_layer):
		return
	var active := _find_active_actor(scene)
	if active == null:
		return
	var hp := int(active.get("hp"))
	var max_hp := maxi(1, int(active.get("max_hp")))
	hp_title.text = "%s — HP" % String(active.get("actor_name"))
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_text.text = "%d/%d" % [hp, max_hp]
	var cd := float(active.get("special_cooldown"))
	var cd_max := maxf(0.01, float(active.get("special_cooldown_max")))
	cooldown_bar.value = clampf(1.0 - (cd / cd_max), 0.0, 1.0)
	cooldown_text.text = "OK" if cd <= 0.0 else "%.1fs" % cd
	coins_text.text = "MOEDAS %d  |  E-TANK %d" % [Progression12.coins, Progression12.etank_charge]

func _find_active_actor(root: Node) -> Node:
	for node in _all_descendants(root):
		var team = node.get("team")
		var controlled = node.get("is_controlled")
		if team != null and String(team) == "ally" and controlled != null and bool(controlled):
			return node
	return null

func _destroy_hud() -> void:
	if is_instance_valid(hud_layer):
		hud_layer.queue_free()
	hud_layer = null

func _all_descendants(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child in root.get_children():
		if child is Node:
			out.append(child)
			out.append_array(_all_descendants(child))
	return out
