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

# E-Tank capacity/use is still tuning-pending. Charge is stored without
# enforcing a cap until the canonical capacity is explicitly locked.

var coins: int = 0
var role_max_hp: Dictionary = {}
var revive_companion_items: int = 0
var extra_life_items: int = 0
var etank_charge: int = 0
var first_clear_rewarded_stages: Array[String] = []

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
	if not ("hp" in actor and "max_hp" in actor):
		return 0
	var hp_before: int = int(actor.hp)
	var max_hp: int = int(actor.max_hp)
	var missing := maxi(0, max_hp - hp_before)
	var direct_heal := mini(missing, amount)
	actor.hp = hp_before + direct_heal
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
