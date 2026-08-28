extends Node

## Sprint 12 (selecao estilo Smash Bros): guarda a escolha de personagem por
## categoria entre a tela de selecao e a fase. O roster deixou de ser fixo
## (Guerreiro/Arqueira/Maga) mas o puzzle da Provacao do Trio so pode ser
## resolvido por UMA mecanica de cada categoria (quebrar entulho / atravessar
## a barreira / teleportar) — por isso a escolha e sempre uma entre DUAS
## opcoes por categoria, nunca livre entre os 6, garantindo que qualquer
## combinacao final consiga terminar a fase.

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

const DEFAULT_TARGET_SCENE := "res://scenes/playtest/platform_party_12.tscn"
const DEFAULT_LOADING_TITLE := "CARREGANDO A CAVERNA..."

var selection: Dictionary = DEFAULT_SELECTION.duplicate()
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

func get_party_roles() -> Array[String]:
	var roles: Array[String] = []
	for category in CATEGORIES:
		roles.append(get_role(category))
	return roles
