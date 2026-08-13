extends Node2D

@onready var player = $Player
@onready var health_label: Label = $CanvasLayer/HUD/HealthLabel

func _ready() -> void:
    print("Laboratorio iniciado: O Cavaleiro Executivo")
    player.health_changed.connect(_on_player_health_changed)
    _on_player_health_changed(player.health, player.max_health)

func _on_player_health_changed(current_health: int, max_health: int) -> void:
    health_label.text = "HP %d/%d" % [current_health, max_health]
