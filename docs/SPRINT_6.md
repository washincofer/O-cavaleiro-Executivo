# Sprint 6 — Correção de auto-dano

## Feedback validado no Sprint 5

- Movimentação: OK
- Salto: OK
- Dash: OK
- Dummy: 3 golpes para derrotar, conforme esperado
- Mercenário Espadachim: 3 golpes para derrotar, conforme esperado
- Comportamento básico dos inimigos: OK

## Bug encontrado

Ao realizar um ataque, a `AttackHitbox` do jogador podia sobrepor alguns pixels da própria `Hurtbox`. Como o código aceitava qualquer nó com `take_damage()` como alvo, o próprio `Player` podia ser registrado como vítima do ataque.

## Correção

O método `_apply_attack_hits()` agora ignora explicitamente `target == self`.

Nenhum valor de movimentação, dash, dano, alcance, vida ou IA foi alterado neste sprint.

## Validação solicitada

1. Atacar o Dummy três vezes.
2. Confirmar que a vida do jogador permanece em 100/100 enquanto o Dummy não causa dano.
3. Atacar o Espadachim e confirmar que o jogador só perde vida quando a janela ativa do golpe do Espadachim realmente o atinge.
4. Revalidar dash e movimentação apenas para garantir ausência de regressões.
