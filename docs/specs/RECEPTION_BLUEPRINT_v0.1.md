# Reception Prototype Blueprint v0.1

## Zonas

1. Entrada
2. Recepção / Balcão
3. Arena Principal
4. Pressão Tática / Choke
5. Saída

## Layout funcional

- Entrada ampla, sem combate imediato.
- Player Spawn com espaço para grupo.
- Balcão próximo ao fundo/superior da sala.
- Duas rotas laterais ao balcão.
- 2 pilares em posições assimétricas.
- Área central aberta.
- 1 divisória criando pressão tática.
- Choke point deliberado, porém navegável.
- Saída visível e inicialmente LOCKED.

## Gameplay Zones

- ZONE_PLAYER_START
- ZONE_ENCOUNTER
- ZONE_OPEN_COMBAT
- ZONE_CHOKE
- ZONE_EXIT

## Technical Points

- SPAWN_PLAYER_START
- TRIGGER_ENCOUNTER_START
- SPAWN_ENEMY_A
- SPAWN_ENEMY_B
- SPAWN_ENEMY_C
- EXIT_DOOR

## Room Flow

ROOM_IDLE
→ TRIGGER_ENCOUNTER_START
→ ROOM_COMBAT
→ ActiveEnemies == 0 AND PendingSpawns == 0
→ ROOM_COMPLETE
→ EXIT_OPEN
→ TRANSITION
