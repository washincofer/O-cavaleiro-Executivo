extends Node

## RC2 canonical progression/economy state.
## Source of truth: docs/CANON_PROGRESSION_ECONOMY_RC2.md

const BASE_MAX_HP := 60
const MAX_MAX_HP := 100
const POWER_LIFE_STEP := 10
const FIRST_CLEAR_REWARD := 500
const REVIVE_COMPANION_DROP_CHANCE := 0.05

const HEAL_LOW := 5
const HEAL_MEDIUM := 15
const HEAL_HIGH := 20
const PICKUP_SCRIPT := preload("res://scripts/playtest/progression_pickup_12.gd")

# Bosses conhecidos recebem o tier maximo de moeda. Os demais tiers abaixo
# sao tuning inicial por HP e podem ser refinados por inimigo sem mudar o canon.
const BOSS_ROLES := ["necromancer", "satyr", "ogre", "bat", "dragon", "coordinator", "especialista", "danelmo"]

var coins: int = 0
var role_max_hp: Dictionary = {}
var revive_companion_items: int = 0
var extra_life_items: int = 0
var etank_charge: int = 0
var first_clear_rewarded_stages: Array[String] = []

var _scan_accum := 0.0
var _registered: Dictionary = {}

func _process(delta: float) -> void:
	_scan_accum += delta
	if _scan_accum < 0.25:
		return
	_scan_accum = 0.0
	var scene := get_tree().current_scene
	if scene != null:
		_scan_node(scene)

func _scan_node(node: Node) -> void:
	_register_actor_if_needed(node)
	for child in node.get_children():
		if child is Node:
			_scan_node(child)

func _register_actor_if_needed(node: Node) -> void:
	if not node.has_signal("died"):
		return
	var team_value = node.get("team")
	var role_value = node.get("role")
	if team_value == null or role_value == null:
		return
	var instance_id := node.get_instance_id()
	if _registered.has(instance_id):
		return
	_registered[instance_id] = true
	var team := String(team_value)
	if team == "ally":
		var role := String(role_value)
		var canonical_max := get_role_max_hp(role)
		node.set("max_hp", canonical_max)
		node.set("hp", canonical_max)
	if not node.is_connected("died", Callable(self, "_on_actor_died")):
		node.connect("died", Callable(self, "_on_actor_died"))
	node.tree_exited.connect(func(): _registered.erase(instance_id), CONNECT_ONE_SHOT)

func _on_actor_died(actor: Node) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	if String(actor.get("team")) != "enemy":
		return
	var parent := actor.get_parent()
	if parent == null:
		return
	var drop_pos := actor.global_position
	_spawn_pickup(parent, drop_pos + Vector2(-8, -4), "coin", coin_value_for_enemy(actor))
	_spawn_pickup(parent, drop_pos + Vector2(8, -4), roll_health_drop_kind(), 0)
	if should_drop_revive_companion():
		_spawn_pickup(parent, drop_pos + Vector2(0, -16), "revive_companion", 1)

func _spawn_pickup(parent: Node, world_position: Vector2, kind: String, amount: int) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var pickup := Area2D.new()
	pickup.set_script(PICKUP_SCRIPT)
	pickup.set("kind", kind)
	pickup.set("amount", amount)
	parent.call_deferred("add_child", pickup)
	pickup.set_deferred("global_position", world_position)

func coin_value_for_enemy(enemy: Node) -> int:
	var role := String(enemy.get("role"))
	if BOSS_ROLES.has(role):
		return 100
	var enemy_hp := int(enemy.get("max_hp"))
	if enemy_hp >= 12:
		return 50
	if enemy_hp >= 8:
		return 30
	if enemy_hp >= 5:
		return 10
	return 5

func reset_progression() -> void:
	coins = 0
	role_max_hp.clear()
	revive_companion_items = 0
	extra_life_items = 0
	etank_charge = 0
	first_clear_rewarded_stages.clear()

func get_role_max_hp(role: String) -> int:
	return int(role_max_hp.get(role, BASE_MAX_HP))

func apply_power_life(role: String) -> bool:
	var before := get_role_max_hp(role)
	if before >= MAX_MAX_HP:
		return false
	role_max_hp[role] = mini(MAX_MAX_HP, before + POWER_LIFE_STEP)
	return true

func apply_heal_to_actor(actor: Node, amount: int) -> int:
	if actor == null or not is_instance_valid(actor):
		return 0
	var hp_value = actor.get("hp")
	var max_hp_value = actor.get("max_hp")
	if hp_value == null or max_hp_value == null:
		return 0
	var hp_before := int(hp_value)
	var max_hp := int(max_hp_value)
	var missing := maxi(0, max_hp - hp_before)
	var direct_heal := mini(missing, amount)
	actor.set("hp", hp_before + direct_heal)
	var overflow := maxi(0, amount - direct_heal)
	if overflow > 0:
		etank_charge += overflow
	return direct_heal

func roll_health_drop_kind() -> String:
	var roll := randf()
	if roll < 0.50:
		return "heal_low"
	if roll < 0.90:
		return "heal_medium"
	return "heal_high"

func health_amount_for_kind(kind: String) -> int:
	match kind:
		"heal_low": return HEAL_LOW
		"heal_medium": return HEAL_MEDIUM
		"heal_high": return HEAL_HIGH
	return 0

func should_drop_revive_companion() -> bool:
	return randf() < REVIVE_COMPANION_DROP_CHANCE

func add_coins(amount: int) -> void:
	coins = maxi(0, coins + amount)

func grant_first_clear_reward(stage_id: String) -> bool:
	if stage_id == "" or first_clear_rewarded_stages.has(stage_id):
		return false
	first_clear_rewarded_stages.append(stage_id)
	add_coins(FIRST_CLEAR_REWARD)
	SaveSystem12.save_game()
	return true

func add_revive_companion_item(amount := 1) -> void:
	revive_companion_items = maxi(0, revive_companion_items + amount)

func consume_revive_companion_item() -> bool:
	if revive_companion_items <= 0:
		return false
	revive_companion_items -= 1
	return true

func add_extra_life_item(amount := 1) -> void:
	extra_life_items = maxi(0, extra_life_items + amount)

func consume_extra_life_item() -> bool:
	if extra_life_items <= 0:
		return false
	extra_life_items -= 1
	return true

func serialize() -> Dictionary:
	return {
		"coins": coins,
		"role_max_hp": role_max_hp,
		"revive_companion_items": revive_companion_items,
		"extra_life_items": extra_life_items,
		"etank_charge": etank_charge,
		"first_clear_rewarded_stages": first_clear_rewarded_stages,
	}

func deserialize(data: Dictionary) -> void:
	coins = int(data.get("coins", 0))
	role_max_hp = Dictionary(data.get("role_max_hp", {})).duplicate(true)
	revive_companion_items = int(data.get("revive_companion_items", 0))
	extra_life_items = int(data.get("extra_life_items", 0))
	etank_charge = int(data.get("etank_charge", 0))
	first_clear_rewarded_stages.clear()
	for stage in data.get("first_clear_rewarded_stages", []):
		first_clear_rewarded_stages.append(String(stage))
