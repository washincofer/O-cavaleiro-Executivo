# O Cavaleiro Executivo — Sprint 11C

## Objetivo

Validar a primeira habilidade utilitaria real de plataforma: **Companion da Escada**.

A Sprint 11C parte da 11B.2 aprovada e preserva: plataforma 2D, selecao 1/2/3, Auto Handoff, followers protegidos, queda fatal, projeteis com colisao, IA sem suicidio e camera lateral.

## Party do laboratorio

1. **CAVALEIRO** — ataque manual.
2. **AUXILIAR ESCADA** — nome funcional e PROVISORIO; `J` posiciona/reposiciona a escada.
3. **ESTAGIARIO** — besta manual, mantido como comparacao de companion ofensivo manual.

O nome/visual definitivo do companion da escada **nao e canonizado nesta sprint**. O comportamento mecanico e o foco.

## Mecanica da escada

- Controle o slot 2 e pressione `J` sobre piso solido.
- A escada nasce ~22 px a frente do personagem e substitui qualquer escada anterior.
- Troque para qualquer aliado e use `W/S` junto a escada para subir/descer.
- A plataforma central esta ~108 px acima do piso: o salto normal (aprox. 40 px de altura fisica) nao deve alcanca-la.
- A escada possui colisao na **layer 8 apenas para inimigos**. Aliados nao colidem com o bloqueador.
- Quando um inimigo encosta no bloqueador, o HUD registra `BLOQUEIO OK`.
- Quando um personagem controlado alcanca a plataforma alta, o HUD registra `ALTO OK`.
- O playtest conclui quando os dois testes estiverem OK.

## Decisoes de design preservadas

- Companions continuam sem ataque automatico.
- A habilidade so e executada quando o companion e controlado.
- A escada continua existindo depois que o jogador troca de personagem.
- Inimigos comuns nao atravessam a escada; aliados podem usa-la.
- Followers inativos continuam protegidos contra dano/queda e podem ser resgatados.
- Inimigos passam a priorizar o personagem ativo, pois followers inativos nao participam do risco de combate.

## Arquivos

- `project.godot` — ativa a cena 11C e adiciona `move_up/move_down`.
- `scenes/playtest/platform_party_11c.tscn` — cena da sprint.
- `scripts/playtest/platform_party_11c.gd` — mundo, party, escada, HUD e criterios.
- `scripts/playtest/platform_actor_11c.gd` — escalada, companion ladder e colisao inimiga.
- `scripts/playtest/platform_ladder_11c.gd` — visual + bloqueador enemy-only.
- `scripts/playtest/platform_bolt_11c.gd` — besta preservada da 11B.2.

## O que testar

Veja `SPRINT_11C_TEST_CHECKLIST.md`.
