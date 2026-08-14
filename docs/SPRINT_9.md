# Sprint 9 — Build de Integração Completa

## Objetivo
Reunir em uma única build a base mecânica aprovada da Sprint 7 com todos os arquétipos já implementados:
- Cavaleiro Executivo
- Mercenário Espadachim
- Estagiário Atirador
- Coordenador de Contenção
- Sala de Protótipo 01 — A Recepção

## Filosofia desta Sprint
Sprint 9 é uma build de TESTE GLOBAL, não de polimento visual.

A prioridade é responder:
1. Todos os sistemas convivem na mesma cena?
2. Os três inimigos funcionam no fluxo completo?
3. A sala pode ser percorrida do começo ao fim?
4. Morte, reinício, dano, dash e ataque continuam estáveis?
5. O Estagiário continua alcançável?
6. A plataforma central continua acessível por salto normal?
7. Os inimigos deixaram de servir como plataforma?

## Cena principal
res://scenes/dev/sprint9_master_test.tscn

Todos os três inimigos já estão fisicamente presentes na Recepção. A porta final só libera quando todos forem derrotados.

## Cena comparativa preservada
res://scenes/dev/reception_full_test.tscn

Esta cena mantém a sequência por fases:
Espadachim -> Espadachim + Estagiário -> Coordenador.

## Controles
- A / seta esquerda: mover para esquerda
- D / seta direita: mover para direita
- Espaço: pular
- J: ataque
- K: dash
- R: reiniciar cena

## Nota visual
Os visuais runtime desta Sprint permanecem deliberadamente simples e estáveis. As artes conceituais aprovadas estão preservadas na documentação para futura integração nativa no Godot.
