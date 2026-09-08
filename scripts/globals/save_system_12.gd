extends Node

## Autoload SaveSystem12.
## RC2: alem de desbloqueios/prologo, persiste a progressao canonica de
## vida/economia/inventario mantida por Progression12.

const SLOT_COUNT := 3
const SAVE_PATH_FORMAT := "user://save_slot_%d.json"

var current_slot: int = -1
var play_seconds: float = 0.0

func _process(delta: float) -> void:
	if current_slot >= 1:
		play_seconds += delta

func slot_path(n: int) -> String:
	return SAVE_PATH_FORMAT % n

func slot_exists(n: int) -> bool:
	return FileAccess.file_exists(slot_path(n))

func read_slot_meta(n: int) -> Dictionary:
	if not slot_exists(n):
		return {}
	var f := FileAccess.open(slot_path(n), FileAccess.READ)
	if not f:
		return {}
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data

func new_game(n: int) -> void:
	current_slot = n
	play_seconds = 0.0
	PartySelection12.unlocked_roles.clear()
	for role in PartySelection12.ALL_ROLES:
		if not PartySelection12.LOCKED_BY_DEFAULT.has(role):
			PartySelection12.unlocked_roles.append(role)
	PartySelection12.prologue_cleared = false
	Progression12.reset_progression()
	save_game()

func load_game(n: int) -> bool:
	var data := read_slot_meta(n)
	if data.is_empty():
		return false
	current_slot = n
	play_seconds = float(data.get("play_seconds", 0.0))
	PartySelection12.unlocked_roles.clear()
	for role in data.get("unlocked_roles", []):
		PartySelection12.unlocked_roles.append(String(role))
	PartySelection12.prologue_cleared = bool(data.get("prologue_cleared", false))
	Progression12.deserialize(Dictionary(data.get("progression", {})))
	return true

func save_game() -> void:
	if current_slot < 1:
		return
	var data := {
		"prologue_cleared": PartySelection12.prologue_cleared,
		"unlocked_roles": PartySelection12.unlocked_roles,
		"play_seconds": play_seconds,
		"progression": Progression12.serialize(),
		"last_saved": Time.get_datetime_string_from_system(),
	}
	var f := FileAccess.open(slot_path(current_slot), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func delete_slot(n: int) -> void:
	if slot_exists(n):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(n)))
	if current_slot == n:
		current_slot = -1
		play_seconds = 0.0
		Progression12.reset_progression()

func most_recent_slot() -> int:
	var best := -1
	var best_stamp := ""
	for n in range(1, SLOT_COUNT + 1):
		var meta := read_slot_meta(n)
		if meta.is_empty():
			continue
		var stamp := String(meta.get("last_saved", ""))
		if stamp > best_stamp:
			best_stamp = stamp
			best = n
	return best

func progress_ratio_from_meta(meta: Dictionary) -> float:
	var unlocked: Array = meta.get("unlocked_roles", [])
	var total: int = PartySelection12.ALL_ROLES.size()
	return float(unlocked.size()) / float(maxi(total, 1))
