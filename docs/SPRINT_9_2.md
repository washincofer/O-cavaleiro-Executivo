# Sprint 9.2 — Colisão contínua do virote

Patch da Sprint 9.1.

## Correção
O virote pneumático continua seguindo trajetória horizontal fixa, porém agora faz uma checagem contínua (ray sweep) entre a posição atual e a próxima posição a cada frame de física.

Objetivo: impedir que o projétil atravesse paredes, balcões, plataformas, portas ou outros `StaticBody2D`, inclusive quando o collider for fino.

## Teste recomendado
1. Posicione o Cavaleiro do lado oposto de uma parede/plataforma em relação ao Estagiário.
2. Deixe o Estagiário disparar.
3. O virote deve desaparecer ao tocar o obstáculo e nunca atingir o jogador atrás dele.
4. Repita com o balcão, a plataforma central e a porta ainda bloqueada.
5. Confirme que, sem obstáculo, o virote continua horizontal e causa 15 de dano ao acertar o jogador.
