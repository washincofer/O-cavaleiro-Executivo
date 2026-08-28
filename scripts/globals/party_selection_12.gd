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
## - "free" (fases de boss: Ruinas, Floresta, Noite Estrelada): qualquer 3
##   personagens do elenco completo (incluindo Paladino/Cavaleiro, que nao
##   pertencem a nenhuma categoria) — a mecanica de interrupcao do boss
##   funciona igual nao importa quem for escalado.

const CATEGORY_BREAKER := "breaker"
const CATEGORY_PIERCER := "piercer"
const CATEGORY_TELEPORTER := "teleporter"

const CATEGORIES := [CATEGORY_BREAKER, CATEGORY_PIERCER, CATEGORY_TELEPORTER]

const OPTIONS := {
	CATEGORY_BREAKER: ["warrior", "fire_mage"],
	CATEGORY_PIERCER: ["archer", "lightning_mage"],
	CATEGORY_TELEPORTER: ["mage", "wanderer"],
}

const DEFAULT_SELECTION := {
	CATEGORY_BREAKER: "warrior",
	CATEGORY_PIERCER: "archer",
	CATEGORY_TELEPORTER: "mage",
}

const MODE_CATEGORIZED := "categorized"
const MODE_FREE := "free"

const ALL_ROLES := [
	"warrior", "archer", "mage", "fire_mage", "lightning_mage", "wanderer", "paladin", "knight",
]
const DEFAULT_FREE_ROLES: Array[String] = ["warrior", "archer", "mage"]
const FREE_PARTY_SIZE := 3

const DEFAULT_TARGET_SCENE := "res://scenes/playtest/platform_party_12.tscn"
const DEFAULT_LOADING_TITLE := "CARREGANDO A CAVERNA..."

var selection: Dictionary = DEFAULT_SELECTION.duplicate()
var selection_mode: String = MODE_CATEGORIZED
var free_roles: Array[String] = DEFAULT_FREE_ROLES.duplicate()
# Fase escolhida na tela de selecao, lida pela tela de loading para saber
# qual cena carregar de fato (cada fase mantem seu proprio controller) e
# qual texto mostrar na barra de progresso.
var target_scene: String = DEFAULT_TARGET_SCENE
var loading_title: String = DEFAULT_LOADING_TITLE

func get_role(category: String) -> String:
	return selection.get(category, DEFAULT_SELECTION[category])

func set_role(category: String, role: String) -> void:
	if OPTIONS.get(category, []).has(role):
		selection[category] = role

func toggle_free_role(role: String) -> void:
	if free_roles.has(role):
		free_roles.erase(role)
	elif free_roles.size() < FREE_PARTY_SIZE:
		free_roles.append(role)

func get_party_roles() -> Array[String]:
	if selection_mode == MODE_FREE:
		return free_roles.duplicate()
	var roles: Array[String] = []
	for category in CATEGORIES:
		roles.append(get_role(category))
	return roles
