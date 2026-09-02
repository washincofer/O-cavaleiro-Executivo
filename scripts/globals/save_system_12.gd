extends Node

## Autoload SaveSystem12 (pos-16, pedido do usuario: tela de Inicio e Salve).
## Ate aqui o jogo nao tinha NENHUMA persistencia — `PartySelection12`
## sempre volta pro padrao a cada boot (ver `_ready()` la). Este autoload e
## quem grava/le esse estado em disco, em 3 slots fixos, sem mexer em como
## `PartySelection12` e usado no resto do jogo: ele so espelha
## `unlocked_roles`/`prologue_cleared` pra dentro/fora de um arquivo JSON.
##
## Registrado depois de PartySelection12 em project.godot (autoloads podem
## se referenciar entre si livremente depois de `_ready()`; a ordem so
## importa se um usasse o outro dentro do proprio `_ready()`, o que nao
## acontece aqui).

const SLOT_COUNT := 3
const SAVE_PATH_FORMAT := "user://save_slot_%d.json"

## Slot atualmente "aberto" nesta sessao (-1 = nenhum — Menu Principal
## ainda nao escolheu Novo Jogo/Continuar). `save_game()` sem slot aberto
## nao faz nada, de proposito: os pontos de autosave (fim da Fase 00, vitoria
## de chefe, entrada no Stage Select) podem disparar antes de um slot existir
## em telas de teste/debug direto — falhar silenciosamente ai e mais seguro
## que gravar no slot errado.
var current_slot: int = -1
var play_seconds: float = 0.0

func _process(delta: float) -> void:
	if current_slot >= 1:
		play_seconds += delta


func slot_path(n: int) -> String:
	return SAVE_PATH_FORMAT % n


func slot_exists(n: int) -> bool:
	return FileAccess.file_exists(slot_path(n))


## Le só os metadados de um slot (pra popular os cards da tela de Salvar) —
## {} se o slot estiver vazio ou corrompido, nunca um erro.
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


## Reseta PartySelection12 pro estado inicial (mesma logica do `_ready()`
## dela) e abre `n` como slot atual, gravando o primeiro save imediatamente
## — assim um slot "novo jogo" já aparece como ATIVO na tela de Salvar mesmo
## antes do primeiro checkpoint da Fase 00.
func new_game(n: int) -> void:
	current_slot = n
	play_seconds = 0.0
	PartySelection12.unlocked_roles.clear()
	for role in PartySelection12.ALL_ROLES:
		if not PartySelection12.LOCKED_BY_DEFAULT.has(role):
			PartySelection12.unlocked_roles.append(role)
	PartySelection12.prologue_cleared = false
	save_game()


## Carrega `n` pra dentro de PartySelection12 e o marca como slot atual.
## Devolve false (sem mudar nada) se o slot estiver vazio/corrompido.
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
	return true


## Serializa o estado atual de PartySelection12 no slot aberto. Chamado nos
## pontos de autosave (fim da Fase 00, vitoria de cada chefe, entrada no
## Stage Select) e pelo botao manual "Salvar" da tela de Salvar/Carregar.
func save_game() -> void:
	if current_slot < 1:
		return
	var data := {
		"prologue_cleared": PartySelection12.prologue_cleared,
		"unlocked_roles": PartySelection12.unlocked_roles,
		"play_seconds": play_seconds,
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


## Slot mais recentemente salvo (maior `last_saved`), ou -1 se todos vazios
## — usado pelo botao "CONTINUAR" do Menu Principal.
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


## Contagem simples de progresso (personagens desbloqueados / total
## desbloqueavel) pra exibir na tela de Salvar sem precisar rastrear
## conclusao fase a fase (o jogo nao tem esse conceito hoje — ver plano).
func progress_ratio_from_meta(meta: Dictionary) -> float:
	var unlocked: Array = meta.get("unlocked_roles", [])
	var total: int = PartySelection12.ALL_ROLES.size()
	return float(unlocked.size()) / float(maxi(total, 1))
