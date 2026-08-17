# Character Sprite Specification v1.0

## Direções

Ordem canônica:
1. Down
2. Left
3. Right
4. Up

## Célula e composição

- Mesma dimensão de célula para todas as animações do mesmo padrão.
- Ground Line comum.
- Center X e Ground Y como referências.
- Pivot / Sorting Anchor na base, entre os pés.
- Escala do personagem imutável entre animações.
- Sem auto-trim.
- Armas podem extrapolar a área corporal, mas não a célula.
- Death precisa caber na célula canônica.

## Separação lógica

- Sprite visual ≠ Hurtbox.
- Sprite visual ≠ Hitbox.
- Sombra separada.
- VFX separados.
- Projéteis separados após o evento de spawn.

## Biblioteca

Core:
- idle [loop]
- walk [loop]
- attack [one-shot]
- hit [one-shot]
- death [one-shot]

Coordenador:
- invoke [one-shot]
- order [one-shot]

## Attack Phases

- Anticipation
- Active
- Recovery

## Eventos

Espadachim:
- HITBOX_ON
- HITBOX_OFF

Estagiário:
- PROJECTILE_SPAWN

Coordenador:
- INVOKE_EVENT
- ORDER_EVENT

## Exportação

- PNG RGBA.
- Native Scale 1x.
- Point/Nearest sampling.
- Uma sheet por animação.
- Linhas = direções.
- Colunas = tempo.
- Frame 0 = início lógico.
- Runtime contém somente APPROVED.
