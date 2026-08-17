# Sprint 10D — Integration Specification

## 10D1 — Greybox Update

Atualizar o greybox da baseline 9.5 para o Blueprint da Recepção. Não reconstruir sistemas mecânicos já validados.

## 10D2 — Directed Regression Validation

Revalidar:
- movement
- environment collision
- ally navigation
- enemy navigation
- projectile collision
- Y-Sort

Classificar issues como:
- REGRESSION
- GEOMETRY ISSUE
- NEW REQUIREMENT

## 10D3 — Encounter Controller

Estados:
- ROOM_IDLE
- ROOM_COMBAT
- ROOM_COMPLETE

Trigger:
- ativado apenas pelo protagonista
- uso único por run

Exit:
- LOCKED em IDLE/COMBAT
- OPEN em COMPLETE

Completion:
- ActiveEncounterEnemies == 0
- PendingSpawns == 0

## 10D4 — Encounter v0.1

- Spawn A: 2 melee
- Spawn B: 1 ranged
- Spawn C: 1 melee
- Total: 4
- Single wave

Valid targets:
- Player
- Active Mercenaries

Friendly fire:
- disabled

## 10D5 — Visual Replacement

Ordem:
1. Floor
2. Walls
3. Doors
4. Counter + Pillars
5. Functional Props
6. Decoration
7. Revalidation

Greybox continua preservado para comparação/debug.

## 10D6 — Playtest

Executar a build integral. Registrar issues:
- BUG
- GAMEPLAY
- READABILITY
- ART
- BALANCE
- UX

Severity:
- P0 Blocker
- P1 Critical
- P2 Major
- P3 Minor

## 10D7 — Triage

Buckets:
- FIX NOW
- NEXT ITERATION
- BACKLOG

Gate:
- GO
- ITERATE
- NO-GO
