# O Cavaleiro Executivo — Sprint 11B

## Escopo aprovado

Esta sprint incorpora duas decisões tomadas após o playtest da 11A:

1. Os próximos testes retornam ao formato **2D plataforma lateral**.
2. O **Auto Handoff on Death** entra dentro da própria 11B, sem criar uma 11A.1 separada.

## Objetivo da 11B

Validar no formato de plataforma o sistema de party iniciado na 11A:

- 1 protagonista + até 2 companions;
- seleção manual por `1`, `2`, `3`;
- apenas o personagem selecionado recebe input;
- aliados não selecionados seguem;
- companions não atacam automaticamente;
- ações dos companions só acontecem quando o jogador os controla e pressiona `J`;
- morte do personagem ativo transfere o controle automaticamente ao próximo vivo da sequência.

## Auto Handoff on Death

Ordem fixa e circular:

`1 -> 2 -> 3 -> 1`

Regras:

- se o slot ativo morrer, procurar o próximo slot vivo;
- pular qualquer slot já morto;
- manter os números dos slots fixos durante todo o teste;
- morte do Cavaleiro NÃO encerra a partida se houver companion vivo;
- Game Over somente quando os três slots estiverem mortos;
- morte de um membro que não está ativo não altera o controle atual.

Exemplos:

- `1` morre -> assume `2`; se `2` já morreu -> assume `3`;
- `2` morre -> assume `3`; se `3` já morreu -> assume `1`;
- `3` morre -> assume `1`; se `1` já morreu -> assume `2`.

## Retorno ao 2D plataforma

O novo laboratório possui:

- movimento horizontal;
- salto e gravidade;
- plataformas elevadas;
- dois vãos com queda fatal para testar handoff;
- câmera lateral seguindo apenas o personagem ativo;
- seguidores usando movimento simples e salto de acompanhamento;
- inimigos com contato/ataque simples para teste de HP e morte.

## Ações manuais usadas para validar a arquitetura

### Slot 1 — Cavaleiro

`J`: ataque corpo a corpo.

### Slot 2 — Espadachim

`J`: **Guarda** por 1,25 s, anulando dano enquanto ativa.

### Slot 3 — Estagiário

`J`: **Disparo de besta** manual.

**Importante:** Guarda e Disparo de Besta são implementações de laboratório para validar o roteamento de habilidades da 11B. Elas NÃO fecham sozinhas o moveset canônico final desses companions. O princípio canônico validado é: companion não age ofensivamente por IA; sua habilidade depende do controle direto do jogador.

O sistema continua preparado para companions puramente utilitários, inclusive o conceito já aprovado de um companion que posiciona uma escada para acesso a plataformas e controle de espaço.

## Controles

- `1` — Cavaleiro
- `2` — Espadachim
- `3` — Estagiário
- `A/D` ou setas — mover
- `Espaço` — pular
- `J` — ação do personagem ativo
- `K` — correr
- `R` — reiniciar

## Critérios de aceite do playtest

1. O jogo inicia em plataforma 2D com o Cavaleiro ativo.
2. `1/2/3` troca o personagem controlado.
3. A câmera acompanha o personagem ativo.
4. Os outros aliados seguem sem atacar automaticamente.
5. O Cavaleiro mantém ação ofensiva própria.
6. O Espadachim só usa Guarda quando controlado e `J` é pressionado.
7. O Estagiário só dispara a besta quando controlado e `J` é pressionado.
8. Cair em um vão mata o membro que caiu.
9. Se o membro morto era o ativo, o controle passa automaticamente ao próximo vivo.
10. A sequência de handoff é circular `1 -> 2 -> 3 -> 1`.
11. Slots mortos são pulados automaticamente.
12. Morte do Cavaleiro não causa Game Over enquanto houver companion vivo.
13. Game Over ocorre apenas quando toda a party morreu.
14. A seleção manual de um slot morto é recusada sem renumerar os demais.
15. Os inimigos continuam capazes de causar dano e matar membros.

## Arquivos do pacote

- `project.godot`
- `scenes/playtest/platform_party_11b.tscn`
- `scripts/playtest/platform_party_11b.gd`
- `scripts/playtest/platform_actor_11b.gd`
- `scripts/playtest/platform_bolt_11b.gd`
- `SPRINT_11B_README.md`
- `SPRINT_11B_TEST_CHECKLIST.md`

## Próximo passo após aprovação

Após o playtest, a próxima sprint deve decidir quais habilidades deixam de ser apenas prova mecânica e entram no kit canônico dos companions, além de iniciar as interações utilitárias próprias de plataforma (por exemplo: escada, bloqueio de passagem, acesso vertical e outras ferramentas de navegação).
