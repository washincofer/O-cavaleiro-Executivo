extends "res://scripts/main.gd"

@onready var door_collision: CollisionShape2D = $ExitDoor/CollisionShape2D
@onready var door_visual: Polygon2D = $ExitDoor/Visual
@onready var status_label: Label = $CanvasLayer/HUD/StatusLabel
@onready var access_label: Label = $AccessLabel

var enemies_alive := 0
var finished := false

func _ready() -> void:
    super._ready()
    access_label.visible = false
    _set_door_locked(true)
    var enemies := [$Swordsman, $InternShooter, $Coordinator]
    for enemy in enemies:
        if enemy != null and enemy.has_signal("died"):
            enemies_alive += 1
            enemy.died.connect(_on_enemy_died)
    _update_status()

func _on_enemy_died() -> void:
    enemies_alive = maxi(0, enemies_alive - 1)
    _update_status()
    if enemies_alive == 0 and not finished:
        finished = true
        _set_door_locked(false)
        access_label.visible = true
        access_label.text = "ACESSO EXECUTIVO AUTORIZADO"
        status_label.text = "SPRINT 9 - LABORATORIO COMPLETO"

func _update_status() -> void:
    if status_label != null and not finished:
        status_label.text = "SPRINT 9 - INIMIGOS RESTANTES: %d" % enemies_alive

func _set_door_locked(locked: bool) -> void:
    door_collision.set_deferred("disabled", not locked)
    if locked:
        door_visual.color = Color(0.46, 0.16, 0.14, 1)
    else:
        door_visual.color = Color(0.18, 0.48, 0.25, 1)
