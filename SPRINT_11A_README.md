# O Cavaleiro Executivo — Sprint 11A

## Objetivo

Prototipar o novo modelo de esquadrão aprovado:

- 1 protagonista + até 2 companions.
- Tecla `1`: controla o Cavaleiro.
- Tecla `2`: controla o Companion 1.
- Tecla `3`: controla o Companion 2.
- Apenas o personagem ativo recebe input de movimento.
- Aliados não controlados apenas seguem o personagem ativo.
- Companions não atacam automaticamente.
- `J` continua sendo ataque quando o Cavaleiro está ativo.
- `J` em um companion chama apenas o ponto de extensão de habilidade da Sprint 11B; nesta 11A não causa dano nem efeito de gameplay.
- IA dos inimigos permanece com comportamento de combate.

## Party usada no protótipo 11A

1. CAVALEIRO — protagonista.
2. ESPADACHIM — companion de teste / slot 2.
3. ESTAGIARIO — companion de teste / slot 3.

O Coordenador aliado sai da party ativa desta sprint para respeitar o limite de até 2 companions. O Coordenador inimigo permanece no encounter para preservar o teste da IA.

## Arquivos alterados

- `project.godot`: adiciona `select_party_1`, `select_party_2`, `select_party_3`.
- `scripts/playtest/reception_actor.gd`: separa protagonista de personagem controlado, desliga combate autônomo dos companions e mantém a IA inimiga.
- `scripts/playtest/reception_playtest.gd`: cria party de 3 slots, troca 1/2/3, câmera no personagem ativo, HUD e seam para a 11B.

## Critérios de aceite

1. Ao iniciar, o Cavaleiro está ativo.
2. `2` transfere movimento e câmera para o Espadachim.
3. `3` transfere movimento e câmera para o Estagiário.
4. `1` retorna ao Cavaleiro.
5. O personagem ativo tem anel amarelo.
6. Os dois aliados não ativos seguem o personagem ativo.
7. Durante combate, companions não atacam por IA.
8. `J` com Cavaleiro continua causando ataque.
9. `J` com companion mostra no HUD a chamada da habilidade 11B, sem causar dano.
10. IA inimiga continua atacando normalmente, inclusive ranged/coordinator.
11. Trigger e saída usam a posição do personagem ativo.
12. A party contém no máximo protagonista + 2 companions.

## Gancho para Sprint 11B

A 11B substitui o placeholder em `activate_companion_ability(actor)` por um roteador de habilidades reais, sem refazer a seleção 1/2/3.

As habilidades podem ser não ofensivas. Exemplo de design já decidido: um companion pode posicionar uma escada para acesso e controle de espaço sem realizar ataques.
