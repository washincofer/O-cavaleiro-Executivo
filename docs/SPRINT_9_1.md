# Sprint 9.1 — Patch de Playtest

## Correção aplicada
O virote pneumático do Estagiário agora é disparado em uma linha estritamente horizontal, travada pela direção (`facing`) no instante do disparo.

### Comportamento esperado
- O projétil não acompanha o jogador.
- Saltar não faz o projétil subir.
- O projétil mantém a mesma altura até colidir com cenário, jogador ou expirar.
- A direção horizontal é determinada no momento do disparo.

## Teste da porta — Sprint 9 Master
1. Abra `scenes/dev/sprint9_master_test.tscn`.
2. Antes de derrotar os inimigos, tente atravessar a porta vermelha em x≈900: ela deve bloquear o jogador.
3. Derrote Espadachim, Estagiário e Coordenador.
4. O texto `ACESSO EXECUTIVO AUTORIZADO` deve aparecer.
5. A porta muda para verde e o collider é desativado.
6. Caminhe pela porta: o jogador deve atravessar até a área à direita.

Observação: nesta versão a passagem confirma o desbloqueio fisicamente; ainda não existe um gatilho separado de fim de fase após cruzar a porta.

Sprint 9.2: continuous bolt collision vs StaticBody2D.
