# Changelog DEV v0.4

## Added — Sprint 10C-A: Character Sprite Specification

- 4 direções: Down, Left, Right, Up.
- Core animations: Idle, Walk, Attack, Hit, Death.
- Coordenador: Invoke e Order.
- Attack model: Anticipation → Active → Recovery.
- Eventos:
  - Espadachim: HITBOX_ON / HITBOX_OFF.
  - Estagiário: PROJECTILE_SPAWN.
  - Coordenador: INVOKE_EVENT / ORDER_EVENT.
- Pivot: base/pés.
- Sprite, hurtbox e hitbox separados.
- Projéteis, VFX e sombra separados do charset.
- Runtime separado de Source.
- PNG RGBA, resolução nativa 1x, Point/Nearest, sem trim.
- Uma sheet por animação.
- Ordem de direções: Down / Left / Right / Up.
- Frames temporalmente da esquerda para a direita.

## Added — Sprint 10C-B: Reception Environment Specification

- Grid ortogonal regular.
- Famílias: Walkable, Blocking, Transition, Tactical, Decorative.
- Piso modular: base + 3 variações leves.
- Paredes modulares com cantos internos/externos e terminações.
- Portas: OPEN / CLOSED / LOCKED.
- Balcão modular, 2 pilares, divisória, banco e arquivo.
- Identidade corporativo-medieval.
- Movement Collision, Projectile Collision, Navigation e Visual separados.
- Y-Sort por anchor de base.
- Atlas por função: tiles, architecture, props, overlays.
- Manifest ambiental obrigatório.
- Blueprint da Recepção com 5 zonas funcionais.

## Added — Sprint 10D: Integration Plan

- Atualizar o greybox 9.5 em vez de reconstruí-lo.
- Estados da sala: ROOM_IDLE / ROOM_COMBAT / ROOM_COMPLETE.
- Encounter Trigger de uso único, ativado pelo protagonista.
- Exit: LOCKED durante encontro → OPEN após conclusão.
- Encounter v0.1:
  - Spawn A: 2 melee.
  - Spawn B: 1 ranged.
  - Spawn C: 1 melee.
  - Single wave.
- Vitória: ActiveEncounterEnemies == 0 e PendingSpawns == 0.
- Protocolo de playtest e triage P0–P3.
- Gate final: GO / ITERATE / NO-GO.

## Pending

- Build integrada da Recepção.
- Medidas físicas de sprites/tiles.
- Atlas e PNGs reais.
- Revalidação na engine.
- Playtest 10D6 e triage 10D7.
