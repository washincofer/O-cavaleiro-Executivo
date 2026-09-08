extends Node

## Integridade visual dos atores.
## Evita CharacterBody2D sem sprite quando um role foi criado dinamicamente.
## Personagens conhecidos usam seus SpriteFrames canonicos; inimigos corporativos
## sem role visual proprio usam o Especialista como fallback TEMPORARIO.

const FASE01 := "res://scenes/playtest/platform_fase01_operacoes_12.tscn"
const FASE02 := "res://scenes/playtest/platform_fase02_tecnologia_12.tscn"

var scan_left := 0.0

func _process(delta: float) -> void:
	scan_left -= delta
	if scan_left > 0.0:
		return
	scan_left = 0.35
	var scene := get_tree().current_scene
	if scene == null:
		return
	if scene.scene_file_path != FASE01 and scene.scene_file_path != FASE02:
		return
	_scan(scene)

func _scan(root: Node) -> void:
	_patch_actor(root)
	for child in root.get_children():
		if child is Node:
			_scan(child)

func _patch_actor(node: Node) -> void:
	var team_value = node.get("team")
	var role_value = node.get("role")
	if team_value == null or role_value == null:
		return
	var team := String(team_value)
	var role := String(role_value)
	var sprite_value = node.get("sprite")
	var sprite: AnimatedSprite2D = sprite_value if sprite_value is AnimatedSprite2D else null

	if sprite == null:
		sprite = AnimatedSprite2D.new()
		sprite.name = "CanonicalSpriteFallback"
		node.add_child(sprite)
		# A propriedade `sprite` existe no PlatformPartyActor12; atualiza quando possivel.
		node.set("sprite", sprite)

	var visual_role := role
	if team == "enemy" and (role == "almoxarifado" or role == "protocolo"):
		visual_role = "especialista"

	var frames := PlatformPartyActor12._build_sprite_frames(visual_role)
	if frames != null and frames.get_animation_names().size() > 0:
		if sprite.sprite_frames == null or sprite.sprite_frames.get_animation_names().is_empty():
			sprite.sprite_frames = frames
		elif team == "enemy" and (role == "almoxarifado" or role == "protocolo"):
			# Separa visualmente inimigo comum de companion com o mesmo role logico.
			sprite.sprite_frames = frames

	if sprite.sprite_frames != null:
		if sprite.sprite_frames.has_animation("idle") and (not sprite.is_playing() or sprite.animation == ""):
			sprite.animation = "idle"
			sprite.play("idle")
		sprite.visible = true
		sprite.z_index = 12

	if team == "enemy":
		# Diferenciacao de comuns sem alterar chefe/subchefe.
		if role == "almoxarifado":
			sprite.modulate = Color("d6b06d")
		elif role == "protocolo":
			sprite.modulate = Color("7fa8cf")
	else:
		sprite.modulate = Color.WHITE

	if role == "cavaleiro_executivo":
		sprite.z_index = 14
