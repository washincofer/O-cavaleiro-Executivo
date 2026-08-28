extends Node2D

## Sprint 15: flash de impacto (spritesheet "Hit" do pack Legacy Collection)
## instanciado por `Actor.take_damage()` a cada dano recebido — melee,
## projetil, rajada em area e pancada do boss passam todos por esse unico
## ponto, entao nenhum callsite de dano precisou mudar. Roda uma vez e se
## destroi sozinho ao terminar a animacao.

const HIT_TEX := preload("res://assets/VFX/Runtime/hit_spark.png")
const FRAME_W := 31
const FRAME_H := 32
const FRAME_COUNT := 3
const FPS := 18.0

func _ready() -> void:
	var sprite := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("hit")
	frames.set_animation_loop("hit", false)
	frames.set_animation_speed("hit", FPS)
	for i in range(FRAME_COUNT):
		var atlas := AtlasTexture.new()
		atlas.atlas = HIT_TEX
		atlas.region = Rect2(i * FRAME_W, 0, FRAME_W, FRAME_H)
		frames.add_frame("hit", atlas)
	sprite.sprite_frames = frames
	sprite.z_index = 50
	add_child(sprite)
	sprite.play("hit")
	sprite.animation_finished.connect(queue_free)
