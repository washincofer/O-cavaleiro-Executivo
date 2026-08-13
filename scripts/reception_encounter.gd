extends Node2D

signal encounter_completed

const SWORDSMAN_SCENE := preload("res://scenes/enemies/swordsman.tscn")
const INTERN_SCENE := preload("res://scenes/enemies/intern_shooter.tscn")
const COORDINATOR_SCENE := preload("res://scenes/enemies/coordinator.tscn")

@export var phase_delay := 0.55

@onready var phase_label: Label = $PhaseLabel
@onready var door: StaticBody2D = $ExitDoor
@onready var door_collision: CollisionShape2D = $ExitDoor/CollisionShape2D
@onready var door_visual: Polygon2D = $ExitDoor/Visual
@onready var access_label: Label = $AccessLabel

var phase := 0
var alive_in_phase := 0
var encounter_finished := false

func _ready() -> void:
    access_label.visible = false
    _set_door_locked(true)
    _start_next_phase_later()

func _start_next_phase_later() -> void:
    await get_tree().create_timer(phase_delay).timeout
    if not is_inside_tree() or encounter_finished:
        return
    _start_next_phase()

func _start_next_phase() -> void:
    phase += 1

    match phase:
        1:
            phase_label.text = "FASE 1 - ESPADACHIM"
            _spawn_enemy(SWORDSMAN_SCENE, Vector2(315, 132))
        2:
            phase_label.text = "FASE 2 - PRESSAO COMBINADA"
            _spawn_enemy(SWORDSMAN_SCENE, Vector2(545, 132))
            _spawn_enemy(INTERN_SCENE, Vector2(480, 82))
        3:
            phase_label.text = "FASE 3 - COORDENADOR"
            _spawn_enemy(COORDINATOR_SCENE, Vector2(765, 126))
        _:
            _complete_encounter()

func _spawn_enemy(scene: PackedScene, spawn_position: Vector2) -> void:
    var enemy = scene.instantiate()
    add_child(enemy)
    enemy.global_position = spawn_position
    alive_in_phase += 1
    enemy.died.connect(_on_enemy_died)

func _on_enemy_died() -> void:
    alive_in_phase = maxi(0, alive_in_phase - 1)
    if alive_in_phase == 0 and not encounter_finished:
        _start_next_phase_later()

func _complete_encounter() -> void:
    if encounter_finished:
        return
    encounter_finished = true
    phase_label.text = "LABORATORIO CONCLUIDO"
    access_label.text = "ACESSO EXECUTIVO AUTORIZADO"
    access_label.visible = true
    _set_door_locked(false)
    encounter_completed.emit()

func _set_door_locked(locked: bool) -> void:
    door_collision.set_deferred("disabled", not locked)
    if locked:
        door_visual.color = Color(0.46, 0.16, 0.14, 1)
    else:
        door_visual.color = Color(0.18, 0.48, 0.25, 1)
