extends Node

## Sprint 12/14 (selecao estilo Smash Bros): guarda a escolha de personagem
## entre a tela de selecao e a fase. Duas fontes de verdade dependendo do
## modo da fase escolhida (ver `selection_mode`):
##
## - "categorized" (so a Caverna): uma opcao por categoria de mecanica
##   (quebrar entulho / atravessar barreira / teleportar) — o puzzle da
##   Provacao do Trio so pode ser resolvido por UMA mecanica de cada tipo,
##   entao a escolha fica travada em DUAS opcoes por categoria, nunca livre
##   entre todo o elenco, garantindo que qualquer combinacao final consiga
##   terminar a fase.
## - "free" (fases de boss: Ruinas, Floresta, Cemiterio, Noite Estrelada):
##   qualquer 3 personagens do elenco completo (incluindo Paladino/Cavaleiro/
##   Heroina da Ponte, que nao pertencem a nenhuma categoria) — a mecanica de
##   interrupcao do boss funciona igual nao importa quem for escalado.
## - "gated" (Covil do Tesouro): igual a "free", mas com um `required_role`
##   sempre forcado num dos 3 slots (ver `stage_select_12.gd`/
##   `toggle_free_role`) — o vao da sala so pode ser cruzado pela mecanica
##   exclusiva desse personagem, entao ele nunca pode ser removido do grupo.

const CATEGORY_BREAKER := "breaker"
const CATEGORY_PIERCER := "piercer"
const CATEGORY_TELEPORTER := "teleporter"

const CATEGORIES := [CATEGORY_BREAKER, CATEGORY_PIERCER, CATEGORY_TELEPORTER]

# O Cavaleiro Executivo e obrigatorio em qualquer grupo (pedido do usuario) —
# a categoria "quebra entulho" vira uma opcao so, sempre ele (mesma mecanica
# de Estocada que Guerreiro/Cavaleiro-Knight ja usam), entao so sobram 2
# categorias de escolha real na Caverna. Nas fases livres/gated (boss),
# `mandatory_free_roles()` garante ele sempre presente nos 3 slots.
const MANDATORY_ROLE := "cavaleiro_executivo"

const OPTIONS := {
	CATEGORY_BREAKER: [MANDATORY_ROLE],
	CATEGORY_PIERCER: ["archer", "lightning_mage"],
	CATEGORY_TELEPORTER: ["mage", "wanderer"],
}

const DEFAULT_SELECTION := {
	CATEGORY_BREAKER: MANDATORY_ROLE,
	CATEGORY_PIERCER: "archer",
	CATEGORY_TELEPORTER: "mage",
}

const MODE_CATEGORIZED := "categorized"
const MODE_FREE := "free"
const MODE_GATED := "gated"

const ALL_ROLES := [
	MANDATORY_ROLE,
	"warrior", "archer", "mage", "fire_mage", "lightning_mage", "wanderer",
	"paladin", "knight", "bridge_heroine",
	"almoxarifado", "protocolo",
]
const DEFAULT_FREE_ROLES: Array[String] = [MANDATORY_ROLE, "archer", "mage"]
const FREE_PARTY_SIZE := 3

# Sprint 15: Paladino/Cavaleiro/Heroina da Ponte comecam bloqueados e sao
# liberados ao vencer o boss de uma fase nova especifica (ver
# `unlock_role`, chamado pelo controller de cada fase na vitoria) — nao
# fazem parte do elenco inicial disponivel na selecao livre.
const LOCKED_BY_DEFAULT := ["paladin", "knight", "bridge_heroine", "almoxarifado", "protocolo"]

const DEFAULT_TARGET_SCENE := "res://scenes/playtest/platform_party_12.tscn"
const DEFAULT_LOADING_TITLE := "CARREGANDO A CAVERNA..."

var selection: Dictionary = DEFAULT_SELECTION.duplicate()
var selection_mode: String = MODE_CATEGORIZED
var free_roles: Array[String] = DEFAULT_FREE_ROLES.duplicate()
var unlocked_roles: Array[String] = []
# Fase escolhida na tela de selecao, lida pela tela de loading para saber
# qual cena carregar de fato (cada fase mantem seu proprio controller) e
# qual texto mostrar na barra de progresso.
var target_scene: String = DEFAULT_TARGET_SCENE
var loading_title: String = DEFAULT_LOADING_TITLE

# Sprint 15: papel que a fase atual libera ao derrotar o boss (vazio = fase
# sem recompensa de personagem, como a Caverna e as Ruinas) — setado por
# `stage_select_12.gd` ao entrar na fase, lido pelo controller da fase na
# vitoria (`unlock_role` + transicao para a cutscene de desbloqueio) e pela
# propria cutscene (`last_unlocked_role`) para saber quem anunciar.
var stage_reward_role: String = ""
var last_unlocked_role: String = ""

# Sprint 15: papel exigido pela fase atual para ser jogada (vazio = sem
# restricao). Setado por `stage_select_12.gd` tanto para bloquear o acesso
# na propria selecao de fase (`is_unlocked`) quanto, no modo "gated", para
# forcar esse personagem no grupo (ver `toggle_free_role`).
var required_role: String = ""

# Dialogo estilo visual novel exibido antes da fase (Sprint pos-16, pedido
# do usuario) — setado por `stage_select_12.gd` junto com o resto do estado
# da fase; `dialogue_12.gd` le esses dois campos pra saber qual roteiro
# mostrar e qual fundo usar, e some (volta pra "") ao terminar/pular.
var pending_dialogue_id: String = ""
var pending_dialogue_bg: String = ""

# Pos-16 (Fase 00 - Recepcao/Prologo, pedido do usuario): a Fase 00 e
# jogada uma unica vez e nao aparece mais como fase selecionavel depois —
# esta flag e o unico estado novo que precisa sobreviver entre sessoes
# (por isso SaveSystem12 a le/escreve junto de `unlocked_roles`). Comeca
# false tanto num boot novo quanto num `SaveSystem12.new_game()`.
var prologue_cleared: bool = false

func _ready() -> void:
	for role in ALL_ROLES:
		if not LOCKED_BY_DEFAULT.has(role):
			unlocked_roles.append(role)

func is_unlocked(role: String) -> bool:
	return unlocked_roles.has(role)

func unlock_role(role: String) -> bool:
	if unlocked_roles.has(role):
		return false
	unlocked_roles.append(role)
	return true

func get_role(category: String) -> String:
	return selection.get(category, DEFAULT_SELECTION[category])

func set_role(category: String, role: String) -> void:
	if OPTIONS.get(category, []).has(role):
		selection[category] = role

func toggle_free_role(role: String) -> void:
	if role == MANDATORY_ROLE:
		return
	if selection_mode == MODE_GATED and role == required_role:
		return
	if free_roles.has(role):
		free_roles.erase(role)
	elif free_roles.size() < FREE_PARTY_SIZE:
		free_roles.append(role)

# Monta os 3 slots livres garantindo o Cavaleiro Executivo (e, se informado,
# um segundo papel exigido pela fase, ex.: Heroina da Ponte no modo gated)
# sempre presentes. Preenche o resto reaproveitando a selecao anterior do
# jogador (se ja tinha uma valida) e so cai pro default se precisar.
func mandatory_free_roles(extra_required: String = "") -> Array[String]:
	var roles: Array[String] = [MANDATORY_ROLE]
	if extra_required != "" and extra_required != MANDATORY_ROLE:
		roles.append(extra_required)
	for role in free_roles:
		if roles.size() >= FREE_PARTY_SIZE:
			break
		if not roles.has(role):
			roles.append(role)
	var fallback: Array[String] = DEFAULT_FREE_ROLES.duplicate()
	var fi := 0
	while roles.size() < FREE_PARTY_SIZE and fi < fallback.size():
		var role: String = fallback[fi]
		if not roles.has(role):
			roles.append(role)
		fi += 1
	return roles

func get_party_roles() -> Array[String]:
	if selection_mode == MODE_FREE or selection_mode == MODE_GATED:
		return free_roles.duplicate()
	var roles: Array[String] = []
	for category in CATEGORIES:
		roles.append(get_role(category))
	return roles
